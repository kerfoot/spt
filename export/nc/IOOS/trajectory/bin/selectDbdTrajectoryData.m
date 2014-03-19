function [data, NC_TEMPLATE] = selectDbdTrajectoryData(dbd, varargin)
%
% data = selectDbdTrajectoryData(dbd, varargin)
%
% Select the sensor data arrays from the Dbd instance (dbd) and map them to
% the IOOS Trajectory NetCDF template variables.  The default NetCDF
% template is taken from the GTrajectory.schemaNcTemplate property.  The
% standard NetCDF template can be found here:
%
% https://github.com/IOOSProfilingGliders/Real-Time-File-Format/tree/master/template
%
% NetCDF variable data is mapped to native Slocum glider sensors in
% getTrajectorySensorMappings.m, which is called by 
% selectDbdTrajectoryData.m.  Currently, you must add sensors to
% getTrajectorySensorMappings.m directly to change the default sensor
% mappings.
%
% Options must be specified as name, value pairs:
%
%   'template', [STRING]
%       Alternate NetCDF template file to use for selected NetCDF variables
%
% See also getTrajectorySensorMappings GTrajectoryNc 
% ============================================================================
% $RCSfile: selectDbdTrajectoryData.m,v $
% $Source: /home/kerfoot/cvsroot/slocum/matlab/spt/export/nc/IOOS/trajectory/bin/selectDbdTrajectoryData.m,v $
% $Revision: 1.2 $
% $Date: 2014/03/19 20:09:02 $
% $Author: kerfoot $
% ============================================================================
%

app = mfilename;

data = [];

% Validate args
if nargin < 1
    error(sprintf('%s:nargin', app),...
        'No Dbd instance specified');
elseif ~isa(dbd, 'Dbd')
    error(sprintf('%s:invalidArgument', app),...
        'Invalid Dbd instance specified');
elseif ~isequal(mod(length(varargin),2),0)
    error(sprintf('%s:varargin', app),...
        'Invalid number of options specified');
end

% Process options
NC_TEMPLATE = GTrajectoryNc().schemaNcTemplate;
for x = 1:2:length(varargin)
    name = varargin{x};
    value = varargin{x+1};
    
    switch lower(name)
        case 'template'
            if ~ischar(value) || isempty(value)
                error(sprintf('%s:invalidOption', app),...
                    'The value for option %s must be a string specifying a template name',...
                    name);
            end
            NC_TEMPLATE = value;
        otherwise
            error(sprintf('%s:invalidOption', app),...
                'Invalid option specified: %s',...
                name);
    end
end
    
if ~exist(NC_TEMPLATE, 'file')
    warning(sprintf('%s:invalidNetCDFTemplate', app),...
        'Cannot locate NetCDF template: %s\n',...
        NC_TEMPLATE);
    return;
end

s_map = getTrajectorySensorMappings(NC_TEMPLATE);
if isempty(s_map)
    return;
end

% Add 'time' and 'pressure' fields to mapped to dbd.timestampSensor and
% dbd.depthSensor
s_map.time = {dbd.timestampSensor}';
s_map.pressure = {dbd.depthSensor}';

% Fieldnames (variables) from the sensor map
vars = fieldnames(s_map);
% Select the available sensors in the Dbd instance
dbd_vars = dbd.sensors;
% Create a structured array of sensor data from the Dbd instance
d = Dbd2struct(dbd);

for v = 1:length(vars)
    
    % Intialize the entry
    data(end+1).ncVarName = vars{v};
    data(end).sensor = '';
    data(end).data = [];
    
    if isempty(s_map.(vars{v}))
% % % % %         warning(sprintf('%s:unknownSensorMapping', app),...
% % % % %             'Sensor map field contains no sensor mappings: %s\n',...
% % % % %             vars{v});
        continue;
    end
    
    % Search for the specified sensor in the available sensor mapping for
    % this sensor
    [C,AI,BI] = intersect(s_map.(vars{v}), dbd_vars);
    if isempty(C)
% % % % %         warning(sprintf('%s:sensorsNotFound', app),...
% % % % %             '%s: No sensors found in the Dbd instance\n',...
% % % % %             vars{v});
       continue;
    end
    
    % Take the first sensor found in the Dbd instance that satisfies the
    % mapping
    [Y,I] = min(AI);
    data(end).sensor = dbd_vars{BI(I)};
    data(end).data = d.(dbd_vars{BI(I)});
    
end

% d = Dbd2struct(dbd)
% Creates a structured array mapping all of the sensors in the Dbd instance
% to their data arrays
function d = Dbd2struct(dbd)

d = [];

[data, sensors] = dbd.toArray();

for s = 3:length(sensors)
    d.(sensors{s}) = data(:,s);
end
