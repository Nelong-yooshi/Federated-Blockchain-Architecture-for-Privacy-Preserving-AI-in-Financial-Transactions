'''
Code Name: Simulation TDX Environment
Description:
    Simulate TDX Env by construct attestation manually.

Change Log:
2025/05/27 Basic arch constructing, use
             
'''

from flask import Flask, jsonify, request, g
from cryptography.hazmat.primitives.asymmetric import rsa, padding
from cryptography.hazmat.primitives import hashes, serialization
import os, base64, json

app = Flask(__name__)

KEY_PATH = "enclave_private.pem"
PUB_PATH = "enclave_public.pem"
ATTESTATION_PATH = "attestation.json"
SIGNATURE_PATH = "attestation.sig"

# 生成 RSA 金鑰對
if not os.path.exists(KEY_PATH):
    private_key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    with open(KEY_PATH, "wb") as f:
        f.write(private_key.private_bytes(
            serialization.Encoding.PEM,
            serialization.PrivateFormat.PKCS8,
            serialization.NoEncryption()
        ))
    with open(PUB_PATH, "wb") as f:
        f.write(private_key.public_key().public_bytes(
            serialization.Encoding.PEM,
            serialization.PublicFormat.SubjectPublicKeyInfo
        ))

# 準備 attestation document
with open(PUB_PATH, "rb") as f:
    pub_pem = f.read()

attestation_doc = {
    "public_key": pub_pem.decode(),
    "model_hash": "abc123fakehash456",
    "enclave_config": "minimal-training-env-v1"
}

# 序列化後簽名
doc_json = json.dumps(attestation_doc, sort_keys=True)
with open(ATTESTATION_PATH, "w") as f:
    f.write(doc_json)

private_key = serialization.load_pem_private_key(open(KEY_PATH, "rb").read(), password=None)
signature = private_key.sign(
    doc_json.encode(),
    padding.PSS(mgf=padding.MGF1(hashes.SHA256()), salt_length=padding.PSS.MAX_LENGTH),
    hashes.SHA256()
)

with open(SIGNATURE_PATH, "wb") as f:
    f.write(signature)


@app.route("/attestation", methods=["GET"])
def get_attestation():
    return jsonify({
        "document": attestation_doc,
        "signature": base64.b64encode(signature).decode()
    })

@app.route("/decrypt", methods=["POST"])
def decrypt_data():
    enc_data = base64.b64decode(request.json["data"])
    decrypted = private_key.decrypt(
        enc_data,
        padding.OAEP(
            mgf=padding.MGF1(algorithm=hashes.SHA256()),
            algorithm=hashes.SHA256(),
            label=None
        )
    )
    return jsonify({"decrypted": decrypted.decode()})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)