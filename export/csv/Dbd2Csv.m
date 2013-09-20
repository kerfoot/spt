function num_files = Dbd2Csv(dbd, varargin)
%
% num_files = Dbd2Csv(dbd, varargin)
%
% Write comma-separated value files for all indexed profiles contained in the
% Dbd instance.  All sensors contained in the Dbd are written.  File are
% named using the following convention:
%
%   glider_yyyymmddTHHMMSS_direction_pro.csv
%
% and are written to the same directory as the source dbd file used to create
% the Dbd instance (Dbd.sourceFile).
%
% Each file is written with the following metdata:
%
% glider
% Dbd.segment
% Dbd.filtype
% Dbd.the8x3filename
% datestr(Dbd.startDatenum)
% Dbd.numProfiles
% Max pressure (decibars)
% File Size (kilobytes)
% Mean lon/lat
%
% Each metadata line is written as token::value
%
% If the specified Dbd instance contains no indexed profiles, a single file is
% written containing only the Dbd instance metadata.
%
% Options:
%   'outputdir': alternate location for writing the .csv files
%   'bindepths': increment for binning by depth 
%   'sensors': cell array of sensors to write to each file
%
% See also Dbd
% ============================================================================
% $RCSfile: Dbd2Csv.m,v $
% $Source: /home/kerfoot/cvsroot/slocum/matlab/spt/export/csv/Dbd2Csv.m,v $
% $Revision: 1.1.1.1 $
% $Date: 2013/09/13 18:51:18 $
% $Author: kerfoot $
% ============================================================================
%

caller = mfilename;

num_files = 0;
        
% Validate inputs
if ~isa(dbd, 'Dbd')
    fprintf(2,...
        '%s: First argument must be an instance of the Dbd class.\n',...
        caller);
    return;
elseif ~isequal(mod(length(varargin),2),0)
    fprintf(2,...
        '%s: Invalid number of options specified.\n',...
        caller);
    return;
end

% DEFAULTS
DEST_DIR = '';
DEPTH_INTERVAL = NaN;
SENSORS = {};
for x = 1:2:length(varargin)
    name = varargin{x};
    value = varargin{x+1};
    
    switch lower(name)
        case 'outputdir'
            if ~ischar(value) || ~isdir(value)
                fprintf(2,...
                    '%s: Value for %s must be a valid directory\n',...
                    caller,...
                    name);
                return;
            end
            DEST_DIR = value;
        case 'depthbin'
            if ~isequal(numel(value),1) || ~isnumeric(value)
                fprintf(2,...
                    '%s: Value for %s must be a numeric scalar\n',...
                    caller,...
                    name);
                return;
            end
            DEPTH_INTERVAL = value;
        case 'sensors'
            if ~iscellstr(value)
                fprintf(2,...
                    '%s: Value for %s must be a cell array of sensors\n',...
                    caller,...
                    name);
                return;
            end
            SENSORS = value;
        otherwise
            fprintf(2,...
                '%s: Invalid option specified: %s\n',...
                caller,...
                name);
            return
    end
end

% Header lines to be written to every file even if the segment contains no
% indexed profiles
PROFILE_HEADER = struct('glider', dbd.glider,...
    'filename', dbd.segment,...
    'filetype', dbd.filetype,...
    'the8x3_filename', dbd.the8x3filename,...
    'file_start_time', datestr(dbd.startDatenum, 'yyyy-mm-dd HH:MM'),...
    'num_profiles_in_segment', num2str(dbd.numProfiles, '%0.0f'),...
    'max_pressure_decibars', '',...
    'file_size_kilobytes', num2str(dbd.bytes/1024, '%0.2f'),...
    'num_records', '0',...
    'profile_time', 'NaN',...
    'profile_lat', 'NaN',...
    'profile_lon', 'NaN',...
    'profile_max_pressure_decibars', 'NaN',...
    'profile_direction', 'x');

if isempty(DEST_DIR)
    DEST_DIR = fileparts(dbd.sourceFile);
end

% Store the maximum pressure from dbd.depthSensor in
% PROFILE_HEADER.max_pressure_decibars
z = dbd.toArray('sensors', dbd.depthSensor);
PROFILE_HEADER.max_pressure_decibars = sprintf('%0.2f', max(z(:,3)));

% If no profiles are contained in the segment, write an empty file with just
% the header info
if isequal(dbd.numProfiles,0)
    
    fName = sprintf('%s_%s_pro.csv',...
        dbd.glider,...
        datestr(dbd.startDatenum, 'yyyymmddTHHMMSS'));
    outFile = fullfile(DEST_DIR, fName);
    [fid, msg] = fopen(outFile, 'w+');
    if fid < 0
        fprintf(2,...
            '%s: %s\n',...
            caller,...
            msg);
        return;
    end
    
    headerLines = fieldnames(PROFILE_HEADER);
    for h = 1:length(headerLines)
        fprintf(fid,...
            '%%%s::%s\n',...
            headerLines{h},...
            PROFILE_HEADER.(headerLines{h}));
    end
    fclose(fid);

    return;
    
end

% Write all sensors if none were specified
if isempty(SENSORS)
    SENSORS = setdiff(dbd.sensors, {'timestamp', 'depth'});
end

% Export the profiles structured array
proData = dbd.toProfiles('sensors', SENSORS,...
    'depthbin', DEPTH_INTERVAL);
for p = 1:length(proData)
    
% % % % %     if strcmp(proData(p).meta.segment,'unit_247_2012_028_2_0')
% % % % %         keyboard;
% % % % %     end
    
    print_flag = true;
    
    % Get the mean timestamp of the profile
    ts = proData(p).timestamp;
    ts(isnan(ts)) = [];
    if isempty(ts)
        fprintf(2,...
            '%s: Profile %0.0f contains no valid timestamps.\n',...
            p);
        continue;
    end
    ts = mean(ts);
    % matlab formatted timestamp (datenum) should end in 'datenum$'.  If not,
    % assume epoch time and convert to matlab time
    if isempty(regexp(proData(p).meta.timestampSensor, 'datenum$', 'once'))
        ts = epoch2datenum(ts);
    end
    
    % Set profile time
    PROFILE_HEADER.profile_time = datestr(mean(ts), 'yyyy-mm-dd HH:MM:SS');
    % Set the profile max depth
    PROFILE_HEADER.profile_max_pressure_decibars =...
        num2str(max(proData(p).depth), '%0.2f');
    
    % Add the profile direction
    tDiff = sum(diff(proData(p).timestamp));
    if tDiff > 0
        PROFILE_HEADER.profile_direction = 'd';
    elseif tDiff < 0
        PROFILE_HEADER.profile_direction = 'u';
    end
    
    % Prepare the data array for writing and the format string
    data = nan(length(proData(p).timestamp),length(SENSORS));
    formatString = '';
    includedSensors = '%sensors::';
    sensorUnits = '%units::';
    for s = 1:length(SENSORS)
        formatString = sprintf('%s%%0.4f,',...
            formatString);
        includedSensors = sprintf('%s%s,',...
            includedSensors,...
            SENSORS{s});
        % Defautl sensor unit
        sensorUnit = 'nodim';
        if isfield(dbd.sensorUnits, SENSORS{s})
            sensorUnit = dbd.sensorUnits.(SENSORS{s});
        end
        sensorUnits = sprintf('%s%s,',...
            sensorUnits,...
            sensorUnit);
        data(:,s) = proData(p).(SENSORS{s});
    end
    % Replace the last comma of formatString with a newline
    formatString = [formatString(1:end-1) '\n'];
    % Remove the last comma of includedSensors
    includedSensors(end) = [];
    
    % Store the number of records in this profile
    PROFILE_HEADER.num_records = sprintf('%0.0f', size(data,1));
    
    % Calculate the mean longitude and latitude of the profiles and add it to
    % the header
    PROFILE_HEADER.profile_lat = sprintf('%0.6f', proData(p).meta.lonLat(2));
    PROFILE_HEADER.profile_lon = sprintf('%0.6f', proData(p).meta.lonLat(1));
    
    % Create the filename: glider_yyyymmddTHHMMSS_direction_pro.csv
    fName = sprintf('%s_%s_pro.csv',...
        proData(p).meta.glider,...
        datestr(ts, 'yyyymmddTHHMMSS'));
    outFile = fullfile(DEST_DIR, fName);
    [fid, msg] = fopen(outFile, 'w+');
    if fid < 0
        fprintf(2,...
            '%s: %s\n',...
            caller,...
            msg);
        return;
    end
    
    % Print the header
    headerLines = fieldnames(PROFILE_HEADER);
    for h = 1:length(headerLines)
        fprintf(fid,...
            '%%%s::%s\n',...
            headerLines{h},...
            PROFILE_HEADER.(headerLines{h}));
    end
    
    % Print the included sensors
    fprintf(fid, '%s\n', includedSensors);
    % Print the sensor units
    fprintf(fid, '%s\n', sensorUnits);
    
    % If print_flag is false, there are no observations to print.  Close up
    % the file and skip to the next profile
% % % % %     if ~print_flag
% % % % %         fclose(fid);
% % % % %         continue;
% % % % %     end
    
    % Write the data
    fprintf(fid, formatString, data');
    
    % Close the file
    fclose(fid);
    
    % Increment the file counter
    num_files = num_files + 1;
    
end
