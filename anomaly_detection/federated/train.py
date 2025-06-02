import torch
import numpy as np
from tqdm import tqdm
import matplotlib.pyplot as plt
import os

from models.autoencoder import Autoencoder
from utils.metrics import compute_metrics
from utils.visualization import plot_learning_curves
from federated.server import FederatedServer
from federated.client import FederatedClient

class FederatedTrainer:
    def __init__(self, model_type='autoencoder', dataset='mnist', params=None):
        self.model_type = model_type
        self.dataset = dataset
        self.params = params if params else self.default_params()
        
        self.prepare_data()

        self.init_global_model()

        self.server = FederatedServer(self.global_model)
        self.clients = self.create_clients()
    
    def default_params(self):
        return {
            'batch_size': 64,
            'lr': 0.001,
            'epochs': 50,
            'local_epochs': 3,
            'latent_dim': 32,
            'weight_decay': 1e-5,
            'num_clients': 5,
            'participation_ratio': 0.6  
        }
    
    def prepare_data(self):
        if self.dataset == 'mnist':
            from utils.data_loader import load_mnist_anomaly
            X_train, X_test, y_test = load_mnist_anomaly()
            self.input_dim = X_train.shape[1]
            
            client_data = self.non_iid_split(X_train, self.params['num_clients'])

            self.client_datasets = []
            for data in client_data:
                tensor_data = torch.FloatTensor(data)
                self.client_datasets.append(torch.utils.data.TensorDataset(tensor_data, tensor_data))

            self.test_data = torch.utils.data.TensorDataset(
                torch.FloatTensor(X_test), torch.FloatTensor(y_test))
    
    def non_iid_split(self, data, num_clients):
        # random split
        split_size = len(data) // num_clients
        splits = []
        for i in range(num_clients):
            start = i * split_size
            end = (i + 1) * split_size if i < num_clients - 1 else len(data)
            splits.append(data[start:end])
        return splits
    
    def init_global_model(self):
        if self.model_type == 'autoencoder':
            self.global_model = Autoencoder(self.input_dim, self.params['latent_dim'])

    
    def create_clients(self):
        clients = []
        for i in range(self.params['num_clients']):
            client = FederatedClient(
                client_id=i,
                data=self.client_datasets[i],
                model=self.init_client_model(),
                params=self.params
            )
            clients.append(client)
        return clients
    
    def init_client_model(self):
        """初始化客戶端模型 (複製全局模型)"""
        if self.model_type == 'autoencoder':
            model = Autoencoder(self.input_dim, self.params['latent_dim'])

        
        model.load_state_dict(self.global_model.state_dict())
        return model
    
    def evaluate(self):
        self.global_model.eval()
        y_true = []
        y_pred = []
        
        test_loader = torch.utils.data.DataLoader(
            self.test_data, batch_size=self.params['batch_size'], shuffle=False)
        
        with torch.no_grad():
            for data, target in test_loader:
                output = self.global_model(data)
                
                if self.model_type == 'autoencoder':
                    recon_error = torch.mean((output - data)**2, dim=1)
                    y_pred.extend(recon_error.cpu().numpy())
                else:
                    y_pred.extend(output.squeeze().cpu().numpy())
                
                y_true.extend(target.cpu().numpy())
        
        return compute_metrics(np.array(y_true), np.array(y_pred), self.model_type)
    
    def train(self):
        train_losses = []
        test_metrics = {'f1': [], 'precision': [], 'recall': []}
        
        best_f1 = 0
        num_participants = int(self.params['num_clients'] * self.params['participation_ratio'])
        
        for round in range(1, self.params['epochs'] + 1):
            # 選擇參與本輪訓練的客戶端
            participants = np.random.choice(
                self.clients, size=num_participants, replace=False)
            
            # 分發全局模型
            self.server.distribute_model(participants)
            
            round_loss = 0
            # 客戶端本地訓練
            for client in participants:
                local_result = client.local_train(epochs=self.params['local_epochs'])
                self.server.receive_update(
                    client.client_id, 
                    local_result['state_dict'], 
                    local_result['num_samples'])
                round_loss += local_result['train_loss']
            
            # 聚合更新
            self.server.aggregate_updates()
            
            # 評估全局模型
            metrics = self.evaluate()
            
            # 記錄結果
            avg_round_loss = round_loss / len(participants)
            train_losses.append(avg_round_loss)
            test_metrics['f1'].append(metrics['f1'])
            test_metrics['precision'].append(metrics['precision'])
            test_metrics['recall'].append(metrics['recall'])
            
            print(f'Round {round}/{self.params["epochs"]}')
            print(f'Avg Client Loss: {avg_round_loss:.4f}')
            print(f'Test F1: {metrics["f1"]:.4f}, Precision: {metrics["precision"]:.4f}, Recall: {metrics["recall"]:.4f}')
            print('-' * 50)
            
            # 保存最佳模型
            if metrics['f1'] > best_f1:
                best_f1 = metrics['f1']
                self.save_model()
        
        # 繪製學習曲線
        plot_learning_curves(train_losses, test_metrics, f'federated_{self.model_type}')
        
        return train_losses, test_metrics
    
    def save_model(self, path='saved_models'):
        if not os.path.exists(path):
            os.makedirs(path)
        
        model_path = os.path.join(path, f'federated_{self.model_type}_{self.dataset}_best.pth')
        torch.save(self.global_model.state_dict(), model_path)
        print(f'Model saved to {model_path}')