function addSensor(obj, sensor_data, sensor_name, sensor_units)
%
% DbdGroup.addSensor(sensor_data, sensor_name[, sensor_units])
%
% Add the sensor data array to the DbdGroup instance under the specified 
% sensor name.  If a third argument (sensor_units) is specified, these units 
% are assigned to the DbdGroup.sensorUnits data structure.  If this argument 
% is omitted, a default unit of 'nodim' is used.  The sensor data array is
% sliced and the appropriate number of values are added to each of the Dbd
% instances contained in DbdGroup.dbds.
% 
% Arguments:
%   sensor_data: a Rx1 array with length equal to sum(DbdGroup.rows)
%   sensor_name: string specifying the sensor name
%   sensor_units (optional): string specifying the sensor units.  Defaults
%       to 'nodim'.
%
% See also DbdGroup DbdGroup.deleteSensor
% ============================================================================
% $RCSfile: addSensor.m,v $
% $Source: /home/kerfoot/cvsroot/slocum/matlab/spt/classes/@DbdGroup/addSensor.m,v $
% $Revision: 1.1.1.1 $
% $Date: 2013/09/13 18:51:19 $
% $Author: kerfoot $
% ============================================================================
%

% Validate inputs
% Validate inputs
if ~isa(obj, 'DbdGroup')
    error('DbdGroup:addSensor',...
        'Method can only be attached to the Dbd class');
elseif nargin < 3 || nargin > 4
    error('DbdGroup:addSensor:nargin',...
        '2 or 3 arguments are required.');
elseif isequal(nargin,3)
    sensor_units = 'nodim'; % Default sensor units if none specified
end

% sensor_name and sensor_units must be non-empty strings
if isempty(sensor_name) || ~ischar(sensor_name)
    error('Dbd:addSensor:invalidArgument',...
        'The sensor name must be specified as a non-empty string.');
elseif isempty(sensor_units) || ~ischar(sensor_units)
    error('Dbd:addSensor:invalidArgument',...
        'The sensor units must be specified as a non-empty string.');
end

% If sensor_data is empty, all we need to do is update the sensor_units
if isempty(sensor_data)
    if ~isfield(obj.dbdData, sensor_name)
        error('Dbd:addSensor:invalidSensor',...
            '%s is not a sensor in the Dbd instance.',...
            sensor_name);
    else
        obj.sensorUnits.(sensor_name) = sensor_units;
        return;
    end
end

% Total number of rows in all DbdGroup.dbds instances
numRows = sum(obj.rows);

% Validate the length of the data array
sensor_data = sensor_data(:);
if ~isequal(length(sensor_data), numRows)
    error('Dbd:addSensor:dimensionError',...
        'Incorrect data array length.');
end

r0 = 1;
r1 = 0;
for x = 1:length(obj.dbds)
    
    r1 = r1 + obj.dbds(x).rows;
    
    obj.dbds(x).addSensor(sensor_data(r0:r1), sensor_name, sensor_units);
    
    r0 = r1 + 1;
    
end

% Add the units to the DbdGroup.sensorUnits structured array
obj.sensorUnits.(sensor_name) = sensor_units;

% Alphabetically order the DbdGroup.sensorUnits fields
obj.sensorUnits = orderfields(obj.sensorUnits);
