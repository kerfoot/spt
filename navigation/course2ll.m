function waypoints = course2ll(course)
%
% Usage: waypoints = course2ll([latitudes longitudes heading distance])
%
% Returns a waypoint [distance] kilometers from the start point (defined by
% [latitudes] and [longitudes]) assuming travel at [heading] degrees along the
% great circle.
%
% The input argument is a 4-column array containing latitudes (decimal
% degrees), longitudes (decimal degrees), compass heading (degrees) and
% distances (kilometers).
%
% The return array (waypoints) contains latitudes (column 1) and longitudes
% (column 2) in decimal degrees.
%
% Reference: http://williams.best.vwh.net/avform.htm
%
% See also ll2course
% ============================================================================
% $RCSfile: course2ll.m,v $
% $Source: /home/kerfoot/cvsroot/slocum/matlab/spt/navigation/course2ll.m,v $
% $Revision: 1.1.1.1 $
% $Date: 2013/09/13 18:51:19 $
% $Author: kerfoot $
% ============================================================================
%

% Return value
waypoints = [];

% Validate inputs
[r,c] = size(course);
if r < 1 || ~isequal(c,4)
    disp([mfilename...
        ' - Input array must be a 4-colum array with at least 1 row.']);
    return;
end

% Convert coordinates to radians
lats = deg2rad(course(:,1));
lons = deg2rad(course(:,2));
% Convert headings to radians
tc   = deg2rad(course(:,3));
% Convert distances to nautical miles and then to radians
d    = nm2rad(km2nm(course(:,4)));

% Initialize the return values
waypoints = repmat(NaN, length(lats), 2);

for x = 1:length(lats)
   
    % Current position and course (all in radians)
    lat1 = lats(x); % latitude
    lon1 = lons(x); % longitude
    tc1  = tc(x);   % course heading from position
    d1   = d(x);    % distance to next waypoint
   
    % Calculate latitude
    lat = asin(sin(lat1)*cos(d1) + cos(lat1)*sin(d1)*cos(tc1));
   
    % Calculate longitude
    dlon = atan2(sin(tc1)*sin(d1)*cos(lat1), cos(d1)-sin(lat1)*sin(lat1));
    lon = mod(lon1 + dlon + pi, 2*pi) - pi;
   
    % Convert waypoints to degrees and add to the return array
    waypoints(x,:) = [rad2deg(lat) rad2deg(lon)];
   
end
