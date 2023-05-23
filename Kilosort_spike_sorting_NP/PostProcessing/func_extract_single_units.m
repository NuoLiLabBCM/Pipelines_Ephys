function func_extract_single_units(KS_folder_probe, output_folder_probe, onset, offset, region, pb)


%% load data
spk_time = readNPY([KS_folder_probe, 'spike_times_sec_adj.npy']);
spk_time_unadj = readNPY([KS_folder_probe, 'spike_times_sec.npy']);
cluster = readNPY([KS_folder_probe, 'spike_clusters.npy']);
amplitudes = readNPY([KS_folder_probe, 'amplitudes.npy']);


%% extract trial-aligned spike data
% assign spikes to corresponding trial
trials = nan(length(spk_time),1);
spk_times_trl_st = nan(length(spk_time),1);
for num_intan = 1 : length(onset.trial)
    trial_st = onset.intan_trig(num_intan) - 1; % include 1s before intan trigger onset 
    trial_end = onset.intan_trig(num_intan) + 8;  % include 5s after intan trigger onset
    spk_in_trial_index = (spk_time >= trial_st & spk_time < trial_end);
    trials(spk_in_trial_index) = onset.trial(num_intan) ;
    spk_times_trl_st(spk_in_trial_index) = spk_time(spk_in_trial_index) - trial_st - 1; % minus 1s to cancel 1s before intan trigger included in "trial_st" 
end


%% extract good cluster based on QC metrics and from manual curation
curation_label = tdfread([KS_folder_probe, 'cluster_group.tsv']);
classifier_label = tdfread([KS_folder_probe, 'cluster_predictions.tsv']);

if exist([KS_folder_probe, 'cluster_info.tsv']) % with manual curation
    cluster_info = tdfread([KS_folder_probe, 'cluster_info.tsv']);  % note that the attributes in this file has been updated based on splitting/merging during manual curation, and therefore different from metrics.csv above
else % no manual curation, just output from classifier (classifier + Dave's QC
    cluster_info = readtable([KS_folder_probe, 'metrics.csv']);
    ch = readNPY([KS_folder_probe, 'clus_table.npy']);
    ch = double(ch(:,2));
    cluster_info.ch = ch;
end

cluster_original_cluster_id = tdfread([KS_folder_probe, 'cluster_original_cluster_id.tsv']);
cluster_qc_threshold_check = tdfread([KS_folder_probe, 'cluster_qc_threshold_check.tsv']);


% extract good cluster based on QC thresholding
QC_cluster = cluster_qc_threshold_check.cluster_id(cluster_qc_threshold_check.qc_threshold_check==1);
disp(['extracted ',num2str(length(QC_cluster)),' units out of ',num2str(size(cluster_info.cluster_id,1)),' units based on QC metrics']);

% extract good cluster based on classifer 
classifier_good_cluster = classifier_label.cluster_id(classifier_label.predictions==1);
i_tmp = ismember(classifier_good_cluster, QC_cluster);
classifier_good_cluster(i_tmp) = [];
disp(['extracted ',num2str(length(classifier_good_cluster)),' units out of ',num2str(size(cluster_info.cluster_id,1)),' units based on classifer']);

% extract good cluster based on manual curation
curation_cluster = find(ismember(string(curation_label.group),string('good ')));
curation_cluster = curation_label.cluster_id(curation_cluster);
i_tmp = ismember(curation_cluster, QC_cluster);
curation_cluster(i_tmp) = [];
i_tmp = ismember(curation_cluster, classifier_good_cluster);
curation_cluster(i_tmp) = [];
disp(['extracted ',num2str(length(curation_cluster)),' units out of ',num2str(size(cluster_info.cluster_id,1)),' units based on manual curation']);


%% save good units based on QC thresholding
n_unit = 0;
for i_cluster_id = QC_cluster'
    n_unit = n_unit+1;
    unit = struct();

    unit.id = i_cluster_id;
    unit.origin_id = cluster_original_cluster_id.original_cluster_id(cluster_original_cluster_id.cluster_id==i_cluster_id);
    
    unit.spike_times = spk_times_trl_st(cluster==i_cluster_id);
    unit.trials = trials(cluster==i_cluster_id);
    unit.channel = zeros(length(unit.spike_times),1)+cluster_info.ch(cluster_info.cluster_id == i_cluster_id);
    unit.stable_trials = min(unit.trials):max(unit.trials);
    unit.spk_times_continuous = spk_time(cluster==i_cluster_id);
    unit.spk_times_unadj = spk_time_unadj(cluster==i_cluster_id);    
    unit.amplitudes = amplitudes(cluster==i_cluster_id);
    
    unit.pk_channel = cluster_info.ch(cluster_info.cluster_id == i_cluster_id);       % note the channel number starts from 0, also adjacent channels are in increments of 2
    
    % QC metric <--------- Needs to be recomputed for manually curated units
    
    % region
    unit.region = region;
    
    % save each unit
    save(strcat(output_folder_probe,'SingleUnit_',pb,'_QC',string(n_unit),'.mat'),'unit')
end


%% save good units based on classifier
% n_unit -- continue counting from above
for i_cluster_id = classifier_good_cluster'
    n_unit = n_unit+1;
    unit = struct();

    unit.id = i_cluster_id;
    unit.origin_id = cluster_original_cluster_id.original_cluster_id(cluster_original_cluster_id.cluster_id==i_cluster_id);
    
    unit.spike_times = spk_times_trl_st(cluster==i_cluster_id);
    unit.trials = trials(cluster==i_cluster_id);
    unit.channel = zeros(length(unit.spike_times),1)+cluster_info.ch(cluster_info.cluster_id == i_cluster_id);
    unit.stable_trials = min(unit.trials):max(unit.trials);
    unit.spk_times_continuous = spk_time(cluster==i_cluster_id);
    unit.spk_times_unadj = spk_time_unadj(cluster==i_cluster_id);    
    unit.amplitudes = amplitudes(cluster==i_cluster_id);
    
    unit.pk_channel = cluster_info.ch(cluster_info.cluster_id == i_cluster_id);       % note the channel number starts from 0, also adjacent channels are in increments of 2
    
    % QC metric <--------- Needs to be recomputed for manually curated units
    
    % region
    unit.region = region;
    
    % save each unit
    save(strcat(output_folder_probe,'SingleUnit_',pb,'_Good',string(n_unit),'.mat'),'unit')
end



%% save good cluster based on manual curation label
% n_unit -- continue counting from above
for i_cluster_id = curation_cluster'
    n_unit = n_unit+1;
    unit = struct();

    unit.id = i_cluster_id;
    unit.origin_id = cluster_original_cluster_id.original_cluster_id(cluster_original_cluster_id.cluster_id == i_cluster_id);
    
    unit.spike_times = spk_times_trl_st(cluster==i_cluster_id);
    unit.trials = trials(cluster==i_cluster_id);
    unit.channel = zeros(length(unit.spike_times),1)+cluster_info.ch(cluster_info.cluster_id == i_cluster_id);
    unit.stable_trials = min(unit.trials):max(unit.trials);
    unit.spk_times_continuous = spk_time(cluster==i_cluster_id);
    unit.spk_times_unadj = spk_time_unadj(cluster==i_cluster_id);    
    unit.amplitudes = amplitudes(cluster==i_cluster_id);
    
    unit.pk_channel = cluster_info.ch(cluster_info.cluster_id == i_cluster_id);       % note the channel number starts from 0, also adjacent channels are in increments of 2
    
    % QC metric <--------- Needs to be recomputed for manually curated units
    
    % region
    unit.region = region;
    
    %     %*************************************************************
    %     %*************************************************************
    %     %*************************************************************
    %     % channel and amplitude missing for some units, probably
    %     corrupted during sorting.
    %     how to handel the exception?
    %     %*************************************************************
    %     %*************************************************************
    %     %*************************************************************
    
    % save each unit
    save(strcat(output_folder_probe,'SingleUnit_',pb,'_Curation',string(n_unit),'.mat'),'unit')
end


end






