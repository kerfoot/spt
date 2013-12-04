function processGps(obj, varargin)
%
% processGps(obj, varargin)
%
% Convert m_gps_lat and m_gps_lon from units of decimal minutes to decimal
% degrees, add the new sensors to the Dbd instance.  'drv_' is prepended to
% the original sensor names to denote that they are derived.  Bad
% coordinates (ie: 69696969) are removed from the derived sensors arrays.
% Two additional sensors are also added (drv_latitude and drv_longitude)
% which contain either the drv_m_gps_lat and drv_m_gps_lon data arrays or
% are interpolated if the 'interp', METHOD option is specified.
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
%   'interp': [STRING] interp1.m method to interpolate the derived gps
%       positions.  Default behavior is no interpolation.
%
% The Dbd class inherits from the Matlab handle class.  It is passed by 
% reference and not copied.  So there is no need to assign the altered Dbd
% instance to a return value, which is why one is not provided.
%
% See also Dbd DbdGroup
% ============================================================================
% $RCSfile: processGps.m,v $
% $Source: /home/kerfoot/cvsroot/slocum/matlab/spt/util/processGps.m,v $
% $Revision: 1.1 $
% $Date: 2013/12/04 17:06:41 $
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
        'First argument must be a valid Dbd or DbdGroup instance.');
elseif ~isequal(mod(length(varargin),2),0)
    error(sprintf('%s:varargin', app),...
        'Invalid number of name,value options specified.');
end

% Default sensors to use for the calculation
LAT_SENSOR = 'm_gps_lat';
LON_SENSOR = 'm_gps_lon';
VALID_INTERP_METHODS = {'none',...
    'nearest',...
    'linear',...
    'spline',...
    'pchip',...
    'cubic',...
    'v5cubic',...
    }';
INTERP_METHOD = 'none';
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
        case 'interp'
            if isempty(value) || ~ischar(value)
                error(sprintf('%s:invalidOptionValue', app),...
                    'The value for option %s must be a string specifying a valid interp1.m interpolation method',...
                    name);
            elseif ~ismember(lower(value), VALID_INTERP_METHODS)
                error(sprintf('%s:invalidOptionValue', app),...
                    'Option %s: %s is not a valid interp1.m interpolation method',...
                    name,...
                    value);
            end
            INTERP_METHOD = lower(value);
        otherwise
            error(sprintf('%s:invalidOptionValue', app),...
                'Invalid option specified: %s',...
                name);
    end
end

% Make sure the latitude sensor is not empty
if isempty(LAT_SENSOR)
    error(sprintf('%s:emptyValue', app),...
        'No latitude sensor specified');
end

% Make sure the longitude sensor is not empty
if isempty(LON_SENSOR)
    error(sprintf('%s:emptyValue', app),...
        'No longitude sensor specified');
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

% Remove masterdata default lat/lon values (69696969)
gps(any(gps(:,[2 3]) > 696969,2),[2 3]) = NaN;
obj.addSensor(['drv_' LAT_SENSOR], gps(:,2), 'degrees');
obj.addSensor(['drv_' LON_SENSOR], gps(:,3), 'degrees');

if ~strcmp(INTERP_METHOD, 'none')
    
    % Interpolate the latitudes
    ilats = interpTimeSeries(gps(:,[1 2]), 'method', INTERP_METHOD);
    % Add the interpolated latitudes
    obj.addSensor('drv_latitude', ilats, 'degrees');
    
    % Interpolate the longitudes
    ilons = interpTimeSeries(gps(:,[1 3]), 'method', INTERP_METHOD);
    % Add the interpolated longitudes
    obj.addSensor('drv_longitude', ilons, 'degrees');
   
else
    % Add the derived values as a new latitude sensor
    obj.addSensor('drv_latitude', gps(:,2), 'degrees');
    % Add the derived values as a new longitude sensor
    obj.addSensor('drv_longitude', gps(:,3), 'degrees');
end
