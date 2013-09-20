function [newTs,newR] = filterYoExtrema(tz, origTs, varargin)
%
% [newTs,newR] = filterYoExtrema(tz, origTs, varargin)
% 
% Returns the timestamps and row indices corresponding to valid profiles
% contained in the time-depth array (tz) and bound by the timestamps contained
% in origTs (see findYoExtrema.m).  The following tests are performed to
% determine if a profile is valid:
%
% 1. Profile must include depths below 1 meter.
% 2. Profile must include at least 3 points.
% 3. Profile must span at least 2 meters.
%
% Finally, the mean sampling interval (meanInt) is calculated for the profile.  
% The profile is then checked for any consecutive records that are greater than 
% meanInt.  If found, the profile is assumed to consist of at least 2 separate 
% profiles.  The indices for the original profile are removed and replaced with
% the new profile indices.
%
% Options:
% 'mindepth': all depths above are excluded from the profile before 
%   validating.
%   Default is 0 meter.
% 'numpoints': the profile must contain at least this many points.  Default is
%   3.
% 'depthspan': minimum depth range the profile must span.  Default is 0 
%   meters.
% 'timespan' : minumum number of seconds a profile must contain.  Defaul is 10
%   seconds.
% 'plot': set to true to plot the yo with the newly indexed profiles.  Default
%   is false.
% 
% See also findYoExtrema
% ============================================================================
% $RCSfile: filterYoExtrema.m,v $
% $Source: /home/kerfoot/cvsroot/slocum/matlab/spt/util/filterYoExtrema.m,v $
% $Revision: 1.1.1.1 $
% $Date: 2013/09/13 18:51:19 $
% $Author: kerfoot $
% ============================================================================
%

newTs = [];
newR = [];

% Plotting styles
yoProps = struct('Marker', '.',...
    'Color', 'k',...
    'LineStyle', 'none',...
    'MarkerSize', 8);
firstProColor = 'r';
secondProColor = 'c';
proProps = struct('Marker', 'none',...
    'Color', firstProColor,...
    'LineStyle', '-',...
    'LineWidth', 1);

if isempty(tz)
    stack = dbstack;
    fprintf(2,...
        '%s E: Time/depth (tz) array is empty\n',...
        stack.name);
    return;
elseif ~isequal(size(tz,2),2)
    stack = dbstack;
    fprintf(2,...
        '%s E: First argument must be a 2-column array of time/depth values\n',...
        stack.name);
    return;
elseif isempty(origTs)
% % % % %     stack = dbstack;
% % % % %     fprintf(2,...
% % % % %         '%s E: Timestamps (origTs) array is empty\n',...
% % % % %         stack.name);
% % % % %     return;
elseif ~isequal(size(origTs,2),2)
    stack = dbstack;
    fprintf(2,...
        '%s E: Second argument must be a 2-column array of yo start/stop times\n',...
        stack.name);
    return;
end

% Default metrics
NUM_PROFILE_POINTS = 3;
MIN_PROFILE_DEPTH_SPAN = 0;
MIN_PROFILE_TIME_SPAN = 10;
MIN_DEPTH = 0;
% Don't plot the yo by default
PLOT_YO = false;

% Must have an even number of options (name/value pairs)
if ~isequal(mod(length(varargin),2),0)
    fprintf(2,...
        '%s E - Invalid number of options specified.\n',...
        caller);
    return;
end
% Process options to alter default metrics and plot the yo
for x = 1:2:length(varargin)
    name = varargin{x};
    value = varargin{x+1};
    switch lower(name)
        case 'mindepth'
            if ~isequal(numel(value),1) || ~isnumeric(value)
                fprintf(2,...
                    '%s E - %s must be a number\n',...
                    caller,...
                    value);
                return;
            end
            MIN_DEPTH = value;
        case 'depthspan'
            if ~isequal(numel(value),1) || ~isnumeric(value)
                fprintf(2,...
                    '%s E - %s must be a number\n',...
                    caller,...
                    value);
                return;
            end
            MIN_PROFILE_DEPTH_SPAN = value;
        case 'numpoints'
            if ~isequal(numel(value),1) || ~isnumeric(value)
                fprintf(2,...
                    '%s E - %s must be a number\n',...
                    caller,...
                    value);
                return;
            end
            NUM_PROFILE_POINTS = value;
        case 'timespan'
            if ~isequal(numel(value),1) || ~isnumeric(value)
                fprintf(2,...
                    '%s E - %s must be a number\n',...
                    caller,...
                    value);
                return;
            end
            MIN_PROFILE_TIME_SPAN = value;
        case 'plot'
            if ~isequal(numel(value),1) || ~islogical(value)
                fprintf(2,...
                    '%s E - %s must be a truth value (true || false)\n',...
                    caller,...
                    name);
                return;
            end
            PLOT_YO = value;
        otherwise
            fprintf(2,...
                '%s E - Unknown option specified: %s\n',...
                caller,...
                name);
            return;
    end
end

% Plot the original yo time-series
if PLOT_YO
    figure('PaperPosition', [0 0 11 8.5],...
        'Tag', 'yo');
    plot(epoch2datenum(tz(:,1)), tz(:,2),...
        yoProps);
    set(gca,...
        'NextPlot', 'Add',...
        'YDir', 'reverse',...
        'Box', 'on',...
        'TickDir', 'out',...
        'LineWidth', 1);
    datetick('x', 'HH:MM');
end

for x = 1:size(origTs)
    
    % Get the profile containing records that occur inclusive of the current 
    % start/stop times of the current profile
    pro = tz(tz(:,1) >= origTs(x,1) & tz(:,1) <= origTs(x,2),:);
    
    % Test 1: Remove all rows whose depth is < MIN_DEPTH
    pro(pro(:,2) < MIN_DEPTH,:) = [];
    % Get rid of nans
    pro(any(isnan(pro),2),:) = [];
    if size(pro,1) < NUM_PROFILE_POINTS
        continue;
    end
    
    % Diff of consecutive timestamps
    tInts = abs(diff(pro(:,1)));
    % Calculate the median
    avgInt = median(tInts);
    % Estimate the time required to complete the profile
    pTime = avgInt * size(pro,1);
    
    % Find all points in the profile having a longer time interval than
    % pTime
    pBreaks = find(tInts > pTime);
    p0 = [1; pBreaks+1];
    p1 = [pBreaks; size(pro,1)];
    pInds = [p0 p1];
    % Loop through the breaks to see if any of the sub-profiles should be
    % classified as their own profiles    
    for p = 1:size(pInds,1)
        sPro = pro(pInds(p,1):pInds(p,2),:);
        
        % Eliminate nans
        sPro(any(isnan(sPro),2),:) = [];
        if size(sPro,1) < NUM_PROFILE_POINTS
            continue;
        end
                
        % profile must span the required timespan
        deltaT = max(sPro(:,1)) - min(sPro(:,1));
        if deltaT < MIN_PROFILE_TIME_SPAN
            continue;
        end
        
        % profile must span the required depths
        deltaZ = max(sPro(:,2)) - min(sPro(:,2));
        if deltaZ < MIN_PROFILE_DEPTH_SPAN
            continue;
        end
        
        % Find the timestamps corresponding to the beginning (ts0) and end
        % (ts1) of the profile
        [ts0,~] = min(sPro(:,1));
        [ts1,~] = max(sPro(:,1));
                
        newTs(end+1,:) = [ts0 ts1];
        
    end
    
end

% Find the row indices corresponding the indexed start/stop times of the
% profiles
for x = 1:size(newTs,1)
    ts0 = newTs(x,1);
    ts1 = newTs(x,2);
    tsInds = find(tz(:,1) >= ts0);
    if isempty(tsInds)
        continue;
    end
    t0ind = tsInds(1);
    tsInds = find(tz(:,1) <= ts1);
    if isempty(tsInds)
        continue;
    end
    t1ind = tsInds(end);
    
    newR(end+1,:) = [t0ind t1ind];
    
end

if PLOT_YO    
    % plot the yos
    for x = 1:size(newR)
        pro = tz(newR(x,1):newR(x,2),:);
        pro(any(isnan(pro),2),:) = [];
        plot(epoch2datenum(pro(:,1)), pro(:,2), proProps);
        switch proProps.Color
            case firstProColor
                proProps.Color = secondProColor;
            otherwise
                proProps.Color = firstProColor;
        end
    end
end
