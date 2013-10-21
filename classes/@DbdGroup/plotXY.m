function h = plotXY(obj, x_sensor, y_sensor, varargin)
% 
% h = plotXY(obj, x_sensor, y_sensor, varargin)
%
% Plots the values for x_sensor against the values for y_sensor on the
% x-axis and y-axis, respectively.
%
% If a only one sensor is specified, the sensor data is plotted as a
% time-series vs Dbd.timestampSensor.
%
% See also Dbd
%
% ============================================================================
% $RCSfile: plotXY.m,v $
% $Source: /home/kerfoot/cvsroot/slocum/matlab/spt/classes/@DbdGroup/plotXY.m,v $
% $Revision: 1.1 $
% $Date: 2013/10/10 18:55:47 $
% $Author: kerfoot $
% ============================================================================
% 

app = mfilename;

h = [];

if ~isa(obj, 'DbdGroup')
    error(sprintf('%s:invalidClass', app),...
        'Method can only be attached to the DbdGroup class');
elseif isequal(nargin,2)
    % Assume we want to plot a time series
    y_sensor = x_sensor;
    x_sensor = obj.timestampSensor;
% % % % %     error(sprintf('%s:nargin', app),...
% % % % %         'Please specify the 2 sensors to plot');
elseif ~isequal(mod(length(varargin),2),0)
    error(sprintf('%s:varargin', app),...
        'Invalid number of options specified');
end

% % % % % for x = 1:2:length(varargin)
% % % % %     
% % % % %     name = varargin{x};
% % % % %     value = varargin{x+1};
% % % % %     
% % % % %     switch lower(name)
% % % % %         otherwise
% % % % %             error(sprintf('%s:varargin', app),...
% % % % %                 'Invalid option: %s',...
% % % % %                 name);
% % % % %     end
% % % % % end

% Make sure the x_sensor and y_sensor are part of the Dbd instance
if ~ismember(x_sensor, obj.sensors)
    warning(sprintf('%s:invalidSensor', app),...
        'Specified x-sensor does not exist in the Dbd instance: %s\n',...
        x_sensor);
    return;
elseif ~ismember(y_sensor, obj.sensors)
    warning(sprintf('%s:invalidSensor', app),...
        'Specified y-sensor does not exist in the Dbd instance: %s\n',...
        y_sensor);
    return;
end
    
% Create the figure
tag = 'DbdGroup_XY_plot';
h = figure('PaperPosition', [0 0 11 8.5],...
    'Tag', tag);
axes('Box', 'on',...
    'LineWidth', 1,...
    'TickDir', 'out',...
    'NextPlot', 'add');

% Grab the data
data = obj.toArray('sensors', {x_sensor, y_sensor});

% Plot the data
plot(data(:,3), data(:,4),...
    'Marker', 'o',...
    'LineStyle', 'none',...
    'Color', 'k',...
    'MarkerFaceColor', 'b',...
    'MarkerEdgeColor', 'b');

% Clean up the axis
axis tight;
xlabel(x_sensor, 'Interpreter', 'None');
ylabel(y_sensor, 'Interpreter', 'None');

% If the units of x_sensor are matlab datenum, format the axis
if ~isempty(regexp(obj.sensorUnits.(x_sensor), 'days since 0000-01-00 00:00:00 GMT', 'once'))
    ts_span = max(data(:,3)) - min(data(:,3));
    if ts_span <= 1
        d_format = 'HH:MM';
    elseif ts_span <= 2
        d_format = 'mm/dd HH:MM';
    else
        d_format = 'mm/dd';
    end
    datetick('x', d_format, 'keeplimits');
end

% Title
title(sprintf('%s - %s UTC',...
    datestr(min(obj.startDatenums), 'yyyy-mm-dd HH:MM:SS'),...
    datestr(max(obj.endDatenums), 'yyyy-mm-dd HH:MM:SS')));


