'''
Code Name: Model Training Client
Description:
    Connect to TDX environment with attestation, and get the public key back.
    Invoke Fabric Gateway Client API, the client will invoke chaincode, get training data.
    Passing the train data to TDX Env by gRPC

Change Log:
2025/05/27 Basic arch constructing, use
             
'''

import requests
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import padding
import base64, json

# 取得 attestation
resp = requests.get("http://localhost:5000/attestation").json()
doc = resp["document"]
signature = base64.b64decode(resp["signature"])

# 載入公鑰
pubkey = serialization.load_pem_public_key(doc["public_key"].encode())
print()
# 驗證簽章
pubkey.verify(
    signature,
    json.dumps(doc, sort_keys=True).encode(),  # 加入 sort_keys 確保一致性
    padding.PSS(mgf=padding.MGF1(hashes.SHA256()), salt_length=padding.PSS.MAX_LENGTH),
    hashes.SHA256()
)

print("Attestation verified. You may now securely communicate.")

plaintext = "很重要哦，訓練資料要記得加密".encode("utf-8")
ciphertext = pubkey.encrypt(
    plaintext,
    padding.OAEP(
        mgf=padding.MGF1(algorithm=hashes.SHA256()),
        algorithm=hashes.SHA256(),
        label=None
    )
)

resp = requests.post("http://localhost:5000/decrypt", json={
    "data": base64.b64encode(ciphertext).decode()
})

print("狀態碼:", resp.status_code)
print("回應內容:", resp.text)

try:
    print(resp.json())
except Exception as e:
    print("JSON parse error:", e)