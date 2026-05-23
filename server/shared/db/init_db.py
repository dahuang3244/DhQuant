# scripts/server/init_db.py
from pathlib import Path
import sys

PROJECT_ROOT = Path(__file__).resolve().parents[3]
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from server.shared.config.path import ensure_dirs
from server.shared.config.settings import get_settings
from server.shared.db.base import Base
from server.shared.db.session import engine
import server.shared.db.models  # 触发所有模型类的注册

def main():
    s = get_settings()
    ensure_dirs(s)
    Base.metadata.create_all(engine)
    print(f"数据库初始化完成：{s.sqlite_path}")

if __name__ == "__main__":
    main()
