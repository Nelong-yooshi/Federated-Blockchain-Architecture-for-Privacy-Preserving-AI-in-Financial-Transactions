## Prerequisites

**Original Dataset**  
   The credit card fraud dataset is too large to include directly on GitHub. To prepare the data:  
   - Create a folder `data/raw_data/` in the project root.  
   - Place the original `creditcard.csv` file inside `data/raw_data/`.  
   - Run:
     ```bash
     python preprocessing.py
     ```
     This script will read `data/raw_data/creditcard.csv` and generate two files:
     - `data/creditcard_iid_dataset.csv`
     - `data/creditcard_noniid_dataset.csv`  

---

## How to Run

With default settings, simply run the following command in the project’s root directory:
```bash
python main.py
```

The results and generated plots will be saved under the `output/` directory.
To customize training parameters, you can use the following command-line options:

| Argument         | Description                                   | Default                                  |
| ---------------- | --------------------------------------------- | ---------------------------------------- |
| `--mode`         | Choose **IID** or **non-IID** dataset         | `iid`                                    |
| `--iid_csv`      | Path to the IID dataset CSV                   | `data/creditcard_iid_dataset.csv`        |
| `--noniid_csv`   | Path to the non-IID dataset CSV               | `data/creditcard_noniid_dataset.csv`     |
| `--rounds`       | Number of global training rounds              | `50`                                     |
| `--local_epochs` | Number of local training epochs per round     | `3`                                      |
| `--lr`           | Learning rate                                 | `1e-3`                                   |
| `--batch`        | Batch size                                    | `64`                                     |
| `--output`       | Output directory for results and plots        | `output`                                 |

> Example:
> To run with the non-IID dataset for 30 rounds and 5 local epochs:
```python main.py --mode noniid --rounds 30 --local_epochs 5 ```

