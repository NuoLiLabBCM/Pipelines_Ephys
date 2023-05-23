function  correct_pk_ch = func_correct_pk_channel(unit,chan_map)
    % pk channel from Jennifer's pipeline is not the real physical peak
    % channel during recording. This is because the pipeline gets rid of 
    % inconnected channels (e.g. reference channel (192 for NP1, 128 for NP2),
    % broken channels). Therefore, the output channels after inconnected
    % channels are shifted.
    
    pk_ch = unit.pk_channel +1; % 0 indexed, need to change to 1 indexed
    inconnected_ch = find(~chan_map.connected);
    
    shifted_value = sum((pk_ch - inconnected_ch) >= 0);

    correct_pk_ch = pk_ch + shifted_value -1; % 1 indexed, need to change to 0 indexed

end