function [XI,YI,ZI,DATAI] = toGrid3d(obj, sensor_name, varargin)
%
% [XI,YI,ZI,DATAI] = DbdGroup.toGrid3d(sensor_name, varargin)
%
% Returns DATAI, a matrix containing the gridded values of the sensor_name,
% along with XI, YI and ZI matrices, which contain the grid points 
% corresponding to the longitude, latitude and depth values of DATAI, 
% respectively.  The values in ZI are the depth values, taken from 
% DbdGroup.depthSensor, in 1 meter bins.
%
% Name/Value options:
%   'xsensor': a string containing an alternate sensor to use for the X
%       array.  The default sensor is drv_longitude, which is automatically 
%       added to the instance when DbdGroup.fillGps is set to a valid 
%       interp1.m interpolation method AND DbdGroup.hasBoundingGps is true.  
%       The sensor must exist in the DbdGroup instance.
%   'ysensor': a string containing an alternate sensor to use for the X
%       array.  The default sensor is drv_latitude, which is automatically 
%       added to the instance when DbdGroup.fillGps is set to a valid 
%       interp1.m interpolation method AND DbdGroup.hasBoundingGps is true.  
%       The sensor must exist in the DbdGroup instance.
%   'zsensor': a string containing an alternate sensor to use for the Z
%       array.  The default sensor is DbdGroup.depthSensor.  The sensor must
%       exist in the DbdGroup instance.
%   'depthbin': an alternate interval for the binned depth values.  Default
%       is 1 meter intervals.
%   't0': single matlab datenum value specifying the minumum profile time
%       to be included.
%   't1': single matlab datenum value specifying the maximum profile time
%       to be included.
%
% See also DbdGroup DbdGroup.toGrid2d
%
% ============================================================================
% $RCSfile: toGrid3d.m,v $
% $Source: /home/kerfoot/cvsroot/slocum/matlab/spt/classes/@DbdGroup/toGrid3d.m,v $
% $Revision: 1.1.1.1 $
% $Date: 2013/09/13 18:51:19 $
% $Author: kerfoot $
% ============================================================================
% 

app = mfilename;

XI = [];
YI = [];
ZI = [];
DATAI = [];

% Validate inputs
if ~isa(obj, 'DbdGroup')
    error(sprintf('%s:invalidClass', app),...
        'Method can only be attached to the DbdGroup class');
elseif nargin < 2
    error(sprintf('%s:nargin', app),...
        'No sensor specified.');
elseif ~ischar(sensor_name) || isempty(sensor_name)
    error(sprintf('%s:invalidArgument', app),...
        'The sensor argument must be a non-empty string.');
elseif ~ismember(sensor_name, obj.sensors)
     warning(sprintf('%s:invalidArgument', app),...
        'Sensor is not contained in the Dbd instance: %s',...
        sensor_name);
    return;
elseif ~isequal(0, mod(length(varargin),2))
    error(sprintf('%s:nargin', app),...
        'Invalid number of name,value options specified.');
end

% Default options
X_SENSOR = 'drv_longitude';
Y_SENSOR = 'drv_latitude';
Z_SENSOR = 'depth';
DEPTH_BIN = 1.0;
T0 = obj.startDatenums(1);
T1 = obj.endDatenums(end);

for x = 1:2:length(varargin)
    name = varargin{x};
    value = varargin{x+1};
    
    switch lower(name)
        case 'xsensor'
            if isempty(value) || ~ischar(value)
                error(sprintf('%s:invalidDataType', app),...
                    'Value for option %s must be a string.',...
                    name);
            elseif ~ismember(value, obj.sensors)
                error(sprintf('%s:invalidSensor', app),...
                    'The specified sensor is not in the Dbd instance.');
            end
            X_SENSOR = value;
        case 'ysensor'
            if isempty(value) || ~ischar(value)
                error(sprintf('%s:invalidDataType', app),...
                    'Value for option %s must be a string.',...
                    name);
            elseif ~ismember(value, obj.sensors)
                error(sprintf('%s:invalidSensor', app),...
                    'The specified sensor is not in the Dbd instance.');
            end
            Y_SENSOR = value;
        case 'zsensor'
            if isempty(value) || ~ischar(value)
                error(sprintf('%s:invalidDataType', app),...
                    'Value for option %s must be a string.',...
                    name);
            elseif ~ismember(value, obj.sensors)
                error(sprintf('%s:invalidSensor', app),...
                    'The specified sensor is not in the Dbd instance.');
            end
            Z_SENSOR = value;
        case 'depthbin'
            if isempty(value) ||...
                    ~isequal(numel(value),1) ||...
                    ~isnumeric(value)
                error(sprintf('%s:invalidDataType', app),...
                    'Value for option %s must be a number indicating the size of the depth bin.',...
                    name);
            elseif value <= 0
                error(sprintf('%s:invalidDataType', app),...
                    'Value for option %s must be greater than 0.',...
                    name);
            end
            DEPTH_BIN = value;
        case 't0'
           if ~isequal(numel(value),1) || ~isnumeric(value)
                error(sprintf('%s:invalidDataType', app),...
                    'Value for option %s must be a numeric datenum scalar.',...
                    name);
            end
            T0 = value;
        case 't1'
            if ~isequal(numel(value),1) || ~isnumeric(value)
                error(sprintf('%s:invalidDataType', app),...
                    'Value for option %s must be a numeric datenum scalar.',...
                    name);
            end
            T1 = value;
        otherwise
            error(sprintf('%s:invalidOption', app),...
                'Invalid option specified: %s.',...
                name);
    end
end

% Create a copy of the DbdGroup.sensors and add 'depth' and 'timestamp' as
% valid sensors since they will be included in the profiles data strucutre
valid_sensors = obj.sensors;
valid_sensors{end+1} = 'depth';
valid_sensors{end+1} = 'timestamp';

% Make sure the X_SENSOR, Y_SENSOR and Z_SENSOR exist in the DbdGroup instance
if ~ismember(X_SENSOR, valid_sensors)
    warning(sprintf('%s:invalidSensor', app),...
        'X-axis sensor %s is not contained in the DbdGroup instance',...
        X_SENSOR);
    return;
elseif ~ismember(Y_SENSOR, valid_sensors)
    warning(sprintf('%s:invalidSensor', app),...
        'Y-axis sensor %s is not contained in the DbdGroup instance',...
        Y_SENSOR);
    return;
elseif ~ismember(Z_SENSOR, valid_sensors)
    warning(sprintf('%s:invalidSensor', app),...
        'Z-axis sensor %s is not contained in the DbdGroup instance',...
        Z_SENSOR);
    return;
end

% Create the profiles data structure
p = obj.toProfiles('sensors', {X_SENSOR, Y_SENSOR, Z_SENSOR, sensor_name},...
    't0', T0,...
    't1', T1);

% Initialize return args
ZI = repmat((0:DEPTH_BIN:ceil(max(cat(1, p.depth))))', 1, length(p));
XI = nan(size(ZI));
YI = XI;
DATAI = XI;

% Loop through each profile
for p_ind = 1:length(p)

    % Fill in the X value
    X_VAL = mean(p(p_ind).(X_SENSOR)(~isnan(p(p_ind).(X_SENSOR))));
    if isnan(X_VAL)
        keyboard;
    end
    XI(:,p_ind) = X_VAL;
    % Fill in the Y value
    Y_VAL = mean(p(p_ind).(Y_SENSOR)(~isnan(p(p_ind).(Y_SENSOR))));
    if isnan(Y_VAL)
        keyboard;
    end
    YI(:,p_ind) = Y_VAL;
    
    % Create the depth-sensor array
    sensor_data = [p(p_ind).(Z_SENSOR) p(p_ind).(sensor_name)];
    % Eliminate any NaN rows
    sensor_data(any(isnan(sensor_data),2),:) = [];
    if size(sensor_data,1) < 2
        continue;
    end
    % Eliminate rows with duplicate timestamps
    sensor_data = sortrows(sensor_data,1);
    dups = find(diff(sensor_data(:,1)) == 0);
    sensor_data(dups+1,:) = [];
    if size(sensor_data,1) < 2
        continue;
    end
    DATAI(:,p_ind) = interp1(sensor_data(:,1),...
        sensor_data(:,2),...
        ZI(:,1));
end
