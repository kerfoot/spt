function deleteSensor(obj, varargin)
%
% Dbd.deleteSensor(sensor_names)
%
% Permanently delete the sensor data for all sensors contained in sensor_names
% and the Dbd.sensorUnits values from all Dbd instances in the DbdGroup 
% instance. 
%
% The following sensors are protected and, thus, cannot be deleted:
%   Dbd.timestampSensor
%   Dbd.depthSensor
%   drv_proInds
%   drv_proDir
%
% See also DbdGroup DbdGroup.addSensor
% ============================================================================
% $RCSfile: deleteSensor.m,v $
% $Source: /home/kerfoot/cvsroot/slocum/matlab/spt/classes/@DbdGroup/deleteSensor.m,v $
% $Revision: 1.2 $
% $Date: 2013/09/18 13:03:08 $
% $Author: kerfoot $
% ============================================================================
%

app = mfilename;

% Validate inputs
if ~isa(obj, 'DbdGroup')
    error(sprintf('%s:invalidClass', app),...
        'Method can only be attached to the DbdGroup class');
elseif nargin < 2
    error(sprintf('%s:nargin', app),...
        'No sensor name(s) or patterns specified.');
end

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

% Remove all sensors in sensor_names from each Dbd instance
for d = 1:length(obj.dbds)
    obj.dbds(d).deleteSensor(REMOVE_SENSORS);
end

% Remove valid fields from DbdGroup.sensorUnits
units_fields = intersect(fieldnames(obj.sensorUnits), REMOVE_SENSORS);
obj.sensorUnits = rmfield(obj.sensorUnits, units_fields);
