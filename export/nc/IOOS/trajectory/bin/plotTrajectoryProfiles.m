function plotTrajectoryProfiles(p, sensor, varargin)
%
% plotTrajectoryProfiles(p, sensor, varargin)
%
% Plots the sensor profiles contained in the specified structured array, p,
% assuming complete data rows exist.
%
% See also checkIoosTrajectoryCompliance ioosTrajectoryNc2Profiles 
% ============================================================================
% $RCSfile: plotTrajectoryProfiles.m,v $
% $Source: /home/kerfoot/cvsroot/slocum/matlab/spt/export/nc/IOOS/trajectory/bin/plotTrajectoryProfiles.m,v $
% $Revision: 1.1 $
% $Date: 2014/04/02 13:23:10 $
% $Author: kerfoot $
% ============================================================================
%

app = mfilename;

if nargin < 2
    error(sprintf('%s:nargin', app),...
        '2 arguments are required');
elseif isempty(p) || ~isstruct(p)
    error(sprintf('%s:invalidArgument', app),...
        'First argument must be a structured array');
elseif ~ischar(sensor) || isempty(sensor) || ~isfield(p, sensor)
    error(sprintf('%s:invalidArgument', app),...
        'Second argument must be a string specifying an existing sensor');
elseif ~isequal(mod(length(varargin),2),0)
    error(sprintf('%s:nargin', app),...
        'Invalid number of options specified');
end

Y_SENSOR = 'depth';
for x = 1:2:length(varargin)
    name = varargin{x};
    value = varargin{x+1};
    
    switch lower(name)
        case 'ysensor'
            if ~ischar(value) || ~isfield(p, value)
                error(sprintf('%s:invalidValue', app),...
                    'Value for option %s must be a valid sensor name',...
                    name);
            end
            Y_SENSOR = value;
        otherwise
            error(sprintf('%s:invalidOption', app),...
                'Invalid option specified: %s',...
                name);
    end
end

if ~isfield(p, Y_SENSOR)
    error(sprintf('%s:invalidSensor', app),...
        '%s is not a field name of the structured array',...
        Y_SENSOR);
end

f = figure('PaperPosition', [0 0 8.5 11]);
axes('NextPlot', 'add',...
    'Box', 'on',...
    'TickDir', 'out',...
    'LineWidth', 1,...
    'XAxisLocation', 'top');
numProfiles = length(p);
cmap = jet(length(p));
for x = 1:numProfiles
    
    data = [p(x).(Y_SENSOR) p(x).(sensor)];
    
    data(any(isnan(data),2),:) = [];
    
    if isempty(data)
        warning(sprintf('%s:noProfileData', app),...
            'Profile %0.0f contains no data\n',...
            x);
        continue;
    end
    
    plot(data(:,2), data(:,1),...
        'Marker', 'none',...
        'LineStyle', '-',...
        'Color', cmap(x,:));
end

ylabel(Y_SENSOR, 'Interpreter', 'none');
xlabel(sensor, 'Interpreter', 'none');
