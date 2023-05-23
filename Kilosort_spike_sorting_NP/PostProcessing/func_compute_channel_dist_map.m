function chan_dist_map = func_compute_channel_dist_map(chanMap)
    % no need to specifiy probe type, chanMap contain all the needed info
    % number of total  AP channels regardless connections.
    % 384 X 384 
    xcoords = chanMap.xcoords;
    ycoords = chanMap.ycoords;
    chan_dist_map = sqrt((xcoords-xcoords').^2 + (ycoords-ycoords').^2);
end
