from __future__ import annotations
import logging
import logging.handlers
import inspect
import functools
import time
from pathlib import Path
import structlog



def _add_func_name(logger, method_name, event_dict):
    """自动添加调用函数的名称和行号到日志中"""
    # 遍历调用栈，找到第一个不在 logging 模块中的函数
    for frame_info in inspect.stack()[2:]:
        frame = frame_info.frame
        if 'structlog' not in frame.f_code.co_filename and 'logging' not in frame.f_code.co_filename:
            event_dict['func_name'] = frame.f_code.co_name
            event_dict['line_no'] = frame_info.lineno
            # 获取文件名（不含路径）
            event_dict['file_name'] = frame_info.filename.split('/')[-1]
            break
    return event_dict


def _custom_renderer(logger, method_name, event_dict):
    """自定义渲染器：格式化日志输出"""
    timestamp = event_dict.pop('timestamp', '')
    level = event_dict.pop('_level', method_name.upper())
    func_name = event_dict.pop('func_name', 'unknown')
    line_no = event_dict.pop('line_no', 0)
    file_name = event_dict.pop('file_name', '')
    event = event_dict.pop('event', '')
    
    # 构建日志头部
    log_header = f"{timestamp} [{level}] {file_name}:{line_no}: {func_name}():"
    
    # 构建事件和其他信息
    parts = [event]
    for key, value in sorted(event_dict.items()):
        if key not in ('_logger', '_name'):
            if isinstance(value, str):
                parts.append(f"{key}='{value}'")
            else:
                parts.append(f"{key}={value}")
    
    log_body = " ".join(parts)
    return f"{log_header} {log_body}"



def setup_logging(service_name: str, log_dir: Path | None = None, log_level=logging.INFO) -> None:
   # "在每个服务进程启动时调用一次，设置日志记录器":
    handlers: list[logging.Handler] = [logging.StreamHandler()]

    if log_dir:
        log_dir.mkdir(parents=True, exist_ok=True)
        file_handler = logging.handlers.RotatingFileHandler(
            log_dir / f"{service_name}.log",
            maxBytes=50 * 1024 * 1024,  # 50 MB
            backupCount=5,
            encoding='utf-8'
        )
        handlers.append(file_handler)
    logging.basicConfig(
        level=log_level,
        format="%(message)s",
        handlers=handlers
    )

    structlog.configure(
        processors=[
            structlog.contextvars.merge_contextvars,  # 合并上下文变量
            structlog.stdlib.add_log_level,  # 添加日志级别
            _add_func_name,  # 添加函数名称和行号
            structlog.processors.TimeStamper(fmt="%Y-%m-%d %H:%M:%S", utc=False),  # 本地时间
            _custom_renderer,  # 使用自定义渲染器格式化输出
        ],
        wrapper_class=structlog.stdlib.BoundLogger,
        context_class=dict,
        logger_factory=structlog.stdlib.LoggerFactory(),
    )

    structlog.contextvars.bind_contextvars(service=service_name)

def get_logger(name: str = "dhquant") -> structlog.stdlib.BoundLogger:
    return structlog.get_logger(name)


def log_execution(operation_name: str | None = None):
    """装饰器：自动记录函数执行过程（开始、完成、失败、耗时）
    
    Args:
        operation_name: 操作名称。如果不提供，将使用函数名称
        
    Example:
        @log_execution("backtest_run")
        def run_backtest(strategy_id: str):
            return {"sharpe": 1.5}
            
        # 输出示例：
        # 2026-05-23 15:30:45 [INFO] backtest_run_started
        # 2026-05-23 15:31:50 [INFO] backtest_run_completed elapsed_seconds=65.2 func=run_backtest
    """
    def decorator(func):
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            name = operation_name or func.__name__
            logger = get_logger(name)
            
            start_time = time.time()
            logger.info(f"{name}_started")
            try:
                result = func(*args, **kwargs)
                elapsed = time.time() - start_time
                logger.info(f"{name}_completed", elapsed_seconds=round(elapsed, 2))
                return result
            except Exception as e:
                elapsed = time.time() - start_time
                logger.error(f"{name}_failed", error=str(e), elapsed_seconds=round(elapsed, 2), exc_info=True)
                raise
        return wrapper
    return decorator