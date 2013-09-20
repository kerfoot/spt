function addSensor(obj, sensor_name, sensor_data, sensor_units)
%
% Dbd.addSensor(sensor_name, sensor_data[, sensor_units])
%
% Add the sensor data array to the Dbd instance under the specified sensor 
% name.  If a third argument (sensor_units) is specified, these units are
% assigned to the Dbd.sensorUnits data structure.  If this argument is
% omitted, a default unit of 'nodim' is used.
%
% Arguments:
%   sensor_data: a Rx1 data array equal to Dbd.rows
%   sensor_name: string specifying the sensor name
%   sensor_units (optional): string specifying the sensor units.  Defaults
%       to 'nodim'.
%
% See also Dbd Dbd.deleteSensor
%
% ============================================================================
% $RCSfile: addSensor.m,v $
% $Source: /home/kerfoot/cvsroot/slocum/matlab/spt/classes/@Dbd/addSensor.m,v $
% $Revision: 1.1.1.1 $
% $Date: 2013/09/13 18:51:19 $
% $Author: kerfoot $
% ============================================================================
%

app = mfilename;

% Validate inputs
if ~isa(obj, 'Dbd')
    error(sprintf('%s:invalidClass', app),...
        'Method can only be attached to the Dbd class');
elseif nargin < 3 || nargin > 4
    error(sprintf('%s:nargin', app),...
        '2 or 3 arguments are required.');
elseif isequal(nargin,3)
    sensor_units = 'nodim'; % Default sensor units if none specified
end

% sensor_name and sensor_units must be non-empty strings
if isempty(sensor_name) || ~ischar(sensor_name)
    error(sprintf('%s:invalidArgument', app),...
        'Sensor name must be a non-empty string.');
elseif isempty(sensor_units) || ~ischar(sensor_units)
    error(sprintf('%s:invalidArgument', app),...
        'Sensor units must be a non-empty string.');
end

% If sensor_data is empty, all we need to do is update the sensor_units
if isempty(sensor_data)
    if ~isfield(obj.dbdData, sensor_name)
        warning(sprintf('%s:invalidSensor', app),...
            '%s is not a sensor in the Dbd instance.',...
            sensor_name);
        return;
    else
        % Update the sensor units
        obj.sensorUnits.(sensor_name) = sensor_units;
        return;
    end
end

% Validate the length of the data array
sensor_data = sensor_data(:);
if ~isequal(length(sensor_data), obj.rows)
    error(sprintf('%s:dimensionError', app),...
        'Incorrect data array dimensions.');
end

% Add the sensorData to obj.dbdData if not empty
obj.dbdData.(sensor_name) = sensor_data;

% Add the sensor units to obj.meta.sensorUnits
obj.sensorUnits.(sensor_name) = sensor_units;

% Order the fields of obj.sensorUnits
obj.sensorUnits = orderfields(obj.sensorUnits);

