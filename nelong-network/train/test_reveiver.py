import requests
import base64
import pandas as pd
from tqdm import tqdm

domain = ['b', 'c']

for i in tqdm(range(2, 4, 1)):

    # 讀取訓練資料
    df = pd.read_csv(f"training_data_{i}.csv")

    # 把 DataFrame 轉成 list of dict（每列變成一個 dictionary）
    txn_data = df.to_dict(orient="records")

    upload_payload = {
        "txnData": txn_data
    }

    # 發送 POST 請求給本機的 API server
    resp = requests.post(f"http://gwcs-{domain[i-2]}.nemo00407.uk/upload_data", json=upload_payload)