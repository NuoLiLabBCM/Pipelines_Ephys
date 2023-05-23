function func_correctSpikeTiming_kilosort(single_unit_dir)

% remove events that are <0.5 ms apart


% generate input file & directories
unit_files = dir([single_unit_dir,'SingleUnit*.mat']);

for i_unit = 1:size(unit_files,1)
    load([single_unit_dir, unit_files(i_unit).name]);
    
    unit_tmp = unit;
    
    
    isi = diff(unit_tmp.spike_times);
    i_1st_spk = diff(unit_tmp.trials)>0;
    
    i_spk_discard = find(isi<.0005  & i_1st_spk==0);
    
    unit_tmp.spike_times(i_spk_discard,:) = [];
    unit_tmp.amplitudes(i_spk_discard,:) = [];
    unit_tmp.trials(i_spk_discard,:) = [];
    unit_tmp.channel(i_spk_discard,:) = [];
    unit_tmp.spk_times_continuous(i_spk_discard,:) = [];
    unit_tmp.spk_times_unadj(i_spk_discard,:) = [];
    
    disp([unit_files(i_unit).name,': ', num2str(size(i_spk_discard,1)),'/',num2str(size(isi,1)+1),' spikes discarded'])
    
end



    
    
   