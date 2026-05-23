# server/apps/supervisor/main.py
from __future__ import annotations
import os
import signal
import subprocess
import sys
import time

from server.shared.config.settings import get_settings
from server.shared.logging.setup import setup_logging, get_logger
from server.apps.supervisor.process_spec import PROCESS_SPECS

logger = get_logger("supervisor.main")


class ProcessManager:
    def __init__(self):
        self.processes = {}  # name -> (Popen, stdout_file, stderr_file)
        self.should_exit = False
        self.restart_counts = {}  # name -> count

    def start_all(self):
        """启动所有定义的服务进程。"""
        logger.info("Starting all DhQuant services...")
        s = get_settings()
        os.makedirs(s.log_dir, exist_ok=True)

        for name, cmd in PROCESS_SPECS.items():
            self.restart_counts[name] = 0
            self.start_process(name, cmd)

    def start_process(self, name: str, cmd: list[str]):
        """启动单个服务进程，并重定向 stdout/stderr 到独立日志文件。"""
        s = get_settings()
        stdout_path = s.log_dir / f"{name}_stdout.log"
        stderr_path = s.log_dir / f"{name}_stderr.log"

        logger.info(f"Launching service '{name}' with command: {' '.join(cmd)}")
        
        # 以追加模式打开 stdout/stderr 运行日志文件
        stdout_file = open(stdout_path, "a", encoding="utf-8")
        stderr_file = open(stderr_path, "a", encoding="utf-8")

        # 使用 setsid 创建独立进程组（Unix 独有，可确保子进程随父进程一同退出，防止 Dramatiq 孤儿进程）
        p = subprocess.Popen(
            cmd,
            stdout=stdout_file,
            stderr=stderr_file,
            preexec_fn=None if os.name == "nt" else os.setsid
        )
        self.processes[name] = (p, stdout_file, stderr_file)

    def stop_all(self):
        """停止所有正在运行的服务进程。"""
        logger.info("Stopping all DhQuant services...")
        self.should_exit = True

        # 1. 尝试发送 SIGTERM 终止进程组
        for name, (p, out_f, err_f) in list(self.processes.items()):
            logger.info(f"Terminating service '{name}' (PID: {p.pid})...")
            try:
                if os.name == "nt":
                    p.terminate()
                else:
                    # 向进程组发送信号，清理主进程及子 Dramatiq 进程
                    os.killpg(os.getpgid(p.pid), signal.SIGTERM)
            except ProcessLookupError:
                pass
            except Exception as e:
                logger.error(f"Error terminating '{name}': {e}")

        # 2. 等待进程退出，超时则强制 KILL
        for name, (p, out_f, err_f) in self.processes.items():
            try:
                p.wait(timeout=3.0)
                logger.info(f"Service '{name}' exited cleanly.")
            except subprocess.TimeoutExpired:
                logger.warn(f"Service '{name}' did not exit in 3s. Killing process group...")
                try:
                    if os.name == "nt":
                        p.kill()
                    else:
                        os.killpg(os.getpgid(p.pid), signal.SIGKILL)
                except Exception:
                    pass
            finally:
                out_f.close()
                err_f.close()

        self.processes.clear()

    def run_loop(self):
        """守护循环：监控子进程健康状况，意外退出时尝试重启。"""
        while not self.should_exit:
            try:
                time.sleep(1.0)
                for name, (p, out_f, err_f) in list(self.processes.items()):
                    ret = p.poll()
                    if ret is not None:
                        # 进程已退出
                        out_f.close()
                        err_f.close()

                        if self.should_exit:
                            break

                        logger.error(f"Service '{name}' exited unexpectedly with return code {ret}!")
                        
                        # 自动重启策略（最多重启 5 次）
                        if self.restart_counts[name] < 5:
                            self.restart_counts[name] += 1
                            logger.info(f"Restarting service '{name}' (attempt {self.restart_counts[name]}/5)...")
                            self.start_process(name, PROCESS_SPECS[name])
                        else:
                            logger.error(f"Service '{name}' reached max restart limit. Giving up.")
                            del self.processes[name]
            except KeyboardInterrupt:
                break
            except Exception as e:
                logger.error(f"Error in supervisor loop: {e}")
                time.sleep(2.0)


def main():
    s = get_settings()
    setup_logging("supervisor", s.log_dir)
    logger.info("Starting DhQuant Supervisor...")

    manager = ProcessManager()

    def signal_handler(signum, frame):
        logger.info(f"Received exit signal ({signum}), shutting down cluster...")
        manager.stop_all()
        sys.exit(0)

    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)

    manager.start_all()
    manager.run_loop()
    manager.stop_all()


if __name__ == "__main__":
    main()
