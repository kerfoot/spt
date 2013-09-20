function distance = gcdist(coordinates)
%
% Usage: distance = gcdist([lats lons])
%
% Calculates the great circle distance between consecutive coordinates
% contained in the 2-column input array.  Coordinates must be specified in
% decimal degrees.
%
% Calculated distances are in meters.
%
% Reference: http://williams.best.vwh.net/avform.htm
% ============================================================================
% $RCSfile: gcdist.m,v $
% $Source: /home/kerfoot/cvsroot/slocum/matlab/spt/navigation/gcdist.m,v $
% $Revision: 1.1.1.1 $
% $Date: 2013/09/13 18:51:19 $
% $Author: kerfoot $
% ============================================================================
%

caller = [mfilename '.m'];

distance = nan(size(coordinates,1),1);

[r,c] = size(coordinates);
if r < 2
    disp([caller ' E - Input arg must contain at least 2 coordinates.']);
    return;
elseif ~isequal(c,2)
    disp([caller ' E - Input arg must contain latitude/longitude pairs.']);
    return;
end

% Convert coordinates to radians
lats = deg2rad(coordinates(:,1));
lons = deg2rad(coordinates(:,2));

% Take the difference between consecutive points
delta_lats = diff(lats);
delta_lons = diff(lons);

% Intialize the output argument to an array of NaNs
distance = nan(length(delta_lats), 1);

for x = 1:length(distance)
   
    % Current latitude coordinates
    lat1 = lats(x);
    lat2 = lats(x+1);
   
    % Calculate the great circle distance in radians
    drad = 2 *...
        asin(sqrt(sin((delta_lats(x)/2))^2 +...
        cos(lat1)*cos(lat2)*(sin(delta_lons(x)/2))^2));
   
    % Convert to nautical miles...
    nm = rad2nm(drad);
   
    % And then to kilometers
    distance(x) = nm2km(nm)*1000;
   
end

% Prepend a 0 to the calculated distance array since no distance was
% traveled at the first gps fix
distance = [0; distance];

       
