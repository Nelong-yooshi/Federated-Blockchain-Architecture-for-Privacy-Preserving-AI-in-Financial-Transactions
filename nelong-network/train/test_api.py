import requests
import base64

pubkey = "alj;dfsalj;ksfdal;jk"

resp = requests.post("http://localhost:8080/pubkey", json={
    "pubkey": base64.b64encode(pubkey.encode()).decode()
})

print("status code: ", resp.status_code)
print("response context: ", resp.text)

try:
    print(resp.json())
except Exception as e:
    print("Json parse error: ", e)