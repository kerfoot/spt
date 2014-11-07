function h = plotProfiles(obj, sensorName, varargin)
%
% h = DbdGroup.plotProfiles(sensorName, varargin)
%
% Sensor profile plots for all Dbd instances in the DbdGroup instance.  
% Depths/pressures values are taken from each Dbd instance's .depth property.  
% All plotted profiles are clickable for profile metadata.
%
% If Dbd.fillDepths is set to a valid interp1.m interpolation method, the 
% plotted profiles will contain the interpolated depths.
%
% The return value is the figure handle, which is assigned a 'Tag' name
% with the following format: 'Dbd.segment_profiles'.
%
% Options:
% 't0' [NUMBER]: datenum value specifying the minimum profile time to include.
% 't1' [NUMBER]: datenum value specifying the maximum profile time to include.
%
% See also Dbd
%
% ============================================================================
% $RCSfile: plotProfiles.m,v $
% $Source: /home/kerfoot/cvsroot/slocum/matlab/spt/classes/@DbdGroup/plotProfiles.m,v $
% $Revision: 1.3 $
% $Date: 2014/01/13 15:54:44 $
% $Author: kerfoot $
% ============================================================================
% 

app = mfilename;

h = [];

if ~isa(obj, 'DbdGroup')
    error(sprintf('%s:invalidClass', app),...
        'Method can only be attached to the DbdGroup class');
elseif nargin < 2
    error(sprintf('%s:nargin', app),...
        'No sensor specified.');
elseif ~ismember(sensorName, obj.sensors)
    fprintf(1,...
        '%s is not sensor in the Dbd instance.',...
        sensorName);
    return;
end

% Process options
t0 = NaN;
t1 = NaN;
for x = 1:2:length(varargin)
    
    name = varargin{x};
    value = varargin{x+1};
    
    switch lower(name)
        case 't0'
            if ~isnumeric(value) || ~isequal(numel(value),1)
                fprintf(2,...
                    'Value for option %s must be a datenum number\n',...
                    name);
                return;
            end
            t0 = value;
        case 't1'
            if ~isnumeric(value) || ~isequal(numel(value),1)
                fprintf(2,...
                    'Value for option %s must be a datenum number\n',...
                    name);
                return;
            end
            t1 = value;
        otherwise
            fprintf(2,...
                'Invalid option: %s\n',...
                name);
            return;
    end
end

pStruct = obj.toProfiles('sensors', sensorName);
if isempty(pStruct)
    fprintf(2,...
        '%s: Segment contains no profiles\n',...
        obj.segment);
    return;
end

% Create a structured array of each profile's meta data
pMeta = cat(1, pStruct.meta);
pt0 = cat(1, pMeta.startDatenum);
pt1 = cat(1, pMeta.endDatenum);
% Filter out unwanted profiles
if ~isnan(t0)
    pStruct(pt1 < t0) = [];
    pMeta = cat(1, pStruct.meta);
    pt0 = cat(1, pMeta.startDatenum);
end
if ~isnan(t1)
    pStruct(pt0 > t1) = [];
end
if isempty(pStruct)
    fprintf(2,...
        '%s: Segment contains no profiles in the specified time interval\n',...
        obj.segment);
    return;
end

screenSize = get(0, 'ScreenSize');
% Set up the figure - portrait
h = figure('PaperPosition', [0 0 8.5 11],...
    'Tag', [regexprep(sensorName, '_', '-') '_profiles'],...
    'WindowButtonUpFcn', @hideProfile,...
    'Visible', 'Off');
figPos = get(gcf, 'Position');
set(gcf,...
    'Position', [figPos([1:3]) screenSize(4)],...
    'Visible', 'On');
% Set up the axes
axes('NextPlot', 'add',...
    'Box', 'on',...
    'LineWidth', 1,...
    'YDir', 'reverse');

defaultProfileLineProps = struct('LineStyle', '-',...
    'MarkerSize', 5,...
    'LineWidth', 1,...
    'ButtonDownFcn', @showProfile);

% Initialize the return value
ph = nan(length(pStruct),1);
% Set up the colormaps
cmap = jet(length(pStruct));
for x = 1:length(pStruct)
    
%     x
%     
%     if isequal(x,22)
%         keyboard;
%     end
    
    % Set default profile line properties
    profileLineProps = defaultProfileLineProps;
    
    pro = [pStruct(x).timestamp...
        pStruct(x).depth...
        pStruct(x).(sensorName)];
    
    goodRows = find(all(~isnan(pro(:,[2 3])),2));
    
    if isempty(goodRows)
        fprintf(1,...
            '%s: Profile %0.0f contains no records.\n',...
            obj.segment,...
            x);
        continue;
    end
    
    % Convert timestamp values from unix time to datenums if needed
    if isempty(regexp(pStruct(x).meta.timestampSensor, '_datenum$', 'once'))
        pro(:,1) = epoch2datenum(pro(:,1));
    end
    
    switch pStruct(x).meta.direction
        case 'd'
            profileLineProps.Marker = 'None';
            pType = 'Downcast';
        case 'u'
            profileLineProps.Marker = 'None';
            pType = 'Upcast';
        otherwise
            continue;
    end
    
    % Update profile line properties
    profileLineProps.UserData = {sprintf('Profile %d (%s)', x, pType),...
        [num2str(length(goodRows), '%d') ' Records' ],...
        ['t0: ' datestr(pStruct(x).meta.startDatenum) ' UTC'],...
        ['t1: ' datestr(pStruct(x).meta.endDatenum) ' UTC'],...
        ['z0: ' num2str(pro(1,2), '%0.2f') ' m'],...
        ['z1: ' num2str(pro(end,2), '%0.2f') ' m']}';
        
    profileLineProps.MarkerFaceColor = cmap(x,:);
    profileLineProps.MarkerEdgeColor = cmap(x,:);
    profileLineProps.Color = cmap(x,:);
    
    % Plot the profile
    ph(x) = plot(pro(goodRows,3), pro(goodRows,2), profileLineProps);
    
end

xlabel([sensorName ' (' obj.sensorUnits.(sensorName) ')'],...
    'Interpreter', 'none');
ylabel('depth',...
    'Interpreter', 'none');
title([obj.dbds(1).glider...
    ' Profiles: '...
    pStruct(1).meta.startTime...
    ' - '...
    pStruct(end).meta.endTime...
    ' UTC'],...
    'Interpreter', 'None');

ph(isnan(ph)) = [];

% Displays the clicked tsLatLon point information
function showProfile(gco, NaN)

% Text Box Properties
textBoxProps = struct('BackgroundColor', [1 1 1],...
    'EdgeColor', [0 0 0],...
    'VerticalAlignment', 'top',...
    'HorizontalAlignment', 'left',...
    'Tag', 'textBox',...
    'UserData', gco);

mFields = {'Marker',...
    'MarkerSize',...
    'MarkerFaceColor',...
    'MarkerEdgeColor',...
    'Color',...
    'LineWidth',...
    'Tag'}';
mProps = [];
for x = 1:length(mFields)
    mProps.(mFields{x}) = get(gco, mFields{x});
end
% set(findobj('Tag', 'profilesFigure'),...
%     'UserData', mProps);
set(gcf,...
    'UserData', mProps);

% Bring the selected profile to the front
pLines = findobj(gca, 'Type', 'Line');
pLines = setxor(gco, pLines);
set(gca,...
    'Children', [gco; pLines])

% Increase the marker size and set the all colors to black
set(gcbo,...
    'MarkerFaceColor', 'k',...
    'MarkerEdgecolor', 'k',...
    'MarkerSize', get(gcbo, 'MarkerSize')*2,...
    'Color', 'k',...
    'LineWidth', 5,...
    'Tag', 'selected');

% Plot the text box
x = min(xlim);
y = min(ylim);
text(x, y,...
    get(gco, 'UserData'),...
    textBoxProps);


% Deletes the text created by showPoint
function hideProfile(gco, NaN)

obj = findobj(gcf, 'Tag', 'textBox');
if isempty(obj)
    return;
end

% Restore the profile's original properties
set(findobj('Tag', 'selected'),...
    get(gcf, 'UserData'));

delete(obj);
