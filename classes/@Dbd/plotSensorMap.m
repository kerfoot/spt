function h = plotSensorMap(obj)
% 
% h = Dbd.plotSensorMap()
%
% Plots a visual representation of sensor data points contained in the Dbd
% instance dataset.  All sensors native to the source data file are plotted.  
% Sensors beginning with 'drv_' are ignored as these are sensors derived from 
% a raw sensor or sensors.
%
% The return value is the figure handle, which is assigned a 'Tag' name
% with the following format: 'Dbd.segment_sensorMap'.
%
% See also Dbd
%
% ============================================================================
% $RCSfile: plotSensorMap.m,v $
% $Source: /home/kerfoot/cvsroot/slocum/matlab/spt/classes/@Dbd/plotSensorMap.m,v $
% $Revision: 1.1.1.1 $
% $Date: 2013/09/13 18:51:19 $
% $Author: kerfoot $
% ============================================================================
% 

app = mfilename;

h = [];

if ~isa(obj, 'Dbd')
    error(sprintf('%s:invalidClass', app),...
        'Method can only be attached to the Dbd class');
end

% Global marker properties
markerProps = struct('Marker', 'o',...
    'MarkerSize', 2,...
    'LineStyle', 'none');

% Get the list (sorted) of sensors contained in this obj, excluding
% obj.timestampSensor since it's our x-axis parameter
dbdSensors = setdiff(obj.sensors, obj.timestampSensor);
% Exclude all sensors which have the 'drv_' prefix as they are sensors that 
% were derived from the raw sensor data and are not part of the dbd file
r = regexp(dbdSensors, '^drv_');
dbdSensors(~cellfun(@isempty, r)) = [];

% Create a colormap with a color for each sensor
cmap = jet(length(dbdSensors));

screenSize = get(0, 'ScreenSize');
% Set up the figure - portrait
h = figure('PaperPosition', [0 0 8.5 11],...
    'Tag', [regexprep(obj.segment, '_', '-') '-' obj.filetype '_sensorMap'],...
    'Visible', 'off');
figPos = get(gcf, 'Position');
set(gcf,...
    'Position', [figPos([1:3]) screenSize(4)],...
    'Visible', 'On');
% Set up the axes
axes('NextPlot', 'add',...
    'Box', 'on',...
    'LineWidth', 1);

% Create an array of yTick values, one foreach sensor
yTicks = (1:length(dbdSensors));

num_points = 1:obj.rows;

for s = 1:length(dbdSensors)
    
    % Grab the data
    sData = [num_points' obj.dbdData.(dbdSensors{s})];

    % Replace the values with the current yTick number
    sData(~isnan(sData(:,2)),2) = yTicks(s);
        
    % Update the marker color
    markerProps.MarkerFaceColor = cmap(s,:);
    markerProps.MarkerEdgeColor = cmap(s,:);

    % Plot the data
    plot(sData(:,1), sData(:,2),...
        markerProps);
    
end

% Format the axex
set(gca,...
    'YTickLabel', dbdSensors,...
    'YTick', yTicks,...
    'YLim', [0 yTicks(end)+0.5],...
    'FontSize', 9);

% Label the x-axis
xlabel('Row Number',...
    'Interpreter', 'none');

% Title the plot
tString = ['Sensor Map: '...
    obj.segment...
    '_',...
    obj.filetype,...
    ' ('...
    obj.startTime...
    ' - '...
    obj.endTime...
    ' GMT)'];
title(tString,...
    'Interpreter', 'None');

