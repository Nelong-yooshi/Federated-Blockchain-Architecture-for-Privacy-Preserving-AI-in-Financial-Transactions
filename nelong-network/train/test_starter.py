import requests
import base64
import pandas as pd
import time


# 向 enclave-server 啟動 training session 並取得 session 編號
resp = requests.get("https://gwcs-a.nemo00407.uk/start_upload")
print("Status:", resp.status_code)
print("Raw response:", repr(resp.text))  # 用 repr 看有無隱藏字元

try:
    sess_json = resp.json()
    print("Session JSON:", sess_json)
except Exception as e:
    print("Failed to decode JSON:", e)

sess_nbr = sess_json['sessionNbr']
print(sess_nbr)
# 準備 POST 的 payload

# 讀取訓練資料
df = pd.read_csv("training_data_1.csv")

# 把 DataFrame 轉成 list of dict（每列變成一個 dictionary）
txn_data = df.to_dict(orient="records")

upload_payload = {
    "txnData": txn_data
}
print(upload_payload)
# 發送 POST 請求給本機的 API server
resp = requests.post("http://gwcs-a.nemo00407.uk/upload_data", json=upload_payload)


tmp = input("等待中:")
requests.get("https://gwcs-a.nemo00407.uk/end_upload")

# API 的 URL（請視情況調整）
url = "http://gwcs-a.nemo00407.uk/get_data"

# 傳送的 JSON 資料
payload = {
    "sessionNbr": sess_nbr  # <- 這裡填你實際的 SessionNbr
}

try:
    # 發送 POST 請求
    response = requests.post(url, json=payload)

    # 檢查回應狀態碼
    if response.status_code == 200:
        data = response.json()
        result = data.get("data", [])
        print("Result:")
        for item in result:
            print(item)
    else:
        print(f"Request failed with status code {response.status_code}")
        print("Response:", response.text)

except requests.exceptions.RequestException as e:
    print("Error during request:", e)

# 印出結果
# print("Status code:", resp.status_code)
# print("Response:", resp.json())