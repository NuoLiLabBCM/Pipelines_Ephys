"""
@author: heet
"""
#imports
import numpy as np
from sklearn.metrics import ConfusionMatrixDisplay
from sklearn.model_selection import LeaveOneOut
from utils import *
from unit_classifier_utils import *
from unit_classifier import *


def trainer(ksdirs_csv, feat_cols, greater_equal, less_equal, energy_threshold, 
            train_filters={}, cf1_kwargs={'class_weight':{-1:0.35, 1:0.65}}, 
            cf2_kwargs={}):
    """Train 2 classifiers for predicting good and mua clusters 
    
    Args: 
        ksdirs_csv (str):       path to excel containing training meta
        feat_cols (list-like):  sequence containing indices of prediction features
        greater_equal (dict):   key, values for QC thresholds (pass >=)
        less_equal (dict):      key, values for QC thresholds (pass <=)
        energy_threshold (int): energy threshold to reject clusters as noise
        train_filters (dict):   train_filters to extract training set
        cf1_kwargs (dict):      kwargs for classifier 1
        cf2_kwargs (dict):      kwargs for classifier 2
        
    Returns trained models for classifier 1 and classifier 2
    """
    #load metric tables
    metrics_ori, ksdirs = get_metrics(ksdirs_csv, dropna=True)
    metrics_ori.reset_index(inplace=True, drop=True) #re-order index
    metrics = extract(metrics_ori, **train_filters)
    
    #add qc passed units to manual labels
    mask = np.ones(len(metrics))
    for key, val in greater_equal.items():
        temp_mask = np.array(metrics[key] >= val, dtype=int)
        mask *= temp_mask
    for key, val in less_equal.items():
        temp_mask = np.array(metrics[key] <= val, dtype=int)
        mask *= temp_mask
    metrics['qc_threshold_check'] = mask    
    metrics.loc[metrics['qc_threshold_check']==1, 'manual_labels'] = 1

    #add training labels for classifier 1
    metrics['manual_labels_cf1'] = metrics['manual_labels'].copy()
    metrics.loc[metrics['manual_labels_cf1']==0, 'manual_labels_cf1'] = 1
    
    #train classifier 1
    label_col = metrics.columns.get_loc('manual_labels_cf1')
    model_cf1, _, _, _, _, predictions, _, _ = run_classification(metrics, 
                            train_filters, train_filters, feat_cols, label_col,
                            cf1_kwargs, assessment_kwargs={})
    
    #update predictions with QC check
    predictions[metrics['qc_threshold_check']==1] = 1
    #update predictions with energy check 
    predictions[metrics['energy'] >= energy_threshold] = -1
    #add classifier 1 predictions to dataframe
    metrics['predictions'] = predictions
    
    train_filters["predictions"] = [1] 
    train_filters["qc_threshold_check"] = [0]
    
    #add training labels for classifier 2
    metrics['manual_labels_cf2'] = metrics['manual_labels'].copy()
    metrics.loc[metrics['manual_labels_cf2']==-1, 'manual_labels_cf2'] = 0
    
    #train classifier 2
    label_col = metrics.columns.get_loc('manual_labels_cf2')

    model_cf2, _, _, _, _, predictions, _, _ = run_classification(metrics, 
                            train_filters, train_filters, feat_cols, label_col,
                            cf2_kwargs, assessment_kwargs={})
 
    return model_cf1, model_cf2


def tester(ksdirs_csv, model_cf1, model_cf2, feat_cols, greater_equal, 
           less_equal, energy_threshold, test_filters={}):
    """Test 2 classifiers for predicting good and mua clusters 
    
    Args: 
        ksdirs_csv (str):       path to excel containing training meta
        model_cf1 (obj):        classifier 1 model object
        model_cf2 (obj):        classifier 2 model object
        feat_cols (list-like):  sequence containing indices of prediction features
        greater_equal (dict):   key, values for QC thresholds (pass >=)
        less_equal (dict):      key, values for QC thresholds (pass <=)
        energy_threshold (int): energy threshold to reject clusters as noise
        test_filters (dict):    test_filters to extract testing set
       
    Returns confusion matrices for classifier 1, classifier 2 and the final 
    combination of classifier 1 + 2
    """
    #load metric tables
    metrics_ori, ksdirs = get_metrics(ksdirs_csv, dropna=True)
    metrics_ori.reset_index(inplace=True, drop=True) #re-order index
    metrics = extract(metrics_ori, **test_filters)
    
    #add qc passed units to manual labels
    mask = np.ones(len(metrics))
    for key, val in greater_equal.items():
        temp_mask = np.array(metrics[key] >= val, dtype=int)
        mask *= temp_mask
    for key, val in less_equal.items():
        temp_mask = np.array(metrics[key] <= val, dtype=int)
        mask *= temp_mask
    metrics['qc_threshold_check'] = mask    
    metrics.loc[metrics['qc_threshold_check']==1, 'manual_labels'] = 1

    #add testing labels for classifier 1
    metrics['manual_labels_cf1'] = metrics['manual_labels'].copy()
    metrics.loc[metrics['manual_labels_cf1']==0, 'manual_labels_cf1'] = 1
    
    #test classifier 1
    label_col = metrics.columns.get_loc('manual_labels_cf1')
    _, _, test_x, test_y = data_splitter(metrics, {}, test_filters, feat_cols, 
                                         label_col)
    predictions = model_cf1.predict(test_x)
    
    #update predictions with QC check
    predictions[metrics['qc_threshold_check']==1] = 1
    #update predictions with energy check 
    predictions[metrics['energy'] >= energy_threshold] = -1
    #add classifier 1 predictions to dataframe
    metrics['predictions'] = predictions
    
    #get assessment for classifier 1
    confusion_cf1, _ = get_model_assessment(predictions, test_y)
    
    #classifier 2
    test_filters["predictions"] = [1] 
    test_filters["qc_threshold_check"] = [0]
    #add training labels for classifier 2
    metrics['manual_labels_cf2'] = metrics['manual_labels'].copy()
    metrics.loc[metrics['manual_labels_cf2']==-1, 'manual_labels_cf2'] = 0
    
    #test classifier 2
    label_col = metrics.columns.get_loc('manual_labels_cf2')

    _, _, test_x, test_y = data_splitter(metrics, {}, test_filters, feat_cols, 
                                         label_col)
    predictions = model_cf2.predict(test_x)
    temp = extract(metrics, **test_filters)
    temp['predictions'] = predictions
    metrics.update(temp)
    #get assessment for classifier 2
    confusion_cf2, _ = get_model_assessment(predictions, test_y)
    
    #final assessement
    confusion, _ = get_model_assessment(metrics.predictions, metrics.manual_labels)
    
    return confusion_cf1, confusion_cf2, confusion
    
def gen_loo(x):
    """generate train and test filters based on UID for leave one out
    cross validation
    
    Args:
        x (list-like):  sequence of UID to generate filters
    
    Returns lists of training and testing filters
    """
    loo = LeaveOneOut()
    loo.get_n_splits(x)
    train_filters, test_filters = [], []
    for i, (train_index, test_index) in enumerate(loo.split(x)):
        train_filters.append({'uid':list(x[train_index])})
        test_filters.append({'uid':list(x[test_index])})
    return train_filters, test_filters

def confusion_plotter(cm, labels=None, **kwargs):
    """Plot confusion matrix
    
    Args:
        cm (ndarray):       confusion matrix
        labels (list-like): display labels for plot. If None, display labels are 
                            set from 0 to n_classes - 1
        kwargs:             passed to ax.set()
    """
    disp = ConfusionMatrixDisplay(confusion_matrix=cm, display_labels=labels)
    disp.plot()
    disp.ax_.set(**kwargs)