clear all
close all
clc

addpath(genpath('.\npy-matlab-master\'))

%% ------- This script extracts single units after KS2 and spike sorting in Phy --------
%
% 1. the data this program can process is recorded by sglx and sorted by
% using pipeline wroted by Jennifer Colonell, which runs catGT, kilosort
% 2.5, TPrime
%
% 2. please change the "user data" section accordingly before clicking
% 
% 3. check the channels for XA channels below, make sure it matches your rig
% 
% -------------------------------------------------------------------------------------

%% user data
Data_info =  {
    % {data folder}  {probe ID}  {region: alm; thalamus; striatum; midbrain; medulla}
    %['..\Data_spike_sorting\Data\BAYLORNL105\221102\'], {'imec0'}, {'alm'};...
    ['..\Data_spike_sorting\Data\BAYLORNL105\221103\'], {'imec1'}, {'alm'};...
    %['..\Data_spike_sorting\Data\BAYLORNL106\221103\'], {'imec1'}, {'alm'};...
    };


%% main loop
for i_session = 1 : size(Data_info,1)
    
    raw_data_folder = Data_info{i_session,1};
    probe = Data_info{i_session,2};
    region = Data_info{i_session,3};
    if length(probe) ~= length(region)
        error('please enter a region for each probe');
    end
    
    disp(['processing session ', raw_data_folder]);
    listing = dir(raw_data_folder);
    listing = listing(contains({listing.name},'catgt') & [listing(:).isdir] == 1);
    main_component = listing.name(7:end); % after "catgt_"
    
    %% get timestamps of accessary signals from nidq file
    nidq_path = [listing.folder, '\', listing.name, '\'];
    binName = [main_component '_t0.nidq.bin'];
    
    if ~exist([nidq_path, 'AccessarySignalTime.mat'],'file')
        if exist([nidq_path, binName],'file')            
            disp('processing NIDQ file');
            
            %% specify which XA channel based on your setup wiring
            XAch_intan_trig = 1;    % <<<<<<<<<<<<<<< USER input, Rig specific!!!
            XAch_bitcode = 2;       % <<<<<<<<<<<<<<< USER input, Rig specific!!!
            XAch_pole_trig = 3;     % <<<<<<<<<<<<<<< USER input, Rig specific!!!
            XAch_cue_trig = 4;      % <<<<<<<<<<<<<<< USER input, Rig specific!!!
            
            % runbo defined function, make sure located in the same folder as this m file
            func_extractEventTimeFromNeuropixel(binName, nidq_path, nidq_path,...
                XAch_intan_trig, XAch_bitcode, XAch_pole_trig, XAch_cue_trig);
        else
            error('Missing NIDQ file')
        end
    end
    load([nidq_path, 'AccessarySignalTime.mat']) % generated by extractEventTImeFromNeuropixel, containing onset & offset
    
    
    %% extract single-unit data
    clear binName
    for pb = 1 : length(probe)
        data_folder = [listing.folder, '\', listing.name, '\',main_component,'_',probe{pb},'\'];
        KS_folder = [data_folder, probe{pb} '_ks2\'];  
        KS_trimmed_folder = [data_folder, probe{pb} '_ks2_trimmed\'];  
        single_unit_folder = [KS_folder(1:end-1), '_SingleUnits\'];
        
        if exist(KS_folder)
            if ~exist(single_unit_folder)
                mkdir(single_unit_folder);
            end
            
            %% extract units from .npy and .tsv files
            if exist(KS_trimmed_folder)
                
                func_extract_single_units(KS_trimmed_folder, single_unit_folder, onset, offset, region{pb}, probe{pb});
                
            else
                % if no curation performed, extract units directly based on strigent QC threshold
                warning('No Curated KS output files found. Extracting units based on strigent QC tresholding');
                
                [qc_metric] = func_read_QC_metric_table(region{pb});  % read QC metric criteria    
                func_extract_single_units_withoutCuration(KS_folder, single_unit_folder, onset, offset, qc_metric, region{pb}, probe{pb});
            end
            
            
            %% Delete copies of the same spike
            func_correctSpikeTiming_kilosort(single_unit_folder);
            
            
            %% correct peak channel info and exract waveform for the units
            unit_file_list = dir([single_unit_folder,'SingleUnit*.mat']);
            chanMapFileInfo = dir([data_folder,'*_chanMap.mat']);
            chan_map = load(fullfile(chanMapFileInfo.folder,chanMapFileInfo.name));
            chan_map.chan_dist_map = func_compute_channel_dist_map(chan_map); % used to determine channels neighboring to pk channel
            for i_unit = 1 : size(unit_file_list,1)
                % load single unit file
                load(fullfile(single_unit_folder,unit_file_list(i_unit).name),'unit')
                disp(unit_file_list(i_unit).name);
                
                %% correct peak channel info and adjacent channels
                [corrected_pk_channel,selected_channels,selected_channels_on_probe] = func_add_channel_info(unit.pk_channel,chan_map);
                unit.corrected_pk_channel_on_probe = corrected_pk_channel; % 0 indexed
                unit.selected_channels = selected_channels; % 0 indexed
                unit.selected_channels_on_probe = selected_channels_on_probe; % 0 indexed
                
                %% extract waveform for the untis
                % for curated units, load the spike waveform from raw data
                waveform_num = 100;
                unit = func_extract_waveforms(data_folder,unit,waveform_num);
                
                
                %% compute quality metrics for the units
                % <--- add a new function to compute these QC on all units
                %func_calculate_unit_QC(single_unit_folder);
                % amplitude
                % firing_rate
                % presence_ratio
                % isi_viol
                % amplitude_cutoff
                % driftQC
                
                
                if sum(isnan(unit.selected_channels))>0
                    disp(unit_file_list(i_unit).name)
                end
                
                save([single_unit_folder, unit_file_list(i_unit).name],'unit');
            end
                   
            
        else
            disp('No KS output files found');
        end
    end
end
