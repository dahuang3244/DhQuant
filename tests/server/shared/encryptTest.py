from server.shared.security.encryption import encrypt, decrypt
c = encrypt("sk-my-secret-api-key")
print(c)           # 乱码密文
print(decrypt(c))  # 恢复原文