function h = plotSampleMap(obj)
% 
% h = Dbd.plotSampleMap()
%
% Plots a visual representation of sensor data points, with respect to the 
% currently selected timestamp (Dbd.timestampSensor), in the Dbd instance.
% All sensors native to the source data file are plotted.  All sensors
% beginning with 'drv_' are ignored as these are sensors derived from a raw
% sensor or sensors.
%
% The return value is the figure handle, which is assigned a 'Tag' name
% with the following format: 'Dbd.segment_sampleMap'.
%
% See also Dbd
%
% ============================================================================
% $RCSfile: plotSampleMap.m,v $
% $Source: /home/kerfoot/cvsroot/slocum/matlab/spt/classes/@Dbd/plotSampleMap.m,v $
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
    'Tag', [regexprep(obj.segment, '_', '-') '-' obj.filetype '_sampleMap'],...
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

% Retrieve the current timestamp sensor from the private obj.dbdData
% structured array
ts = obj.dbdData.(obj.timestampSensor);

% Convert the timestamp sensor unit to datenum units if in unix time
if isempty(regexp(obj.timestampSensor, '_datenum$', 'once'))
    ts = epoch2datenum(ts);
end

for s = 1:length(dbdSensors)
    
    % Grab the data
    sData = [ts obj.dbdData.(dbdSensors{s})];

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
    'XLim', [obj.startDatenum obj.endDatenum],...
    'YTickLabel', dbdSensors,...
    'YTick', yTicks,...
    'YLim', [0 yTicks(end)+0.5],...
    'FontSize', 9);

% Label the x-axis
datetick('x', 'HH:MM', 'keeplimits');
xlabel(obj.timestampSensor,...
    'Interpreter', 'none');

% Title the plot
tString = ['Sample Map: '...
    obj.segment...
    ' ('...
    datestr(obj.startDatenum, 'yyyy-mm-dd HH:MM')...
    ' - '...
    datestr(obj.endDatenum, 'yyyy-mm-dd HH:MM')...
    ' GMT)'];
title(tString,...
    'Interpreter', 'None');

