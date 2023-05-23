%%
clear all;
close all

% list of data files
session_dir = {
    
% '..\Data_spike_sorting\Data\BAYLORNL105\221102\catgt_NL_NL105_20221102_session1_g0\NL_NL105_20221102_session1_g0_imec0\imec0_ks2_SingleUnits\';...
% '..\Data_spike_sorting\Data\BAYLORNL106\221103\catgt_NL_NL106_20221103_session1_g0\NL_NL106_20221103_session1_g0_imec1\imec1_ks2_SingleUnits\';...
% 'H:\kilosort_output\RGT09\20230215\catgt_RGT09_20230215_sessio1_bank0_g0\RGT09_20230215_sessio1_bank0_g0_imec0\imec0_ks2_SingleUnits\';...
'H:\kilosort_output\RGT09\20230216\catgt_RGT09_20230216_sessio1_bank0_g0\RGT09_20230216_sessio1_bank0_g0_imec0\imec0_ks2_SingleUnits\';...
};


for i_session = 1:size(session_dir,1)
    
    % generate input file & directories
    single_unit_dir = [session_dir{i_session}];%num2str(position),
    if ~exist([single_unit_dir,'BadUnits'])
        mkdir([single_unit_dir,'BadUnits'])
    end
    if ~exist([single_unit_dir,'CheckBadUnits'])
        mkdir([single_unit_dir,'CheckBadUnits'])
    end
    unit_files1 = dir([single_unit_dir,'SingleUnit*QC*.mat']);      % only check automated sorting files and manually combined units
    unit_files2 = dir([single_unit_dir,'SingleUnit*_combined.mat']);
    unit_files3 = dir([single_unit_dir,'SingleUnit*Good*.mat']);
    unit_files = [unit_files1; unit_files2; unit_files3];
    
    for i_unit = 1:size(unit_files,1)
        load([single_unit_dir, unit_files(i_unit).name]);
        
        figure;
        subplot(3,3,1);
        isi = diff(unit.spike_times);
        isi = isi(find(isi<.5));
        isi = [isi; -isi];
        edges = [-.03:.00025:.03];
        n = histc(isi,edges);
        plot(edges, n, 'r')
        if max(n)~=0
            axis([-.02 .02 0 max(n)]);
        end
        subplot(3,3,4);
        plot(nanmean(unit.waveforms),'b')
        
        subplot(3,3,[2 3 5 6 8 9]);
        spike_times_psth = {};
        n_trial = 0;
        for i_trial = min(unit.trials):max(unit.trials)
            n_trial = n_trial+1;
            spike_times_psth{n_trial,1} = unit.spike_times(unit.trials==i_trial)';
        end
        [psth t] = func_getPSTH(spike_times_psth,0,max(unit.spike_times));
        bar(t,psth,'k');hold on;
        trials = unit.trials-min(unit.trials);
        plot(unit.spike_times,trials/max(trials)*max(psth)+max(psth)*1.2,'.k')
        xlim([0 min([6 max(unit.spike_times)])])
        
        saveas(gcf,[single_unit_dir,'CheckBadUnits\', unit_files(i_unit).name(1:end-4),'.png'],'png');
        close;
    end
    
end
clearvars -except session_dir position probe


