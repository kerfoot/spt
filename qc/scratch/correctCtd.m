% Load the DbdGroup
load(fullfile('/tmp/deployments/2013/ru28-391', 'ru28-391_DbdGroup_sci-qc0'));

dbd_ind = 1;

dbd = dgroup.dbds(dbd_ind)

% Plot the original salinity profile stats
dbd.averageProfiles('drv_sea_water_salinity', 'plot', true);

SHIFTS = [-0.1:-0.1:-1.0];

cond0 = dbd.toArray('sensors', 'drv_sea_water_electrical_conductivity');
temp0 = dbd.toArray('sensors', 'drv_sea_water_temperature');
temp1 = temp0(:,[1 3]);

for s = 1:length(SHIFTS)
    
    % Shift the sensor data
    cond1 = shiftTimeSeries(cond0(:,[1 3]), SHIFTS(s));
% % % % %     temp1 = shiftTimeSeries(temp0(:,[1 3]), SHIFTS(s));
    
    % Add as new sensors
% % % % %     dbd.addSensor('drv_sea_water_temperature_tcor',...
% % % % %         temp1(:,2),...
% % % % %         dbd.sensorUnits.drv_sea_water_temperature);
    dbd.addSensor('drv_sea_water_electrical_conductivity_tcor',...
        cond1(:,2),...
        dbd.sensorUnits.drv_sea_water_electrical_conductivity);
    
    dbd.averageProfiles('drv_sea_water_electrical_conductivity_tcor', 'plot', true);
    
% % % % %     % Recalculate derived ctd products using the new sensors
% % % % %     addCtdSensors(dbd,...
% % % % %         'conductivitysensor', 'drv_sea_water_electrical_conductivity_tcor',...
% % % % %         'temperaturesensor', 'drv_sea_water_temperature');
% % % % %     
% % % % %     % Plot the corrected salinity data
% % % % %     dbd.averageProfiles('drv_sea_water_salinity', 'plot', true);
    
end