import torch
import numpy as np
from collections import defaultdict

class FederatedServer:
    def __init__(self, global_model, client_weights=None):
        self.global_model = global_model
        self.client_weights = client_weights  
        
        # store
        self.updates = defaultdict(list)
    
    def receive_update(self, client_id, model_state, num_samples):
        self.updates[client_id] = {
            'state_dict': model_state,
            'num_samples': num_samples
        }
    
    def aggregate_updates(self):
        """FedAvg"""
        if not self.updates:
            return
        
        total_samples = sum(update['num_samples'] for update in self.updates.values())
        
        global_state = self.global_model.state_dict()
        
        for key in global_state.keys():
            # weight average
            global_state[key] = torch.stack([
                update['state_dict'][key].float() * (update['num_samples'] / total_samples)
                for update in self.updates.values()
            ], 0).sum(0)
        
        self.global_model.load_state_dict(global_state)
        
        # clear
        self.updates = defaultdict(list)
    
    def distribute_model(self, clients):
        global_state = self.global_model.state_dict()
        for client in clients:
            client.model.load_state_dict(global_state)