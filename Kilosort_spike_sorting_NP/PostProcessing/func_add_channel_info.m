function  [correct_pk_ch_0_index,selected_channels,selected_channels_on_probe] = func_add_channel_info(pk_channel,chan_map)
    % pk channel from Jennifer's pipeline is not the real physical peak
    % channel during recording. This is because the pipeline gets rid of 
    % inconnected channels (e.g. reference channel (192 for NP1, 128 for NP2),
    % broken channels). Therefore, the output channels after inconnected
    % channels are shifted.

        pk_ch_1_index = pk_channel + 1; % 0 indexed, need to change to 1 indexed        
        chan_order = 1:length(chan_map.connected);
        chan_order(~chan_map.connected) = [];
        correct_pk_ch_0_index = chan_order(pk_ch_1_index) - 1; % 1 indexed, need to change to 0 indexed

    %%  get adjacent channels (<= +-2, 5 channels max)
    % Hard coded physical distance to be 31 um. This could exclude channels
    % from same row as pk channel, but include two more channels above and
    % below the pk channel. works both for NP1 and NP2.
    adjacent_channels_1_index = find(chan_map.chan_dist_map(correct_pk_ch_0_index +1,:) < 31); % pk channel is 0 indexed, need to change to 1 indexed
    selected_channels_on_probe = sort(adjacent_channels_1_index) - 1; % goes back to 0 indexed
    
    %% adjacent channel (order with unconnected channel excluded (ks output order)) 
    selected_channels = nan(1,length(selected_channels_on_probe));
    for i = 1 : length(selected_channels)
        tmp_index = find(chan_order == (selected_channels_on_probe(i)+1));
        if numel(tmp_index) == 1
            selected_channels(i) = tmp_index; % 1 indexed
        end
    end
    selected_channels = selected_channels - 1; % 0 indexed

end