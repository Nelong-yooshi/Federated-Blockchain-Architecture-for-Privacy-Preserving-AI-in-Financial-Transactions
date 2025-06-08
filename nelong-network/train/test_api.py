import requests

url = 'http://gwcs-a.nemo00407.uk/get_model'
response = requests.get(url)

if response.status_code == 200:
    with open('downloaded_model.json', 'wb') as f:
        f.write(response.content)
    print("模型下載完成")
else:
    print("下載失敗，狀態碼:", response.status_code)