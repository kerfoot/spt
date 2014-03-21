classdef Dbd < handle
    %
    % obj = Dbd(dbd_file, varargin)
    %
    % Create and new instance of the Dbd class representing the specified 
    % Slocum glider data file (dbd_file).  
    %
    % The class accepts 2 forms of ascii data files, both of which are 
    % produced by the dbd2asc utility, provided by TWRC.  This utility
    % creates ascii output composed of a series of metadata header lines
    % followed by the data values and is typically referred to as dinkum
    % binary ascii data.  This output may, optionally, be piped to the
    % dba2_orig_matlab utility to create a pair of files for each original
    % binary file.  The file pairs consists of a Matlab script file (.m)
    % and an ascii data file which has the metadata header stripped out to
    % facilitate loading in the Matlab programming environment.  If the
    % matlab formatted data files are used the input argument, dbd_file, is
    % the name of the .m file, not the .dat sibling file.
    %
    % By default, all sensors in the data file are stored in the instance, 
    % with the exception of sensors beginning with 'gld_dup_', as these are 
    % duplicate sensors added to the file during the binary to ascii merge 
    % process.
    %
    % All valid timestamp and depth sensors are always included in the
    % instance, regardless of whether an optional sensor list is specified via
    % the 'sensors' options.
    %
    % If the masterdata sensors m_gps_lat and m_gps_lon are contained in
    % the source file, the values for each are converted from decimal
    % minutes (DDMM.mmmm) to decimal degrees (DD.dddd) and added as the new
    % sensors drv_latitude and drv_longitude.
    %
    % Options: 
    % The following name,value option pairs modify the default behavior:
    %
    %   'dupsensors': true or false (false by default).  Set to true to
    %       include all sensors (even duplicates) in the instance.
    %   'includesensors': cell array of sensor names to include in the instance.
    %       Non-existent sensors are ignored.
    %   'excludesensors': cell array of sensors or regular expression
    %       patterns to exclude from the instance.
    %
    % See also DbdGroup
    % ============================================================================
    % $RCSfile: Dbd.m,v $
    % $Source: /home/kerfoot/cvsroot/slocum/matlab/spt/classes/@Dbd/Dbd.m,v $
    % $Revision: 1.9 $
    % $Date: 2014/03/21 19:35:13 $
    % $Author: kerfoot $
    % ============================================================================
    %
    
    % Properties are displayed as they are listed here, which is why there are
    % multiple property definitions with the same Access rights.
    properties (SetAccess = immutable)
        glider = '';
        segment = '';
        sourceFile = '';
        the8x3filename = '';
        filetype = '';
        bytes = 0;
        rows = 0;
    end
    
    properties (Dependent = true, SetAccess = private)
        sensors = {};
    end
        
    properties (GetAccess = public, SetAccess = private)
        sensorUnits = [];
    end
    
    properties (Dependent = true, SetAccess = private)
        startDatenum = NaN;
        endDatenum = NaN;
        startTime = '';
        endTime = '';      
    end
    
    properties (Dependent = true, AbortSet = true)
        timestampSensor = '';
        depthSensor = '';
    end
    
    properties (Access = private)
        privateStartDatenum = NaN;
        privateEndDatenum = NaN;
        privateTimestampSensor = '';
        privateDepthSensor = '';
        privateFlaggedProfiles = [];
    end

    properties (GetAccess = public, SetAccess = private)
        dbdTimestampSensors = {};
        dbdDepthSensors = {}; 
    end
        
    properties (Access = public)
        profileInds = [];
    end
    
    properties (Dependent = true, AbortSet = true)
        numProfiles = 0;
    end
    
    properties (Access = public, AbortSet = true)
        fillTimes = 'none';
        proMinTimeSpan = 8;
        proMinNumPoints = 2;
        fillDepths = 'none';
        proMinDepth = 1;
        proMinDepthSpan = 2;
        fillGps = 'none';
    end 
    
    properties (SetAccess = private)
        hasBoundingGps = false;
    end
    
    properties (Access = public, AbortSet = true)
        scratch = [];
    end 
    
    properties (GetAccess = protected, SetAccess = private)
        validTimestampSensors = {'m_present_time',...
            'sci_m_present_time',...
            'sci_ctd41cp_timestamp',...
            }';
        validDepthSensors = {'m_depth',...
            'm_pressure',...
            'sci_water_pressure',...
            'm_water_pressure',...
            }';
    end
    
    properties (Access = private)
        dbdData = struct([]);
    end
    
    % Constructor
    methods
        function obj = Dbd(sourceFile, varargin)
            
            % Must specify a source file to process
            if isequal(nargin,0)
                % Return and empty instance of the Class
                return;
            elseif ~ischar(sourceFile)
                error('Dbd:invalidType',...
                    'The filename must be a string.');
            elseif ~exist(sourceFile, 'file')
                % File must exist
                error('Dbd:fileNotFound',...
                    'File does not exist.');
            end
            
            % Process options
            if ~isequal(mod(length(varargin),2),0)
                % All options are specified as name/value pairs, so there must
                % be an even number of options specified.
                error('Dbd:varargin',...
                    'Invalid number of name/value option pairs.');
            end
            % Options
            SENSOR_LIST = {};
            INCLUDE_DUPS = false;
            EXCLUDE_SENSORS = {};
            for x = 1:2:length(varargin)
                name = varargin{x};
                value = varargin{x+1};
                switch lower(name)
                    case 'includesensors'
                        if ~iscellstr(value)
                            error('Dbd:invalidArgument',...
                                'Value for %s must be a cell array of strings.',...
                                name);
                        end
                        SENSOR_LIST = value;
                    case 'dupsensors'
                        if ~islogical(value)
                            error('Dbd:invalidArgument',...
                                'Value for %s must be true or false.',...
                                name);
                        end
                        INCLUDE_DUPS = value;
                    case 'excludesensors'
                        if ischar(value)
                            value = {value}';
                        elseif ~iscellstr(value)
                            error(sprintf('%s:invalidOptionValue', app),...
                                'Value for option %s must be a string or cell array of strings containing patterns',...
                                name);
                        end
                        EXCLUDE_SENSORS = value;
                    otherwise
                        error('Dbd:invalidArgument',...
                            'Invalid option specified: %s',...
                            name);
                end
            end
            
            % There are 2 types of files which can be used to contstruct this
            % instance:
            % 1. Standalone .dat file containing all file metadata and sensor
            %   data.
            % 2. Matlab .m file used to load the data in a corresponding .dat
            %   file and create global sensor variable names.
            %
            % If sourceFile ends in .dat, parse the .dat file and fill in the
            % instance properties/data.  If sourceFile ends in .m, run the .m
            % file to load the data and parse the .m file to fill in instance
            % properties
            
            % Fully-qualified path to the file
            [s,atts,errId] = fileattrib(sourceFile);
            if isequal(s,0)
                error(['Dbd:' errId],...
                    atts);
            end
            % Should be fully-qualified path to the file
            sourceFile = atts.Name;
            
            [p,f,ext] = fileparts(sourceFile);
            
            if strcmp(ext, '.m') % m-file specified
                
                % Make sure we can find the .dat file
                datFile = fullfile(p, [f '.dat']);
                % Make sure it's on the path
                if ~exist(datFile, 'file')
                    error('Dbd:fileNotFound',...
                        'Segment m-file companion .dat file (%s) not found.',...
                        datFile);
                end
                % Try to load the file
                try
                    % Sensors names are declared as global variables, so we need
                    % to clear all global variables in the 'caller' workspace to
                    % prevent conflicts from any previously loaded dbd files.
                    evalin('caller', 'clear global');
                    run(sourceFile);
                catch ME
                    error('Dbd:%s: %s',...
                        ME.identifier,...
                        ME.message);
                end
                
                 % Store the size of the .dat file
                dInfo = dir(datFile);
                obj.bytes = dInfo.bytes;

                % Set the numRows field
                obj.rows = size(data,1);

                % Start setting properties
                obj.sourceFile = sourceFile;

                % Parse the run_name var to get the proper name, filetype and 
                % the8x3filename
                tokens = regexp(run_name, '(.*)\-(\w+)\((.*)\)', 'tokens');
                if isempty(tokens)
                    error('Dbd:parseError',...
                        'Error parsing dbd run_name: %s',...
                        run_name);
                end
                obj.the8x3filename = tokens{1}{3};
                obj.segment = regexprep(tokens{1}{1}, {'\-', '_[demnst]bd'}, '_');

                % Store the original filetype
                obj.filetype = tokens{1}{2};

                % Set the glider name
                g = regexp(tokens{1}{1}, '^(.*)\-\d{4}', 'tokens');
                obj.glider = g{1}{1};
                
                % Get the list of included sensors.  A sensor is a global 
                % variable containing a numeric scalar
                vars = whos('global');
                [fSensors{1:length(vars)}] = deal(vars.name);
                % Set SENSOR_LIST to sensorNames if not list was specified
                if isempty(SENSOR_LIST)
                    SENSOR_LIST = fSensors;
                end
                
                % Add obj.validTimestampSensors to SENSOR_LIST
                SENSOR_LIST = union(SENSOR_LIST, obj.validTimestampSensors);
                % Add obj.validDepthSensors to SENSOR_LIST
                SENSOR_LIST = union(SENSOR_LIST, obj.validDepthSensors);
                
                % Loop through each sensor in fSensors and add the data to
                % obj.dbdData.  Also, Since we don't have the units 
                % information for the sensors, set each sensor field in 
                % meta.sensorUnits to 'nodim'
                s = 1;
                while s <= length(fSensors)
                    if ~INCLUDE_DUPS && strncmp(fSensors{s}, 'gld_dup_', 8)
                        fSensors(s) = [];
                        continue;
                    elseif ~isequal(length(eval(fSensors{s})),1) ||...
                            ~isnumeric(eval(fSensors{s})) ||...
                            ~ismember(fSensors{s}, SENSOR_LIST)
                        fSensors(s) = [];
                        continue;
                    end

                    % Map the sensor name to the data array
                    obj.dbdData(1).(fSensors{s}) =...
                        data(:,eval(fSensors{s}));

                    obj.sensorUnits.(fSensors{s}) = 'nodim';
                    
                    % Increment the counter
                    s = s+1;

                end
                
            else % Self-contained data file specified (ie: dbd2asc)
                
                % Store the size of the .dat file
                dInfo = dir(sourceFile);
                obj.bytes = dInfo.bytes;

                % Set the source file name
                obj.sourceFile = sourceFile;

                % Regexp to make sure the user hasn't specified the .dat
                % file of a .m/.dat pair.
                dataRegexp = '^NaN|^\d|^\-';
                
                % Open up the file and parse the header
                fid = fopen(sourceFile, 'r');
                ht = fgetl(fid);
                % Keep track of the line number
                lineNumber = 1;
                while ~feof(fid) &&...
                        isempty(regexp(ht, '^segment_filename_0', 'tokens'))
                    
                    if ~isempty(regexp(ht, dataRegexp, 'once'))
                        error('Dbd:invalidFileType',...
                            '%s: file is not a valid dba file',...
                            sourceFile);
                    end
                    
                    % Look for the segment name, 8.3 name and the glider
                    % name, all from the same line
                    tokens = regexp(ht,...
                        '^filename_label:\s*(.*)\-(\w*)\((.*)\)',...
                        'tokens');
                    if ~isempty(tokens)
                        obj.segment = regexprep(tokens{1}{1},...
                            '\-',...
                            '_');
                        % Set the 8.3 filename
                        obj.the8x3filename = tokens{1}{3};
                        % Set the glider name
                        g = regexp(tokens{1}{1},...
                            '^(.*)\-\d{4}',...
                            'tokens');
                        obj.glider = g{1}{1};
                        % Set the original filetype property
                        obj.filetype = tokens{1}{2};
                    end
                    ht = fgetl(fid);
                    lineNumber = lineNumber + 1;
                end
                
                % Make sure the header was parsed properly before
                % proceeding
                if isempty(obj.segment)
                    error('Dbd:invalidFile',...
                        '%s: File header was unable to be parsed',...
                        sourceFile);
                end
                
                % Get the next line, which should be a whitespace delimited
                % string of sensors contained in the file
                ht = fgetl(fid);
                % Increment the line counter
                lineNumber = lineNumber + 1;
                fSensors = split(ht, ' ');
                fSensors(cellfun(@isempty, fSensors)) = [];
                % The next line should be a whitespace delimited string of
                % sensor units
                ht = fgetl(fid);
                % Increment the line counter
                lineNumber = lineNumber + 1;
                fUnits = split(ht, ' ');
                % There's an extra \n on the end of this line which results in
                % the last element containing an empty string.  Get rid of it
                fUnits(cellfun(@isempty, fUnits)) = [];
                % The number of parsed sensor names must be equal to the
                % number of parsed sensor units
                if ~isequal(length(fSensors), length(fUnits))
                    error('Dbd:parseError',...
                        'The number of sensors and sensor units do not match up.');
                end
                
                % Get and discard the next line, which should be a whitespace 
                % delimited string of sensor byte numbers
                fgetl(fid);
                % Increment the file counter
                lineNumber = lineNumber + 1;
                % Close the file
                fclose(fid);
                
                % Read in the data matrix using beginning at the first line
                % after the header, which was already read.
                data = dlmread(sourceFile, ' ', lineNumber, 0);

                % If the 2 cell arrays are of equal length:
                % 1. Skip any sensors not contained in SENSOR_LIST, which
                %   may have been user-specified.
                % 2. Add all included sensors to the .sensor property
                % 3. Add the sensor data to the obj.dbdData structure
                % 4. Add the sensor's units to the obj.meta.sensorUnits
                %   structure.
                
                % Set SENSOR_LIST to sensorNames if not list was specified               
                if isempty(SENSOR_LIST)
                    SENSOR_LIST = fSensors;
                end
                
                % Add obj.validTimestampSensors to SENSOR_LIST
                SENSOR_LIST = union(SENSOR_LIST, obj.validTimestampSensors);
                % Add obj.validDepthSensors to SENSOR_LIST
                SENSOR_LIST = union(SENSOR_LIST, obj.validDepthSensors);
                
                % Loop through each sensor in fSensors and add the data to
                % obj.dbdData and add the sensor's units (from fUnits) to
                % the obj.meta.sensorUnits data structure
                for s = 1:length(fSensors)
                    if ~INCLUDE_DUPS && strncmp(fSensors{s}, 'gld_dup_', 8)
                        continue;
                    elseif ~ismember(fSensors{s}, SENSOR_LIST)
                        continue;
                    end
                    % Map the sensor name to the data array
                    obj.dbdData(1).(fSensors{s}) = data(:,s);
                    % Add the sensor units to the obj.meta structure
                    obj.sensorUnits.(fSensors{s}) = fUnits{s};

                end                
            end        
                                        
            % Set the rows property
            obj.rows = size(data,1);
            
            % Find valid timestamps in the obj.sensors property
            tsTf = ismember(obj.validTimestampSensors, obj.sensors);
            if ~any(tsTf)
                error('Dbd:missingTimestampSensor',...
                    'File contains no valid timestamp sensors.');
            end
            % Get the row indices where valid depth sensors were found
            tInd = find(tsTf == 1);
            newTsSensors = cell(length(tsTf),1);
            for t = 1:length(tInd)
                tr = tInd(t);
                rawSensor = obj.validTimestampSensors{tr};
                % Store the timestamp in a temporary variable
                ts = obj.dbdData.(rawSensor);
                % Set any raw timestamp sensor values which are equal
                % to 0 to NaN
                ts(ts == 0) = NaN;
                % Replace duplicate timestamp values, ignoring NaNs, with NaN
                r = find(~isnan(ts));
                dups = find(diff(ts(r)) == 0);
                ts(r(dups+1)) = NaN;
                % Update the array in obj.dbdData
                obj.dbdData.(rawSensor) = ts;
                % Update the raw timestamp sensor units which are unix
                % times
                obj.sensorUnits.(rawSensor) =...
                    'seconds since 1970-01-01 00:00:00 GMT';
                % Create the new sensor name
                drvSensor = ['drv_' rawSensor '_datenum'];
                % Convert to datenum and add to dbdData
                obj.dbdData.(drvSensor) =...
                    epoch2datenum(ts);
                % Add the units to the obj.meta.sensorUnits
                obj.sensorUnits.(drvSensor) =...
                    'days since 0000-01-00 00:00:00 GMT';
                % Add the sensor to the list of newTsSensors
                newTsSensors{t} = drvSensor;
                % Add the datenum sensor to the available timestamp sensors
                % cell array
                obj.dbdTimestampSensors{end+1} = drvSensor;
                % Add the original sensor to the available timestamp sensors
                obj.dbdTimestampSensors{end+1} = rawSensor;
            end
            % Prepend the newTsSensors to obj.validTimestampSensors
            obj.validTimestampSensors = [newTsSensors;...
                obj.validTimestampSensors];
            obj.dbdTimestampSensors = obj.dbdTimestampSensors';
            
            % Set the default timestamp sensor to the first available
            % obj.dbdTimestampSensor
            obj.timestampSensor = obj.dbdTimestampSensors{1};
                        
            % Get the valid depth sensors from the obj file.  Any sensor in
            % obj.validDepthSensors that ends with '_pressure' is pressure
            % measured in bars.  Create a new sensor for each and multiply
            % the values by 10 to convert to decibars
            zTf = ismember(obj.validDepthSensors, obj.sensors);
            if ~any(zTf)
                error('Dbd:missingDepthSensor',...
                    'File contains no valid depth/pressure sensors.');
            end
            % Get the row indices where valid depth sensors were found
            zInd = find(zTf == 1);
            for z = 1:length(zInd)
                zr = zInd(z);
                if ~isempty(regexp(obj.validDepthSensors{zr},...
                        '_pressure$',...
                        'once'))
                    % Create the derived sensor name which will contain the
                    % raw pressure values converted from bars to decibars
                    drvSensor = ['drv_' obj.validDepthSensors{zr}];
                    obj.dbdData.(drvSensor) =...
                        obj.dbdData.(obj.validDepthSensors{zr})*10;
                    obj.validDepthSensors{end+1} = drvSensor;
                    
                    % Add the derived depth/pressure sensor to the
                    % obj.dbdDepthSensors property
                    obj.dbdDepthSensors{end+1} = drvSensor;
                    % Add the units to the obj.meta.sensorUnits
                    obj.sensorUnits.(drvSensor) = 'decibars';
                end
                % Add the raw depth/pressure sensor to the
                % obj.dbdDepthSensors property
                obj.dbdDepthSensors{end+1} = obj.validDepthSensors{zr};
            end
            
            % Transpose the list of validDepthSensors
            obj.dbdDepthSensors = obj.dbdDepthSensors';
            
            % Use the first sensor in dbdTimestampSensors as the default
            % timestamp sensor
            obj.timestampSensor = obj.dbdTimestampSensors{1};
            
            % Use the first timestamp in validTimestampSensors to set the
            % segment start and end time as datenums
            ts = obj.dbdData.(obj.timestampSensor);
            ts(isnan(ts)) = [];
            obj.privateStartDatenum = min(ts);
            obj.privateEndDatenum = max(ts);

            % Use the first sensor in dbdDepthSensors to set the default
            % obj.depthSensor
            obj.depthSensor = obj.dbdDepthSensors{1};
            
            % If EXCLUDE_SENSORS is not empty, remove the sensors specified
            if ~isempty(EXCLUDE_SENSORS)
                obj.deleteSensor('regexp', EXCLUDE_SENSORS);
            end
            
            % Re-index the yo profiles
            obj.indexProfiles();
          
% % % % %             % Add the derived GPS sensors with nan-filled arrays
% % % % %             dbd.dbdData.drv_latitude = nan(obj.rows,1);
% % % % %             dbd.dbdData.drv_longitude = nan(obj.rows,1);
% % % % %             obj.sensorUnits.drv_latitude = 'degrees';
% % % % %             obj.sensorUnits.drv_longitude = 'degrees';
% % % % %                 
% % % % %             % Convert m_gps_lat and/or m_gps_lon (if they exist) from the 
% % % % %             % default units (decimial minuts) to decimal degrees and add
% % % % %             % them as new sensors drv_latitude and/or drv_longitude
% % % % %             GPS_SENSORS = {'m_gps_lat',...
% % % % %                 'm_gps_lon',...
% % % % %                 }';            
            % GPS fixes only interpolated if they bound a set of profiles
            % and the sensors (m_gps_lat, m_gps_lon) are included in the
            % instance.  If GPS_SENSORS are not found, add drv_latitude and
            % drv_longitude sensors, initialized to an array of NaNs.
% % % % %             if isequal(length(intersect(GPS_SENSORS, obj.sensors)),2)
                obj.interpGps(obj.fillGps);
% % % % %             end
            
        end
    end
    
    % Instance get/set methods
    methods
        
        % obj.sensors
        function value = get.sensors(obj)
            value = sort(fieldnames(obj.dbdData));
        end
        
        % obj.startDatenum
        function value = get.startDatenum(obj)
            value = obj.privateStartDatenum;
        end
        
        % obj.startTime
        function value = get.startTime(obj)
            value = '';
            if isnan(obj.privateStartDatenum)
                return;
            end
            value = datestr(obj.privateStartDatenum, 'yyyy-mm-dd HH:MM:SS');
        end
        
        % obj.endDatenum
        function value = get.endDatenum(obj)
            value = obj.privateEndDatenum;
        end
        
        % obj.endTime
        function value = get.endTime(obj)
            value = '';
            if isnan(obj.privateEndDatenum)
                return;
            end
            value = datestr(obj.privateEndDatenum, 'yyyy-mm-dd HH:MM:SS');
        end
        
        % obj.timestampSensor
        function value = get.timestampSensor(obj)
            value = obj.privateTimestampSensor;
        end
        % obj.timestampSensor
        % Sets the obj.timestampSensor property to any sensor value
        % contained in obj.dbdTimestampSensors.
        function set.timestampSensor(obj, sensorName)
            if ~ischar(sensorName)
                error('Dbd:invalidArgument',...
                    'Sensor name must be a string.');
            elseif ~ismember(sensorName, obj.dbdTimestampSensors)
                warning('Dbd:invalidTimestampSensor',...
                    '%s: Sensor (%s) does not exist.',...
                    obj.segment,...
                    sensorName);
                return;
            end
            obj.privateTimestampSensor = sensorName;
            
            % Re-index the yo profiles
            obj.indexProfiles();
            
        end
        
        % obj.depthSensor
        function value = get.depthSensor(obj)
            value = obj.privateDepthSensor;
        end
        % obj.timestampSensor
        % Sets the obj.timestampSensor property to any sensor value
        % contained in obj.dbdTimestampSensors.
        function set.depthSensor(obj, sensorName)
            if ~ischar(sensorName)
                error('Dbd:invalidArgument',...
                    'Sensor name must be a string.');
            elseif ~ismember(sensorName, obj.dbdDepthSensors)
                warning('Dbd:invalidDepthSensor',...
                    '%s: Sensor (%s) does not exist.',...
                    obj.segment,...
                    sensorName);
                return;
            end
            obj.privateDepthSensor = sensorName;
            
            % Re-index the yo profiles
            obj.indexProfiles();
            
        end
        
        % obj.profileInds
        function value = get.profileInds(obj)
            value = obj.profileInds;
        end
        
        % obj.numProfiles
        function value = get.numProfiles(obj)
            value = size(obj.profileInds,1);
        end
        
        % obj.fillDepths
        function value = get.fillDepths(obj)
            value = obj.fillDepths;
        end
        function set.fillDepths(obj, value)
            
            % Force to lower case
            value = lower(value);
            
            errorMsg = ['Value must be a string specifying a valid '...
                'interp1.m method.'];
            interpMethods = {'none',...
                'nearest',...
                'linear',...
                'spline',...
                'pchip',...
                'cubic',...
                'v5cubic',...
                }';
            if isempty(value)
                error('Dbd:emptyArgument',...
                    errorMsg);
            elseif ~ischar(value)
                error('Dbd:invalidArgument',...
                    errorMsg);
            elseif ~ismember(value, interpMethods)
                error('Pbd:InvalidMethod',...
                    errorMsg);
            end
            % Set the attribute
            obj.fillDepths = value;
            
            % Re-index the yo profiles
            obj.indexProfiles();
            
        end
        
        % obj.fillTimes
        function value = get.fillTimes(obj)
            value = obj.fillTimes;
        end
        function set.fillTimes(obj, value)
            
            % Force to lower case
            value = lower(value);
            
            errorMsg = ['Value must be a string specifying a valid '...
                'interp1.m method.'];
            interpMethods = {'none',...
                'nearest',...
                'linear',...
                'spline',...
                'pchip',...
                'cubic',...
                'v5cubic',...
                }';
            if isempty(value)
                error('Dbd:emptyArgument',...
                    errorMsg);
            elseif ~ischar(value)
                error('Dbd:invalidArgument',...
                    errorMsg);
            elseif ~ismember(value, interpMethods)
                error('Pbd:InvalidMethod',...
                    errorMsg);
            end
            % Set the attribute
            obj.fillTimes = value;
            
            % Re-index the yo profiles
            obj.indexProfiles();
            
        end
        
        % obj.proMinDepth
        function value = get.proMinDepth(obj)
            value = obj.proMinDepth;
        end
        function set.proMinDepth(obj, value)
            if ~isequal(numel(value),1) || ~isnumeric(value) || value < 0
                error('Dbd:invalidArgument',...
                    'Value must be positive numeric scalar.');
            end
            % Set the attribute
            obj.proMinDepth = value;
            
            % Re-index the yo profiles
            obj.indexProfiles();
            
        end
        
        % obj.proMinTimeSpan
        function value = get.proMinTimeSpan(obj)
            value = obj.proMinTimeSpan;
        end
        function set.proMinTimeSpan(obj, value)
            if ~isequal(numel(value),1) || ~isnumeric(value) || value < 0
                error('Dbd:invalidArgument',...
                    'Value must be positive numeric scalar.');
            end
            % Set the attribute
            obj.proMinTimeSpan = value;
            
            % Re-index the yo profiles
            obj.indexProfiles();
            
        end
        
        % obj.proMinDepthSpan
        function value = get.proMinDepthSpan(obj)
            value = obj.proMinDepthSpan;
        end
        function set.proMinDepthSpan(obj, value)
            if ~isequal(numel(value),1) || ~isnumeric(value) || value < 0
                error('Dbd:invalidArgument',...
                    'Value must be positive numeric scalar.');
            end
            % Set the attribute
            obj.proMinDepthSpan = value;
            
            % Re-index the yo profiles
            obj.indexProfiles();
            
        end

           
        % obj.proMinNumPoints
        function value = get.proMinNumPoints(obj)
            value = obj.proMinNumPoints;
        end
        function set.proMinNumPoints(obj, value)
            if ~isequal(numel(value),1) || ~isnumeric(value) || value < 0
                error('Dbd:invalidArgument',...
                    'Value must be positive numeric scalar.');
            end
            % Set the attribute
            obj.proMinNumPoints = value;
            
            % Re-index the yo profiles
            obj.indexProfiles();
            
        end
        
        % obj.fillGps
        function value = get.fillGps(obj)
            value = obj.fillGps;
        end
        function set.fillGps(obj, value)
            
            % Force to lower case
            value = lower(value);
            
            errorMsg = ['Value must be a string specifying a valid '...
                'interp1.m method.'];
            interpMethods = {'none',...
                'nearest',...
                'linear',...
                'spline',...
                'pchip',...
                'cubic',...
                'v5cubic',...
                }';
            if isempty(value)
                error('Dbd:emptyArgument',...
                    errorMsg);
            elseif ~ischar(value)
                error('Dbd:invalidArgument',...
                    errorMsg);
            elseif ~ismember(value, interpMethods)
                error('Pbd:InvalidMethod',...
                    errorMsg);
            end
            
            % Interpolate the GPS
            success = obj.interpGps(value);
            
            if success
                % Set the attribute
                obj.fillGps = value;
            else
                obj.fillGps = 'none';
            end
        end
    end
    
    % Private methods
    methods (Access = private)
            
        function indexProfiles(obj)
            
            % When called from the constructor, it's possible that one or both
            % of obj.timestampSensor and obj.depthSensor will not yet be set.
            % Check for this and return unless they have both been set
            if isempty(obj.timestampSensor) || isempty(obj.depthSensor)
                return;
            end
            
            % Get the depth time-series
            tzSensors = {obj.timestampSensor, obj.depthSensor};
            tz = obj.toArray('sensors', tzSensors);
            tz(:,3:end) = [];
            % Number of rows in the tz array
            r = size(tz,1);
            % Initialize an array of nans equal to the number of rows in tz
            % which will hold the profile number
            pNums = nan(r,1);
            % Initialize an array of nans equal to the number of rows in tz
            % which will hold the profile direction
            pDirs = zeros(r,1);
            
            % Add the units
            obj.sensorUnits.drv_proInds = 'nodim';
            obj.sensorUnits.drv_proDir = 'nodim';
            
            % If the timestamp sensor ends in '_datenum', convert to unix time
            % (seconds since 1970-01-01 00:00:00 GMT) since findYoExtrema
            % indexes best using seconds.
            if ~isempty(regexp(obj.timestampSensor, '_datenum$', 'once'))
                tz(:,1) = datenum2epoch(tz(:,1));
            end
            % Fill in times if specified via .fillTimes property
            if ~strcmpi('none', obj.fillTimes)
                tz(:,1) = fillMissingValues(tz(:,1),...
                    'interpmethod', obj.fillTimes);
            end
            % Interpolate missing depths if specified via .fillDepths property
            if ~strcmpi('none', obj.fillDepths)
                tz(:,2) = interpTimeSeries(tz,...
                    'interpmethod',...
                    obj.fillDepths);
            end    
            % Index the yo profiles
            [v,nR] = findYoExtrema(tz);
            if isempty(v)
                obj.profileInds = [];
%                 obj.numProfiles = 0;
                obj.dbdData.drv_proInds = pNums;
                obj.dbdData.drv_proDir = pDirs;
                
                return;
            end
            % Clean up indexed profiles using the objects profile qc
            % properties
            [~,nR] = filterYoExtrema(tz, v,...
                'depthspan', obj.proMinDepthSpan,...
                'mindepth', obj.proMinDepth,...
                'numpoints', obj.proMinNumPoints,...
                'timespan', obj.proMinTimeSpan);
            
            % Fill in the profileInds property
            obj.profileInds = nR;
            
            % Number of profiles
            numProfiles = size(nR,1);
            
            % Fill in pNums with the sequential profile number
            for p = 1:numProfiles
                pNums(nR(p,1):nR(p,2)) = p;
            end
            % Loop through each profile and fill in pDirs with the profile
            % direction:
            % -1 = downcast
            %  1 = upcast
            %  0 = record is a part of the first and next profile
            % If any profile record numbers intersect, set the profile number
            % to the mean of the 2 profile numbers (ie: 1 & 2 = 1.5)
            for p = 1:numProfiles - 1
                p1deltaZ = tz(nR(p,1),2) - tz(nR(p,2),2);
                if p1deltaZ < 1
                    pDirs(nR(p,1):nR(p,2)) = -1;
                elseif p1deltaZ > 1
                    pDirs(nR(p,1):nR(p,2)) = 1;
                end
                p2deltaZ = tz(nR(p+1,1),2) - tz(nR(p+1,2),2);
                if p2deltaZ < 1
                    pDirs(nR(p+1,1):nR(p+1,2)) = -1;
                elseif p2deltaZ > 1
                    pDirs(nR(p+1,1):nR(p+1,2)) = 1;
                end
                C = intersect(nR(p,1):nR(p,2), nR(p+1,1):nR(p+1,2));
                if ~isempty(C)
                    pNums(C) = mean([p p+1]);
                    pDirs(C) = 0;
                end
            end
            % Add a sensor, 'drv_proInds' to obj.dbdData and fill it in with
            % pNums
            obj.dbdData.drv_proInds = pNums;
            
            % Add a sensor, 'drv_proDir' to obj.dbdData and fill it in with 
            % the profile directions
            obj.dbdData.drv_proDir = pDirs;
            
            % Sort the obj.sensorUnits fields
            obj.sensorUnits = orderfields(obj.sensorUnits);
            
            % See if the indexed profiles are bookended by gps fixes
            if ismember('m_gps_lat', obj.sensors) &&...
                    ismember('m_gps_lon', obj.sensors)
                
                % Export the gps fixes
                gps = obj.toArray('sensors', {'m_gps_lat', 'm_gps_lon'});
                
                % Replace bad and default gps fix values from masterdata 
                % (69696969):
                % abs(lats) > 90
                % abs(lons) > 180
                gps(abs(gps(:,3)) > 9000,3) = NaN;
                gps(abs(gps(:,4)) > 18000,4) = NaN;
                
                % Check the segment to determine if it contains a gps fix
                % at the start AND the end of the segment
                if ~isempty(nR) &&...
                        any(all(~isnan(gps(1:obj.profileInds(1,2),[3 4])),2)) &&...
                        any(all(~isnan(gps(obj.profileInds(end,1):end,[3 4])),2))
                    % If the indexed profiles have a valid gps fix
                    % before the end of the first profile and a valid gps fix
                    % after beginning of the last profile, set to true.
                    %
                    % The glider has an annoying habit of keeping depth
                    % values from the previous underwater segment,
                    % depending on which depth sensor is being used.  This
                    % means that it's possible for the file to contain a
                    % profile prior to acquiring a gps fix.
                    obj.hasBoundingGps = true;
                else
                    % Otherwise, set to false
                    obj.hasBoundingGps = false;
                end
            end
            
        end
        
        % interpGps(obj)
        % Interpolate the GPS fixes (m_gps_lon/m_gps_lat) using the interp1
        % method contained in obj.fillGps, provided the Dbd instance
        % contains profiles bounded by GPS fixes.
        function success = interpGps(obj, method)
            
            success = false;
            
            % Force to lower case
            value = lower(method);
            
            errorMsg = ['Value must be a string specifying a valid '...
                'interp1.m method.'];
            interpMethods = {'none',...
                'nearest',...
                'linear',...
                'spline',...
                'pchip',...
                'cubic',...
                'v5cubic',...
                }';
            if isempty(value)
                error('Dbd:interpGps:emptyArgument',...
                    errorMsg);
            elseif ~ischar(value)
                error('Dbd:interpGps:invalidArgument',...
                    errorMsg);
            elseif ~ismember(value, interpMethods)
                error('Dbd:interpGps:InvalidMethod',...
                    errorMsg);
            end
            
            % Initialize drv_latitude and drv_longitude with nan arrays
            nan_array = nan(obj.rows,1);
            obj.addSensor('drv_latitude', nan_array, 'degrees');
            obj.addSensor('drv_longitude', nan_array, 'degrees');

% % % % %             obj.hasBoundingGps = false;
            
            GPS_SENSORS = {'m_gps_lat',...
                'm_gps_lon',...
                }';
            
            % GPS fixes only interpolated if they bound a set of profiles
            % and the sensors (m_gps_lat, m_gps_lon) are included in the
            % instance.  If GPS_SENSORS are not found, add drv_latitude and
            % drv_longitude sensors, initialized to an array of NaNs.
            if ~isequal(length(intersect(GPS_SENSORS, obj.sensors)),2)                
                warning('Dbd:fillGps:missingSensor',...
                    'Masterdata sensors m_gps_lat & m_gps_lon required for interpolation.\n');
                
                return;
            end
            
            success = true;
            
            % Convert GPS_SENSORS values to decimal degrees, replace the
            % drv_latitude and drv_longitude nan arrays and return if 
            % interpolation method is 'none'
            if strcmp(value, 'none')
                gps = obj.toArray('sensors', GPS_SENSORS);
                obj.addSensor('drv_latitude', dm2dd(gps(:,3)));
                obj.addSensor('drv_longitude', dm2dd(gps(:,4)));
                return;
            end
            
            % Get the gps fixes.  Use m_present_time, if available, since
            % it's used to timestamp the fixes.  If it's not available, use
            % the default timestamp sensor
            TF = intersect('m_present_time', obj.dbdTimestampSensors);
            if ~isempty(TF)
                GPS_SENSORS = ['m_present_time'; GPS_SENSORS];
            else
                GPS_SENSORS = [obj.timestampSensor; GPS_SENSORS];
            end
            gps = obj.toArray('sensors', GPS_SENSORS);
            
            % Set to NaN any bad gps fixes(default value from masterdata 
            % is 69696969):
            % abs(lats) > 90
            % abs(lons) > 180
            gps(abs(gps(:,4)) > 9000,4) = NaN;
            gps(abs(gps(:,5)) > 18000,5) = NaN;
            
            % Convert from decimal minutes to decimal degrees
            gps(:,[4 5]) = dm2dd(gps(:,[4 5]));
            
            % Create or replace sensors drv_latitude/drv_longitude with
            % converted m_gps_lat and/or m_gps_lon if they exist
            % Interpolate the lats and lons using the specified method
            try
                i_lat = interpTimeSeries(gps(:,[3 4]),...
                    'method',...
                    value);
            catch ME
                fprintf(2,...
                    'Dbd:fillGps: Interpolation error (%s:%s).\n',...
                    ME.identifier,...
                    ME.message);
                i_lat = gps(:,4);
            end
            try
                i_lon = interpTimeSeries(gps(:,[3 5]),...
                    'method',...
                    value);
            catch ME
                fprintf(2,...
                    'Dbd:fillGps:m_gps_lon: Interpolation error (%s:%s).\n',...
                    ME.identifier,...
                    ME.message);
                i_lon = gps(:,5);
            end

            % Replace the sensor data with the interpolated values
            obj.addSensor('drv_latitude', i_lat);                
            obj.addSensor('drv_longitude', i_lon);
                
        end
        
    end
    
end
