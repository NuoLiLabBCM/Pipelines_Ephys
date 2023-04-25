"""
@author: heet
"""
import os, shutil
import numpy as np
from utils import get_metrics, extract, trim_NPYs
from unit_classifier_utils import gen_model, data_splitter, fit_and_test, get_model_assessment 

def run_classification(metrics, train_filters, test_filters, feat_cols, label_col,
                       model_kwargs, assessment_kwargs):
    """Run classification on ONE set of training and testing filters 
    
    Args:
        metrics (Dataframe):    Dataframe containing unit metrics
        train_filters (dict):   key = column headers, val = filter values at key
        test_filters (dict):    key = column headers, val = filter values at key
        feat_cols (list-like):  feature column indices to extract for classifier
        label_col: (list-like): column index for ground truth labels
        model_kwargs:           kwargs passed to gen_model()
        assessment_kwargs:      kwargs passed to get_model_assessment()
    
    Returns: model, train_x, train_y, test_x, test_y, predictions, confusion, 
    accuracy
    """
    model = gen_model(**model_kwargs)
    train_x, train_y, test_x, test_y = data_splitter(metrics, train_filters, 
                                                     test_filters, feat_cols, 
                                                     label_col)
    predictions = fit_and_test(model, train_x, train_y, test_x)
    confusion, accuracy = get_model_assessment(predictions, test_y, **assessment_kwargs)
    
    return model, train_x, train_y, test_x, test_y, predictions, \
           confusion, accuracy

def batch_classifications(metrics, train_filters, test_filters, feat_cols, label_col,
                          model_kwargs, assessment_kwargs):
    """Run classification on MULTIPLE sets of training and testing filters. 
    Inputs are similar to run_classification() but you must give a list of 
    train_filters and corresponding test_filters. In addition, instead of giving
    the metrics, you give the path to a csv file containing all the directories
    of Kilosrt outputs. See a sample CSV in samples folder."""
    
    resultant = {'model':[], 'train_x': [], 'train_y':[], 'test_x':[], 'test_y':[],
              'prediction':[], 'test_identifier':[], 'train_identifier': [],
              'confusion':[], 'accuracy':[], 'intercept': []}
    
    for train_filter, test_filter in zip(train_filters, test_filters):
        model, train_x, train_y, test_x, test_y, preds, conf, acc = \
            run_classification(metrics, train_filter, test_filter, feat_cols, 
                               label_col, model_kwargs, assessment_kwargs)
        
        resultant['model'].append(model)
        resultant['intercept'].append(model.intercept_[0])
        resultant['train_x'].append(train_x)
        resultant['train_y'].append(train_y)
        resultant['test_x'].append(test_x)
        resultant['test_y'].append(test_y)
        resultant['prediction'].append(preds)
        resultant['test_identifier'].append(test_filter)
        resultant['train_identifier'].append(train_filter)
        resultant['confusion'].append(conf)
        resultant['accuracy'].append(acc)
    resultant['features_used'] = list(metrics.columns[feat_cols])
    return resultant


def run(ksdirs_csv, trim_meta_path, model1_coef, model1_intercept, model2_coef, 
        model2_intercept, feat_cols, greater_equal, less_equal, 
        energy_threshold):
    """ """
    #load metric tables
    metrics, ksdirs = get_metrics(ksdirs_csv, dropna=True)
    metrics.reset_index(inplace=True, drop=True) #re-order index
    #generate classifier 1
    model_cf1 = gen_model()
    model_cf1.classes_ = np.array([-1, 1]) #-1 = bad, 1 = good or mua
    model_cf1.coef_ = model1_coef
    model_cf1.intercept_ = model1_intercept
    train_filters, test_filters = None, None
    _, _, test_x, _ = data_splitter(metrics, train_filters, test_filters, 
                                         feat_cols, -1)
    #predict with classifier 1
    predictions = model_cf1.predict(test_x)
    
    mask = predictions.copy()
    for key, val in greater_equal.items():
        temp_mask = np.array(metrics[key] >= val, dtype=int)
        mask *= temp_mask
    for key, val in less_equal.items():
        temp_mask = np.array(metrics[key] <= val, dtype=int)
        mask *= temp_mask
    metrics['qc_threshold_check'] = mask
   
    #update predictions with QC check
    predictions[metrics['qc_threshold_check']==1] = 1
    #update predictions with energy check
    predictions[metrics['energy'] >= energy_threshold] = -1
    #add classifier 1 predictions to dataframe
    metrics['predictions'] = predictions
    
    #for classifier 2
    #take only good or mua predictions and drop units that passed QC
    metrics_filt = extract(metrics, **{'predictions': [1], 'qc_threshold_check':[0]})
    model_cf2 = gen_model()
    
    model_cf2.classes_ = np.array([0, 1]) #0 = mua, 1 = good
    model_cf2.coef_ = model2_coef
    model_cf2.intercept_ = model2_intercept
    _, _, test_x, _ = data_splitter(metrics_filt, train_filters, test_filters, 
                                    feat_cols, -1)
    #predict with classifier 2
    predictions = model_cf2.predict(test_x)
    
    #update earlier predictions based on classifier 2
    metrics['predictions'][metrics_filt.index] = predictions
    
    # trim numpy files
    for uid, ksdir in zip(metrics.uid.unique(), ksdirs):
        print("\n\nTrimming File: {}\n" .format(uid+1))
        save_dir = ksdir + '_trimmed'
        os.makedirs(save_dir, exist_ok=True)
        x = extract(metrics, **{'uid': [uid]})
        x.to_csv(ksdir + '\\cluster_predictions.tsv', columns=['cluster_id','predictions'], index=False, sep='\t')
        x = extract(x, **{'predictions': [1,0]})
        tokens = trim_NPYs(x['cluster_id'], ksdir, trim_meta_path, save_dir)
        x['cluster_id'] = np.array(tokens)[:,1]
        x['original_cluster_id'] = np.array(tokens)[:,0]
        x.iloc[:, 0:16].to_csv(save_dir + '\\metrics.csv', sep=',', index=False)
        x.to_csv(save_dir + '\\cluster_predictions.tsv', columns=['cluster_id','predictions'], index=False, sep='\t')
        x.to_csv(save_dir + '\\cluster_original_cluster_id.tsv', columns=['cluster_id','original_cluster_id'], index=False, sep='\t')
        x.to_csv(save_dir + '\\cluster_qc_threshold_check.tsv', columns=['cluster_id', 'qc_threshold_check'], index=False, sep='\t')
        x = extract(x, **{'predictions': [1]})
        x['group'] = 'good'
        x.to_csv(save_dir + '\\cluster_group.tsv', columns=['cluster_id','group'], index=False, sep='\t')
        shutil.copyfile(ksdir+'\\params.py', save_dir+'\\params.py')
        if os.path.isfile(ksdir+'\\events.csv'):
            shutil.copyfile(ksdir+'\\events.csv', save_dir+'\\events.csv')
    return metrics