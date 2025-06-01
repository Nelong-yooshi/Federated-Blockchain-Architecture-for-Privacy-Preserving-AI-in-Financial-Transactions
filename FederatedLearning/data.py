import pandas as pd, numpy as np, torch, os
from torch.utils.data import Dataset, DataLoader, WeightedRandomSampler
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler

FEATURES = [f"V{i}" for i in range(1, 29)]  # V1‑V28

class CreditDataset(Dataset):
    def __init__(self, X, y):
        self.X = torch.tensor(np.asarray(X), dtype=torch.float32)
        self.y = torch.tensor(np.asarray(y), dtype=torch.float32).view(-1, 1)
    def __len__(self):
        return len(self.X)
    def __getitem__(self, idx):
        return self.X[idx], self.y[idx]


def _make_balanced_loader(X, y, batch_size):
    cls_cnt = y.value_counts().to_dict()
    weights = y.map(lambda c: 1.0 / cls_cnt[c]).values
    sampler = WeightedRandomSampler(weights, num_samples=len(y), replacement=True)
    return DataLoader(CreditDataset(X, y), batch_size=batch_size, sampler=sampler, drop_last=False)


def load_federated_csv(csv_path: str, batch_size: int = 64, test_ratio: float = 0.2, val_ratio: float = 0.1):
    df = pd.read_csv(csv_path)

    scaler = StandardScaler()
    df[FEATURES] = scaler.fit_transform(df[FEATURES])

    loaders = []
    for cid in sorted(df["client_id"].unique()):
        dfc = df[df["client_id"] == cid].reset_index(drop=True)

        # ── 1st split: train+val vs test ──
        X_tmp, X_test, y_tmp, y_test = train_test_split(
            dfc[FEATURES], dfc["Class"],
            test_size=test_ratio, stratify=dfc["Class"], random_state=42)

        # ── 2nd split: train vs val ──
        real_val_ratio = val_ratio / (1.0 - test_ratio)  # fraction within tmp
        X_train, X_val, y_train, y_val = train_test_split(
            X_tmp, y_tmp,
            test_size=real_val_ratio,
            stratify=y_tmp,
            random_state=42)

        train_loader = _make_balanced_loader(X_train, y_train, batch_size)
        val_loader   = DataLoader(CreditDataset(X_val,  y_val),   batch_size=batch_size, shuffle=False)
        test_loader  = DataLoader(CreditDataset(X_test, y_test),  batch_size=batch_size, shuffle=False)
        loaders.append((train_loader, val_loader, test_loader))
    return loaders
