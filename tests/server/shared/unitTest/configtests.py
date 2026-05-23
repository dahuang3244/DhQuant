from server.shared.config.settings import get_settings
from server.shared.config.path import ensure_dirs
import os

s = get_settings()
ensure_dirs(s)

print(f"LOG_DIR exists: {os.path.exists(s.log_dir)}")
print(f"DATA_DIR exists: {os.path.exists(s.sqlite_path.parent)}")