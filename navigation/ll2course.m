function tc = ll2course(latslons)
%
% Usage: tc = ll2course([latitudes longitudes])
%
% Returns the compass direction between consecutive points contained in the
% input array (along the great circle), measured in degrees true north.  
%
% The input array must be a 2-column array containing latitudes and longitudes
% in decimal degrees.
%
% Reference: http://williams.best.vwh.net/avform.htm
%
% See also course2ll
% ============================================================================
% $RCSfile: ll2course.m,v $
% $Source: /home/kerfoot/cvsroot/slocum/matlab/spt/navigation/ll2course.m,v $
% $Revision: 1.1.1.1 $
% $Date: 2013/09/13 18:51:19 $
% $Author: kerfoot $
% ============================================================================
%

% Intialize the return value
tc = [];

[r,c] = size(latslons);
if isempty(latslons)
    return;
elseif r < 2
    disp('Input array must have at least 2 rows.');
    return;
elseif ~isequal(c,2)
    disp('Input array must consist of latitude/longitude pairs.');
    return;
end

% Seperate out latitudes and longitudes
lats = latslons(:,1);
lons = latslons(:,2);

% Convert coordinates to radians
lats = deg2rad(lats);
lons = deg2rad(lons);

% Take the difference between consecutive points
delta_lons = diff(lons);

% Size the return value
tc = repmat(NaN, length(lats)-1, 1);

for x = 1:length(tc)
    
    % Current latitude coordiantes
    lat1 = lats(x);
    lat2 = lats(x+1);
    
    % Poles special case
    if cos(lat1) < eps
        if lat1 > 0
            tcrad = pi;
        else
            tcrad = pi*2;
        end
    else % All other cases
        tcrad = mod(atan2(sin(delta_lons(x))*cos(lat2),...
            cos(lat1)*sin(lat2)-sin(lat1)*cos(lat2)*cos(delta_lons(x))), 2*pi);
    end
    
    % Convert from radians to degrees
    tc(x) = rad2deg(tcrad);

end
