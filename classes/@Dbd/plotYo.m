function h = plotYo(obj)
%
% h = Dbd.plotYo(Dbd)
%
% Plots the indexed yo profile for the Dbd instance.  The time-series is 
% created using the from the Dbd.timestampSensor and Dbd.depthSensor.  Indexed
% profiles are plotted over the yo in alternating colors.
%
% If Dbd.fillTimes and/or Dbd.fillDepths are set to a valid interp1.m
% interpolation method, the plotted yo will contain the interpolated
% timestamps and depths, respectively.
%
% The return value is the figure handle, which is assigned a 'Tag' name
% with the following format: 'Dbd.segment_yoProfile'.
%
% No figure is created if the instance does not contain a valid time-series.
%
% See also Dbd
%
% ============================================================================
% $RCSfile: plotYo.m,v $
% $Source: /home/kerfoot/cvsroot/slocum/matlab/spt/classes/@Dbd/plotYo.m,v $
% $Revision: 1.1.1.1 $
% $Date: 2013/09/13 18:51:19 $
% $Author: kerfoot $
% ============================================================================
% 

app = mfilename;

h = [];

% Must be an instance of the Dbd class
if ~isa(obj, 'Dbd')
    error(sprintf('%s:invalidClass', app),...
        'Method can only be attached to the Dbd class');
end
 
% Plot formatting
yoProps = struct('Marker', '.',...
    'Color', 'k',...
    'LineStyle', 'none',...
    'MarkerSize', 12);
firstProColor = 'r';
secondProColor = 'c';
proProps = struct('Marker', 'none',...
    'Color', firstProColor,...
    'LineStyle', '-',...
    'LineWidth', 1);

% Get an array of obj.timestampSensor, obj.depthSensor and obj.drv_proInds
tzi = obj.toArray('sensors', {'drv_proInds'});
if isempty(tzi)
    fprintf(1,...
        '%s: Instance does not contain a valid depth time-series.',...
        obj.segment);
    return;
end

% Find the indexed profile numbers
proNums = unique(floor(tzi(:,3)));
proNums(isnan(proNums)) = [];
if isempty(proNums)
    fprintf(1, '%s: Instance contains no indexed profiles.',...
        obj.segment);
    return;
end

% Remove nans
tzi(any(isnan(tzi(:,1:2)),2),:) = [];
if isempty(tzi)
    fprintf(1,...
        '%s: Instance contains no complete (non-NaN) time-depth records.',...
        obj.segment);
    return;
end
% If obj.timestampSensor is in unix time (does not end in '_datenum'), convert
% it to matlab datenum units
if isempty(regexp(obj.timestampSensor, '_datenum$', 'once'))
    tzi(:,1) = epoch2datenum(tzi(:,1));
end

% Set up the figure - portrait
h = figure('PaperPosition', [0 0 11 8.5],...
    'Tag', [regexprep(obj.segment, '_', '-') '-' obj.filetype '_yoProfile']);
% Set up the axes
axes('NextPlot', 'add',...
    'Box', 'on',...
    'LineWidth', 1,...
    'YDir', 'reverse');

% Plot the yo
plot(tzi(:,1), tzi(:,2),...
    yoProps);

for x = 1:length(proNums)

    % Current profile number
    pInd = proNums(x);
    % Get the profile data
    pro = tzi(tzi(:,3) > pInd-1 & tzi(:,3) < pInd+1,:);
    % Skip if no profile data
    if isempty(pro)
        continue;
    end
    % Plot the yo
    plot(pro(:,1), pro(:,2), proProps);
    % Switch the color
    switch proProps.Color
        case firstProColor
            proProps.Color = secondProColor;
        otherwise
            proProps.Color = firstProColor;
    end
end

% Label the axes and title the plot
datetick('x', 'HH:MM', 'keeplimits');
xlabel(obj.timestampSensor,...
    'Interpreter', 'none');
ylabel(obj.depthSensor,...
    'Interpreter', 'none');
tString = sprintf('Yo Profile: %s (%s - %s UTC)',...
    obj.segment,...
    datestr(obj.startDatenum, 'yyyy-mm-dd HH:MM'),...
    datestr(obj.endDatenum, 'yyyy-mm-dd HH:MM'));
title(tString,...
    'Interpreter', 'none');
