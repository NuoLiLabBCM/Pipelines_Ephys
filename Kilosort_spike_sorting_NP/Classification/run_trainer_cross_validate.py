"""
@author: heet
"""
#imports
import numpy as np
from unit_classifier_trainer import trainer, tester, confusion_plotter, gen_loo
import pandas as pd

######## USER INPUT ############################

ksdirs_csv = r'A:\Heet\Code\heet\meta\training_sessions.xlsx'

feat_cols = np.arange(1, 16) #fixed; change ONLY if needed
energy_threshold = 1e8 #change if needed

#Threshold for QC check
#greater_equal will pass units with values >=
#less_equal will pass units with values <=
greater_equal = {'amplitude': 100, 'firing_rate': 0.2, 'presence_ratio': 0.95} #change if needed
less_equal = {'isi_viol': 0.1, 'amplitude_cutoff': 0.1, 'drift': 0.1} #change if needed

#classifier kwargs
#see https://scikit-learn.org/stable/modules/generated/sklearn.linear_model.LogisticRegression.html
cf1_kwargs = {'class_weight':{-1:0.35, 1:0.65}} #change if needed
cf2_kwargs = {} #change if needed

####### USER INPUT ENDS HERE ###################

meta = pd.read_excel(ksdirs_csv)
x = meta.UID.to_numpy()
train_filters, test_filters = gen_loo(x)

for train_filter, test_filter in zip(train_filters, test_filters):

    cf1, cf2 = trainer(ksdirs_csv, feat_cols, greater_equal, less_equal, energy_threshold, 
                train_filter, cf1_kwargs=cf1_kwargs, cf2_kwargs=cf2_kwargs)

    cm1, cm2, cm = tester(ksdirs_csv, cf1, cf2, feat_cols, greater_equal, 
               less_equal, energy_threshold, test_filter)
    
    #plot final results
    kwargs = {'title': 'Final -- Test UID:' + str(test_filter['uid'][0]), 
              'xlabel':'Predicted labels', 'ylabel': 'Manual labels'}
    confusion_plotter(cm, labels=['bad', 'mua', 'good'], **kwargs)