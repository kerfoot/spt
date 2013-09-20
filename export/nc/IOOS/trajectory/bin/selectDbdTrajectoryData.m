function data = selectDbdTrajectoryData(dbd, varargin)

app = mfilename;

data = [];

s_map = getTrajectorySensorMappings();

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
