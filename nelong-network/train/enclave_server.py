from flask import Flask, request, jsonify, after_this_request
from cryptography.hazmat.primitives.asymmetric import padding as asym_padding
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.backends import default_backend
import base64, json
import threading
import requests
import pandas as pd

app = Flask(__name__)

# session_id -> session info
sessions = {}

def create_session(session_id):
    private_key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    public_key = private_key.public_key()
    public_key_pem = public_key.public_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PublicFormat.SubjectPublicKeyInfo
    ).decode()

    attestation_doc = {
        "public_key": public_key_pem,
        "model_hash": "abc123fakehash456",
        "enclave_config": "minimal-training-env-v1"
    }

    doc_json = json.dumps(attestation_doc, sort_keys=True)
    signature = private_key.sign(
        doc_json.encode(),
        asym_padding.PSS(mgf=asym_padding.MGF1(hashes.SHA256()), salt_length=asym_padding.PSS.MAX_LENGTH),
        hashes.SHA256()
    )

    sessions[session_id] = {
        "private_key": private_key,
        "attestation_doc": attestation_doc,
        "signature": signature,
        "session_members": [],
    }

def get_session_or_400(session_id):
    session = sessions.get(session_id)
    if not session:
        return None, jsonify({"error": "invalid or missing session_id"}), 400
    return session, None, None

@app.route("/", methods=["GET"])
def home():
    return jsonify({"megage": "Welcome home!"})

@app.route('/new_session', methods=['POST'])
def new_session():
    data = request.get_json()
    session_id = data.get("sessionNbr")
    if not session_id:
        return jsonify({"error": "missing session_id"}), 400
    if session_id in sessions:
        return jsonify({"error": "session_id already exists"}), 400
    
    create_session(session_id)
    return jsonify({"status": "new session created", "sessionNbr": session_id})

@app.route("/attestation", methods=["POST"])
def get_attestation():
    data = request.get_json()
    session_id = data.get("sessionNbr")
    session, err, code = get_session_or_400(session_id)
    if err: return err, code

    return jsonify({
        "document": session["attestation_doc"],
        "signature": base64.b64encode(session["signature"]).decode()
    })

@app.route("/decrypt", methods=["POST"])
def decrypt_data():
    data = request.get_json()
    session_id = data.get("session_id")
    enc_data = data.get("data")
    if not enc_data:
        return jsonify({"error": "missing encrypted data"}), 400

    session, err, code = get_session_or_400(session_id)
    if err: return err, code

    try:
        decrypted = session["private_key"].decrypt(
            base64.b64decode(enc_data),
            asym_padding.OAEP(
                mgf=asym_padding.MGF1(algorithm=hashes.SHA256()),
                algorithm=hashes.SHA256(),
                label=None
            )
        )
        return jsonify({"decrypted": decrypted.decode()})
    except Exception as e:
        return jsonify({"error": str(e)}), 400

# 給網頁client的
@app.route("/train_register", methods=["POST"])
def train_member():
    data = request.get_json()
    sessionNbr = data.get("sessionNbr")
    mspID = data.get("mspID")
    if not mspID:
        return jsonify({"error": "need to provide MSP ID"}), 400

    session, err, code = get_session_or_400(sessionNbr)
    if err: return err, code

    session["session_members"].append(mspID)
    return jsonify({"status": "member added", "member_count": len(session["session_members"])})

@app.route("/member_lst", methods=["POST"])
def get_member_lst():
    data = request.get_json()
    sessionNbr = data.get("sessionNbr")
    session, err, code = get_session_or_400(sessionNbr)
    if err: return err, code

    @after_this_request
    def trigger_callback(response):
        # 開一個 thread 非同步執行後續操作
        threading.Thread(target=background_task, args=(session, sessionNbr)).start()
        return response
    
    return jsonify({"memberLst": session["session_members"]})

def background_task(session, sessionNbr):
    jsonData = {
        "sessionNbr": sessionNbr
    }
    resp = requests.post("https://gwcs-a.nemo00407.uk/get_data", json=jsonData)
    data = resp.json()['data']
    print(data)
    decrypted = []

    for p_raw in data:
        print(p_raw)
        if isinstance(p_raw, str):
            p = json.loads(p_raw)
        else:
            p = p_raw

        try:
            enc_key = base64.b64decode(p["key"])
            nonce = base64.b64decode(p["nonce"])
            ciphertext = base64.b64decode(p["data"] + '=' * (-len(p["data"]) % 4))
            tag = base64.b64decode(p["tag"] + '=' * (-len(p["tag"]) % 4))  # ✅ 新增：處理 tag
        except Exception as e:
            print("[!] base64 解碼錯誤：", e)
            continue

        try:
            # RSA 解密 AES key
            aes_key = session['private_key'].decrypt(
                enc_key,
                asym_padding.OAEP(
                    mgf=asym_padding.MGF1(algorithm=hashes.SHA256()),
                    algorithm=hashes.SHA256(),
                    label=None
                )
            )
        except Exception as e:
            print("[!] AES 金鑰解密錯誤：", e)
            continue

        try:
            # AES-GCM 解密（需提供 tag）
            decryptor = Cipher(
                algorithms.AES(aes_key),
                modes.GCM(nonce, tag),  # ✅ 使用 tag
                backend=default_backend()
            ).decryptor()

            plaintext = decryptor.update(ciphertext) + decryptor.finalize()
            decoded_str = plaintext.decode()
            print("[debug] 解密出來字串：", decoded_str)
        except Exception as e:
            print("[!] AES-GCM 解密錯誤：", e)
            continue

        try:
            obj = json.loads(decoded_str)
            print("[debug] 解密後 JSON：", obj)
        except Exception as e:
            print("[!] JSON decode 失敗：", e)
            continue

        decrypted.append(obj)

    print("[*] 解密完成：", decrypted)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
