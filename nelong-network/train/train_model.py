import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score
import xgboost as xgb

# === 1. 載入資料 ===
# 請將 "data.csv" 換成你的實際檔名
df = pd.read_csv("training_data_hashed.csv")
df["tx_date"] = pd.to_datetime(df["tx_date"])
df["tx_day"] = df["tx_date"].dt.day
df["tx_month"] = df["tx_date"].dt.month
df["tx_weekday"] = df["tx_date"].dt.weekday
df = df.drop(columns=["tx_date", "tx_time", "act_date"])

y = df["label"]
# === 2. 特徵與標籤分離 ===
X = pd.get_dummies(df.drop(columns=["label"]), drop_first=True)

# === 3. 資料切分（訓練:驗證 = 8:2）===
X_train, X_val, y_train, y_val = train_test_split(
    X, y, test_size=0.2, random_state=42, stratify=y
)

# === 4. 建立與訓練模型 ===
model = xgb.XGBClassifier(
    objective='binary:logistic',  # 若是多分類可改成 multi:softmax
    eval_metric='logloss',
    use_label_encoder=False,
    random_state=42
)
model.fit(X_train, y_train)

model.save_model("model.json")
# === 5. 驗證模型 ===
y_proba = model.predict_proba(X_val)[:, 1]
# 依照 90% 門檻判斷是否異常
y_pred_90 = (y_proba > 0.95).astype(int)
# 計算準確率
acc = accuracy_score(y_val, y_pred_90)
print(f"以 90% 機率門檻分類的準確率：{acc:.4f}")

# 如果你想看前幾筆預測結果：
result_df = X_val.copy()
result_df["true_label"] = y_val.values
result_df["pred_proba"] = y_proba
result_df["pred_label_90%"] = y_pred_90

print(result_df.head())
