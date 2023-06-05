function [unit] = func_combine_duplicate_unit_kilosort(unit1,unit2)


amplitudes_tmp = cat(1,unit1.amplitudes, unit2.amplitudes);
spike_times_tmp = cat(1,unit1.spike_times, unit2.spike_times);
spk_times_continuous_tmp = cat(1,unit1.spk_times_continuous, unit2.spk_times_continuous);
spk_times_unadj_tmp = cat(1,unit1.spk_times_unadj, unit2.spk_times_unadj);
trials_tmp      = cat(1,unit1.trials, unit2.trials);
channel_tmp     = cat(1,unit1.channel, unit2.channel);
stable_trials_tmp = cat(2,unit1.stable_trials, unit2.stable_trials);
stable_trials_tmp = sort(unique(stable_trials_tmp));


i_spk_sorted = [];
for i_trial = stable_trials_tmp
    i_spk_iTrial = find(trials_tmp==i_trial);
    spk_times_iTrial = spike_times_tmp(i_spk_iTrial);
    [dummy i_sorted_tmp] = sort(spk_times_iTrial);
    i_spk_sorted = cat(1,i_spk_sorted,i_spk_iTrial(i_sorted_tmp));    
end


%
unit.id=[unit1.id unit2.id];
if isfield(unit1,'origin_id')
    unit.origin_id = [unit1.origin_id unit2.origin_id];
end

unit.spike_times =  spike_times_tmp(i_spk_sorted,:);
unit.spk_times_continuous = spk_times_continuous_tmp(i_spk_sorted,:);
unit.spk_times_unadj = spk_times_unadj_tmp(i_spk_sorted,:);
unit.amplitudes =  amplitudes_tmp(i_spk_sorted,:);
unit.trials    =  trials_tmp(i_spk_sorted,:);
unit.channel   =  channel_tmp(i_spk_sorted,:);
unit.stable_trials   =  stable_trials_tmp;
unit.pk_channel = unit1.pk_channel; % align to first unit
unit.region = unit1.region; % align to first unit
unit.corrected_pk_channel_on_probe = unit1.corrected_pk_channel_on_probe;% align to first unit
unit.selected_channels = unit1.selected_channels;% align to first unit
unit.selected_channels_on_probe = unit1.selected_channels_on_probe;% align to first unit

waveforms_tmp = nan(size(unit2.waveforms));
mean_waveform_tmp = nan(size(unit2.mean_waveform));
    
ch_idx_2_1 = find(ismember(unit2.selected_channels,unit1.selected_channels))*82;
ch_idx_1_2 = find(ismember(unit1.selected_channels,unit2.selected_channels))*82;
if isempty(ch_idx_1_2) || isempty(ch_idx_2_1)
    error('two units have no overlap channel. Should not be combined. Please double check')
end
for i_ch = 1 : length(ch_idx_2_1)
    cur_ch_1_2 = ch_idx_1_2(i_ch);
    cur_ch_2_1 = ch_idx_2_1(i_ch);
    waveforms_tmp(:,(cur_ch_1_2-81):cur_ch_1_2) = unit2.waveforms(:,(cur_ch_2_1-81):cur_ch_2_1);
    mean_waveform_tmp(1,(cur_ch_1_2-81):cur_ch_1_2) = unit2.mean_waveform(1,(cur_ch_2_1-81):cur_ch_2_1);
end
waveforms_cat = cat(1,unit1.waveforms, waveforms_tmp);
mean_waveform_cat  = cat(1,unit1.mean_waveform, mean_waveform_tmp);

unit.waveforms   =  waveforms_cat;
unit.mean_waveform   = mean_waveform_cat;

% % QC metric <--------- Needs to be recomputed for merged units<-- do this outside of this function
% unit.amplitude = cat(1,unit1.amplitude, unit2.amplitude);
% unit.firing_rate = cat(1,unit1.firing_rate, unit2.firing_rate);
% unit.presence_ratio = cat(1,unit1.presence_ratio, unit2.presence_ratio);
% unit.isi_viol = cat(1,unit1.isi_viol, unit2.isi_viol);
% unit.amplitude_cutoff = cat(1,unit1.amplitude_cutoff, unit2.amplitude_cutoff);
% unit.driftQC = cat(1,unit1.driftQC, unit2.driftQC);



end






