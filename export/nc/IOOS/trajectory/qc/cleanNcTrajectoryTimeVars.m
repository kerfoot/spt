function clean_sensor_data = cleanNcTrajectoryTimeVars(sensor_data, varargin)
% 
% clean_sensor_data = cleanNcTrajectoryTimeVars(sensor_data, varargin)
%
% Remove NaN values from the 'time' coordinate variable and all data variables
% that are dimensioned along the 'time' coordinate.  The input argument
% (sensor_data) is a structure array returned by selectDbdTrajectoryData.m.
%
% See also selectDbdTrajectoryData GTrajectoryNc
%

clean_sensor_data = [];

app = mfilename;

% Required fields
REQUIRED_VARS = {'ncVarName',...
    'sensor',...
    'data',...
    }';
% Do not check the following variables
EXCLUDE_VARS = {'time',...
    'time_uv',...
    'trajectory',...
    'lat_uv',...
    'lon_uv',...
    'u',...
    'u_qc',...
    'v',...
    'v_qc',...
    'platform',...
    'instrument_ctd',...
    }';

% Validate inputs
if isequal(nargin,0)
    error(sprintf('%s:nargin', app),...
        'No NetCDF variable data structure specified');
elseif isempty(sensor_data) ||...
        ~isstruct(sensor_data) ||...
        ~isequal(length(intersect(fieldnames(sensor_data), REQUIRED_VARS)),length(REQUIRED_VARS))
    error(sprintf('%s:nargin', app),...
        'Invalid NetCDF variable data structure');
end

% Default options
KEEP_ALL = false;    
% Process options

% Copy sensor_data to clean_sensor_data
clean_sensor_data = sensor_data;

% List of NetCDF variable names in sensor_data
nc_vars = {sensor_data.ncVarName}';

% Find the 'time' variable
[tf, t_ind] = ismember('time', nc_vars);
if ~tf
    error(sprintf('%s:variableNotFound', app),...
        'NetCDF variable data structured is missing the ''time'' variable');
end
% Count the number of time records
num_ts = length(sensor_data(t_ind).data);
% Find the NaN rows
nan_rows = find(isnan(sensor_data(t_ind).data));
num_nans = length(nan_rows);
% % % % % fprintf(1,...
% % % % %     '''time'' coordinate contains no NaN rows\n');
if isequal(num_nans,0)
    return;
elseif isequal(num_nans, num_ts)
    warning(sprintf('%s:noTimeVariableData', app),...
        'NetCDF data structure contains no valid timestamps\n');
    return;
end

% Remove the nans from the time variable
clean_sensor_data(t_ind).data(nan_rows) = [];
% Count the number of good time values
num_clean_times = length(clean_sensor_data(t_ind).data);

% List of variables to examine
check_vars = setdiff(nc_vars, EXCLUDE_VARS);

% The 'time' variable is a coordinate variable and cannot contain NaN
% values.  So we need to find the rows in this var that have NaNs and
% remove those rows from the other variables in the data structure not
% contained in EXCLUDE_VARS
for v = 1:length(check_vars)
    
    % Find the location of the variable
    [tf, v_ind] = ismember(check_vars{v}, nc_vars);
    if ~tf
        continue;
    end
    
    % Count the number of records in the variable data
    num_records = length(clean_sensor_data(v_ind).data);
    
    % Compare the number of records in this variable to t and display a
    % warning if the 2 numbers are not equal.
    % SPECIAL CASE: If the data array is empty, fill it with an array of
    % nans equal to the number of non-NaN time values
    if isequal(num_records,0)
        clean_sensor_data(v_ind).data = nan(num_clean_times,1);
    elseif ~isequal(num_ts, num_records)
        warning(sprintf('%s:numVariableRecords', app),...
            'Skipping %s: The number of records in data variable (%0.0f) does not equal the time steps (%0.0f)',...
            check_vars{v},...
            num_records,...
            num_ts);
        continue;
    end
    
    % Remove the NaN rows from the variable data
    clean_sensor_data(v_ind).data(nan_rows) = [];
    
end
