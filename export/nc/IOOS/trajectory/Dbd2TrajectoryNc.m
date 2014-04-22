function [nc_file, sensor_data] = Dbd2TrajectoryNc(dbd, varargin)
%
% [nc_file, sensor_data] = Dbd2TrajectoryNc(dbd, varargin)
%
% Write a Trajectory NetCDF file containing the Dbd instance data.  The
% file conforms to the IOOS National Glider Network conventions:
%
% https://github.com/IOOSProfilingGliders/Real-Time-File-Format
%
% The NetCDF file is written using the toNc method of the GTrajectoryNc
% class, which interally uses a NetCDF template file.  The location of the
% template file is contained in the schemaNcTemplate property of the
% GTrajectory instance.
%
% The output file (nc_file) is written to the current working directory and
% named using the following convention:
%
%   glider-YYYYmmddTHHMMSS_rt0.nc
%
% All sensor data is written as contained in the Dbd instance.  This means
% you must be aware of the Dbd.fillTimes, Dbd.fillDepths and Dbd.fillGps
% properties.  The 'time' coordinate variable is checked for missing values
% (NaN) and all missing value record indices are removed from the data 
% variables.
%
% NetCDF variable data is mapped to native Slocum glider sensors in
% getTrajectorySensorMappings.m, which is called by 
% selectDbdTrajectoryData.m.  Currently, you must add sensors to
% getTrajectorySensorMappings.m directly to change the default sensor
% mappings.
%
% Options must be specified as name, value pairs:
%
%   'outputdir', [STRING]
%       Write NetCDF file to an alternate location.  Default is the current
%       working directory.
%
%   'interpsensors', [CELL_ARRAY]
%       Interpolate the sensors contained in the cell array prior to 
%       writing to the NetCDF file.  Default is for no interpolation.
%
%   'interpallsensors', [LOGICAL]
%       Interpolate all sensors prior to writing the NetCDF file.
%       Overrrides 'interpsensors' option.  Default is false.
%
%   'clobber', [LOGICAL]
%       Overwrite the existing file, if it exists.  Default is false.
%
%   'wmoid', [STRING]
%       WMO ID assigned to this deployment.  If specified, the 'wmo_id'
%       attribute of the platform variable is set to this value.
%
% See also GTrajectoryNc selectDbdTrajectoryData getTrajectorySensorMappings
% ============================================================================
% $RCSfile: Dbd2TrajectoryNc.m,v $
% $Source: /home/kerfoot/cvsroot/slocum/matlab/spt/export/nc/IOOS/trajectory/Dbd2TrajectoryNc.m,v $
% $Revision: 1.5 $
% $Date: 2014/04/22 20:24:38 $
% $Author: kerfoot $
% ============================================================================
%

% Absolute path to the created NetCDF trajectory file
nc_file = '';

app = mfilename;

% Validate arguments
if isequal(nargin,0)
    error(sprintf('%s:nargin', app),...
        'No DbdGroup instance specified');
elseif ~isa(dbd, 'Dbd')
    error(sprintf('%s:invalidArgument', app),...
        'First argument is not a Dbd instance');
elseif ~isequal(mod(length(varargin),2),0)
    error(sprintf('%s:varargin', app),...
        'Invalid number of name,value options specified');
end

% Default options
OUTPUT_DIR = pwd;
INTERP_SENSORS = {};
INTERP_ALL_SENSORS = false;
CLOBBER = true;
WMO_ID = '';
GLOBAL_ATTRIBUTES = {};
% Process option
for x = 1:2:length(varargin)
    name = varargin{x};
    value = varargin{x+1};
    switch lower(name)
        case 'outputdir'
            if ~ischar(value) || ~isdir(value)
                error(sprintf('%s:invalidOptionValue', app),...
                    'Value for option %s must be of string specifying a valid directory',...
                    name);
            end
            OUTPUT_DIR = value;
        case 'interpsensors'
            if ~iscellstr(value)
                error(sprintf('%s:invalidOptionValue', app),...
                    'Value for option %s must be a cell array of strings',...
                    name);
            end
            INTERP_SENSORS = value;
        case 'interpallsensors'
            if ~isequal(numel(value),1) || ~islogical(value)
                error(sprintf('%s:invalidOptionValue', app),...
                    'Value for option %s must be a logical value',...
                    name);
            end
            INTERP_ALL_SENSORS = value;
        case 'clobber'
            if ~isequal(numel(value),1) || ~islogical(value)
                error(sprintf('%s:invalidOptionValue', app),...
                    'Value for option %s must be a logical value',...
                    name);
            end
            CLOBBER = value;
        case 'wmoid'
            if ~ischar(value)
                warning(sprintf('%s:invalidOptionValue', app),...
                    'Value for option %s must be a string specifying a valid WMO id',...
                    name);
                continue;               
            end
            WMO_ID = value;
        case 'globalattributes'
            if ~isstruct(value) || ~isequal(length(value),1)
                error(sprintf('%s:invalidOptionValue', app),...
                    'Value for option %s must be a structured array mapping file attributes to values',...
                    name);
            end
            GLOBAL_ATTRIBUTES = value;
        otherwise
            error(sprintf('%s:invalidOption', app),...
                'Invalid option specified: %s',...
                name);
    end
end

% Create the NetCDF file name
nc_file = fullfile(OUTPUT_DIR,...
    sprintf('%s-%s_rt0.nc',...
    dbd.glider,...
    datestr(dbd.startDatenum, 'yyyymmddTHHMMSS')));
% Check to see if the NetCDF file already exists.  If CLOBBER is true (via
% function option), delete the existing file so that we can write a new one
if exist(nc_file, 'file')
    if CLOBBER
        fprintf(2,...
            'Clobbering existing NetCDF file: %s\n',...
            nc_file);
        delete(nc_file);
    else
        warning(sprintf('%s:fileExists', app),...
            'NetCDF file already exists: %s\n',...
            nc_file);
        return;
    end
end

if INTERP_ALL_SENSORS
    fprintf('%s: Interpolating all sensor data arrays and setting corresponding qc flag values\n',...
        app);
end

% Process the Dbd instance

% Check to see if any profile were indexed.  If not, no need to write
% the NetCDF file
if isequal(dbd.numProfiles,0)
    fprintf('Segment %s contains no indexed profiles\n',...
        dbd.segment);
    return;
end

% If the dbd.timestampSensor is formatted as datenums, set it to the
% corresponding unix timestamp sensor
if ~isempty(regexp(dbd.timestampSensor, '^drv_.*_datenum$', 'once'))
    dbd.timestampSensor = dbd.timestampSensor(5:end-8);
end

% Select the variable data 
[sensor_data, netcdf_template] = selectDbdTrajectoryData(dbd);
if isempty(sensor_data)
    nc_file = '';
    return;
end

fprintf(1,...
    'Dbd instance sensor data chosen: %s\n',...
    netcdf_template);

% List of all NetCDF variable names
sensor_vars = {sensor_data.ncVarName}';

% Make sure that the data structure contains a time variable
[~, T_INDEX] = ismember('time', sensor_vars);
% The time variable cannot be empty
if isempty(sensor_data(T_INDEX).data)
    error(sprintf('%s:emptyTimeVariable', app),...
        '%s: Segment contains to time values\n',...
        dbd.segment);
end

% Store the length of the time coordinate array
array_length = length(sensor_data(T_INDEX).data);

% SPECIAL CASE: Use the pressure values as a proxy for the depth variable data
% if the depth array is empty
[TF,zr] = ismember('depth', sensor_vars);
if TF && isempty(sensor_data(zr).data)
    pr = find(strcmp('pressure', sensor_vars) == 1);
    if ~isempty(pr)
        if strcmp('bar', dbd.sensorUnits.(sensor_data(pr).sensor))
            % Multiply by 10 to convert bars to decibars
            sensor_data(zr).data = sensor_data(pr).data*10;
        else
            % Assume meters or decibars
            sensor_data(zr).data = sensor_data(pr).data;
        end
    end
end

% Create an instance of the GTrajectoryNc class
nc = GTrajectoryNc();

% Interpolate all sensors if INTERP_ALL_SENSORS is set to true
if INTERP_ALL_SENSORS
    INTERP_SENSORS = sensor_vars;
end

% Check for a time_qc variable
[QC_TF, QC_INDEX] = ismember('time_qc', sensor_vars);
if ~QC_TF
    warning(sprintf('%s:missingQcVariable', app),...
        '%s: The NetCDF template is missing the required time_qc variable\n',...
        dbd.segment);
    return;
end 

% Interpolate the time variable first and assign the appif the following conditions are met:
% 1. The user has specified interpolation of the time variable (via
% INTERP_SENSORS).
% 2. The time_qc data array is empty.  If it's not empty (ie: was taken
% directly from the Dbd instance, assume we've already performed
% interpolation and/or QC of this variable

if ismember('time', INTERP_SENSORS) &&...
        isempty(sensor_data(QC_INDEX).data)
    fprintf(1,...
        'Filling in missing timestamps...\n');
    
    % Retrieve the time_qc variable description
    var_atts = nc.getVariableAttributes('time_qc');
    
    if ~isempty(var_atts)
        % See if the nc variable has a flag_meanings attribute
        [TF,ATT_INDEX] = ismember('flag_meanings', {var_atts.Name});
        if ~TF
            warning(sprintf('%s:missingVariableAttribute', app),...
                'Skipping QC: Variable (%s) is missing the required flag_meanings attribute\n',...
                'time_qc');
        else
            % Remove time_qc from sensor_vars to prevent further downstream
            % processing
            sensor_vars(QC_INDEX) = [];

            % Initialize the data array to nans (_FillValue)
            sensor_data(QC_INDEX).data =...
                nan(length(sensor_data(T_INDEX).data),1);

            % Select the raw data
            raw_data = sensor_data(T_INDEX).data;

            % Split the flag_meanings attribute value (string) on whitespace
            flags = split(var_atts(ATT_INDEX).Value);

            % QC Step 1: replace VARIABLE_qc _FillValues with the 0-based
            % index corresponding to 'no_qc_performed' for VARIABLE rows that
            % have a data value
            % Look for a 'no_qc_performed' flag and, if it exists, replace the
            % NaN flag values with the 0-based index of the flag meaning
            [TF,I] = ismember('no_qc_performed', flags);
            if TF
                % Replace 0s with the flag value - 1 (I - 1)
                sensor_data(QC_INDEX).data(~isnan(raw_data)) = I - 1;
            end
            
            % QC Step 2: interpolate and replace VARIABLE_qc _FillValues with 
            % the 0-based index corresponding to 'interpolated_value' for
            % VARIABLE rows that contain an interpolated value.
            % Look for a 'interpolated_value' flag and, if it exists, replace
            % the NaN flag values with the 0-based index of the flag meaning
            [TF,I] = ismember('interpolated_value', flags);
            if TF
                % Find the row numbers of all nans prior to the
                % interpolation
                raw_nan_r = find(isnan(raw_data));
                if ~isempty(raw_nan_r)
                    sensor_data(T_INDEX).data =...
                        fillMissingValues(sensor_data(T_INDEX).data);
                    interp_nan_r = find(isnan(sensor_data(T_INDEX).data));
                else
                    interp_nan_r = raw_nan_r;
                end

                % Get the row indices of the missing values that were filled
                filled_rows = setdiff(raw_nan_r, interp_nan_r);
                
                if ~isempty(filled_rows)
                    % Replace 0s with the flag value - 1 (I - 1)
                    sensor_data(QC_INDEX).data(filled_rows) = I - 1;
                end
                
            end
        end        
    end
end

nc_vars = {sensor_data.ncVarName}';

% Fill all _qc sensors with 0 to denote raw data if they are empty
r = ~cellfun(@isempty, regexp(sensor_vars, '_qc$', 'once'));
for x = 1:length(r)
    
    % Skip the non-qc sensors
    if ~r(x)
        continue;
    end
    
    % Name of the variable corresponding to the qc variable
    data_var = sensor_vars{x}(1:end-3);
    
    % Skip if the data variable is missing
    [TF,VAR_INDEX] = ismember(data_var, nc_vars);
    if ~TF
        continue;
    end
    
    % Initialize the sensor data array if it's empty
    if (isempty(sensor_data(VAR_INDEX).data))
        sensor_data(VAR_INDEX).data = nan(array_length,1);
    end
    
    % Find the index of the _qc variable
    [~, QC_INDEX] = ismember(sensor_vars{x}, nc_vars);
    
    % Skip the interpolation if the *_qc variable is not empty.  If it's
    % not empty, we'll assume the user has already dealt with interpolation
    % and any other QC issues
    if ~isempty(sensor_data(QC_INDEX).data)
        warning(sprintf('%s:foundVariableQcValues', app),...
            'Skipping %s: QC flag values found\n',...
            sensor_vars{x});
        continue;
    end
    
    % Initialize the *_qc data array to nan (_FillValue)
    sensor_data(QC_INDEX).data =...
        nan(length(sensor_data(VAR_INDEX).data),1);
    
    % See if the nc variable has a flag_meanings attribute
    var_atts = nc.getVariableAttributes(sensor_vars{x});
    if isempty(var_atts)
        continue;
    end 
    
    % See if the nc variable has a flag_meanings attribute
    [TF,ATT_INDEX] = ismember('flag_meanings', {var_atts.Name});
    if ~TF
        warning(sprintf('%s:missingVariableAttribute', app),...
            'Skipping QC: Variable (%s) is missing the required flag_meanings attribute\n',...
            'time_qc');
        continue;
    end

    % Select the raw data
    raw_data = sensor_data(VAR_INDEX).data;

    % Split the flag_meanings attribute value (string) on whitespace
    flags = split(var_atts(ATT_INDEX).Value);

    % QC Step 1: replace VARIABLE_qc _FillValues with the 0-based
    % index corresponding to 'no_qc_performed' for VARIABLE rows that
    % have a data value
    % Look for a 'no_qc_performed' flag and, if it exists, replace the
    % NaN flag values with the 0-based index of the flag meaning
    [TF,I] = ismember('no_qc_performed', flags);
    if TF
        % Replace 0s with the flag value - 1 (I - 1)
        sensor_data(QC_INDEX).data(~isnan(raw_data)) = I - 1;
    end

    % Check INTERP_SENSORS to see if we need to interpolate the variable
    % data
    if ismember(data_var, INTERP_SENSORS)
        
        % QC Step 2: interpolate and replace VARIABLE_qc _FillValues with 
        % the 0-based index corresponding to 'interpolated_value' for
        % VARIABLE rows that contain an interpolated value.
        % Look for a 'interpolated_value' flag and, if it exists, replace
        % the NaN flag values with the 0-based index of the flag meaning
        [TF,I] = ismember('interpolated_value', flags);
        if TF
            % Find the row numbers of all nans prior to the
            % interpolation
            raw_nan_r = find(isnan(raw_data));
            if ~isempty(raw_nan_r)
                sensor_data(VAR_INDEX).data =...
                    fillMissingValues(sensor_data(VAR_INDEX).data);
                interp_nan_r = find(isnan(sensor_data(VAR_INDEX).data));
            else
                interp_nan_r = raw_nan_r;
            end

            % Get the row indices of the missing values that were filled
            filled_rows = setdiff(raw_nan_r, interp_nan_r);

            if ~isempty(filled_rows)
                % Replace 0s with the flag value - 1 (I - 1)
                sensor_data(QC_INDEX).data(filled_rows) = I - 1;
            end

        end        
    end
end

% Add a trajectory id
[~,VAR_INDEX] = ismember('trajectory', nc_vars);
sensor_data(VAR_INDEX).data = 1;

% Add the segment id data
[~,VAR_INDEX] = ismember('segment_id', nc_vars);
sensor_data(VAR_INDEX).data = ones(length(sensor_data(T_INDEX).data),1);

% Remove NaNs from the time coordinate variable and all variables that
% are dimensioned on the time variable
clean_data = cleanNcTrajectoryTimeVars(sensor_data);

% Re-create the list of variables
sensor_vars = {clean_data.ncVarName}';

% Make sure the clean_data 'time' variable has data after being cleaned
[~,LOC] = ismember('time', sensor_vars);
if isempty(clean_data(LOC).data)
    fprintf(2,...
        'Skipping %s: Cleaned time-dimensioned variables contain no records\n',...
        dbd.segment);
    return;
end

% Add the data to the instance
for s = 1:length(clean_data)
    if isempty(clean_data(s).data)
        continue;
    end
    try
        nc.addVariableData(clean_data(s).ncVarName, clean_data(s).data);
    catch ME
        fprintf(2,...
            '%s: %s (%s)\n',...
            dbd.segment,...
            ME.identifier,...
            ME.message);
        continue;
    end
end

% Add a 'sensor_name' attribute to some of the data variables to specify
% which native slocum glider sensor the data came from
slocum_sensor_vars = {'time',...
    'lat',...
    'lon',...
    'depth',...
    'pressure',...
    'conductivity',...
    'density',...
    'salinity',...
    'temperature',...
    'u',...
    'v',...
    }';
for v = 1:length(slocum_sensor_vars)
    [TF,LOC] = ismember(slocum_sensor_vars{v}, sensor_vars);
    if ~TF
        continue;
    elseif isempty(clean_data(LOC).data)
        continue;
    end
    nc.setVariableAttribute(slocum_sensor_vars{v}, 'sensor_name', clean_data(LOC).sensor);
end

% See if we have a platform variable
atts = nc.getVariableAttributes('platform');
if ~isempty(atts)
    % Add/fill in some attributes if we have a platform variable in the
    % NetCDF schema
    
    % Glider id 
    nc.setVariableAttribute('platform',...
        'id', dbd.glider);
    % long_name
    nc.setVariableAttribute('platform',...
        'long_name', sprintf('Slocum Glider %s', dbd.glider));
    % type
    nc.setVariableAttribute('platform',...
        'type', 'slocum');
    % comment
    nc.setVariableAttribute('platform',...
        'comment', sprintf('Slocum Glider %s', dbd.glider));
end

% See if we have instrument_ctd variable
atts = nc.getVariableAttributes('instrument_ctd');
if ~isempty(atts)
    % Add/fill in some attributes if we have a platform variable in the
    % NetCDF schema
    
    % comment
    nc.setVariableAttribute('instrument_ctd',...
        'comment', sprintf('Slocum Glider %s', dbd.glider));
end

% Add the WMO id if specified
if ~isempty(WMO_ID)
    fprintf(1,...
        '%s: Adding platform_id.wmo_id (%s)\n',...
        app,...
        nc_file);
    nc.setVariableAttribute('platform', 'wmo_id', WMO_ID);
end

% Set some global attributes

% Default global comment
nc.setGlobalAttribute('comment',...
    'Data provided by the Mid-Atlantic Regional Association Coastal Ocean Observing System');

nc_ts = datestr(now, 'yyyy-mm-ddTHH:MM:SSZ');
nc.setGlobalAttribute('source_file', dbd.sourceFile);
nc.setGlobalAttribute('date_created', nc_ts);
nc.setGlobalAttribute('date_issued', nc_ts);
nc.setGlobalAttribute('date_modified', nc_ts);
gps_sensors = {'drv_latitude',...
    'drv_longitude',...
    }';
gps_data = dbd.toArray('sensors', gps_sensors);
nc.setGlobalAttribute('geospatial_lat_max', max(gps_data(:,3)));
nc.setGlobalAttribute('geospatial_lat_min', min(gps_data(:,3)));
nc.setGlobalAttribute('geospatial_lon_max', max(gps_data(:,4)));
nc.setGlobalAttribute('geospatial_lon_min', min(gps_data(:,4)));
nc.setGlobalAttribute('geospatial_vertical_max', max(gps_data(:,2)));
nc.setGlobalAttribute('geospatial_vertical_min', min(gps_data(:,2)));
nc.setGlobalAttribute('history', sprintf('Created %s', nc_ts));
nc.setGlobalAttribute('id',...
    sprintf('%s-%s', dbd.glider, datestr(epoch2datenum(min(gps_data(:,1))), 'yyyymmddTHHMMSS')));
nc.setGlobalAttribute('time_coverage_start',...
    datestr(epoch2datenum(min(gps_data(:,1))), 'yyyy-mm-ddTHH:MM:SSZ'));
nc.setGlobalAttribute('time_coverage_end',...
    datestr(epoch2datenum(max(gps_data(:,1))), 'yyyy-mm-ddTHH:MM:SSZ'));

% Update any global attributes contained in the GLOBAL_ATTRIBUTES
% structured array
if ~isempty(GLOBAL_ATTRIBUTES)
    if isstruct(GLOBAL_ATTRIBUTES) && isequal(length(GLOBAL_ATTRIBUTES),1)
        gAtts = fieldnames(GLOBAL_ATTRIBUTES);
        for g = 1:length(gAtts)
            fprintf(1,...
                'Setting file attribute: %s\n',...
                gAtts{g});
            nc.setGlobalAttribute(gAtts{g}, GLOBAL_ATTRIBUTES.(gAtts{g}));
        end
    else
        warning(sprintf('%s:invalidDataType', app),...
            'User-specified global attributes argument must be a structured array mapping attribute name to the attribute value\n');
    end
end
% Fill in the depth-average current variables
% Take the mean of the 'time' variable and use it as the 'time_uv' value
nc.addVariableData('time_uv', mean(nc.getVariableData('time')));

fprintf(1,...
    'Writing NetCDF: %s\n',...
    nc_file);
try
    nc.toNc(nc_file);
catch ME
    nc_file = '';
end


