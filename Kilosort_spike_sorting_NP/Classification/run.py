"""
@author: heet
"""
import numpy as np
from unit_classifier import run
from params import *

######## USER INPUT ############################

ksdirs_csv = r'A:\Heet\Code\heet\meta\classification_sessions.xlsx'
trim_meta_path = r'A:\Heet\Code\heet\meta\numpy_truncation_meta.xlsx'
region = 'alm'

####### USER INPUT ENDS HERE ###################




feat_cols = params['feat_cols']
energy_threshold = params['energy_threshold']
greater_equal = params['greater_equal']
less_equal = params['less_equal']
model1_coef = params[region]['model1_coef']
model1_intercept = params[region]['model1_intercept']
model2_coef = params[region]['model2_coef']
model2_intercept = params[region]['model2_intercept']

result = run(ksdirs_csv, trim_meta_path, model1_coef, model1_intercept, 
              model2_coef, model2_intercept, feat_cols, greater_equal, less_equal, 
              energy_threshold)