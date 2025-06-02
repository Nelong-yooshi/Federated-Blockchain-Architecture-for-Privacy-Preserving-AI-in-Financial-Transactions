import matplotlib.pyplot as plt
import numpy as np

def plot_learning_curves(train_losses, test_metrics, model_name):
    plt.figure(figsize=(12, 5))
    
    # lost
    plt.subplot(1, 2, 1)
    plt.plot(train_losses, label='Train Loss')
    plt.title(f'{model_name} - Training Loss')
    plt.xlabel('Epoch')
    plt.ylabel('Loss')
    plt.legend()
    
    # score
    plt.subplot(1, 2, 2)
    plt.plot(test_metrics['f1'], label='F1 Score')
    plt.plot(test_metrics['precision'], label='Precision')
    plt.plot(test_metrics['recall'], label='Recall')
    plt.title(f'{model_name} - Test Metrics')
    plt.xlabel('Epoch')
    plt.ylabel('Score')
    plt.legend()
    
    plt.tight_layout()
    plt.savefig(f'results/{model_name}_learning_curves.png')
    plt.close()
