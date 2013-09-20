function [data, columns] = toArray(obj, varargin)
%
% [data, columns] = Dbd.toArray(varargin)
%
% Returns an MxN array consisting of all sensor data in the Dbd instance.
% The second return value, columns, is a cell array containing the sensor
% names in the data array column order.  The first 2 elements in the cell
% array are 'timestamp' and 'depth' and contain copies of the timestamp and
% depth/pressure values of Dbd.timestampSensor and Dbd.depthSensor,
% respectively.
%
% If Dbd.fillTimes and/or Dbd.fillDepths are set to a valid interp1.m
% interpolation method, the first and/or second columns, respectively,
% will contain the interpolated data array(s).
%
% Name/Value options:
%   'sensors': a cell array of strings containing the sensors to include.  Any 
%       sensor name not contained in the Dbd instance results in a NaN-filled 
%       column.
%
% See also Dbd
%
% ============================================================================
% $RCSfile: toArray.m,v $
% $Source: /home/kerfoot/cvsroot/slocum/matlab/spt/classes/@Dbd/toArray.m,v $
% $Revision: 1.1.1.1 $
% $Date: 2013/09/13 18:51:19 $
% $Author: kerfoot $
% ============================================================================
% 

app = mfilename;

data = [];
columns = {};

% Validate inputs
if ~isa(obj, 'Dbd')
    error(sprintf('%s:invalidClass', app),...
        'Method can only be attached to the Dbd class');
elseif ~isequal(mod(length(varargin),2),0)
    error(sprintf('%s:nargin', app),...
        'Invalid number of name,value options specified.');
end

% Process options
sensorSet = obj.sensors;
for x = 1:2:length(varargin)
    name = varargin{x};
    value = varargin{x+1};
    switch lower(name)
        case 'sensors'
            % sensorSet must be a string or cell array of strings
            if ~ischar(value) && ~iscellstr(value)
                error(sprintf('%s:invalidDataType', app),...
                    'Value for option %s must be a string or cell array of strings.',...
                    name);
            elseif ischar(value)
                value = {value};
            end
            sensorSet = value;
        otherwise
            error(sprintf('%s:invalidOption', app),...
                'Invalid option specified: %s.',...
                name);
    end
end

sensorSet = sensorSet(:);

% We're going to add a 'timestamp' and 'depth' field which correspond to
% obj.timestampSensor and obj.depthSensor, respectively.  So we need to
% make sure that these sensors are removed from the sensors specified by
% the user to prevent overwriting of these fields.
% Use a regexp to remove the elements instead of setdiff as setdiff sorts the
% return value so that the output sensors are not in the same order as the
% input sensors
sensorSet(~cellfun(@isempty, regexp(sensorSet, '^timestamp$|^depth$'))) = [];

% obj.timestampSensor and obj.depthSensor are always the first 2 columns in
% the returned array.
sensorSet = [{obj.timestampSensor; obj.depthSensor}; sensorSet];

% Initialize the return array
data = nan(length(obj.dbdData.(obj.timestampSensor)), length(sensorSet));

% Fill in the sensor data as long as the sensor exists.  If it is not a
% sensor in obj.sensors, keep the nan column
for s = 1:length(sensorSet)
    if ~ismember(sensorSet{s}, obj.sensors)
        continue;
    end
    data(:,s) = obj.dbdData.(sensorSet{s});
end

% Check obj.fillTimes and obj.fillDepths.  If true, fill in the missing values
% prior to dumping to the return array
if ~strcmp(obj.fillTimes, 'none') && any(isnan(data(:,1)))
    data(:,1) = fillMissingValues(data(:,1),...
        'fillmethod',...
        obj.fillTimes);
    % If obj.timestampSensor is in the sensorSet, replace the original data
    % array with the filled data array
    [~,LOC] = ismember(obj.timestampSensor, sensorSet);
    if LOC > 0
        data(:,LOC) = data(:,1);
    end
end

if ~strcmp(obj.fillDepths, 'none') && any(isnan(data(:,2)))
    data(:,2) = interpTimeSeries(data(:,1:2),...
        'fillmethod',...
        obj.fillDepths);
    % If obj.depthpSensor is in the sensorSet, replace the original data
    % array with the filled data array
    [~,LOC] = ismember(obj.depthSensor, sensorSet);
    if LOC > 0
        data(:,LOC) = data(:,2);
    end
end

columns = sensorSet;
columns{1} = 'timestamp';
columns{2} = 'depth';
