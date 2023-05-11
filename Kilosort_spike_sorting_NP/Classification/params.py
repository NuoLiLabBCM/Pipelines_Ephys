"""
@author: heet
"""
import numpy as np

params = {'alm': {'model1_coef': np.expand_dims(np.array([0.0101489,3.72591,-0.264386,-4.66496,-0.000806505,-0.214886,-0.0703261, 1.73804,-0.210772,1.02468,-0.0189152, -0.00143671,0.160225,-0.00563709,0.0255617]), 0),
                  'model1_intercept': np.array([-1.96730646]), 
                  'model2_coef': np.expand_dims(np.array([0.0365116,5.85205,-1.32439,-4.47627,-0.000572417,-0.526771,0.0838639,0.847815, -0.129248,0.998982,-0.0772774,0.0036283, -0.157023,0.000110858,-2.87045]), 0),
                  'model2_intercept': np.array([-5.49694128]),
                  'energy_threshold': 1e8,
                  'greater_equal': {'amplitude': 100, 'firing_rate': 0.2, 'presence_ratio': 0.95},
                  'less_equal': {'isi_viol': 0.1, 'amplitude_cutoff': 0.1, 'drift': 0.1}},
         'feat_cols': np.arange(1,16)}
          