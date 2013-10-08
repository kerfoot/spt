function addTrackDistance(obj, varargin)
%
% addTrackDistance(obj, varargin)
%
% Convert m_gps_lat and m_gps_lon from units of decimal minutes to decimal
% degrees, calculate the distance along track and add the new sensor to the 
% Dbd instance as drv_distance_along_track.  'drv_' is prepended to the 
% original sensor names to denote that they are derived.  
%
% If the lat and lon (m_gps_lat and m_gps_lon, respectively) are not
% contained in the Dbd instance, the derived sensors are still added and
% will contain an array of nans.
%
% Options:
%   'latsensor': name of the latitude sensor to convert instead of the default
%       (m_gps_lat).  The sensor must exist in the Dbd instance
%   'lonsensor': name of the longitude sensor to convert instead of the
%       default (m_gps_lon).  The sensor must exist in the Dbd instance
%
% The Dbd class inherits from the Matlab handle class.  It is passed by 
% reference and not copied.  So there is no need to assign the altered Dbd
% instance to a return value, which is why one is not provided.
%
% See also Dbd DbdGroup
% ============================================================================
% $RCSfile: addTrackDistance.m,v $
% $Source: /home/kerfoot/cvsroot/slocum/matlab/spt/util/addTrackDistance.m,v $
% $Revision: 1.3 $
% $Date: 2013/10/08 20:32:01 $
% $Author: kerfoot $
% ============================================================================
%

app = mfilename;

% Validate input args
if isequal(nargin,0)
    error(sprintf('%s:nargin', app),...
        'No Dbd or DbdGroup instance specified.');
elseif ~isa(obj, 'Dbd') && ~isa(obj, 'DbdGroup')
    error(sprintf('%s:invalidArgument', app),...
        'First argument must be a valid Dbd or DbdGroup.');
elseif ~isequal(mod(length(varargin),2),0)
    error(sprintf('%s:varargin', app),...
        'Invalid number of name,value options specified.');
end

% Default sensors to use for the calculation
LAT_SENSOR = 'm_gps_lat';
LON_SENSOR = 'm_gps_lon';

% Process options
for x = 1:2:length(varargin)
    
    name = varargin{x};
    value = varargin{x+1};
    
    switch name
        case 'latsensor'
            if ~ischar(value)
                error(sprintf('%s:invalidOptionValue', app),...
                    'The value for option %s must be a string specifying an existing latitude sensor',...
                    name);
            end
            LAT_SENSOR = value;
        case 'lonsensor'
            if ~ischar(value) || ~ismember(value, obj.sensors)
                error(sprintf('%s:invalidOptionValue', app),...
                    'The value for option %s must be a string specifying an existing longitude sensor',...
                    name);
            end
            LON_SENSOR = value;
        otherwise
            error(sprintf('%s:invalidOptionValue', app),...
                'Invalid option specified: %s',...
                name);
    end
end

% Initiliaze the track distance array
if isa(obj, 'Dbd')
    track_distance = nan(obj.rows,1);
elseif isa(obj, 'DbdGroup')
    track_distance = nan(sum(obj.rows),1);
end

% Add the initialized array as a new sensor
obj.addSensor('drv_distance_along_track',...
    track_distance,...
    'kilometers');

% Make sure the latitude sensor is not empty
if isempty(LAT_SENSOR)
    warning(sprintf('%s:emptyValue', app),...
        'No latitude sensor specified');
    return;
end

% Make sure the longitude sensor is not empty
if isempty(LON_SENSOR)
    warning(sprintf('%s:emptyValue', app),...
        'No longitude sensor specified');
    return;
end

% Figure out which timestamp to use for interpolation.  We'd prefer
% m_present_time, but will use the default Dbd.timestampSensor if we don't
% have access to it.
if ismember('m_present_time', obj.sensors)
    gps_sensors = {'m_present_time',...
        LAT_SENSOR,...
        LON_SENSOR,...
        }';
    % Pull out the gps array
    gps = obj.toArray('sensors', gps_sensors);
    gps(:,[1 2]) = [];
else
    gps_sensors = {LAT_SENSOR,...
        LON_SENSOR,...
        }';
    % Pull out the gps array
    gps = obj.toArray('sensors', gps_sensors);
    gps(:,2) = [];
end

% Check the units and convert if necessary
if isempty(regexp(obj.sensorUnits.(LAT_SENSOR),...
        '^degrees$|^decimal degrees$',...
        'once'))
    gps(:,2) = dm2dd(gps(:,2));
end
if isempty(regexp(obj.sensorUnits.(LON_SENSOR),...
        '^degrees$|^decimal degrees$',...
        'once'))
    gps(:,3) = dm2dd(gps(:,3));
end

% Fill in missing timestamps before interpolating the gps
gps(:,1) = fillMissingValues(gps(:,1));

% Interpolate the GPS fixes
gps(:,2) = interpTimeSeries(gps(:,[1 2]));
gps(:,3) = interpTimeSeries(gps(:,[1 3]));

% Find all valid (non-NaN) gps fixes
r = find(all(~isnan(gps(:,[2 3])),2));
if isempty(r)
    warning(sprintf('%s:noValidRows', app),...
        'GPS array contains no valid fixes.\n');
    return;
end

% Calculate track distance for all valid gps fixes
d = gcdist(gps(r,[2 3]));
% Cumulatively sum the distance
track_distance(r) = cumsum(d);

% Add the track distance as a new sensor
obj.addSensor('drv_distance_along_track',...
    round(track_distance)/1000,...
    'kilometers');

