import argparse, torch, os
from data import load_federated_csv
from train import fedavg_training

DEFAULT_IID_CSV = "data/creditcard_iid_dataset.csv"
DEFAULT_NONIID_CSV = "data/creditcard_noniid_dataset.csv"


def parse_args():
    p = argparse.ArgumentParser(description="FedAvg CreditCard Experiment")
    p.add_argument("--mode", choices=["iid", "noniid"], default="iid", help="dataset mode")
    p.add_argument("--iid_csv", default=DEFAULT_IID_CSV)
    p.add_argument("--noniid_csv", default=DEFAULT_NONIID_CSV)
    p.add_argument("--rounds", type=int, default=50)
    p.add_argument("--local_epochs", type=int, default=10)
    p.add_argument("--lr", type=float, default=1e-3)
    p.add_argument("--batch", type=int, default=64)
    p.add_argument("--output", default="output")
    return p.parse_args()


def main():
    args = parse_args()
    csv_path = args.iid_csv if args.mode == "iid" else args.noniid_csv
    label = args.mode
    out_dir = os.path.join(args.output, label)

    loaders = load_federated_csv(csv_path, batch_size=args.batch)

    device = "cuda" if torch.cuda.is_available() else "cpu"
    print(f"Start federated learning training...")
    fedavg_training(
        client_loaders=loaders,
        rounds=args.rounds,
        local_epochs=args.local_epochs,
        lr=args.lr,
        device=device,
        out_dir=out_dir,
    )
    print(f"Completed OuO")

if __name__ == "__main__":
    main()