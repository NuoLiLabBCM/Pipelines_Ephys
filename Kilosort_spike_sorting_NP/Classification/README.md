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