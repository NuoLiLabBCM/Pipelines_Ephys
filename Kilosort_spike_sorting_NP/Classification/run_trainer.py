"""
@author: heet
"""
#imports
import numpy as np
from unit_classifier_trainer import trainer, tester, confusion_plotter

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


#filters can be supplied as dictionaries
#for example, train_filters = {"uid": [0, 1], "Imec": [0]}
#this will train only on UID 0 and 1 with Imec 0 

train_filters = {} #change if needed
test_filters = {} #change if needed

####### USER INPUT ENDS HERE ###################


cf1, cf2 = trainer(ksdirs_csv, feat_cols, greater_equal, less_equal, energy_threshold, 
            train_filters, cf1_kwargs=cf1_kwargs, cf2_kwargs=cf2_kwargs)

cm1, cm2, cm = tester(ksdirs_csv, cf1, cf2, feat_cols, greater_equal, 
           less_equal, energy_threshold, test_filters)

#plot classifier 1 results
kwargs = {'title': 'Classifier 1', 'xlabel':'Predicted labels', 
          'ylabel': 'Manual labels'}
confusion_plotter(cm1, labels=['bad', 'good+mua'], **kwargs)

#plot classifier 2 results
kwargs = {'title': 'Classifier 2', 'xlabel':'Predicted labels', 
          'ylabel': 'Manual labels'}
confusion_plotter(cm2, labels=['mua', 'good'], **kwargs)

#plot final results
kwargs = {'title': 'Final', 'xlabel':'Predicted labels', 
          'ylabel': 'Manual labels'}
confusion_plotter(cm, labels=['bad', 'mua', 'good'], **kwargs)


#print model params
print("Model 1\n--------\nIntercept")
print(cf1.intercept_[0])
print("\nCoefficients")
print(*list(cf1.coef_[0]), sep='\n')

print("\n\nModel 2\n--------\nIntercept")
print(cf2.intercept_[0])
print("\nCoefficients")
print(*list(cf2.coef_[0]), sep='\n')