from flask import Flask, request, jsonify
from cryptography.hazmat.primitives.asymmetric import rsa, padding
from cryptography.hazmat.primitives import hashes, serialization
import base64, json

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
        padding.PSS(mgf=padding.MGF1(hashes.SHA256()), salt_length=padding.PSS.MAX_LENGTH),
        hashes.SHA256()
    )

    sessions[session_id] = {
        "private_key": private_key,
        "attestation_doc": attestation_doc,
        "signature": signature,
        "session_members": []
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
    session_id = data.get("session_id")
    if not session_id:
        return jsonify({"error": "missing session_id"}), 400
    if session_id in sessions:
        return jsonify({"error": "session_id already exists"}), 400
    
    create_session(session_id)
    return jsonify({"status": "new session created", "session_id": session_id})

@app.route("/attestation", methods=["POST"])
def get_attestation():
    data = request.get_json()
    session_id = data.get("session_id")
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
            padding.OAEP(
                mgf=padding.MGF1(algorithm=hashes.SHA256()),
                algorithm=hashes.SHA256(),
                label=None
            )
        )
        return jsonify({"decrypted": decrypted.decode()})
    except Exception as e:
        return jsonify({"error": str(e)}), 400

# 給網頁client的
@app.route("/train_member", methods=["POST"])
def train_member():
    data = request.get_json()
    session_id = data.get("session_id")
    mspID = data.get("mspID")
    if not mspID:
        return jsonify({"error": "need to provide MSP ID"}), 400

    session, err, code = get_session_or_400(session_id)
    if err: return err, code

    session["session_members"].append(mspID)
    return jsonify({"status": "member added", "member_count": len(session["session_members"])})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
