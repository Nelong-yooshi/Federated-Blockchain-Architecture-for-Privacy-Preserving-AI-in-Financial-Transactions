import numpy as np
from sklearn.preprocessing import MinMaxScaler
from sklearn.model_selection import train_test_split
from sklearn.datasets import fetch_openml
import pandas as pd

def load_mnist_anomaly(normal_class=0):
    mnist = fetch_openml('mnist_784', version=1, as_frame=False)
    X, y = mnist.data, mnist.target.astype(int)
    
    X = X / 255.0
    
    # split normal and anomaly
    normal_idx = y == normal_class
    X_normal = X[normal_idx]
    X_anomaly = X[~normal_idx]
    
    # split train and test
    X_train, X_test_normal = train_test_split(X_normal, test_size=0.2, random_state=42)
    X_test = np.concatenate([X_test_normal, X_anomaly[:1000]], axis=0)
    y_test = np.concatenate([np.zeros(X_test_normal.shape[0]), np.ones(1000)], axis=0)
    
    return X_train, X_test, y_test

def load_creditcard(data_path='data/creditcard.csv'):
    data = pd.read_csv(data_path)
    X = data.drop(['Class', 'Time'], axis=1).values
    y = data['Class'].values
    
    scaler = MinMaxScaler()
    X[:, -1] = scaler.fit_transform(X[:, -1].reshape(-1, 1)).flatten()
    
    # split train and test
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y)
    
    return X_train, X_test, y_train, y_test