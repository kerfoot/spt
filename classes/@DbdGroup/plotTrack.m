function h = plotTrack(obj, varargin)
%
% h = plotTrack()
%
% Plots all measured gps fixes (m_gps_lon/m_gps_lat), if they exist, in the
% Dbd instances contained in the DbdGroup instance.  The fixes are plotted
% as black dots connected by a black line.  Clicking on any of the fixes
% displays fix metadata and prints the gps fix time as a matlab datenum in
% the console.
%
% See also DbdGroup
% ============================================================================
% $RCSfile: plotTrack.m,v $
% $Source: /home/kerfoot/cvsroot/slocum/matlab/spt/classes/@DbdGroup/plotTrack.m,v $
% $Revision: 1.1.1.1 $
% $Date: 2013/09/13 18:51:19 $
% $Author: kerfoot $
% ============================================================================
% 

if ~isa(obj, 'DbdGroup')
    error('DbdGroup:plotTrack',...
        'Method can only be attached to the DbdGroup class');
end
 
% GPS points
gps_sensors = {'m_gps_lat',...
    'm_gps_lon',...
    }';
if length(intersect(gps_sensors, obj.sensors)) ~= length(gps_sensors)
    error('DbdGroupp:plotTrack',...
        'DbdGroup instance is missing the required GPS sensors (m_gps_lat, m_gps_lon).');
end

[gps, gps_sensors] = obj.toArray('sensors', gps_sensors);
% Remove depth (column 2)
gps(:,2) = [];

% Set bad fixes to NaN
gps(any(gps(:,[2 3]) > 18000,2),:) = NaN;

% Remove NaNs
gps(any(isnan(gps),2),:) = [];
if isempty(gps)
    warning('DbdGroup:noSensorData',...
        'No valid timestamped GPS coordinates found in the instance.');
    h = [];
    return;
end

% Convert any unix times to datenums
r = find(gps(:,1) > datenum2epoch(datenum(1990,1,1,0,0,0)));
gps(r,:) = epoch2datenum(gps(r,:));

% Convert from NMEA to decimal degrees
gps(:,[2 3]) = dm2dd(gps(:,[2 3]));

varargin{end+1} = 'platform';
varargin{end+1} = obj.dbds(1).glider;
h = plotClickableTrack(gps, varargin{:});

function h = plotClickableTrack(tsLatLon, varargin)
%
% h = plotClickableTrack(tsLatLon, varargin)
%
% Plot the gps track contained in tsLatLon on the current axis.  All plotted 
% gps coordinates are clickable, providing the glider name, unix timestamp of 
% the fix and a date string representation of the timestamp.
%
% The appearance of the markers can be altered by specifying the (properly
% capitalized) marker property and the desired value.  For example, to change
% the markers to red stars, enter the following:
%
%   h = plotStructTrack(dataStruct, 'Marker', '*', 'MarkerFaceColor', 'r');
%
% See also dbd2lvl0 
% ============================================================================
% $RCSfile: plotTrack.m,v $
% $Source: /home/kerfoot/cvsroot/slocum/matlab/spt/classes/@DbdGroup/plotTrack.m,v $
% $Revision: 1.1.1.1 $
% $Date: 2013/09/13 18:51:19 $
% $Author: kerfoot $
% ============================================================================
%

h = [];

caller = [mfilename '.m'];

% Defaults ----
% Default marker properties
defaultMarkers = struct('Marker', 'o',...
    'LineStyle', 'None',...
    'MarkerFaceColor', 'k',...
    'MarkerEdgeColor', 'k',...
    'MarkerSize', 4,...
    'Tag', 'track',...
    'ButtonDownFcn', @showPoint);

allFields = fieldnames(defaultMarkers);
dFields = allFields;

platform = 'unknown';
% Process optional arguments
for x = 1:2:length(varargin)
    
    name = varargin{x};
    value = varargin{x+1};
    
    switch name
        case 'platform' % Allow the user to specify a platform name
            if ~ischar(value)
                disp([caller ' E - Platform must be a string!']);
                return;
            end
            platform = value;
        otherwise
        I = find(strcmpi(name,dFields) == 1, 1);
        if ~isempty(I)
            defaultMarkers.(allFields{I(1)}) = value;
        else
            defaultMarkers.(name) = value;
        end
    end
    
end

% Set up the textbox delete function using the WindowButtonUpFcn
f = figure('WindowButtonUpFcn', @hidePoint);
axes('LineWidth', 1,...
    'TickDir', 'out',...
    'Box', 'on',...
    'NextPlot', 'add');

% Number of GPS records
r = size(tsLatLon,1);
% Intialize the array of handles to be plotted
h = nan(r+1,1);

% Set the track line properties
lineProps               = defaultMarkers;
lineProps.Marker        = 'None';
lineProps.LineStyle     = '-';
if ~isfield(defaultMarkers, 'Color')
    lineProps.Color     = defaultMarkers.MarkerFaceColor;
end
lineProps.ButtonDownFcn = '';

% Plot the track first
h(1) = plot(tsLatLon(:,3), tsLatLon(:,2),...
    lineProps);
% Sort by time
tsLatLon = sortrows(tsLatLon,1);
gpsMarkers = defaultMarkers;
for x = 1:r
      
    if isequal(x,1)
        % Start point
        gpsMarkers.MarkerFaceColor = [0 0.5 0];
        gpsMarkers.MarkerSize = 10;
    elseif isequal(x,r)
        % End Point
        gpsMarkers.MarkerFaceColor = [0.75 0 0];
        gpsMarkers.MarkerSize = 10;
    else
        % Standard tsLatLon point
        gpsMarkers.MarkerFaceColor = defaultMarkers.MarkerFaceColor;
        gpsMarkers.MarkerSize = defaultMarkers.MarkerSize;
    end
    
    % Create the user data
    ts = datestr(tsLatLon(x,1), 31);
    ts([end-2:end]) = [];
    gpsMarkers.UserData = {platform,...
        ts,...
        num2str(tsLatLon(x,1)),...
        num2str(datenum2epoch(tsLatLon(x,1)), '%0.0f')}';
    
    h(x+1) = plot(tsLatLon(x,3), tsLatLon(x,2),...
        gpsMarkers);
    
end
    
% Displays the clicked tsLatLon point information
function showPoint(gcbo, NaN)

% Text Box Properties
textBoxProps = struct('BackgroundColor', [1 1 1],...
    'EdgeColor', [0 0 0],...
    'VerticalAlignment', 'top',...
    'HorizontalAlignment', 'left',...
    'Tag', 'textBox',...
    'UserData', gcbo);

mFields = {'Marker',...
    'MarkerSize',...
    'MarkerFaceColor',...
    'MarkerEdgeColor',...
    'Color',...
    'LineWidth',...
    'Tag'}';
mProps = [];
for x = 1:length(mFields)
    mProps.(mFields{x}) = get(gcbo, mFields{x});
end
% set(findobj('Tag', 'profilesFigure'),...
%     'UserData', mProps);
set(gcf,...
    'UserData', mProps);

% Increase the marker size and set the MarkerFaceColor to yellow
set(gcbo,...
    'Marker', '.',...
    'MarkerFaceColor', 'k',...
    'MarkerEdgecolor', 'k',...
    'MarkerSize', 20,...
    'Color', 'k',...
    'LineWidth', 4,...
    'Tag', 'selected');

% Plot the text box
x = min(xlim);
y = max(ylim);
userdata = get(gcbo, 'UserData');
tb = text(x, y,...
    userdata,...
    textBoxProps);

% Show the datenum of the clicked point
userdata{3}




% Deletes the text created by showPoint
function hidePoint(gcbo, NaN)

obj = findobj(gcf, 'Tag', 'textBox');
if isempty(obj)
    return;
end

% Restore the profile's original properties
set(findobj('Tag', 'selected'),...
    get(gcf, 'UserData'));

delete(obj);