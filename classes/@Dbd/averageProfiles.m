function [dMean, uMean, dStd, uStd, allMean, allStd] = averageProfiles(obj, sensor, varargin)
%
% [dMean, uMean, dStd, uStd, allMean, allStd] = averageProfiles(obj, sensor, varargin)
%
% Calculates the downcast, upcast and total means and standard deviations for 
% the specified sensor.  The profiles are binned to 1 meter depth prior to
% performing the statistical analysis.
%
% Options:
%   'depthbin': INCREMENT
%       Specify an alternate depth binning increment.  Default is 1 meter.
%   'plot': LOGICAL
%       Set to true to plot the results.  Default is false/
%       
% See also dbd
%
% ============================================================================
% $RCSfile: averageProfiles.m,v $
% $Source: /home/kerfoot/cvsroot/slocum/matlab/spt/classes/@Dbd/averageProfiles.m,v $
% $Revision: 1.2 $
% $Date: 2014/01/13 15:53:56 $
% $Author: kerfoot $
% ============================================================================
% 

app = mfilename;

% Validate inputs
if nargin < 2
    error(sprintf('%s:nargin', app),...
        'No sensor specified');
elseif ~isa(obj, 'Dbd')
    error(sprintf('%s:invalidClass', app),...
        'Method can only be attached to the Dbd class');
elseif ~isequal(mod(length(varargin),2),0)
    error(sprintf('%s:nargin', app),...
        'Invalid number of name,value options specified.');
elseif ~ismember(sensor, obj.sensors)
    error(sprintf('%s:invalidSensor', app),...
        'Sensor not found');
end

DEPTH_BIN = 1;
PLOT = false;
NUM_DEVS = 1;
% Process options
for x = 1:2:length(varargin)
    name = varargin{x};
    value = varargin{x+1};
    
    switch lower(name)
        case 'depthbin'
            if ~isequal(numel(value),1) || ~isnumeric(value) || value <= 0
                error(sprintf('%s:invalidOptionValue', app),...
                    'Value for option must be a positive numeric scalar');
            end
            DEPTH_BIN = value;
        case 'plot'
            if ~isequal(numel(value),1) || ~islogical(value)
                error(sprintf('%s:invalidOptionValue', app),...
                    'Value for option must be a logical value');
            end
            PLOT = value;
        case 'numdevs'
            if ~isequal(numel(value),1) || ~isnumeric(value) || value < 0
                error(sprintf('%s:invalidOptionValue', app),...
                    'Value for option %s must be a positive integer',...
                    name);
            end
            NUM_DEVS = value;
        otherwise
            error(sprintf('%s:invalidOption', app),...
                'Invalid option specified: %s',...
                name);
    end
end

% Initialize return values
dMean = [];
uMean = [];
dStd = [];
uStd = [];
allMean = [];
allStd = [];

% Grid the profile data
[X,Y,DATAI] = obj.toGrid2d(sensor, 'depthbin', DEPTH_BIN);
if all(isnan(DATAI))
    warning(sprintf('%s:noData', app),...
        '%s: No data points found for %s\n',...
        obj.segment,...
        sensor);
    return;
end

% Create a profiles data structure so that we can figure out which profile
% direction
p = obj.toProfiles('sensors', sensor);
P_DIRS = {};
for x = 1:length(p)
    P_DIRS{x} = p(x).meta.direction;
end

% Find the downs
DOWNS = DATAI(:,strcmp('d', P_DIRS));
% Find the ups
UPS= DATAI(:,strcmp('u', P_DIRS));

% Calculate the averge row by row to exclude nans
dMean = [Y nan(length(Y), 1)];
uMean = dMean;
dStd = dMean;
uStd = dMean;
allMean = dMean;
allStd = dMean;

for x = 1:length(Y)
    
    c = find(~isnan(DOWNS(x,:)));
    dMean(x,2) = mean(DOWNS(x,c));
    dStd(x,2) = std(DOWNS(x,c));
    
    c = find(~isnan(UPS(x,:)));
    uMean(x,2) = mean(UPS(x,c));
    uStd(x,2) = std(UPS(x,c));
    
    c = find(~isnan(DATAI(x,:)));
    allMean(x,2) = mean(DATAI(x,c));
    allStd(x,2) = std(DATAI(x,c));
    
end
    
if PLOT
    
    figure('PaperPosition', [0 0 11 8.5]);
    ax(1) = subplot(1,2,1);
    ax(2) = subplot(1,2,2);
    
    set(ax,...
        'NextPlot', 'add',...
        'Box', 'on',...
        'LineWidth', 1,...
        'TickDir', 'out',...
        'YDir', 'reverse');
    
    % Plot the downs
    for x = 1:size(DOWNS,2)
        r = find(~isnan(DOWNS(:,x)));
        plot(ax(1), DOWNS(r,x), Y(r), 'b--');
    end
    
    % Plot the ups
    for x = 1:size(UPS,2)
        r = find(~isnan(UPS(:,x)));
        plot(ax(1), UPS(r,x), Y(r), 'r--');
    end
    
    % Plot the mean downcast
    r = find(~isnan(dMean(:,2)));
    plot(ax(1), dMean(r,2), dMean(r,1),...
        'Marker', 'none',...
        'LineWidth', 2,...
        'Color', 'b',...
        'LineStyle', '-');
    
    % Plot the mean upcast
    r = find(~isnan(uMean(:,2)));
    plot(ax(1), uMean(r,2), uMean(r,1),...
        'Marker', 'none',...
        'LineWidth', 2,...
        'Color', 'r',...
        'LineStyle', '-');
    
    % Calculate and plot the 1-standard deviation polygon for downcasts
    y = [Y; flipud(Y)];
    x = [dMean(:,2) + dStd(:,2)*NUM_DEVS; flipud(dMean(:,2) - dStd(:,2)*NUM_DEVS)];
    y(isnan(x)) = [];
    x(isnan(x)) = [];
    [x,y] = poly2cw(x, y);
    [faces,vertices] = poly2fv(x,y);
    axes(ax(1))
    h = patch('Faces', faces,...
        'Vertices', vertices,...
        'FaceColor', 'b',...
        'EdgeColor', 'none',...
        'FaceAlpha', 0.2);
    
    % Calculate and plot the 1-standard deviation polygon for upcasts
    y = [Y; flipud(Y)];
    x = [uMean(:,2) + uStd(:,2)*NUM_DEVS; flipud(uMean(:,2) - uStd(:,2)*NUM_DEVS)];
    y(isnan(x)) = [];
    x(isnan(x)) = [];
    [x,y] = poly2cw(x, y);
    [faces,vertices] = poly2fv(x,y);
    axes(ax(1));
    h = patch('Faces', faces,...
        'Vertices', vertices,...
        'FaceColor', 'r',...
        'EdgeColor', 'none',...
        'FaceAlpha', 0.2);
    title(['Down(b)/Up(r) Mean & Deviation'],...
        'Interpreter', 'none');
    
    % Axes 2: mean and dev of all profiles
    % Plot the downs
    for x = 1:size(DOWNS,2)
        r = find(~isnan(DOWNS(:,x)));
        plot(ax(2), DOWNS(r,x), Y(r), 'b--');
    end
    
    % Plot the ups
    for x = 1:size(UPS,2)
        r = find(~isnan(UPS(:,x)));
        plot(ax(2), UPS(r,x), Y(r), 'r--');
    end
    
    % Plot the mean downcast
    r = find(~isnan(allMean(:,2)));
    plot(ax(2), allMean(r,2), allMean(r,1),...
        'Marker', 'none',...
        'LineWidth', 2,...
        'Color', 'k',...
        'LineStyle', '-');
    
    % Calculate and plot the 1-standard deviation polygon for upcasts
    y = [Y; flipud(Y)];
    x = [allMean(:,2) + allStd(:,2)*NUM_DEVS; flipud(allMean(:,2) - allStd(:,2)*NUM_DEVS)];
    y(isnan(x)) = [];
    x(isnan(x)) = [];
    [x,y] = poly2cw(x, y);
    [faces,vertices] = poly2fv(x,y);
    axes(ax(2))
    h = patch('Faces', faces,...
        'Vertices', vertices,...
        'FaceColor', 'k',...
        'EdgeColor', 'none',...
        'FaceAlpha', 0.2);
    plot(x, y,...
        'Marker', 'none',...
        'Color', 'k',...
        'LineWidth', 1);
    title(['All Mean & Deviation'],...
        'Interpreter', 'none');
    
    t = toptitle([sensor ' (' obj.segment ')']);
    set(t,...
        'Interpreter', 'none',...
        'VerticalAlignment', 'top');
end
