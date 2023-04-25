# Ecephys pipeline
Originally forked from [https://github.com/jenniferColonell/ecephys_spike_sorting](https://github.com/jenniferColonell/ecephys_spike_sorting). Added some functionality to use with Li Lab's data preprocessing pipeline.  

## Installation

For installation, refer to **Spike sorting.pdf** under installation_guide.

## Usage
Need to edit 3 scripts before running. 
#### create_input_json.py
This file contains information about paths to codes. Once edited, it will remain constant across runs unless you change where the codes or output directories are located
```python
# hard coded paths to code on your computer and system
ecephys_directory = r'C:\Users\lab\Downloads\ecephys_spike_sorting-master_v2\ecephys_spike_sorting'
    
# location of kilosor respository and kilosort version
kilosort_repository = r'C:\Users\lab\Downloads\Kilosort-2.5'

# Kilosort version
KS2ver = '2.5'

npy_matlab_repository = r'C:\Users\lab\Downloads\npy-matlab-master'

# contains the CatGT.exe file
catGTPath = r'C:\Users\lab\Downloads\ecephy_spike_sorting_v2_dependencies\CatGT-Win'

#  contains the tPrime.exe file
tPrime_path=r'C:\Users\lab\Downloads\TPrime-win'

# contains the C_Waves.exe file
cWaves_path=r'C:\Users\lab\Downloads\C_Waves-win'
        
# You need to create a folder for kilosort to store its temporary output and specify it’s path
kilosort_output_tmp = r'A:\Heet\SpikeGLX\kilosort_datatemp'       
```
#### slglx_multi_run_pipeline.py
Parameters in this file will change with different sessions/animals since they point to input and output data directories.
```python
# auxiliary channels. Right now, can only accept a maximum of 4 channels mentioned below
XA_channels = {'intan_trig': 1, 'bitcode': 2, 'pole_trig': 3, 'cue_trig': 4}

# log file for the current pipeline run
logName = 'NL105_221102_log.csv'

# raw neuropixel data directory
npx_directory = r'A:\Heet\SpikeGLX\sample_NP_data\BAYLORNL105\221102\NP'

# Each run_spec is a list of 4 strings:
#   undecorated run name (no g/t specifier, the run field in CatGT)
#   gate index, as a string (e.g. '0')
#   triggers to process/concatenate, as a string e.g. '0,400', '0,0 for a single file
#           can replace first limit with 'start', last with 'end'; 'start,end'
#           will concatenate all trials in the probe folder
#   probes to process, as a string, e.g. '0', '0,3', '0:3'
#   brain regions, list of strings, one per probe, to set region specific params
#           these strings must match a key in the param dictionaries above.

run_specs = [['NL_NL105_20221102_session1', '0', 'start,end', '0', ['cortex']]]

# Output destination
catGT_dest = r'A:\Heet\SpikeGLX\output\BAYLORNL105\221102_200s'

# directory to store JSON files. You need to create this directory. 
json_directory = r'A:\Heet\SpikeGLX\json_files' 

#read the catGT README to set these parameters for your rig/recording setup
catGT_cmd_string = '-prb_fld -out_prb_fld -apfilter=butter,12,300,10000 -lffilter=butter,12,1,500 -gfix=0.5,0.20,0.02 '
ni_extract_string = '-xa=0,0,0,1,0.5,7500 -xa=0,0,1,1,0.5,2 -xa=0,0,2,1,0.5,1300 -xa=0,0,3,1,0.5,100 -xd=0,0,8,0,500'
event_ex_param_str = 'xa=0,0,3,1,0.5,100'
```

#### driftmap.m
```matlab
% Absolute path to spikes-master directory.
addpath(genpath('C:\Users\lab\Downloads\spikes-master'))
% Absolute path to npy-matlab-master directory.
addpath(genpath('C:\Users\lab\Downloads\npy-matlab-master'))

```