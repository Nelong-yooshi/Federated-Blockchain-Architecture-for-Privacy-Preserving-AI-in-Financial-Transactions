import csv, os, copy, numpy as np, torch
from typing import List, Tuple, Dict
import torch.nn as nn, torch.optim as optim
from sklearn.metrics import (
    accuracy_score, precision_score, recall_score, f1_score,
)
import matplotlib.pyplot as plt
from model import FedNet

MetricDict = Dict[str, float]



def _train_local(model, loader, criterion, optimizer, device):
    model.train(); running = 0.0
    for x, y in loader:
        x, y = x.to(device), y.to(device)
        optimizer.zero_grad()
        out = model(x)
        loss = criterion(out, y)
        loss.backward(); optimizer.step()
        running += loss.item() * y.size(0)
    return running / len(loader.dataset)


def _evaluate(model, loaders, device) -> MetricDict:
    model.eval(); y_true, y_prob = [], []
    with torch.no_grad():
        for loader in loaders:
            for x, y in loader:
                prob = model(x.to(device)).cpu().numpy().reshape(-1)
                y_prob.extend(prob.tolist())
                y_true.extend(y.numpy().reshape(-1).tolist())
    y_pred = (np.array(y_prob) >= 0.99).astype(int)
    return {
        "accuracy":  accuracy_score(y_true, y_pred),
        "precision": precision_score(y_true, y_pred, zero_division=0),
        "recall":    recall_score(y_true, y_pred, zero_division=0),
        "f1":        f1_score(y_true, y_pred, zero_division=0),
    }


def fedavg_training(client_loaders: List[Tuple], rounds: int, local_epochs: int,
                     lr: float, device: str, out_dir: str):
    os.makedirs(out_dir, exist_ok=True)
    csv_path = os.path.join(out_dir, "metrics.csv")
    with open(csv_path, "w", newline="") as f:
        csv.writer(f).writerow([
            "round", "loss", "acc", "prec", "rec", "f1"
        ])

    global_model = FedNet().to(device)
    criterion = nn.BCELoss()

    series_loss, series_p, series_r, series_f1 = [], [], [], []

    for r in range(1, rounds + 1):
        # ---- Local training ----
        local_states, local_sizes, local_losses = [], [], []
        for tl, _, _ in client_loaders:  
            local_model = copy.deepcopy(global_model)
            opt = optim.SGD(local_model.parameters(), lr=lr)
            for _ in range(local_epochs):
                loss = _train_local(local_model, tl, criterion, opt, device)
            local_states.append(copy.deepcopy(local_model.state_dict()))
            local_sizes.append(len(tl.dataset))
            local_losses.append(loss)

        new_state = copy.deepcopy(local_states[0])
        for k in new_state.keys():
            new_state[k] = sum(ws[k] for ws in local_states) / len(local_states)
        global_model.load_state_dict(new_state)

        test_loaders = [trip[2] for trip in client_loaders]  # test_loader
        metrics = _evaluate(global_model, test_loaders, device)
        avg_loss = sum(local_losses) / len(local_losses)

        with open(csv_path, "a", newline="") as f:
            csv.writer(f).writerow([
                r, avg_loss, metrics["accuracy"], metrics["precision"], metrics["recall"], metrics["f1"],
            ])
        print(f"Round {r:02d}/{rounds} | Loss {avg_loss:.4f} | Pre {metrics['precision']:.4f} | Rec {metrics['recall']:.4f} | F1 {metrics['f1']:.4f}")

        series_loss.append(avg_loss)
        series_p.append(metrics['precision'])
        series_r.append(metrics['recall'])
        series_f1.append(metrics['f1'])

    # ---- Plot Loss ----
    plt.figure(); plt.plot(series_loss, marker="o")
    plt.title("Loss vs Round"); plt.xlabel("Round"); plt.ylabel("Loss")
    plt.grid(True, linestyle=":", alpha=0.4); plt.tight_layout()
    plt.savefig(os.path.join(out_dir, "loss.png"), dpi=150); plt.close()

    # ---- Plot Precision / Recall / F1 ----
    rounds_ax = range(1, rounds + 1)
    plt.figure()
    plt.plot(rounds_ax, series_p, label="Precision", marker="o")
    plt.plot(rounds_ax, series_r, label="Recall",    marker="s")
    plt.plot(rounds_ax, series_f1, label="F1-Score", marker="^")
    plt.title("Precision / Recall / F1 vs Round")
    plt.xlabel("Round"); plt.ylabel("Score")
    plt.grid(True, linestyle=":", alpha=0.4); plt.legend(); plt.tight_layout()
    plt.savefig(os.path.join(out_dir, "pr_recall_f1.png"), dpi=150); plt.close()
