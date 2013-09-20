function [tsInds, r] = findYoExtrema(tz, varargin)
%
% Usage: [tsInds, r] = findYoExtrema(tz, varargin)
% 
% Returns the timestamps and row indices corresponding the peaks and valleys
% (profiles start/stop) found in the time-depth array, tz.  All indices are
% returned.
%
% Use filterYoExtrema.m to remove invalid/imcomplete profiles.
%
% See also filterYoExtrema
% ============================================================================
% $RCSfile: findYoExtrema.m,v $
% $Source: /home/kerfoot/cvsroot/slocum/matlab/spt/util/findYoExtrema.m,v $
% $Revision: 1.1.1.1 $
% $Date: 2013/09/13 18:51:19 $
% $Author: kerfoot $
% ============================================================================
%

% Return values
r = []; % Row indices
tsInds = []; % tz(r,1) values

yoProps = struct('Marker', '.',...
    'Color', 'k',...
    'LineStyle', 'none',...
    'MarkerSize', 8);
proProps = struct('Marker', 'none',...
    'Color', 'g',...
    'LineStyle', '-',...
    'LineWidth', 1);

% Time-series grid interval
INT = 10;
% To plot or not to plot
plotFlag = false;
% Process options
for x = 1:2:length(varargin)-1
    name = varargin{x};
    value = varargin{x+1};
    
    switch lower(name)
        case 'plot'
            if ~islogical(value)
                error(['Option: ' name ' requires a logical value (true|false)']);
            end
            plotFlag = value;
        case 'interval'
            if ~isequal(length(value),1) || ~isnumeric(value) || value <= 0
                error(['Option: ' name ' must be numeric and > 0']);
            end
            INT = value;
        otherwise
            error(['Invalid option: ' name]);
    end
end

% Make a copy of the timeseries variable
origTz = tz;

% Set negative values to NaN
tz(tz(:,2) <= 0,2) = NaN;

% Get rid of nans
tz(any(isnan(tz),2),:) = [];
if size(tz,1) < 2
    return;
end

% Get rid of successive duplicate time stamps
tz(diff(tz(:,1)) == 0,:) = [];
if size(tz,1) < 2
    return;
end

% Interpolate the time-series to a fixed time grid
ts = [min(tz(:,1)):INT:max(tz(:,1))]';
try
    itz = [ts interp1(tz(:,1), tz(:,2), ts)];
catch ME
    fprintf(2, '%s: %s\n', ME.identifier, ME.message);
    return;
end

% Smooth
itz(:,2) = smooth(itz(:,2), ceil(INT/2));

% Calculate delta depth
dZ = diff(itz(:,2));
% Replace negative values with -1 and positive values with 1
dZ(dZ <= 0) = -1;
dZ(dZ >= 0) = 1;

% Filter dZ
dZ = smooth(dZ, ceil(INT/2));
% Replace negative values with -1 and positive values with 1
dZ(dZ <= 0) = -1;
dZ(dZ >= 0) = 1;

% Find the rows where dZ changed direction
r0 = 1;
r1 = length(dZ)+1;
dr = find(diff(dZ) ~= 0) + 1;
% Get the timestamps corresponding to the changes in dZ direction
r0 = [1; dr-1];
r1 = [dr+1; length(dZ)+1];
% 2d array of start/stop timestamps
drTs = [itz(r0,1) itz(r1,1)];

if plotFlag
    figure('PaperPosition', [0 0 11 8.5],...
        'Tag', 'yo');
    plot(epoch2datenum(origTz(:,1)), origTz(:,2),...
        yoProps);
    set(gca,...
        'NextPlot', 'Add',...
        'YDir', 'reverse',...
        'Box', 'on',...
        'TickDir', 'out',...
        'LineWidth', 1);
end

r = nan(size(drTs,1),2);
tsInds = r;
for x = 1:size(drTs,1)
    % Timestamps for searching for the original profile
    t0 = drTs(x,1);
    t1 = drTs(x,2);
    
    % Find the row indices into the original profile
    proInds = find(origTz(:,1) >= t0-(INT*2) & origTz(:,1) <= t1+(INT*2));
    % Slice out the profile
    pro = origTz(proInds,:);
    
    % Find the minimum and maximum depth in the profile
    [~,minI] = min(pro(:,2));
    [~,maxI] = max(pro(:,2));
    
    % Store the indices into origYo corresponding to the beginning and end
    % of this profile
    r(x,:) = sort(proInds([minI maxI]));
    tsInds(x,:) = [origTz(r(x,1)) origTz(r(x,2))];
    
    % Plot if specified
    if plotFlag
        % Redefine pro
        pro = origTz(r(x,1):r(x,2),:);
        % Remove nans
        pro(any(isnan(pro),2),:) = [];
        % Plot the yo
        plot(epoch2datenum(pro(:,1)), pro(:,2), proProps);
        % Switch the color
        switch proProps.Color
            case 'r'
                proProps.Color = 'g';
            otherwise
                proProps.Color = 'r';
        end
    end
    
end

if ~isempty(findobj('Tag', 'yo'))
    axis tight;
    set(gca, 'YLim', [0 max(ylim)]);
    datetick('x', 'HH:MM', 'keepticks', 'keeplimits');
end

