function [output] = func_read_QC_metric_table(region)

% regions = {'alm';'thalamus';'striatum';'midbrain';'medulla'}; % make imec has same order as regions

%  set criteria
qc_metric = struct();
qc_metric.alm.amp = 100; % uV
qc_metric.alm.fr = 0.2; % Hz
qc_metric.alm.pres_ratio = 0.95;
qc_metric.alm.isi_vio = 0.1;
qc_metric.alm.amp_cutoff = 0.1;
qc_metric.alm.drift_metric = 0.1;

qc_metric.thalamus.amp = 90; % uV
qc_metric.thalamus.fr = 0.1; % Hz
qc_metric.thalamus.pres_ratio = 0.9;
qc_metric.thalamus.isi_vio = 0.05;
qc_metric.thalamus.amp_cutoff = 0.08;
qc_metric.thalamus.drift_metric = 0.2;

qc_metric.striatum.amp = 70; % uV
qc_metric.striatum.fr = 0.1; % Hz
qc_metric.striatum.pres_ratio = 0.9;
qc_metric.striatum.isi_vio = 0.5;
qc_metric.striatum.amp_cutoff = 0.1;
qc_metric.striatum.drift_metric = 0.2;

qc_metric.midbrain.amp = 100; % uV
qc_metric.midbrain.fr = 0.1; % Hz
qc_metric.midbrain.pres_ratio = 0.9;
qc_metric.midbrain.isi_vio = 1;
qc_metric.midbrain.amp_cutoff = 0.08;
qc_metric.midbrain.drift_metric = 0.5;

qc_metric.medulla.amp = 150; % uV
qc_metric.medulla.fr = 0.2; % Hz
qc_metric.medulla.pres_ratio = 0.9;
qc_metric.medulla.isi_vio = 10;
qc_metric.medulla.amp_cutoff = 0.15;
qc_metric.medulla.drift_metric = 0.5;


output = eval(['qc_metric.',region,';']);


