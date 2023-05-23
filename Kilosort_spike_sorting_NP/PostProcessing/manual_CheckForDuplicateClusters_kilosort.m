clear all;
close all;

% list of data files
session_dir = {
    
% '..\Data_spike_sorting\Data\BAYLORNL105\221102\catgt_NL_NL105_20221102_session1_g0\NL_NL105_20221102_session1_g0_imec0\imec0_ks2_SingleUnits\';...
% 'H:\kilosort_output\RGT09\20230215\catgt_RGT09_20230215_sessio1_bank0_g0\RGT09_20230215_sessio1_bank0_g0_imec0\imec0_ks2_SingleUnits\';...
    %['..\Data_spike_sorting\Data\BAYLORNL105\221102\'], {'imec0'}, {'alm'};...
   'H:\kilosort_output\RGT09\20230216\catgt_RGT09_20230216_sessio1_bank0_g0\RGT09_20230216_sessio1_bank0_g0_imec0\imec0_ks2_SingleUnits\';...


};

for i_session = 1:size(session_dir,1)
    
    % generate input file & directories
    single_unit_dir = [session_dir{i_session}];
    if ~exist([single_unit_dir,'CheckDuplicate'])
        mkdir([single_unit_dir,'CheckDuplicate'])
    end
    
    unit_files = dir([single_unit_dir,'SingleUnit*Curation*.mat']);
    
    % load site map
    i_str = findstr(single_unit_dir,'\');
    chan_map_folder = single_unit_dir(1:i_str(end-1));
    chan_map_file = dir([chan_map_folder,'*ap_chanMap*']);
    load([chan_map_folder, chan_map_file.name]);
    
    % go through unit pairs
    for i_unit = 1:size(unit_files,1)
        load([single_unit_dir, unit_files(i_unit).name]);
        
        unit_tmp = unit;
        unit_channel = median(unit_tmp.channel);
        
        % Use the channel map to claculate closest neighoring channels
        KS_chanMap = nan(size(chanMap0ind));        % create a map of KS ch# on the physical probe
        KS_chanMap(connected) = [0:(sum(connected)-1)];
        i_unit_ch = find(KS_chanMap==unit_channel); % find the physical channel unit is from
        if isempty(i_unit_ch)
            error('should not be here');
        end
        dist_all_ch = sqrt((xcoords - xcoords(i_unit_ch)).^2+(ycoords - ycoords(i_unit_ch)).^2);
        i_neigh_ch = find(dist_all_ch>0 & dist_all_ch<=31);   % find channels on the physical probe that are less 31 um from pk channel     
        neigh_ch = KS_chanMap(i_neigh_ch);
        neigh_ch(isnan(neigh_ch)) = [];             % discard any unconnected channel, which will show up as NaN

        
        for i_unit_pair = i_unit+1:size(unit_files,1)
            
            load([single_unit_dir, unit_files(i_unit_pair).name]);
            
            unit_pair_tmp = unit;
            unit_pair_channel = median(unit_pair_tmp.channel);
            
            if abs(unit_channel-unit_pair_channel)==0 | ismember(unit_pair_channel,neigh_ch)
                close all
                
                func_check_for_duplicate_unit_kilosort(unit_tmp, unit_files(i_unit).name(1:end-4), unit_pair_tmp, unit_files(i_unit_pair).name(1:end-4), single_unit_dir);
                
            end
            
        end
    end
end 
clearvars -except session_dir position probe

keyboard
%% mannually put in the duplicate unit pair
% clear;
single_unit_dir='H:\kilosort_output\RGT09\20230216\catgt_RGT09_20230216_sessio1_bank0_g0\RGT09_20230216_sessio1_bank0_g0_imec0\imec0_ks2_SingleUnits\';...
combine_pairs={
    '73' '74';...
    '136' '139';...
    '178' '179';...
    '182' '183';...
    };

unit_tmp = dir([single_unit_dir,'SingleUnit*Curation*.mat']);
unit_base_name = unit_tmp.name;
i_str = findstr(unit_base_name,'Curation');
unit_base_name = unit_base_name(1:i_str(1)+7);

if ~exist([single_unit_dir,'DuplicateUnits'])
    mkdir([single_unit_dir,'DuplicateUnits'])
end

file_list = {};
if size(combine_pairs,1)>0
    % combine units
    for i_pair = 1:size(combine_pairs,1)
        tf=0;
        pair1=combine_pairs{i_pair,1};
        pair2=combine_pairs{i_pair,2};
        if exist([single_unit_dir, unit_base_name,pair1,'.mat'],'file') & exist([single_unit_dir, unit_base_name,pair2,'.mat'],'file')
            tf=1;
        elseif ~exist([single_unit_dir, unit_base_name,pair1,'.mat'],'file') & exist([single_unit_dir, unit_base_name,pair2,'.mat'],'file')
            % this occurs if pair1 has been merged and is now another unit
            tmp=[];
            for k=1:size(combine_pairs,1)
                tmp(k)=strcmp(combine_pairs{k,2},pair1);
            end
            tmp=find(tmp);
            pair1=combine_pairs{tmp(1),1};
            tf=1;
        end
        if tf
            disp(['combining ',unit_base_name,' ',pair1,'  ',pair2]);
            
            
            load([single_unit_dir, unit_base_name,pair1,'.mat']);
            unit1 = unit;
            
            load([single_unit_dir, unit_base_name,pair2,'.mat']);
            unit2 = unit;
            
            clear unit;
            [unit] = func_combine_duplicate_unit_kilosort(unit1,unit2);
            
            
            isi = diff(unit.spike_times);
            i_1st_spk = diff(unit.trials)>0;
            i_spk_discard = find(isi<.0005  & i_1st_spk==0);
            
            unit.spike_times(i_spk_discard,:) = [];
            unit.spk_times_continuous(i_spk_discard,:) = [];
            unit.spk_times_unadj(i_spk_discard,:) = [];
            unit.amplitudes(i_spk_discard,:) = [];
            unit.trials(i_spk_discard,:) = [];
            unit.channel(i_spk_discard,:) = [];
            
            disp([num2str(size(i_spk_discard,1)),'/',num2str(size(isi,1)+1),' spikes discarded'])
            
            
            %% compute quality metrics for the merged unit
            % <--- add a new function to compute these QC on all units
            %func_calculate_unit_QC(single_unit_folder);
            % amplitude
            % firing_rate
            % presence_ratio
            % isi_viol
            % amplitude_cutoff
            % driftQC
            
            disp(['Updating ', unit_base_name, pair1]);
            copyfile([single_unit_dir, unit_base_name, pair1,'.mat'],[single_unit_dir, 'DuplicateUnits\', unit_base_name, pair1, '_orig.mat']);
            save([single_unit_dir, unit_base_name, pair1,'.mat'], 'unit');
            file_list{end+1,1} = [single_unit_dir, unit_base_name, pair1,'.mat'];
            
            disp(['Deleting ', unit_base_name, pair2]);
            copyfile([single_unit_dir, unit_base_name, pair2,'.mat'],[single_unit_dir, 'DuplicateUnits\', unit_base_name, pair2, '_orig.mat']);
            delete([single_unit_dir, unit_base_name, pair2,'.mat']);

        end
    end
end

file_list = unique(file_list);
for i_file = 1:length(file_list)
    movefile(file_list{i_file}, [file_list{i_file}(1:end-4),'_combined.mat']);
end


