import numpy as np
from sklearn.metrics import f1_score, precision_score, recall_score, roc_auc_score, average_precision_score

def compute_metrics(y_true, y_pred, model_type):
    y_true = np.array(y_true)
    y_pred = np.array(y_pred)
    
    metrics = {}
    
    if model_type == 'autoencoder':
        thresholds = np.linspace(np.min(y_pred), np.max(y_pred), 100)
        best_f1 = 0
        best_thresh = 0
        
        for thresh in thresholds:
            pred_labels = (y_pred > thresh).astype(int)
            f1 = f1_score(y_true, pred_labels)
            if f1 > best_f1:
                best_f1 = f1
                best_thresh = thresh
        
        y_pred_labels = (y_pred > best_thresh).astype(int)

    
    metrics['f1'] = f1_score(y_true, y_pred_labels)
    metrics['precision'] = precision_score(y_true, y_pred_labels)
    metrics['recall'] = recall_score(y_true, y_pred_labels)
    
    try:
        metrics['roc_auc'] = roc_auc_score(y_true, y_pred)
    except ValueError:
        metrics['roc_auc'] = 0.0 
        
    try:
        metrics['pr_auc'] = average_precision_score(y_true, y_pred)
    except ValueError:
        metrics['pr_auc'] = 0.0
    
    return metrics