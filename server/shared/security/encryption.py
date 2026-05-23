from __future__ import annotations
import os
from pathlib import Path
from cryptography.fernet import Fernet

def generate_key() -> Path:
    from server.shared.config.settings import get_settings
    return get_settings().project_root/"data"/".master_key"

def gen_or_create_master_key() -> bytes:
    """
    优先读取环境变量 DHQUANT_MASTER_KEY，
    如果不存在则从文件读取，
    如果文件不存在则生成新的密钥并保存到文件
    """

    env_key = os.getenv("DHQUANT_MASTER_KEY")
    if env_key:
        return env_key.encode()

    key_path = generate_key()
    if key_path.exists():
        return key_path.read_bytes()
    #首次运行，生成密钥并保存
    key = Fernet.generate_key()
    key_path.parent.mkdir(parents=True, exist_ok=True)
    key_path.write_bytes(key)
    #设置文件权限
    os.chmod(key_path, 0o600)
    return key


def encrypt(plaintext:str)->str:
    key = gen_or_create_master_key()
    f = Fernet(key)
    return f.encrypt(plaintext.encode()).decode()

def decrypt(ciphertext:str)->str:
    key = gen_or_create_master_key()
    f = Fernet(key)
    return f.decrypt(ciphertext.encode()).decode()