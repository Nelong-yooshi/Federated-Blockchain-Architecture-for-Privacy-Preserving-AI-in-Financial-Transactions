import pandas as pd
import numpy as np
from sklearn.utils import shuffle
from sklearn.cluster import KMeans

def main():
    # read the raw data
    df = pd.read_csv('./raw_data/creditcard.csv')

    # parameter settings
    num_clients = 10
    iid_output = 'creditcard_iid_dataset.csv'
    noniid_output = 'creditcard_noniid_dataset.csv'

    # —— IID split ——
    df_iid = shuffle(df, random_state=42).reset_index(drop=True)
    df_iid['client_id'] = df_iid.index % num_clients
    df_iid.to_csv(iid_output, index=False)
    print(f'IID dataset saved to {iid_output}')

    # —— non-IID split（KMeans） —— 
    features = df.loc[:, 'V1':'V28'].values
    kmeans = KMeans(n_clusters=num_clients, random_state=42)
    cluster_labels = kmeans.fit_predict(features)
    df_noniid = df.copy()
    df_noniid['client_id'] = cluster_labels
    df_noniid.to_csv(noniid_output, index=False)
    print(f'non-IID dataset saved to {noniid_output}')

if __name__ == '__main__':
    main()
