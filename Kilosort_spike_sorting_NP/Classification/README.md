# Unit classifier

Python based classifier to predict 'good' and 'mua' clusters using [Kilosort](https://github.com/MouseLand/Kilosort) output.

## Installation

All packages required should be part of the standard distribution that comes with [Anaconda](https://www.anaconda.com/).

While running, if [sklearn](https://scikit-learn.org/stable/) throws an error like:
```python
ModuleNotFoundError: No module named 'sklearn'
```
Install sklearn by launching Anaconda Prompt
```bash
conda install -c anaconda scikit-learn 
```

## Usage
#### Step 1
Edit **classification_sessions.xlsx** (found inside the meta folder).

**Path** column should point to the kilosort output directory. 

**UID** (uid = unique ID) column should contain a unique ID number for each entry in Path.


#### Step 2

Open run.py in any interpreter (for example, [Spyder](https://www.spyder-ide.org/))
```python
#Only two paths need to be set
ksdirs_csv = r'Path to classification_sessions.xlsx'
trim_meta_path = r'path to numpy_truncation_meta.xlsx'

#select brain region
region = 'alm'

#Then run this script (Shortcut: F5 if using Spyder)
```

## Output
Creates a replica of the kilosort output directory with the suffix `*_trimmed` at the same level as the original kilosort folder(s) mentioned in **classification_sessions.xlsx**.

The results can be visualized in [Phy](https://github.com/cortex-lab/phy)

This folder contains:

`*.npy files`: Trimmed numpy containing clusters predicted as 'good' or 'mua'

`cluster_qc_threshold_check.tsv`: Flags for clusters that passed quality check criteria (1=passed)

`cluster_predictions.tsv`: Predictions labels. (1=good, 0=mua)

`cluster_original_cluster_id.tsv`: Mapping of cluster IDs before and after trimming.  
 
# Unit classifier trainer
Set of scripts and modules for training new classifiers. Contains 2 main driver scripts:
> 1.  **run_trainer.py** - Trains on entire dataset and prints the model intercept and coefficients for Classifier 1 and 2.
> 2. **run_trainer_cross_validate** - Runs leave one out cross validation on the dataset. 

Both scripts will plot confusion matrices for model assessment. 

## Usage
#### run_trainer.py
Set the following parameters and run the script. Most parameters (except paths to files/dirs) will work well with the defaults. 
```python
#set path to your Excel containing session information
ksdirs_csv = r'A:\Heet\Code\heet\meta\training_sessions.xlsx'

feat_cols = np.arange(1, 16) #fixed; change ONLY if needed
energy_threshold = 1e8 #change if needed. Clusters with energy exceeding threshold will be rejected

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

```

#### run_trainer_cross_validate.py
Similar to run_trainer.py but instead of training on entire dataset, cross validates using the leave one out method. Will generate 'N' confusion plots, where N is the number of sessions supplied in ***ksdirs_csv.***

```python
#set path to your Excel containing session information
ksdirs_csv = r'A:\Heet\Code\heet\meta\training_sessions.xlsx'

feat_cols = np.arange(1, 16) #fixed; change ONLY if needed
energy_threshold = 1e8 #change if needed. Clusters with energy exceeding threshold will be rejected

#Threshold for QC check
#greater_equal will pass units with values >=
#less_equal will pass units with values <=
greater_equal = {'amplitude': 100, 'firing_rate': 0.2, 'presence_ratio': 0.95} #change if needed
less_equal = {'isi_viol': 0.1, 'amplitude_cutoff': 0.1, 'drift': 0.1} #change if needed

#classifier kwargs
#see https://scikit-learn.org/stable/modules/generated/sklearn.linear_model.LogisticRegression.html
cf1_kwargs = {'class_weight':{-1:0.35, 1:0.65}} #change if needed
cf2_kwargs = {} #change if needed
```