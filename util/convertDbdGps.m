function convertDbdGps(dbd, varargin)
%
% convertDbdGps(dbd, varargin)
%
% Convert m_gps_lat and m_gps_lon from units of decimal minutes to decimal
% degrees and add the new sensors to the Dbd instance as drv_m_gps_lat and
% drv_m_gps_lon.  'drv_' is prepended to the original sensor names to denote 
% that they are derived.  
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
% See also Dbd
% ============================================================================
% $RCSfile: convertDbdGps.m,v $
% $Source: /home/kerfoot/cvsroot/slocum/matlab/spt/util/convertDbdGps.m,v $
% $Revision: 1.1.1.1 $
% $Date: 2013/09/13 18:51:19 $
% $Author: kerfoot $
% ============================================================================
%

app = mfilename;

% Validate input args
if isequal(nargin,0) || ~isa(dbd, 'Dbd')
    error(sprintf('%s:nargin', app),...
        'No Dbd instance specified.');
elseif ~isa(dbd, 'Dbd')
    error(sprintf('%s:invalidArgument', app),...
        'Dbd instance is invalid');
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
            if ~ischar(value) || ~ismember(value, dbd.sensors)
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

% Pull out the LAT_SENSOR (will be all nans if not present), convert to
% decimal degres and add as a new sensor: drv_LAT_SENSOR
lats = dbd.toArray('sensors', {LAT_SENSOR});
dbd.addSensor(['drv_' LAT_SENSOR], dm2dd(lats(:,end)), 'decimal degrees');
    
% Pull out the LON_SENSOR (will be all nans if not present), convert to
% decimal degres and add as a new sensor: drv_LON_SENSOR
lats = dbd.toArray('sensors', {LON_SENSOR});
dbd.addSensor(['drv_' LON_SENSOR], dm2dd(lats(:,end)), 'decimal degrees');