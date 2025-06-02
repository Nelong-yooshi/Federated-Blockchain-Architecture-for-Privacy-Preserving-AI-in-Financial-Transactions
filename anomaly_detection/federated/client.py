import torch
import torch.optim as optim
from tqdm import tqdm
from models.autoencoder import Autoencoder

class FederatedClient:
    def __init__(self, client_id, data, model, params):
        self.client_id = client_id
        self.data = data
        self.model = model
        self.params = params

        self.optimizer = optim.Adam(self.model.parameters(), 
                                lr=params['lr'], 
                                weight_decay=params['weight_decay'])
        
        self.train_loader = torch.utils.data.DataLoader(
            data, batch_size=params['batch_size'], shuffle=True)
    
    def train_epoch(self):
        self.model.train()
        total_loss = 0
        
        for batch_idx, (data, target) in enumerate(self.train_loader):
            data = data.to(self.device)
            target = target.to(self.device)
            
            self.optimizer.zero_grad()
            output = self.model(data)
            
            if isinstance(self.model, Autoencoder):
                loss = torch.nn.MSELoss()(output, target)
            else:
                labels = torch.zeros(data.size(0), 1).to(self.device)
                loss = torch.nn.BCELoss()(output, labels)
            
            loss.backward()
            self.optimizer.step()
            
            total_loss += loss.item()
        
        avg_loss = total_loss / len(self.train_loader)
        return avg_loss
    
    def local_train(self, epochs=1):

        train_losses = []
        
        for epoch in range(epochs):
            loss = self.train_epoch()
            train_losses.append(loss)
        
        return {
            'state_dict': self.model.state_dict(),
            'num_samples': len(self.train_loader.dataset),
            'train_loss': sum(train_losses) / len(train_losses)
        }
    
    @property
    def device(self):
        return next(self.model.parameters()).device