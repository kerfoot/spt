function dgroup = dbds2DbdGroup(dbd_list, varargin)
%
% dgroup = dbds2DbdGroup(dbd_list[,DbdGroup, varargin])
%
% Creates a new DbdGroup instance containing the Dbd instances created from
% the files contained in dbd_list.  Default timestamp and depth sensors are
% used.  The following measured/derived CTD sensors are added to the instance:
%
%   'drv_sea_water_temperature'
%   'drv_sea_water_electrical_conductivity'
%   'drv_sea_water_salinity'
%   'drv_sea_water_density'
%   'drv_sea_water_potential_temperature'
%   'drv_speed_of_sound_in_sea_water'
%
% If a valid DbdGroup instance is specified as an optional second argument,
% the Dbd instances are added to this DbdGroup.
%
% Options must be specified as name, value pairs:
%
%   'sensors', [CELL ARRAY]
%       List of sensor names to include in each Dbd instance.
%
%   'timestampsensor', [STRING or CELL ARRAY]
%       Sensor name to be used as the timestamp sensor, Dbd.timestampSensor, 
%       for each Dbd instance, if available.  If not available, a default
%       sensor is chosen automatically.
%
%   'depthsensor', [STRING or CELL ARRAY]
%       Sensor name to be used as the depth sensor, Dbd.depthSensor, for each 
%       Dbd instance, if available.  If not available, a default sensor is 
%       chosen automatically.
%
%   'replace', [LOGICAL]
%       Set to true to replace existing Dbd instances for which the size of 
%       the source data file has changed.  Default is true.
%
%   'fillgps', [LOGICAL]
%       Set to true to linearly interpolate measured gps fixes and store the
%       values ('drv_longitude' and 'drv_latitude').  Interpolation is 
%       only performed on segments in which the segment is bound by a pre-dive
%       and post-dive gps fix, which is specified by the 'hasBoundingGps' 
%       property of the Dbd instance.  Default is true.
%
%   'deletesource', [LOGICAL]
%       Set to true to delete the source data file after processing, 
%       regardless of whether a Dbd instance was added to the DbdGroup 
%       instance.  Default is false.
%
%   'addctdsensors', [LOGICAL]
%       Set to false to prevent the addition of derived CTD parameters.
%
%   'promintimespan', [NUMBER]
%       Number of seconds an indexed profile must span to be considered a
%       profile.  The default value is set when an instance of the Dbd
%       class is created.
%
%   'promindepthspan', [NUMBER]
%       Number of meters an indexed profile must span to be considered a
%       profile.  The default value is set when an instance of the Dbd class 
%       is created.
%
%   'promindepth', [NUMBER]
%       The minumum depth, in meters, that may be used when indexing profiles.
%       The default value is set when an instance of the Dbd class 
%       is created.
%
%   'prominnumpoints', [NUMBER]
%       Minimum number of points that an indexed profile must contain to be
%       considered a profile.  The default value is set when an instance of 
%       the Dbd class is created.
%
% ============================================================================
% $RCSfile: dbds2DbdGroup.m,v $
% $Source: /home/kerfoot/cvsroot/slocum/matlab/spt/proc/dbds2DbdGroup.m,v $
% $Revision: 1.1.1.1 $
% $Date: 2013/09/13 18:51:18 $
% $Author: kerfoot $
% ============================================================================
%

app = mfilename;

% Validate first argument, which must be either a string or cell array of
% strings specifying filenames to process
if isequal(nargin,0)
    error(sprintf('%s:nargin', app),...
        'You must specify a dbd filename or cell array of filenames to process.');
elseif isempty(dbd_list)
    error(sprintf('%s:invalidArg', app),...
        'The dbd file list is empty.');
elseif ischar(dbd_list)
    dbd_list = {dbd_list}';
elseif ~iscellstr(dbd_list)
    error(sprintf('%s:nargin', app),...
        'You must specify a dbd filename or cell array of filenames to process.');
end

% If an odd number of varargin args are specified, check the first one to see 
% if it's a DbdGroup instance.  If it is, we'll add new Dbd instances to
% it.  If it's NOT an instance of the DbdGroup class, throw an error
if isequal(mod(length(varargin),2),1)
    
    % Throw an error if the first varargin arg is not an instance of the
    % DbdGroup class
    if ~isa(varargin{1}, 'DbdGroup')
        error(sprintf('%sDbdGroup', app),...
            'Argument must be an instance of the DbdGroup class.');
    end
    
    % Store the DbdGroup instance 
    dgroup = varargin{1};
    varargin(1) = [];

elseif ~isequal(mod(length(varargin),2),0)
    
    % If no DbdGroup was specified as the first varargin arg, make sure an
    % even number of name,value options was specified.  If not, throw an
    % error
    error(sprintf('%s:varargin', app),...
        'Invalid number of options specified.');
    
else
    dgroup = DbdGroup();
end

% Valid interpolation methods for 'fillgps', 'filltimes' & 'filldepths'
INTERP_METHODS = {'none',...
    'nearest',...
    'linear',...
    'spline',...
    'pchip',...
    'cubic',...
    'v5cubic',...
    }';

% Default options
SENSOR_LIST = {};
TIMESTAMP_SENSORS = {};
DEPTH_SENSORS = {};
REPLACE = true;
FILL_TIMES = '';
FILL_DEPTHS = '';
FILL_GPS = 'linear';
DELETE_DBDS = false;
CTD_SENSORS = true;
PRO_MIN_TIME_SPAN = NaN;
PRO_MIN_NUM_POINTS = NaN;
PRO_MIN_DEPTH = NaN;
PRO_MIN_DEPTH_SPAN = NaN;
CONVERT_GPS = true;
% Set to false to prevent saving of individual dbd instances
SAVE_DBD_DIR = '';
for x = 1:2:length(varargin)
    
    name = varargin{x};
    value = varargin{x+1};
    
    switch lower(name)
        
        case 'sensors'
            if ischar(value)
                value = {value}';
            elseif ~iscellstr(value)
                error(sprintf('%s:invalidOptionValue', app),...
                    'Value for option must be a string or cell array of strings.');
            end
            SENSOR_LIST = value;
            
        case 'timestampsensor'
            if ischar(value)
                value = {value}';
            elseif ~iscellstr(value)
                error(sprintf('%s:invalidOptionValue', app),...
                    ['Value for option %s must be a string or cell array '...
                    'of strings specifying a Dbd timestamp sensor.\n'],...
                    name);
            end
            TIMESTAMP_SENSORS = value;
            
        case 'depthsensor'
            if ischar(value)
                value = {value}';
            elseif ~iscellstr(value)
                error(sprintf('%s:invalidOptionValue', app),...
                    ['Value for option %s must be a string or cell array '...
                    'of strings specifying a Dbd depth sensor.\n'],...
                    name);
            end
            DEPTH_SENSORS = value;
            
        case 'replace'
            if ~isequal(numel(value),1) || ~islogical(value)
                error(sprintf('%s:invalidOptionValue', app),...
                    'Value for option %s must be a logical scalar.',...
                    name);
            end
            REPLACE = value;
            
        case 'filltimes'
            if ~isempty(value) && ~ischar(value)
                error(sprintf('%s:invalidOptionValue', app),...
                    'Value for option %s must be a valid interp1 interpolation method.',...
                    name);
            elseif isempty(value)
                error(sprintf('%s:invalidOptionValue', app),...
                    'No value specified for option %s.',...
                    name);
            elseif ~ismember(lower(value), INTERP_METHODS)
                 error(sprintf('%s:invalidOptionValue', app),...
                    '%s for option %s is not a valid interp1 interpolation method.',...
                    value,...
                    name);
            end
            FILL_TIMES = lower(value);
            
        case 'filldepths'
            if ~isempty(value) && ~ischar(value)
                error(sprintf('%s:invalidOptionValue', app),...
                    'Value for option %s must be a valid interp1 interpolation method.',...
                    name);
            elseif isempty(value)
                error(sprintf('%s:invalidOptionValue', app),...
                    'No value specified for option %s.',...
                    name);
            elseif ~ismember(lower(value), INTERP_METHODS)
                 error(sprintf('%s:invalidOptionValue', app),...
                    '%s for option %s is not a valid interp1 interpolation method.',...
                    value,...
                    name);
            end
            FILL_DEPTHS = lower(value);
            
        case 'fillgps'
            if ~isempty(value) && ~ischar(value)
                error(sprintf('%s:invalidOptionValue', app),...
                    'Value for option %s must be a valid interp1 interpolation method.',...
                    name);
            elseif isempty(value)
                error(sprintf('%s:invalidOptionValue', app),...
                    'No value specified for option %s.',...
                    name);
            elseif ~ismember(lower(value), INTERP_METHODS)
                 error(sprintf('%s:invalidOptionValue', app),...
                    '%s for option %s is not a valid interp1 interpolation method.',...
                    value,...
                    name);
            end
            FILL_GPS = lower(value);
            
        case 'deletesource'
            if ~isequal(numel(value),1) || ~islogical(value)
                error(sprintf('%s:invalidOptionValue', app),...
                    'Value for option %s must be a logical scalar.',...
                    name);
            end
            DELETE_DBDS = value;
            
         case 'addctdsensors'
            if ~isequal(numel(value),1) || ~islogical(value)
                error(sprintf('%s:invalidOptionValue', app),...
                    'Value for option %s must be a logical scalar.',...
                    name);
            end
            CTD_SENSORS = value;
            
        case 'promintimespan'
            if ~isequal(numel(value),1) || ~isnumeric(value)
                error(sprintf('%s:invalidOptionValue', app),...
                    'Value for option %s must be a numeric scalar.',...
                    name);
            end
            PRO_MIN_TIME_SPAN = value;
            
        case 'prominnumpoints'
            if ~isequal(numel(value),1) || ~isnumeric(value)
                error(sprintf('%s:invalidOptionValue', app),...
                    'Value for option %s must be a numeric scalar.',...
                    name);
            end
            PRO_MIN_NUM_POINTS = value;
            
        case 'promindepth'
            if ~isequal(numel(value),1) || ~isnumeric(value)
                error(sprintf('%s:invalidOptionValue', app),...
                    'Value for option %s must be a numeric scalar.',...
                    name);
            end
            PRO_MIN_DEPTH = value;
            
        case 'promindepthspan'
            if ~isequal(numel(value),1) || ~isnumeric(value)
                error(sprintf('%s:invalidOptionValue', app),...
                    'Value for option %s must be a numeric scalar.',...
                    name);
            end
            PRO_MIN_DEPTH_SPAN = value;
            
        case 'convertgps'
            if ~isequal(numel(value),1) || ~islogical(value)
                error(sprintf('%s:invalidOptionValue', app),...
                    'Value for option %s must be a logical scalar.',...
                    name);
            end
            CONVERT_GPS = value;
            
        case 'dbddir'
            if ~ischar(value) || ~isdir(value)
                error(sprintf('%s:invalidOptionValue', app),...
                    'Value for %s must be a string specifying a valid directory',...
                    name);
            end
            SAVE_DBD_DIR = value;
            
        otherwise
            error('dbds2DbdGroup:invalidOption',...
                'Invalid option: %s.',...
                name);
    end
end

% Display options
if REPLACE
    fprintf(1,...
        '>> Updating Dbd instances if the file size changes.\n');
end
if FILL_GPS
    fprintf(1,...
        '>> Filling GPS fixes.\n');
end

% Set FILL_GPS to an empty string if 'none' specified
% % % % % if strcmp(FILL_GPS, 'none')
% % % % %     FILL_GPS = '';
% % % % % end

for d = 1:length(dbd_list)
    
% % % % %     if isequal(d,53)
% % % % %         keyboard;
% % % % %     end
    
    % Create the Dbd instance
    try
        dbd = Dbd(dbd_list{d},...
            'sensors', SENSOR_LIST);
    catch ME
        fprintf(2,...
            'Skipping source file: %s (%s: %s)\n',...
            dbd_list{d},...
            ME.identifier,...
            ME.message);
        continue;
    end
    
    % Check the DbdGroup.segments to see if this file has already been
    % processed
    [Y,I] = ismember(dbd.segment, dgroup.segments);
    if Y
        fprintf(1,...
            '%s: DbdGroup already contains the Dbd instance.\n',...
            dbd.segment);
        if REPLACE && ~isequal(dbd.bytes, dgroup.bytes(I))
            % If we're replacing files when the file size changes (via the
            % 'replace' option, check the filesize and remove the Dbd
            % instance if it has changed
            fprintf(2,...
                '%s: Filesize has changed.  Updating Dbd instance.\n',...
                dbd.segment);
            dgroup.removeDbd(dbd.segment);
        else
            if DELETE_DBDS
                fprintf(1,...
                    'Deleting source file: %s...\n',....
                    dbd_list{d});
                delete(dbd_list{d});               
            end
            continue;
        end
    end
    
    fprintf(1,...
        ' > Adding Dbd instance: %s\n',...
        dbd.segment);
    
    % Try to set the Dbd instance's timestamp sensor
    [C,AI] = intersect(TIMESTAMP_SENSORS, dbd.dbdTimestampSensors);
    if ~isempty(C)
        fprintf(1,...
            'Setting Dbd instance timestamp sensor: %s\n',...
            TIMESTAMP_SENSORS{min(AI)});
        dbd.timestampSensor = TIMESTAMP_SENSORS{min(AI)};
    end
    
    % Try to set the Dbd instance's depth sensor
    [C,AI] = intersect(DEPTH_SENSORS, dbd.dbdDepthSensors);
    if ~isempty(C)
        fprintf(1,...
            'Setting Dbd instance depth sensor: %s\n',...
            DEPTH_SENSORS{min(AI)});
        dbd.depthSensor = DEPTH_SENSORS{min(AI)};
    end
    
    % Interpolate Dbd.timestampSensor
    if ~isempty(FILL_TIMES)
        fprintf(1,...
            'Dbd.timestampSensor values will be filled using %s interpolation.\n',...
            FILL_TIMES);
        dbd.fillTimes = FILL_TIMES;
    end
    
    % Interpolate Dbd.depthSensor
    if ~isempty(FILL_DEPTHS)
        fprintf(1,...
            'Dbd.depthSensor values will be filled using %s interpolation.\n',...
            FILL_DEPTHS);
        dbd.fillTimes = FILL_DEPTHS;
    end
    
    % Interpolate gps fixes for Dbd instances that have bounding gps fixes
    % (.hasBoundingGps)
    if ~isempty(FILL_GPS) && dbd.hasBoundingGps
        dbd.fillGps = FILL_GPS;
    end
    
    % Change Dbd.proMinTimeSpan if specified via option
    if ~isnan(PRO_MIN_TIME_SPAN)
        fprintf(1,...
            'Setting new profile indexing minimum time span: %0.0f\n',...
            PRO_MIN_TIME_SPAN);
        dbd.proMinTimeSpan = PRO_MIN_TIME_SPAN;
    end
    
    % Change Dbd.proMinNumPoints if specified via option
    if ~isnan(PRO_MIN_NUM_POINTS)
        fprintf(1,...
            'Setting new profile indexing minimum number of points: %0.0f\n',...
            PRO_MIN_NUM_POINTS);
        dbd.proMinNumPoints = PRO_MIN_NUM_POINTS;
    end
    
    % Change Dbd.proMinDepth if specified via option
    if ~isnan(PRO_MIN_DEPTH)
        fprintf(1,...
            'Setting new profile indexing minimum depth: %0.2f\n',...
            PRO_MIN_DEPTH);
        dbd.proMinDepth = PRO_MIN_DEPTH;
    end
    
    % Change Dbd.proMinDepthSpan if specified via option
    if ~isnan(PRO_MIN_DEPTH_SPAN)
        fprintf(1,...
            'Setting new profile indexing minimum depth span: %0.0f\n',...
            PRO_MIN_DEPTH_SPAN);
        dbd.proMinDepthSpan = PRO_MIN_DEPTH_SPAN;
    end
    
    % Derive and add ctd sensors if specified via the 'addctdsensors'
    % option
    if CTD_SENSORS
        addDbdCtdSensors(dbd);
    end
    
    % Convert m_gps_lon and m_gps_lat to decimal degrees, if they exist, and 
    % add as drv_m_gps_lat and drv_m_gps_lon
    if CONVERT_GPS
        convertDbdGps(dbd);
    end
    
    % Save the Dbd instance if SAVE_DBD_DIR contains a valid directory
    if ~isempty(SAVE_DBD_DIR)
        try
            dbd_file = fullfile(SAVE_DBD_DIR, [dbd.segment '_Dbd_qc0.mat']);
            fprintf('%s: Saving Dbd instance %s\n',...
                app,...
                dbd_file);
            save(dbd_file, 'dbd');
        catch ME
            warning('%s: %s\n',...
                ME.identifier,...
                ME.message);
        end
    end
    
    % Add the instance
    dgroup.addDbd(dbd);
    
    % Delete the source file if specified via the 'deletesource' option
    if DELETE_DBDS
        fprintf(1,...
            'Deleting source file: %s...\n',...
            dbd_list{d});
        delete(dbd_list{d});               
    end
end

