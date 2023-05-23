
function func_calculate_unit_QC(single_unit_folder)

%
% load each single unit file and calculate QC metric for each units
% The following QC metrics are calculated
%   amplitude
%   firing_rate
%   presence_ratio
%   isi_viol
%   amplitude_cutoff
%   driftQC
%

single_unit_files = dir([single_unit_folder,'SingleUnit*.mat']);       % only load raw data for curated units

for i_unit = 1:length(single_unit_files)
    disp(['Calculating unit ',num2str(i_unit),' QC']);
    load([single_unit_folder, single_unit_files(i_unit).name]);
    
   
    %<-----i'm here need to calculate QC
        keyboard

    spike_times = unit.spk_times_continuous;
    unit_ch = unit.pk_channel;
    
    %   amplitude
    %   firing_rate
    %   presence_ratio
    %   isi_viol
    %   amplitude_cutoff
    %   driftQC
    
    
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



    
    
end









