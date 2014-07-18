% Settings
SENSOR = 'drv_sea_water_electrical_conductivity';
OUT_DIR = '';

% Settings validation
if ~ismember(SENSOR, dgroup.sensors)
    error(sprintf('%s:invalidSensor', mfilename),...
        'Invalid DbdGroup sensor: %s',...
        SENSOR);
end

shiftResults = [];
numDbds = length(dgroup.dbds);
% numDbds = 20;
for x = 1:numDbds
    if isequal(dgroup.dbds(x).numProfiles,0)
        continue;
    end
    
    disp(['Processing Segment: ' dgroup.dbds(x).segment]);
    
% % % % %     [results, sensorDataRange] = iterateDownUpProfileShifts(dgroup.dbds(x),...
% % % % %         SENSOR,...
% % % % %         'hasprofiles', 0.5,...
% % % % %         'validateupdown', 0.75,...
% % % % %         'plot', true);
    [results, sensorDataRange] = iterateDownUpProfileShifts(dgroup.dbds(x),...
        SENSOR,...
        'hasprofiles', 0.5,...
        'validateupdown', 0.75);
    
    % Segment name
    shiftResults(end+1).segment = dgroup.dbds(x).segment;
    
    ind = length(shiftResults);
    
    % Sensor
    shiftResults(ind).sensor = SENSOR;
    % Difference between sensor data max and min value
    shiftResults(ind).dataRange = sensorDataRange;
    
    [Y,I] = min(results(:,2));
    if isnan(Y)
        shiftResults(ind).bestShift = [NaN NaN];
    else
        shiftResults(ind).bestShift = results(I,:);
    end
    
    if isequal(I,1) || isequal(I,size(results,1))
        shiftResults(ind).minimized = false;
    else
        shiftResults(ind).minimized = true;
    end
    
    % Total number of profiles in the segment
    shiftResults(ind).numProfiles = dgroup.dbds(x).numProfiles;
        
    % Sensor time shift results
    shiftResults(ind).results = results;
    
end