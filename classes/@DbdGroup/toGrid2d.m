function [X,Y,DATAI] = toGrid2d(obj, sensor_name, varargin)
%
% [X,Y,DATAI] = toGrid2d(sensor_name, varargin)
%
% Returns DATAI, a matrix containing the gridded values of the sensor_name,
% along with X and Y vectors, which contain the grid points corresponding
% to the values of DATAI.  Be default, X contains the mean timestamps of
% each profile in the DbdGroup instance.  Y always contains the depths
% of the gridded sensor values and, by default, are the depth values in 1
% meter intervals.
%
% Name/Value options:
%   'xsensor': a string containing an alternate sensor to use for the X
%       array.  The default sensor is DbdGroup.timestampSensor.  The sensor
%       must exist in the DbdGroup instance.
%   'depthbin': an alternate interval for the binned depth values.  Default
%       is 1 meter intervals.
%   't0': single matlab datenum value specifying the minumum profile time
%       to be included.
%   't1': single matlab datenum value specifying the maximum profile time
%       to be included.
%
% See also DbdGroup DbdGroup.toGrid3d
%
% ============================================================================
% $RCSfile: toGrid2d.m,v $
% $Source: /home/kerfoot/cvsroot/slocum/matlab/spt/classes/@DbdGroup/toGrid2d.m,v $
% $Revision: 1.1.1.1 $
% $Date: 2013/09/13 18:51:19 $
% $Author: kerfoot $
% ============================================================================
% 

app = mfilename;

X = [];
Y = [];
DATAI = [];

% Validate inputs
if ~isa(obj, 'DbdGroup')
    error(sprintf('%s:invalidClass', app),...
        'Method can only be attached to the Dbd class');
elseif nargin < 2
     error(sprintf('%s:nargin', app),...
        'No sensor specified.');
elseif isempty(obj.dbds)
    warning('DbdGroup:emptyDbdGroup',...
        'The DbdGroup instance is empty');
    return;
elseif ~ischar(sensor_name) || isempty(sensor_name)
    warning(sprintf('%s:invalidArgument', app),...
        'The sensor argument must be a non-empty string.');
    return;
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
X_SENSOR = 'timestamp';
DEPTH_BIN = 1.0;
T0 = obj.startDatenums(1);
T1 = obj.endDatenums(end);
for x = 1:2:length(varargin)
    name = varargin{x};
    value = varargin{x+1};
    
    switch lower(name)
        case 'xsensor'
            if ~ischar(value)
                error(sprintf('%s:invalidDataType', app),...
                    'Value for option %s must be a string.',...
                    name);
            elseif ~ismember(value, obj.sensors)
                error(sprintf('%s:invalidSensor', app),...
                    'The specified sensor is not in the Dbd instance.');
            end
            X_SENSOR = value;
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

% Create the profiles data structure
p = obj.toProfiles('sensors', {X_SENSOR, sensor_name},...
    't0', T0,...
    't1', T1);
if isempty(p)
    return;
end

% Initialize return args
X = nan(1, length(p));
Y = (0:DEPTH_BIN:ceil(max(cat(1, p.depth))))';
DATAI = nan(length(Y), length(X));

% Loop through each profile
for p_ind = 1:length(p)

    % Fill in the X value
    X(p_ind) = mean(p(p_ind).(X_SENSOR)(~isnan(p(p_ind).(X_SENSOR))));

    % Create the depth-sensor array
    sensor_data = [p(p_ind).depth p(p_ind).(sensor_name)];
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
        Y);
end
