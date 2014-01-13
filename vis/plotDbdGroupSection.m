function fname_template = plotDbdGroupSection(obj, sensor, varargin)
%
% Usage: iNames = plotDbdGroupSection(obj, sensor, varargin)
%
% Creates a time-series scatter cross-section plot of sensor versus depth, 
% at full color scale, with a vertical colorbar for the specified DbdGroup
% instance. If available, bathymetry (m_water_depth) is also plotted.
%
% The default behavior can be modified using a combination of name,value
% pairs.  Valid options are:
%
%   'plotbathy': true (default) to plot bathymetry.
%   'minbathy': minimum bathymetry value to plot.
%   'protype': profile type to plot.  All profiles are plotted by default.
%       Other options include 'd' (downs) or 'u' (up).
%   't0': minimum time value to plot.
%   't1': maximum time value to plot.
%   'colorbar': 'vert' (default) to plot a vertical colorbar, 'horiz' to plot
%       a horizontal colorbar or 'none'.
%   'clim': 2-element vector for minimum and maximum values.
%   'xsensor': x-axis sensor.  Default is Pbd.timestampSensor.
%   'ymin': minimum y-axis value.
%   'ymax': maximum y-axis value.
%
% ============================================================================
% $RCSfile: plotDbdGroupSection.m,v $
% $Source: /home/kerfoot/cvsroot/slocum/matlab/spt/vis/plotDbdGroupSection.m,v $
% $Revision: 1.6 $
% $Date: 2014/01/13 15:56:40 $
% $Author: kerfoot $
% $Name:  $
% ============================================================================
%

app = mfilename;

fname_template = '';

% Validate args
if nargin < 2
    warning('plotPbdGroupSection:invalidArgumentNumber',...
        'A minimum of 2 arguments required.');
    return;
elseif ~isa(obj, 'DbdGroup')
    warning('DbdGroup:invalidClassType',...
        'The first argument must be a DbdGroup instance.');
    return;
elseif isempty(sensor) ||...
        ~ischar(sensor) ||...
        ~ismember(sensor, obj.sensors)
    warning('plotPbdGroupSection:invalidSensorArgument',...
        'Second argument must be a valid sensor name.');
    return;
end

% Create a figure that is initially invisible to account for the colormap
% call
figure('PaperPosition', [0 0 11 8.5],...
    'Visible', 'on');

% Add this value to the max bathymetry value to get some spacing from the
% bottom of the plot
BATHY_OFFSET = 5;

% Values for 'protype' option
profileTypes = {'a',...
    'all',...
    'down',...
    'd',...
    'up',...
    'u',...
    }';
cbarTypes = {'none',...
    'horiz',...
    'vert',...
    }';
% Default option values
PLOT_BATHY = true;
MIN_BATHY = 5;
PRO_DIR = 'all';
t0 = NaN;
t1 = NaN;
CLIM = [];
CBAR_TYPE = 'vert';
XAXIS_SENSOR = '';
YMIN = NaN;
YMAX = NaN;
sensorLabel = '';
COLORMAP = jet(64);

% Process options
for x = 1:2:length(varargin)
    
    name = varargin{x};
    value = varargin{x+1};
    
    switch lower(name)
        case 'plotbathy'
            if isempty(value) ||...
                    ~islogical(value) ||...
                    ~isequal(numel(value),1)
                close(gcf);
                error(sprintf('%s:invalidOptionValue', app),...
                    'Value for option %s must be a true or false',...
                    name);              
            end
            PLOT_BATHY = value;
        case 'minbathy'
            if isempty(value) ||...
                    ~isequal(numel(value),1) ||...
                    ~isnumeric(value)
                close(gcf);
                error(sprintf('%s:invalidOptionValue', app),...
                    'Value for option %s must be a numeric scalar',...
                    name);
            end
            MIN_BATHY = value;
        case 'profiledir'
            if isempty(value) ||...
                    ~ischar(value) ||...
                    ~ismember(value, profileTypes)
                close(gcf);
                error(sprintf('%s:invalidOptionValue', app),...
                    'Value for option %s must be a non-empty string',...
                    name);
            end
            PRO_DIR = value;
        case 'starttime'
            if isempty(value) ||...
                   ~isequal(numel(value),1) ||...
                   ~isnumeric(value) 
               close(gcf);
               error(sprintf('%s:invalidOptionValue', app),...
                    'Value for option %s must be a datenum.m type',...
                    name);
            end
            t0 = value;
        case 'endtime'
            if isempty(value) ||...
                   ~isequal(numel(value),1) ||...
                   ~isnumeric(value) 
               close(gcf);
               error(sprintf('%s:invalidOptionValue', app),...
                    'Value for option %s must be a datenum.m type',...
                    name);
            end
            t1 = value;
        case 't0'
            if isempty(value) ||...
                   ~isequal(numel(value),1) ||...
                   ~isnumeric(value) 
               close(gcf);
               error(sprintf('%s:invalidOptionValue', app),...
                    'Value for option %s must be a datenum.m type',...
                    name);
            end
            t0 = value;
        case 't1'
            if isempty(value) ||...
                   ~isequal(numel(value),1) ||...
                   ~isnumeric(value) 
               close(gcf);
               error(sprintf('%s:invalidOptionValue', app),...
                    'Value for option %s must be a datenum.m type',...
                    name);
            end
            t1 = value;
        case 'colorbar'
            if isempty(value) ||...
                    ~ischar(value)
                close(gcf);
                error(sprintf('%s:invalidOptionValue', app),...
                    'Value for option %s must be a non-empty string',...
                    name);
            end
            m = strncmpi(value, cbarTypes, 1);
            if ~any(m)
                close(gcf);
                warning([mfilename ':invalidOptionValue'],...
                    ['Value for option ' name ' must be one of the following:']);
                return;
            end
            CBAR_TYPE = cbarTypes{m};
        case 'clim'
            if isempty(value) ||...
                    ~isequal(numel(value),2) ||...
                    ~all(isnumeric(value))
                close(gcf);
               error(sprintf('%s:invalidOptionValue', app),...
                    'Value for option %s must be a 2-element numeric array',...
                    name);
            end
            CLIM = value;
        case 'xsensor'
            if isempty(value) ||...
                    ~ischar(value) ||...
                    ~ismember(value, obj.sensors)
                close(gcf);
                error(sprintf('%s:invalidOptionValue', app),...
                    'Option %s: sensor does not exist',...
                    name);
            end
            XAXIS_SENSOR = value;
        case 'ymin'
            if ~isequal(numel(value),1) ||...
                    ~isnumeric(value)
                close(gcf);
                error(sprintf('%s:invalidOptionValue', app),...
                    'Value for option %s must be a numeric scalar',...
                    name);
            end
            YMIN = value;
        case 'ymax'
            if ~isequal(numel(value),1) ||...
                    ~isnumeric(value)
                close(gcf);
                error(sprintf('%s:invalidOptionValue', app),...
                    'Value for option %s must be a numeric scalar',...
                    name);
            end
            YMAX = value;
        case 'sensorlabel'
            if isempty(value) || ~ischar(value)
                close(gcf);
                error(sprintf('%s:invalidOptionValue', app),...
                    'Value for option %s must be a non-empty string',...
                    name);
            end
            sensorLabel = value;
        case 'colormap'
            if ~isnumeric(value) ||...
                    isempty(value) ||...
                    ~isequal(size(value,2), 3)
                close(gcf);
                error(sprintf('%s:invalidOptionValue', app),...
                    'Value for option %s must be an Mx3 array',...
                    name);
            end
            COLORMAP = value;
        otherwise
            close(gcf);
            error(sprintf('%s:invalidOption', app),...
                    'Invalid option specified: %s',...
                    name);
    end
end

set(gcf, 'Visible', 'on');

% Variable to hold bathymetry if we're going to plot it
bathy = [];

% Get the data
if isempty(XAXIS_SENSOR)
    
    % If no x-axis sensor was specified, we'll use the timestamp values
    % from obj.timestampSensors.  We need to check each instance to see if
    % the obj.dbds(x).timestampSensor is a unix timestamp and switch it the
    % corresponding datenum sensor.  Keep track of the indices as we'll
    % need to change it back to the original sensor once we're done since
    % the DbdGroup is a reference to the data structure
    epoch_matches = regexp(obj.timestampSensors, '_datenum$');
    % Find the Dbd instance index where the match failed
    r = find(cellfun(@isempty, epoch_matches) == 1);
    for x = 1:length(r)
        obj.dbds(r(x)).timestampSensor = sprintf('drv_%s_datenum',...
            obj.dbds(r(x)).timestampSensor);
    end
    
    sensorList = {sensor,...
        'drv_proInds',...
        'drv_proDir',...
        }';
    [data, sensorList] = obj.toArray('sensors', sensorList,...
        't0', t0,...
        't1', t1);
    
    % Grab bathy data if plotting it
    if PLOT_BATHY
        if ismember('drv_m_present_time_datenum', obj.sensors)
            bathy_sensors = {'drv_m_present_time_datenum',...
                'm_water_depth',...
                }';
            bathy = obj.toArray('sensors', bathy_sensors,...
                't0', t0,...
                't1', t1);
            % Remove default timestamp and depth, keeping only the sensors
            % in bathy_sensors
            bathy(:,[1 2]) = [];
        else
            bathy = obj.toArray('sensors', 'm_water_depth',...
                't0', t0,...
                't1', t1);
            % Remove default depth, keeping timestamp and m_water_depth
            bathy(:,2) = [];
        end
        
        % Fill in missing timestamps if there are any
        if any(isnan(bathy(:,1)))
            bathy(:,1) = fillMissingValues(bathy(:,1),...
                'interpmethod', 'linear');
        end
        bathy(any(isnan(bathy),2),:) = [];

    end
    
else
    sensorList = {XAXIS_SENSOR,...
        sensor,...
        'drv_proInds',...
        'drv_proDir',...
        }';
    [data, sensorList] = obj.toArray('sensors', sensorList);
    % Reorder the data: time, xaxis, yaxis, sensor, drv_proInds, drv_proDir
    data = data(:,[3 2 4:end]);
    sensorList = sensorList([3 2 4:end]);
    
    % Grab bathy data if plotting it
    if PLOT_BATHY
        bathy = obj.toArray('sensors', {XAXIS_SENSOR, 'm_water_depth'},...
            't0', t0,...
            't1', t1);
        bathy(:,1:2) = [];
        % Fill in missing timestamps if there are any
        if any(isnan(bathy(:,1)))
            bathy(:,1) = fillMissingValues(bathy(:,1),...
                'interpmethod', 'linear');
        end
        bathy(any(isnan(bathy),2),:) = [];
    end
end

% Change the obj.dbds(x).timestampSensor values back to their epoch time,
% if used
for x = 1:length(r)
    obj.dbds(r(x)).timestampSensor = obj.dbds(r(x)).timestampSensor(5:end-8);
end

% Get rid of all rows containing at least one nan
data(any(isnan(data),2),:) = [];
if isempty(data)
    fprintf(2,...
        'Dataset contains no valid records.\n');
    return;
end

% Eliminate other profile types if specified by the user via the 'protype'
% option
switch PRO_DIR(1)
    case 'd'
        data(data(:,5) >= 0,:) = [];
    case 'u'
        data(data(:,5) <= 0,:) = [];
end

% Set up color bounds
if isempty(CLIM)
    CLIM = [min(data(:,3)) max(data(:,3))];
end

% Plot the data
h = fastScatter(data(:,1), data(:,2), data(:,3),...
    'colorbar', CBAR_TYPE,...
    'colormap', COLORMAP,...
    'clim', CLIM);

% Find the axes in the current figure
ax = findobj(gcf, 'Type', 'axes');
% Store the data axes, which was created first and has a lower handle
% number
data_ax = min(ax);

% Figure formatting
set(gcf,...
    'PaperPosition', [0 0 11 8.5]);

if ~isempty(bathy)
    if ~isnan(MIN_BATHY)
        bathy(bathy(:,2) < MIN_BATHY,:) = [];
    end
end

% Find the maximum depth of the sensor data
MAX_DEPTH = max(data(:,2));

if ~isempty(bathy)
    % Since we're plotting bathymetry, we need to find the maximum depth of
    % both the bathymetry and the sensors dataset
    MAX_DEPTH = max([bathy(:,2); data(:,2)]);
    bathy = [min(bathy(:,1)) MAX_DEPTH+BATHY_OFFSET;...
        bathy;...
        max(bathy(:,1)) MAX_DEPTH+BATHY_OFFSET];
    % Plot it
    hb = fill(bathy(:,1), bathy(:,2), 'k');
    set(hb, 'Tag', 'bathy');
end

% Set min/max values for y-axis (defaults to min/max values if not specified 
% by 'ymin'/'ymax' options)
if isnan(YMIN)
    YMIN = 0;
end
if isnan(YMAX)
    YMAX = MAX_DEPTH;
end    

% Label the colorbar if it exists
cb = findobj(gcf, 'Tag', 'Colorbar');
if ~isempty(cb)
    if ~isempty(sensorLabel)
        cbarLabel = [sensorLabel ' (' obj.sensorUnits.(sensor) ')'];
    else
        cbarLabel = [sensor ' (' obj.sensorUnits.(sensor) ')'];
    end
    ylabel(cb,...
        cbarLabel,...
        'Interpreter', 'None');
end

% Set t0 and t1 to the minimum and maximum timestamp values, respectively
if isnan(t0)
	t0 = min(obj.startDatenums);
end
if isnan(t1)
	t1 = max(obj.endDatenums);
end

% Format axes
axis tight;
% Save the dataaspectrio
dasp = get(data_ax, 'DataAspectRatio');
set(data_ax,...
    'ydir', 'reverse',...
    'ylim', [YMIN YMAX],...
    'xlim', [t0 t1],...
    'box', 'on',...
    'tickdir', 'out',...
    'linewidth', 1,...
    'DataAspectRatio', [dasp(1)/2 dasp(2:3)]);

% Title the plot
tString = [obj.dbds(1).glider...
    ': '...
    datestr(t0, 'yyyy-mm-dd HH:MM')...
    ' - '...
    datestr(t1, 'yyyy-mm-dd HH:MM')...
    ' GMT'];
title(tString,...
    'Interpreter', 'None',...
    'FontSize', 14);

fname_template = [datestr(t0,'yyyymmddTHHMM')...
    '-'...
    datestr(t1,'yyyymmddTHHMM')...
    '_'...
    regexprep(sensor, '\_', '-')];
