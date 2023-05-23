function func_extract_single_units_withoutCuration(KS_folder_probe, output_folder_probe, onset, offset, qc_metric, region, pb)


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


%% extract firing time, fr per trial, qc metric
tb = readtable([KS_folder_probe, 'metrics.csv']);

for i = 1 : size(tb,1)
    cluster_id = tb.cluster_id(i);
    tb.spk_time{i} = spk_time(cluster == cluster_id);
    fr_per_trial = nan(length(onset.trial),1);
    for j = 1 : length(onset.trial)
        temp = cell2mat(tb.spk_time(i));
        trial_range = [onset.intan_trig(j) offset.intan_trig(j)];
        fr_per_trial(j) = sum(temp>=trial_range(1) & temp< trial_range(2)) / (trial_range(2)-trial_range(1));
    end
    tb.fr_per_trial{i} = fr_per_trial;
    tb.avg_fr_per_trial(i) = mean(fr_per_trial);
    movingMeanSpikeRate = movmean(fr_per_trial,6);
    spikeRate = downsample(movingMeanSpikeRate,6);
    poissDistr = poisscdf(spikeRate,tb.avg_fr_per_trial(i));
    tb.driftQC(i) = length(find(poissDistr > 0.95 | poissDistr < 0.05)) / length(poissDistr);
    tb.region{i} = region;
end


%% extract good cluster based on QC metrics
good_cluster = tb.amplitude > qc_metric.amp & ...
    tb.firing_rate > qc_metric.fr & ...
    tb.presence_ratio > qc_metric.pres_ratio & ...
    tb.isi_viol < qc_metric.isi_vio & ...
    tb.amplitude_cutoff < qc_metric.amp_cutoff & ...
    tb.driftQC < qc_metric.drift_metric;
good_cluster_id = tb.cluster_id(good_cluster);

disp(['extracted ',num2str(sum(good_cluster)),' units out of ',num2str(size(tb,1)),' units based on QC metrics']);


%% save good units
n_unit = 0;
for i_cluster_id = good_cluster_id'
    n_unit = n_unit+1;
    unit = struct();

    unit.id = i_cluster_id;
    unit.spike_times = spk_times_trl_st(cluster==i_cluster_id);
    unit.trials = trials(cluster==i_cluster_id);
    unit.channel = zeros(length(unit.spike_times),1)+tb.peak_channel(tb.cluster_id == i_cluster_id);
    unit.stable_trials = min(unit.trials):max(unit.trials);
    unit.spk_times_continuous = spk_time(cluster==i_cluster_id);
    unit.spk_times_unadj = spk_time_unadj(cluster==i_cluster_id);    
    unit.amplitudes = amplitudes(cluster==i_cluster_id);
    unit.pk_channel = tb.peak_channel(tb.cluster_id == i_cluster_id);       % note the channel number starts from 0, also adjacent channels are in increments of 2

    
    % QC metric
    unit.amplitude = tb.amplitude(tb.cluster_id == i_cluster_id);
    unit.firing_rate = tb.firing_rate(tb.cluster_id == i_cluster_id);
    unit.presence_ratio = tb.presence_ratio(tb.cluster_id == i_cluster_id);
    unit.isi_viol = tb.isi_viol(tb.cluster_id == i_cluster_id);
    unit.amplitude_cutoff = tb.amplitude_cutoff(tb.cluster_id == i_cluster_id);
    unit.driftQC = tb.driftQC(tb.cluster_id == i_cluster_id);
    
    % region
    unit.region = string(tb.region(tb.cluster_id == i_cluster_id));
    
    % save each unit
    save(strcat(output_folder_probe,'SingleUnit_',pb,'_QC',string(n_unit),'.mat'),'unit')
end


end






