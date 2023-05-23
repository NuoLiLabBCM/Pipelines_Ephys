function unit = func_extract_waveforms(dataFolder,unit,nWf)

% %% Loading data from kilosort/phy easily
% 
% sp = loadKSdir(myKsDir);
% 
% % sp.st are spike times in seconds
% % sp.clu are cluster identities
% % spikes from clusters labeled "noise" have already been omitted

%% set waveform params
% To get the true waveforms of the spikes (not just kilosort's template
% shapes), use the getWaveForms function:

apD = dir(fullfile(dataFolder, '*ap*.bin')); % AP band file from spikeGLX specifically, after catgt filtering
gwfparams.fileName = fullfile(apD(1).folder,apD(1).name);         % notice that fileName's dir is different than dataDir, which is within imec*_ks2
metaD = dir(fullfile(dataFolder,'*ap.meta'));
gwfparams.metaName = fullfile(metaD(1).folder,metaD(1).name);
gwfparams.dataType = 'int16';            % Data type of .dat file (this should be BP filtered)
gwfparams.nCh = 385;                      % Number of channels that were streamed to disk in .dat file
% gwfparams.wfWin = [-40 41];              % Number of samples before and after spiketime to include in waveform
gwfparams.wfWin = [-20 61];              % Number of samples before and after spiketime to include in waveform
gwfparams.nWf = nWf;                    % Number of waveforms per unit to pull out


gwfparams.spikeTimes = ceil(unit.spk_times_unadj*30000); % Vector of cluster spike times (in samples) same length as .spikeClusters
gwfparams.spikeClusters = unit.id;
    
%% get waveforms
wf = getWaveForms(gwfparams,unit);
unit.waveforms = wf.waveForms .* 10^6; % in uV
unit.mean_waveform = reshape(wf.waveFormsMean',1,[]) .* 10^6; % in uV


end


%% user defined functions

function wf = getWaveForms(gwfparams,unit)
% function wf = getWaveForms(gwfparams)
%
% Extracts individual spike waveforms from the raw datafile, for multiple
% clusters. Returns the waveforms and their means within clusters.
%
% Contributed by C. Schoonover and A. Fink
%
% % EXAMPLE INPUT
% gwfparams.dataDir = '/path/to/data/';    % KiloSort/Phy output folder
% gwfparams.fileName = 'data.dat';         % .dat file containing the raw 
% gwfparams.dataType = 'int16';            % Data type of .dat file (this should be BP filtered)
% gwfparams.nCh = 385;                      % Number of channels that were streamed to disk in .dat file
% gwfparams.wfWin = [-40 41];              % Number of samples before and after spiketime to include in waveform
% gwfparams.nWf = 2000;                    % Number of waveforms per unit to pull out
% gwfparams.spikeTimes =    [2,3,5,7,8,9]; % Vector of cluster spike times (in samples) 
% gwfparams.spikeClusters = 2;             % Number of cluster IDs
%
% % OUTPUT
% wf.unitIDs                               % [nClu,1]            List of cluster IDs; defines order used in all wf.* variables
% wf.spikeTimeKeeps                        % [1,nWf]          Which spike times were used for the waveforms
% wf.waveForms                             % [nWf,nCh,nSWf] Individual waveforms
% wf.waveFormsMean                         % [nCh,nSWf]     Average of all waveforms (per channel)
%                                          % nClu: number of different clusters in .spikeClusters
%                                          % nSWf: number of samples per waveform
%
% % USAGE
% wf = getWaveForms(gwfparams);

% Load .dat and KiloSort/Phy output

%%%%% runbo change according to output from Jennifer's pipeline

fileName = gwfparams.fileName;

filenamestruct = dir(fileName);
dataTypeNBytes = numel(typecast(cast(0, gwfparams.dataType), 'uint8')); % determine number of bytes per sample
nSamp = filenamestruct.bytes/(gwfparams.nCh*dataTypeNBytes);  % Number of samples per channel
wfNSamples = length(gwfparams.wfWin(1):gwfparams.wfWin(end));
mmf = memmapfile(fileName, 'Format', {gwfparams.dataType, [gwfparams.nCh nSamp], 'x'});

selected_channels = unit.selected_channels;
selected_channels_on_probe = unit.selected_channels_on_probe;
corrected_pk_channel_on_probe = unit.corrected_pk_channel_on_probe;

nChInMap=length(unit.selected_channels_on_probe);

%%

% Read spike time-centered waveforms
unitIDs = gwfparams.spikeClusters;
spikeTimeKeeps = nan(1,gwfparams.nWf);
waveForms = nan(gwfparams.nWf,nChInMap,wfNSamples);
% waveFormsMean = nan(nChInMap,wfNSamples);
%%
curSpikeTimes = gwfparams.spikeTimes;
curUnitnSpikes = size(curSpikeTimes,1);
spikeTimesRP = curSpikeTimes(randperm(curUnitnSpikes));
spikeTimeKeeps(1:min([gwfparams.nWf curUnitnSpikes])) = sort(spikeTimesRP(1:min([gwfparams.nWf curUnitnSpikes])));
%%
selected_channels_1_indexed = selected_channels_on_probe +1;
for curSpikeTime = 1:min([gwfparams.nWf curUnitnSpikes])
    tmpWf = mmf.Data.x(1:gwfparams.nCh,spikeTimeKeeps(curSpikeTime)+gwfparams.wfWin(1):spikeTimeKeeps(curSpikeTime)+gwfparams.wfWin(end));

    waveForms(curSpikeTime,:,:) = tmpWf(selected_channels_1_indexed,:);
end
waveForms = func_convert_int_2_volt(gwfparams.metaName,waveForms,selected_channels_1_indexed);
% waveFormsMean(:,:) = squeeze(mean(waveForms(:,:,:),1,'omitnan'));

%     disp(['Completed ' int2str(curUnitInd) ' units of ' int2str(numUnits) '.']);

%% 
% set waveform from inconnected channels to be NaN
waveForms(:,isnan(selected_channels),:) = NaN;
% concatenate waveforms accordingly
concatenated_waveforms = func_concatenate_waveforms(waveForms,selected_channels_on_probe,corrected_pk_channel_on_probe);


%%
% Package in wf struct
wf.unitIDs = unitIDs;
wf.spikeTimeKeeps = spikeTimeKeeps;
wf.waveForms = concatenated_waveforms;
wf.waveFormsMean = squeeze(mean(wf.waveForms,1));


end

function concatenated_waveforms = func_concatenate_waveforms(waveforms,selected_channels,corrected_pk_channel_on_probe)
    center_ch = find(selected_channels == corrected_pk_channel_on_probe); % 0 indexed
    sz_wf = size(waveforms);
    concatenated_waveforms = nan(sz_wf(1),sz_wf(3)*5);

    for i = 1 : length(selected_channels)
        part_wf = squeeze(waveforms(:,i,:));
        part_index = i - center_ch +3;
        concatenated_waveforms(:,(sz_wf(3)*(part_index-1)+1):(sz_wf(3)*part_index)) = part_wf;
    end
end


