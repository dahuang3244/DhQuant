from pathlib import Path
from server.shared.logging.setup import setup_logging, get_logger

# 确保 logs 目录存在
log_path = Path("./logs")
log_path.mkdir(exist_ok=True)

setup_logging("test-service", log_dir=log_path)
log = get_logger("my_module")
log.info("hello", action="startup", status="ok")
# 应该看到带 service=test-service 的彩色日志