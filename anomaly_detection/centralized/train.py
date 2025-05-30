import torch
import torch.optim as optim
from torch.utils.data import DataLoader, TensorDataset
from tqdm import tqdm
import numpy as np
from sklearn.metrics import f1_score
import matplotlib.pyplot as plt
import os
import torch.nn as nn

from models.autoencoder import Autoencoder
from utils.metrics import compute_metrics
from utils.visualization import plot_learning_curves

class CentralizedTrainer:
    def __init__(self, model_type='autoencoder', dataset='mnist', params=None):
        self.model_type = model_type
        self.dataset = dataset
        self.params = params if params else self.default_params()
        
        self.load_data()
        
        self.init_model()
        
        self.device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
        self.model.to(self.device)
        
    def default_params(self):
        return {
            'batch_size': 64,
            'lr': 0.001,
            'epochs': 50,
            'latent_dim': 32,
            'weight_decay': 1e-5
        }
    
    def load_data(self):
        if self.dataset == 'mnist':
            from utils.data_loader import load_mnist_anomaly
            X_train, X_test, y_test = load_mnist_anomaly()
            self.input_dim = X_train.shape[1]
            
            X_train = torch.FloatTensor(X_train)
            X_test = torch.FloatTensor(X_test)
            y_test = torch.FloatTensor(y_test)

            self.train_loader = DataLoader(TensorDataset(X_train, X_train), 
                                        batch_size=self.params['batch_size'], 
                                        shuffle=True)
            
            self.test_loader = DataLoader(TensorDataset(X_test, y_test), 
                                        batch_size=self.params['batch_size'], 
                                        shuffle=False)
    
    def init_model(self):
        if self.model_type == 'autoencoder':
            self.model = Autoencoder(self.input_dim, self.params['latent_dim'])
            self.criterion = nn.MSELoss()

        
        self.optimizer = optim.Adam(self.model.parameters(), 
                                lr=self.params['lr'], 
                                weight_decay=self.params['weight_decay'])
    
    def train_epoch(self, epoch):
        self.model.train()
        total_loss = 0
        
        for batch_idx, (data, target) in enumerate(self.train_loader):
            data = data.to(self.device)
            target = target.to(self.device)
            
            self.optimizer.zero_grad()
            output = self.model(data)
            
            if self.model_type == 'autoencoder':
                loss = self.criterion(output, target)
            
            loss.backward()
            self.optimizer.step()
            
            total_loss += loss.item()
        
        avg_loss = total_loss / len(self.train_loader)
        return avg_loss
    
    def evaluate(self):
        self.model.eval()
        y_true = []
        y_pred = []
        
        with torch.no_grad():
            for data, target in self.test_loader:
                data = data.to(self.device)
                target = target.to(self.device)
                
                output = self.model(data)
                
                if self.model_type == 'autoencoder':
                    recon_error = torch.mean((output - data)**2, dim=1)
                    y_pred.extend(recon_error.cpu().numpy()) 
                else:
                    y_pred.extend(output.squeeze().cpu().numpy())  
                
                y_true.extend(target.cpu().numpy()) 
                
        y_true = np.array(y_true)
        y_pred = np.array(y_pred)
        
        return compute_metrics(y_true, y_pred, self.model_type)
    
    def train(self):
        train_losses = []
        test_metrics = {'f1': [], 'precision': [], 'recall': []}
        
        best_f1 = 0
        for epoch in range(1, self.params['epochs'] + 1):
            train_loss = self.train_epoch(epoch)
            metrics = self.evaluate()
            
            train_losses.append(train_loss)
            test_metrics['f1'].append(metrics['f1'])
            test_metrics['precision'].append(metrics['precision'])
            test_metrics['recall'].append(metrics['recall'])
            
            print(f'Epoch {epoch}/{self.params["epochs"]}')
            print(f'Train Loss: {train_loss:.4f}')
            print(f'Test F1: {metrics["f1"]:.4f}, Precision: {metrics["precision"]:.4f}, Recall: {metrics["recall"]:.4f}')
            print('-' * 50)
            
            # save best model
            if metrics['f1'] > best_f1:
                best_f1 = metrics['f1']
                self.save_model()
                
        plot_learning_curves(train_losses, test_metrics, self.model_type)
        
        return train_losses, test_metrics
    
    def save_model(self, path='saved_models'):
        if not os.path.exists(path):
            os.makedirs(path)
        
        model_path = os.path.join(path, f'{self.model_type}_{self.dataset}_best.pth')
        torch.save(self.model.state_dict(), model_path)
        print(f'Model saved to {model_path}')