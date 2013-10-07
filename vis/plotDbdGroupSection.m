function iTemplate = plotDbdGroupSection(obj, sensor, varargin)
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
% $Revision: 1.3 $
% $Date: 2013/10/01 12:54:02 $
% $Author: kerfoot $
% $Name:  $
% ============================================================================
%

iTemplate = '';

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
MIN_BATHY = 1;
PRO_TYPE = 'all';
t0 = NaN;
t1 = NaN;
CLIM = [];
CBAR_TYPE = 'vert';
XAXIS_SENSOR = '';
YMIN = NaN;
YMAX = NaN;
sensorLabel = '';

% Process options
for x = 1:2:length(varargin)
    
    name = varargin{x};
    value = varargin{x+1};
    
    switch lower(name)
        case 'plotbathy'
            if isempty(value) ||...
                    ~islogical(value) ||...
                    ~isequal(numel(value),1)
                warning([mfilename ':invalidOptionValue'],...
                    ['Value for option ' name ' must be logical.']);
                return;
            end
            PLOT_BATHY = value;
        case 'minbathy'
            if isempty(value) ||...
                    ~isequal(numel(value),1) ||...
                    ~isnumeric(value)
                warning([mfilename ':invalidOptionValue'],...
                    ['Value for option ' name ' must be a 1-element number.']);
                return;
            end
            MIN_BATHY = value;
        case 'protype'
            if isempty(value) ||...
                    ~ischar(value) ||...
                    ~ismember(value, profileTypes)
                warning([mfilename ':invalidOptionValue'],...
                    ['Value for option ' name ' must be a non-empty string.']);
                return;
            end
            PRO_TYPE = value;
        case 'starttime'
            if isempty(value) ||...
                   ~isequal(numel(value),1) ||...
                   ~isnumeric(value) 
               warning([mfilename ':invalidOptionValue'],...
                   ['Value for option ' name ' must be of type datenum.']);
               return;
            end
            t0 = value;
        case 'endtime'
            if isempty(value) ||...
                   ~isequal(numel(value),1) ||...
                   ~isnumeric(value) 
               warning([mfilename ':invalidOptionValue'],...
                   ['Value for option ' name ' must be of type datenum.']);
               return;
            end
            t1 = value;
        case 't0'
            if isempty(value) ||...
                   ~isequal(numel(value),1) ||...
                   ~isnumeric(value) 
               warning([mfilename ':invalidOptionValue'],...
                   ['Value for option ' name ' must be of type datenum.']);
               return;
            end
            t0 = value;
        case 't1'
            if isempty(value) ||...
                   ~isequal(numel(value),1) ||...
                   ~isnumeric(value) 
               warning([mfilename ':invalidOptionValue'],...
                   ['Value for option ' name ' must be of type datenum.']);
               return;
            end
            t1 = value;
        case 'colorbar'
            if isempty(value) ||...
                    ~ischar(value)
                warning([mfilename ':invalidOptionValue'],...
                    ['Value for option ' name ' must be a non-empty string.']);
                return;
            end
            m = strncmpi(value, cbarTypes, 1);
            if ~any(m)
                warning([mfilename ':invalidOptionValue'],...
                    ['Value for option ' name ' must be one of the following:']);
                cbarTypes
                return;
            end
            CBAR_TYPE = cbarTypes{m};
        case 'clim'
            if isempty(value) ||...
                    ~isequal(numel(value),2) ||...
                    ~all(isnumeric(value))
                warning([mfilename ':invalidOptionValue'],...
                    ['Value for option ' name ' must be a 2-element numeric vector.']);
                return;
            end
            CLIM = value;
        case 'xsensor'
            if isempty(value) ||...
                    ~ischar(value) ||...
                    ~ismember(value, obj.sensors)
                warning([mfilename ':invalidOptionValue'],...
                    ['Value for option ' name ' must be an existing DbdGroup sensor.']);
                return;
            end
            XAXIS_SENSOR = value;
        case 'ymin'
            if ~isequal(numel(value),1) ||...
                    ~isnumeric(value)
                warning([mfilename ':invalidOptionValue'],...
                    ['Value for option ' name ' must be a 1-element number.']);
                return;
            end
            YMIN = value;
        case 'ymax'
            if ~isequal(numel(value),1) ||...
                    ~isnumeric(value)
                warning([mfilename ':invalidOptionValue'],...
                    ['Value for option ' name ' must be a 1-element number.']);
                return;
            end
            YMAX = value;
        case 'sensorlabel'
            if isempty(value) || ~ischar(value)
                fprintf(1,...
                    'Value for option %s must be a string.\n',...
                    value);
                return;
            end
            sensorLabel = value;
        otherwise
            warning([mfilename ':invalidOption'],...
                ['Invalid option: ' name]);
            return;
    end
end

% If MIN_BATHY is non-NaN, set PLOT_BATHY to true as we'll assume if the user
% entered a min bathymetry value, they want to plot the bathymetry
if MIN_BATHY >= 1
    PLOT_BATHY = true;
end
% Variable to hold bathymetry if we're going to plot it
bathy = [];

% Get the data
if isempty(XAXIS_SENSOR)
    sensorList = {sensor,...
        'drv_proInds',...
        'drv_proDir',...
        }';
    [data, sensorList] = obj.toArray('sensors', sensorList,...
        't0', t0,...
        't1', t1);
    
    % Grab bathy data if plotting it
    if PLOT_BATHY
        bathy = obj.toArray('sensors', 'm_water_depth',...
            't0', t0,...
            't1', t1);
        % Fill in missing timestamps if there are any
        if any(isnan(bathy(:,1)))
            bathy(:,1) = fillMissingValues(bathy(:,1),...
                'interpmethod', 'linear');
        end
        bathy(any(isnan(bathy),2),:) = [];
        bathy(:,2) = [];
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

% Get rid of all rows containing at least one nan
data(any(isnan(data),2),:) = [];
if isempty(data)
    fprintf(2,...
        'Dataset contains no valid records.\n');
    return;
end

% Eliminate other profile types if specified by the user via the 'protype'
% option
switch PRO_TYPE(1)
    case 'd'
        data(data(:,5) >= 0,:) = [];
    case 'u'
        data(data(:,5) <= 0,:) = [];
end

% Set up color bounds
if isempty(CLIM)
    CLIM = [min(data(:,3)) max(data(:,3))];
end

% Create the figure
figure('PaperPosition', [0 0 11 8.5]);

% Plot the data
h = fast_scatter(data(:,1), data(:,2), data(:,3),...
    'colorbar', CBAR_TYPE,...
    'clim', CLIM);

if ~isempty(bathy)
    if ~isnan(MIN_BATHY)
        bathy(bathy(:,2) < MIN_BATHY,:) = [];
    end
end

if ~isempty(bathy)
    bathy = [min(bathy(:,1)) max(bathy(:,2)) + BATHY_OFFSET;...
        bathy;...
        max(bathy(:,1)) max(bathy(:,2)) + BATHY_OFFSET];
    % Plot it
    hb = fill(bathy(:,1), bathy(:,2), 'k');
    set(hb, 'Tag', 'bathy');
end

% Set min/max values for y-axis (defaults to min/max values if not specified 
% by 'ymin'/'ymax' options)
if isnan(YMIN);
    z = data(~isnan(data(:,2)),2);
    YMIN = min(z);
end
if isnan(YMAX)
    z = [bathy(:,2); data(:,2)];
    z(isnan(z)) = [];
    YMAX = max(z);
end    
    
% Format axes
axis tight;
dasp = get(gca, 'DataAspectRatio');
set(gca,...
    'ydir', 'reverse',...
    'ylim', [YMIN YMAX],...
    'box', 'on',...
    'tickdir', 'out',...
    'linewidth', 1,...
    'DataAspectRatio', [dasp(1)/2 dasp(2:3)]);

% Label the colorbar if it exists
cb = findobj('Tag', 'Colorbar');
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
if isnan(t0) || isnan(t1)
    ts = obj.toArray('sensors', {'null'});
    if isnan(t0)
        t0 = min(ts(:,1));
    end
    if isnan(t1)
        t1 = max(ts(:,1));
    end
end
% Convert unix times (which appear to be very large datenums) to datenums
if t0 > datenum(3000,1,1,0,0,0)
    t0 = epoch2datenum(t0);
end
if t1 > datenum(3000,1,1,0,0,0)
    t1 = epoch2datenum(t1);
end

% Title the plot
tString = [obj.dbds(1).glider...
    ': '...
    datestr(t0, 'yyyy-mm-dd HH:MM')...
    ' - '...
    datestr(t1, 'yyyy-mm-dd HH:MM')...
    ' GMT'];
title(tString, 'FontSize', 14);

iTemplate = [datestr(t0,'yyyymmddTHHMM')...
    '-'...
    datestr(t1,'yyyymmddTHHMM')...
    '_'...
    regexprep(sensor, '\_', '-')];
