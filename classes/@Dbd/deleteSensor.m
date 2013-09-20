function deleteSensor(obj, varargin)
%
% Dbd.deleteSensor(REMOVE_SENSORS)
%
% Permanently delete sensors from the Dbd instance.  The following sensors are
% protected and cannot be deleted:
%
%   Dbd.timestampSensor
%   Dbd.depthSensor
%   drv_proInds
%   drv_proDir
%
% See also Dbd Dbd.addSensor
%
% ============================================================================
% $RCSfile: deleteSensor.m,v $
% $Source: /home/kerfoot/cvsroot/slocum/matlab/spt/classes/@Dbd/deleteSensor.m,v $
% $Revision: 1.2 $
% $Date: 2013/09/18 13:03:01 $
% $Author: kerfoot $
% ============================================================================
%

app = mfilename;

% Validate inputs
if ~isa(obj, 'Dbd')
    error(sprintf('%s:invalidClass', app),...
        'Method can only be attached to the Dbd class');
elseif nargin < 2
    error(sprintf('%s:nargin', app),...
        'No sensor name(s) or patterns specified.');
end

PATTERNS = {};

% If we have only a single input argument (exlcuding the class instance),
% assume it's a specific sensor name or list of names to remove.  If we
% have at least 2 arguments, process them as options
if isequal(nargin,2)

    REMOVE_SENSORS = varargin{1};
    
    % REMOVE_SENSORS must be a string or cell array of strings
    if ischar(REMOVE_SENSORS)
        % Convert to a cell array of strings if a string
        REMOVE_SENSORS = {REMOVE_SENSORS}';
    elseif ~iscellstr(REMOVE_SENSORS)
        error(sprintf('%s:invalidArgument', app),...
            'Please specify a string or cell array of strings.');
    end
    
    if isempty(REMOVE_SENSORS)
        warning(sprintf('%s:emptyArgument', app),...
            'No sensor names were specified.\n');
        return;
    end
    
elseif ~isequal(mod(length(varargin),2),0)
    error(sprintf('%s:varargin', app),...
        'Invalid number of options specified');
else
    for x = 1:2:length(varargin)
        name = varargin{x};
        value = varargin{x+1};
        
        switch lower(name)
            case 'regexp'
                if ischar(value)
                    PATTERNS = {value}';
                elseif ~iscellstr(value)
                    error(sprintf('%s:invalidOptionValue', app),...
                        'Value for option %s must be a string or cell array of strings containing patterns',...
                        name);
                end
                PATTERNS = value;
            otherwise
                error(sprintf('%s:invalidOptionValue', app),...
                    'Value for option %s must be a string or cell array of strings containing patterns',...
                    name);
        end
    end
end
        
% Store a copy of the Dbd instance sensors
SENSOR_LIST = obj.sensors;
% If regexp patterns were specified via the 'regexp' option, create the
% list of sensors to remove from the instance by matching each pattern
% against the sensors in SENSOR_LIST
if ~isempty(PATTERNS)
    REMOVE_SENSORS = {};
    for r = 1:length(PATTERNS)
        % Match the list of sensors agains the pattern
        matches = regexp(SENSOR_LIST, PATTERNS{r});
        REMOVE_SENSORS = [REMOVE_SENSORS;...
            SENSOR_LIST(~cellfun(@isempty, matches))];
    end
    
    if isempty(REMOVE_SENSORS)
        warning(sprintf('%s:noSensorMatches', app),...
            'No sensor patterns matched.\n');
    end
    
end

if isempty(REMOVE_SENSORS)
    warning(sprintf('%s:emptyArgument', app),...
            'No sensor names were specified.\n');
        return;
end

% Remove invalid sensors from REMOVE_SENSORS
REMOVE_SENSORS = intersect(unique(REMOVE_SENSORS), obj.sensors);
if isempty(REMOVE_SENSORS)
    warning(sprintf('%s:invalidSensor', app),...
        'The specified sensor(s) does not exist in the instance\n');
    return;
end

% Do not allow the removal of:
%   Dbd.dbdTimestampSensors
%   Dbd.dbdDepthSensors
%   drv_proInds
%   drv_proDir
PROTECTED_SENSORS = [obj.dbdDepthSensors;...
    obj.dbdDepthSensors;...
    'drv_proInds';...
    'drv_proDir'];
[p_sensors,I] = intersect(REMOVE_SENSORS, PROTECTED_SENSORS);
if ~isempty(p_sensors)
    for x = 1:length(p_sensors)
        warning(sprintf('%s:protectedSensor', app),...
            'Cannot delete protected sensor: %s',...
            p_sensors{x});
    end
    REMOVE_SENSORS(I) = [];
end
if isempty(REMOVE_SENSORS)
    return;
end

% Delete the data array from obj.dbdData
obj.dbdData = rmfield(obj.dbdData, REMOVE_SENSORS);

% Remove the sensor units from obj.sensorUnits
obj.sensorUnits = rmfield(obj.sensorUnits, REMOVE_SENSORS);

% If sensorName is a valid timestamp or depth sensor, it needs to be removed
% from obj.dbdTimestampSensors or obj.dbdDepthSensors
[~,~,BI] = intersect(REMOVE_SENSORS, obj.dbdTimestampSensors);
if ~isempty(BI)
    obj.dbdTimestampSensors(BI) = [];
end

[~,~,BI] = intersect(REMOVE_SENSORS, obj.dbdDepthSensors);
if ~isempty(BI)
    obj.dbdDepthSensors(BI) = [];
end