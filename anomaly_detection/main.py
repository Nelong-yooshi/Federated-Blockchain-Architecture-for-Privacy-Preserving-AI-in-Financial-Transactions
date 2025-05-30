import os
import yaml
from centralized.train import CentralizedTrainer
from federated.train import FederatedTrainer


def ensure_dir(directory):
    if not os.path.exists(directory):
        os.makedirs(directory)

def load_config(config_path='configs/params.yaml'):
    try:
        with open(config_path, 'r', encoding='utf-8') as f:
            config = yaml.safe_load(f)
        
        if config:
            # int參
            int_params = ['batch_size', 'latent_dim', 'epochs', 'num_clients', 'local_epochs']
            for param in int_params:
                if param in config:
                    config[param] = int(config[param])
            
            # float參
            float_params = ['lr', 'weight_decay', 'participation_ratio']
            for param in float_params:
                if param in config:
                    config[param] = float(config[param])
        
        return config
    except Exception as e:
        print(f"Error loading config: {e}, using default parameters")
        return {
            'batch_size': 64,
            'lr': 0.001,
            'epochs': 50,
            'weight_decay': 1e-5,
            'latent_dim': 32,
            'num_clients': 5,
            'participation_ratio': 0.6,
            'local_epochs': 3
        }

def main():
    # 創建必要的目錄
    ensure_dir('saved_models')
    ensure_dir('results')
    
    # 加載配置
    config = load_config()
    print("Loaded config:", config)
    
    # 模型類型列表
    model_types = ['autoencoder']
    
    for model_type in model_types:
        print(f'\n{"="*50}')
        print(f'Training {model_type} model')
        print(f'{"="*50}\n')
        
        # 集中式訓練
        print('\nCentralized Training\n' + '-'*30)
        cent_trainer = CentralizedTrainer(model_type=model_type, params=config)
        cent_loss, cent_metrics = cent_trainer.train()
        
        # 聯邦學習訓練
        print('\nFederated Training\n' + '-'*30)
        fed_trainer = FederatedTrainer(model_type=model_type, params=config)
        fed_loss, fed_metrics = fed_trainer.train()
        
        # 比較結果
        final_cent_metrics = {k: v[-1] for k, v in cent_metrics.items()}
        final_fed_metrics = {k: v[-1] for k, v in fed_metrics.items()}
        
        print('\nFinal Metrics Comparison:')
        print(f'{"Metric":<15} {"Centralized":<15} {"Federated":<15}')
        for metric in final_cent_metrics.keys():
            print(f'{metric:<15} {final_cent_metrics[metric]:<15.4f} {final_fed_metrics[metric]:<15.4f}')
        

if __name__ == '__main__':
    main()