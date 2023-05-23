

%% 
function func_extractEventTimeFromNeuropixel(binName, path, saving_dir, XAch_intan_trig, XAch_bitcode, XAch_pole_trig, XAch_cue_trig)
%%

%% Parse the corresponding metafile
meta = ReadMeta(binName, path);

%% Get data
sp_rate = SampRate(meta);
nSamp = floor(str2double(meta.fileTimeSecs)* sp_rate);
dataArray = ReadBin(0, nSamp, meta, binName, path);
dataArray(1:end-1,:) = dataArray(1:end-1,:) ./ 10000; % transform XA channel value to be 

intan_trig = dataArray(XAch_intan_trig,:);            % extract dta from XA based on user inputs
bitcode = dataArray(XAch_bitcode,:);
if nargin == 7
    pole_trig = dataArray(XAch_pole_trig,:);
    cue_trig = dataArray(XAch_cue_trig,:);
end

time_stamp = 1/sp_rate : 1/sp_rate : nSamp/sp_rate;

%% get onset time for various signals
onset = struct();
offset = struct();
[onset.intan_trig,offset.intan_trig] = func_find_pulse(intan_trig,time_stamp);
if nargin == 7
    [onset.pole_trig,offset.pole_trig] = func_find_pulse(pole_trig,time_stamp);
    [onset.cue_trig,offset.cue_trig] = func_find_pulse(cue_trig,time_stamp);
end

pulse_check(onset)
pulse_check(offset)

%% get trial number based on bitcode
onset.trial = func_read_bitcode(bitcode,onset.intan_trig,offset.intan_trig,time_stamp);


save([saving_dir,'AccessarySignalTime.mat'],'onset','offset')

end

%% ========================================================
% find pulse onsets and offsets
function [onset,offset] = func_find_pulse(trace,time_stamp)

    trig_on = diff(trace>1)==1;
    trig_off = diff(trace>1)==-1;
    
    if length(trig_on) > length(trig_off)
        warning('missing trigger off')
    elseif length(trig_on) < length(trig_off)
        warning('missing trigger on')
    end

    onset = time_stamp(trig_on);
    offset = time_stamp(trig_off);

end


% ========================================================
% find pulse onsets and offsets
function trial = func_read_bitcode(bitcode,onset_intan_trig,offset_intan_trig,time_stamp)

    trial = NaN(1,length(onset_intan_trig));

    for i = 1 : length(onset_intan_trig)
        trl_st = find(time_stamp == onset_intan_trig(i));
        trl_nd = find(time_stamp == offset_intan_trig(i));

        i_time_stamp = time_stamp(trl_st:trl_nd) - time_stamp(trl_st); % set the time when trial starts as 0
        i_bitcode = bitcode(trl_st:trl_nd);

        t_offset = 0.5005; % 0.5s of wavesurfer trigger then bitcode start，allowing 0.5ms jitter

        bitcode_Interval = 7/1000;  % samples       % 2 ms for bit, 5 ms for gap
        numBit = 10; % number of bits
        t_start = (0:numBit-1)*bitcode_Interval + t_offset;
        t_end = t_start+1.5/1000;
        bit_tmp = [];
        
        for i_bit = 1:numBit

            i_sample = i_time_stamp>=t_start(i_bit) & i_time_stamp<=t_end(i_bit);
            bit_state = mean(i_bitcode(i_sample));

            if bit_state>.5
                bit_tmp = [bit_tmp '1'];
            else
                bit_tmp = [bit_tmp '0'];
            end
        end
        i_str = findstr(bit_tmp,'1');
        bit_tmp = fliplr(bit_tmp(1:i_str(end)));
        trial(i) = bin2dec(bit_tmp);

    end

end



% ========================================================
% check if a certain pulse is missing comapred to others
function pulse_check(pulse_time)
    fd = fieldnames(pulse_time);
    fd_leng = zeros(length(fd),1);
    for i = 1 : length(fd)
        fd_leng(i) = length(fd{i});
    end
    mtx = fd_leng' - fd_leng;
    if sum(sum(mtx)) ~= 0
        error('missing trigger')
    end
end


% =========================================================
% Parse ini file returning a structure whose field names
% are the metadata left-hand-side tags, and whose right-
% hand-side values are MATLAB strings. We remove any
% leading '~' characters from tags because MATLAB uses
% '~' as an operator.
%
% If you're unfamiliar with structures, the benefit
% is that after calling this function you can refer
% to metafile items by name. For example:
%
%   meta.fileCreateTime  // file create date and time
%   meta.nSavedChans     // channels per timepoint
%
% All of the values are MATLAB strings, but you can
% obtain a numeric value using str2double(meta.nSavedChans).
% More complicated parsing of values is demonstrated in the
% utility functions below.
%
function [meta] = ReadMeta(binName, path)

    % Create the matching metafile name
    [dumPath,name,dumExt] = fileparts(binName);
    metaName = strcat(name, '.meta');

    % Parse ini file into cell entries C{1}{i} = C{2}{i}
    fid = fopen(fullfile(path, metaName), 'r');
% -------------------------------------------------------------
%    Need 'BufSize' adjustment for MATLAB earlier than 2014
%    C = textscan(fid, '%[^=] = %[^\r\n]', 'BufSize', 32768);
    C = textscan(fid, '%[^=] = %[^\r\n]');
% -------------------------------------------------------------
    fclose(fid);

    % New empty struct
    meta = struct();

    % Convert each cell entry into a struct entry
    for i = 1:length(C{1})
        tag = C{1}{i};
        if tag(1) == '~'
            % remake tag excluding first character
            tag = sprintf('%s', tag(2:end));
        end
        meta = setfield(meta, tag, C{2}{i});
    end
end % ReadMeta


% Read nSamp timepoints from the binary file, starting
% at timepoint offset samp0. The returned array has
% dimensions [nChan,nSamp]. Note that nSamp returned
% is the lesser of: {nSamp, timepoints available}.
%
% IMPORTANT: samp0 and nSamp must be integers.
%
function dataArray = ReadBin(samp0, nSamp, meta, binName, path)

    nChan = str2double(meta.nSavedChans);

    nFileSamp = str2double(meta.fileSizeBytes) / (2 * nChan);
    samp0 = max(samp0, 0);
    nSamp = min(nSamp, nFileSamp - samp0);

    sizeA = [nChan, nSamp];

    fid = fopen(fullfile(path, binName), 'rb');
    fseek(fid, samp0 * 2 * nChan, 'bof');
    dataArray = fread(fid, sizeA, 'int16=>double');
    fclose(fid);
end % ReadBin


% =========================================================
% Return sample rate as double.
%
function srate = SampRate(meta)
    if strcmp(meta.typeThis, 'imec')
        srate = str2double(meta.imSampRate);
    else
        srate = str2double(meta.niSampRate);
    end
end % SampRate