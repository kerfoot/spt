function outFile = writeIoosGliderFlatNc(pStruct, varargin)
%
% outFile = writeIoosGliderFlatNc(pStruct[,varargin])
%
% Accepts a single profile contained in pStruct, returned from 
% mapIoosGliderFlatNcSensors.m, and writes a NetCDF file conforming to
% the IOOS National Glider Data Assembly Standard Specification, version 2.
%
% Options:
% 'mode', [STRING]: file type which can be either 'rt' (real-time) or 'delayed'.
% 'clobber', [true or false]: by default, existing NetCDF files are not 
%   overwritten.  Set to true to overwrite existing files.
% 'ncschema', STRUCT: structured array mapping global NetCDF file
%   attributes to values.  If not specified, default values are taken from 
%   the NetCDF template file.
% 'outfile', STRING: the NetCDF filename is constructed from the .meta
%   field.  Use this option to specify a custom filename.
% 'outdirectory', STRING: NetCDF files are written to the current working
%   directory.  Use this option to specify an alternate path.
% 'mode', STRING: the state of the dataset, which can be either 'rt' for
%   real-time (i.e.: sbd/tbd  files) or 'delayed' for a recovered dataset (i.e.:
%   dbd/ebd files).  Default is rt.
%
% See also mapIoosGliderFlatNcSensors getIoosGliderFlatNcSensorMappings loadNcJsonSchema
%

outFile = '';
app = mfilename;

REQUIRED_FIELDS = {'meta',...
    'vars',...
    'profile_id',...
    }';
REQUIRED_NC_VARS = {'time',...
    'trajectory',...
    'lat',...
    'lon',...
    'depth',...
    'temperature',...
    'salinity',...
    'density',...
    'time_uv',...
    'lat_uv',...
    'lon_uv',...
    'u',...
    'v',...
    'profile_id',...
    'profile_time',...
    'profile_lat',...
    'profile_lon',...
    }';
MODES = {'rt',...
    'delayed',...
    }';
DATENUM_CUTOFF = datenum(2100,1,1);
% Validate input args
if nargin < 2
    warning(sprintf('%s:nargin', app),...
        '2 arguments are required.\n');
    return;
elseif ~isstruct(pStruct) ||...
        ~isequal(length(pStruct),1) ||...
        ~isequal(length(REQUIRED_FIELDS), length(intersect(REQUIRED_FIELDS,fieldnames(pStruct))))
    warning(sprintf('%s:invalidArgument', app),...
        'pStruct must be a structured array containing appropriate fields.\n');
    return;
elseif isempty(pStruct.meta) || isempty(pStruct.vars)
    warning(sprintf('%s:invalidArgument', app),...
        'pStruct fields are empty.\n');
    return;
elseif isempty(pStruct.profile_id) || isnan(pStruct.profile_id)
    warning(sprintf('%s:invalidProfileId', app),...
        'The pStruct does not contain a valid profile_id\n');
    return;
end

% Default options
CLOBBER = false;
NC_SCHEMA = [];
OUT_DIR = pwd;
outFile = '';
MODE = MODES{1};
% Process options
for x = 1:2:length(varargin)
    name = varargin{x};
    value = varargin{x+1};
    switch lower(name)
        case 'clobber'
            if ~isequal(numel(value),1) || ~islogical(value)
                error(sprintf('%s:invalidOptionValue', app),...
                    'Value for option %s must be a logical value',...
                    name);
            end
            CLOBBER = value;
        case 'ncschema'
            if ~isstruct(value) || ~isequal(length(struct),1)
                error(sprintf('%s:invalidOptionValue', app),...
                    'Value for option %s must be a structured array mapping attribute names to values',...
                    name);
            end
            NC_SCHEMA = value;
        case 'outfilename'
            if ~ischar(value) || isempty(value)
                error(sprintf('%s:invalidOptionValue', app),...
                    'Value for option %s must be a string specifying the filename to write',...
                    name);
            end
            outFile = value;
        case 'outdirectory'
            if ~ischar(value) || isempty(value) || ~isdir(value)
                error(sprintf('%s:invalidOptionValue', app),...
                    'Value for option %s must be a string specifying a valid directory to write',...
                    name);
            end
            OUT_DIR = value;
        case 'mode'
            if ~ischar(value) || isempty(value) || ~ismember(value, MODES)
                fprintf(2,...
                    '%s: Value for option %s must be a string specifying the file type (''realtime'' or ''delayed'')\n',...
                    app,...
                    name);
                return;
            end
            MODE = value;
        otherwise
            error(sprintf('%s:invalidOption', app),...
                'Invalid option specified: %s',...
                name);
    end
end

% We need the template file
NC_TEMPLATE = 'IOOS_Glider_NetCDF_v2.0.nc';
if ~exist(NC_TEMPLATE, 'file')
    fprintf(2,...
        '%s:ncTemplateNotFound: The NetCDF template %s could not be found\n',...
        app,...
        NC_TEMPLATE);
    return;
end

% Grab the template info file as a structured array
try
    nci = ncinfo(NC_TEMPLATE);
catch ME
    fprintf(2,...
        '%s:%s: %s\n',...
        app,...
        ME.identifer,...
        ME.message);
    return;
end

% Get the list of variables in the template
NC_VARS = {nci.Variables.Name}';
PROFILE_VARS = {pStruct.vars.ncVarName}';

% Make sure we have the REQUIRED_VARIABLES in PROFILE_VARS
if ~isequal(length(intersect(REQUIRED_NC_VARS, PROFILE_VARS)),length(REQUIRED_NC_VARS))
    fprintf(2,...
        '%s:missingRequiredVariable: pStruct is missing one or more required variables\n',...
        app);
    return;
end
% Make sure we have variables in PROFILE_VARS that are also in NC_VARS
VARS = intersect(NC_VARS, PROFILE_VARS);
if isempty(VARS)
    fprintf(2,...
        '%s:noVariablesFound: pStruct does not contain any valid NetCDF variables\n',...
        app);
    return;
end

% Create the filename, if not specified
if isempty(outFile)
    outFile = fullfile(OUT_DIR,...
        sprintf('%s_%s_%s.nc',...
            pStruct.meta.glider,...
            datestr(pStruct.meta.startDatenum, 'yyyymmddTHHMMZ'),...
            MODE));
else
    ncP = fileparts(outFile);
    if ~isdir(ncP)
        warning(sprintf('%s:invalidDirectory', app),...
            'The specified output directory does not exist: %s\n',...
            ncP);
        outFile = '';
        return;
    end
end

% Delete the current file, if it exists and CLOBBER is set to true
if exist(outFile, 'file')
    if CLOBBER
        fprintf(1,...
            'Clobbering existing file: %s\n',...
            outFile);
        try
            delete(outFile);
        catch ME
            fprintf('%s:%s\n',...
                ME.identifier,...
                ME.message);
            return;
        end
    else
        fprintf(2,...
            '%s: File already exists and will not be overwritten: %s\n',...
            app,...
            outFile);
        outFile = '';
        return;
    end
end

% If a ncschema structured array was specified, update the global attributes
% with the elements in NC_SCHEMA.Attributes
schemaVars = {};
if ~isempty(NC_SCHEMA)
    schemaVars = {NC_SCHEMA.Variables.Name}';
    schemaAtts = {NC_SCHEMA.Attributes.Name}';
    nciAtts = {nci.Attributes.Name}';
    for a = 1:length(schemaAtts)
        [~,I] = ismember(schemaAtts{a}, nciAtts);
        if isequal(I,0)
            I = length(nci.Attributes) + 1;
        elseif isempty(deblank(NC_SCHEMA.Attributes(a).Value))
            continue;
        end
        nci.Attributes(I).Name = schemaAtts{a};
        nci.Attributes(I).Value = NC_SCHEMA.Attributes(a).Value;
    end
end
    
% Add some specific global attributes
creationTimestamp = datestr(now, 'YYYY-mm-ddTHH:MM:SSZ');
% Global date_created attribute
[~,I] = ismember('date_created', {nci.Attributes.Name}');
if isequal(I,0)
    I = length(nci.Attributes) + 1;
    nci.Attributes(I).Name = 'date_created';
end
nci.Attributes(I).Value = creationTimestamp;
% Global date_issued attribute
[~,I] = ismember('date_issued', {nci.Attributes.Name}');
if isequal(I,0)
    I = length(nci.Attributes) + 1;
    nci.Attributes(I).Name = 'date_issued';
end
nci.Attributes(I).Value = creationTimestamp;
% Global history attribute
[~,I] = ismember('history', {nci.Attributes.Name}');
if isequal(I,0)
    I = length(nci.Attributes) + 1;
    nci.Attributes(I).Name = 'history';
end
nci.Attributes(I).Value = char(nci.Attributes(I).Value, [datestr(now, 'yyyy-mm-ddTHH:MM:SSZ') ' ' mfilename('fullpath') '.m']);
% title and id identifier
id = sprintf('%s-%s',...
    pStruct.meta.glider,...
    datestr(pStruct.meta.startDatenum, 'yyyymmddTHHMM'));
% Global title attribute
[~,I] = ismember('title', {nci.Attributes.Name}');
if isequal(I,0)
    I = length(nci.Attributes) + 1;
    nci.Attributes(I).Name = 'title';
end
nci.Attributes(I).Value = id;
% Global title attribute
[~,I] = ismember('id', {nci.Attributes.Name}');
if isequal(I,0)
    I = length(nci.Attributes) + 1;
    nci.Attributes(I).Name = 'id';
end
nci.Attributes(I).Value = id;

% Template Dimensions
NC_DIMS = {nci.Dimensions.Name}';
% Handle dimension variables first (REQUIRED_NC_VARS)
% TIME dimension
[~,timeDI] = ismember('time', NC_DIMS);
[~,VI] = ismember('time', PROFILE_VARS);
% Time dimension cannot have missing values, so get a row index of non-nan
% values to remove records for variables dimensioned along time.
goodT = find(~isnan(pStruct.vars(VI).data));
timeLength = length(goodT);
% timeLength = length(pStruct.vars(VI).data);
nci.Dimensions(timeDI).Length = timeLength;
nci.Dimensions(timeDI).Unlimited = false;

% traj_strlen dimension
[~,trajDI] = ismember('traj_strlen', NC_DIMS);
[~,VI] = ismember('trajectory', PROFILE_VARS);
% Confirm that pStruct.vars(VI).data is a string
if ~ischar(pStruct.vars(VI).data)
    fprintf(2,...
        '%s:invalidDataType: trajectory data must be a string specified as: glider-YYYYmmddTHHMM\n',...
        app);
    delete(outFile);
    outFile = '';
end
trajStrLength = length(pStruct.vars(VI).data);
nci.Dimensions(trajDI).Length = trajStrLength;
nci.Dimensions(trajDI).Unlimited = false;

% Update the nci.Variables.Dimensions length and unlimited settings
timeVars = {};
for v = 1:length(nci.Variables)
    
% % % % %     if strcmp(nci.Variables(v).Name, 'platform')
% % % % %         keyboard;
% % % % %     end
    
    if ~isempty(nci.Variables(v).Dimensions)
        varDims = {nci.Variables(v).Dimensions.Name}';

        [~,I] = ismember('time', varDims);
        if ~isequal(I,0)
            timeVars{end+1} = nci.Variables(v).Name;
            nci.Variables(v).Dimensions(I).Length = timeLength;
            nci.Variables(v).Dimensions(I).Unlimited = false;
            nci.Variables(v).Size = timeLength;
        end

        [~,I] = ismember('traj_strlen', varDims);
        if ~isequal(I,0)
            nci.Variables(v).Dimensions(I).Length = trajStrLength;
            nci.Variables(v).Dimensions(I).Unlimited = false;
            nci.Variables(v).Size = trajStrLength;
        end
    end
        
    % Skip the rest of the block if no NC_SCHEMA was specified
    if isempty(schemaVars)
        continue;
    end
    
    % Skip the rest of this block if this variable is not defined in the NC_SCHEMA
    [~,I] = ismember(nci.Variables(v).Name, schemaVars);
    if isequal(I,0)
        continue;
    end
    
    % List of NC_SCHEMA variable attributes
    varAtts = {NC_SCHEMA.Variables(I).Attributes.Name}';
    % List of nci variable attributes
    nciAtts = {nci.Variables(v).Attributes.Name}';
    % Loop through the NC_SCHEMA attributes and update/add to the nci variable
    % attributes
    for a = 1:length(varAtts)
        [~,J] = ismember(varAtts{a}, nciAtts);
        if isequal(J,0)
            J = length(nci.Variables(v).Attributes) + 1;
        elseif ischar(NC_SCHEMA.Variables(I).Attributes(a).Value) && isempty(deblank(NC_SCHEMA.Variables(I).Attributes(a).Value))
            continue;
        elseif isempty(NC_SCHEMA.Variables(I).Attributes(a).Value)
            continue;
        end
        nci.Variables(v).Attributes(J).Name = varAtts{a};
        nci.Variables(v).Attributes(J).Value = NC_SCHEMA.Variables(I).Attributes(a).Value;
    end
    
end

% Create the file
try
    ncwriteschema(outFile, nci);
    fprintf(1,...
        'Writing NetCDF: %s\n',...
        outFile);
catch ME
    fprintf(2,...
        '%s:%s: %s\n',...
        app,...
        ME.identifier,...
        ME.message);
    outFile = '';
    return;
end

for v = 1:length(PROFILE_VARS)
    
    PROFILE_VARS{v};
    
    [~,I] = ismember(PROFILE_VARS{v}, NC_VARS);
    if isequal(I,0)
        fprintf(2,...
            '%s: No NetCDF variable definition found\n',...
            PROFILE_VARS{v});
        continue;
    elseif isempty(pStruct.vars(v).data)
% % % % %         fprintf(2,...
% % % % %             '%s: Variable contains no data\n',...
% % % % %             PROFILE_VARS{v});
        continue;
    end
    
    % If this variable uses 'time' as a dimension, remove any records that have
    % a missing timestamp
    if ismember(PROFILE_VARS{v}, timeVars)
        pStruct.vars(v).data = pStruct.vars(v).data(goodT);
    end
    
    if ~isequal(length(pStruct.vars(v).data), nci.Variables(I).Size)
% % % % %         fprintf(2,...
% % % % %             '%s: Data array does not match NetCDF variable size definition\n',...
% % % % %             PROFILE_VARS{v});
        continue;
    end
    
    % Convert matlab datenum times to unix times if the variable is 'time'
    if ~isempty(regexp(PROFILE_VARS{v}, 'time', 'once'))
        meanVal = mean(pStruct.vars(v).data(~isnan(pStruct.vars(v).data)));
        if meanVal < DATENUM_CUTOFF
            pStruct.vars(v).data = datenum2epoch(pStruct.vars(v).data);
        end
    end
    
    % Replace NaNs with _FillValues
    pStruct.vars(v).data(isnan(pStruct.vars(v).data)) = nci.Variables(I).FillValue;
    
    % Write the data
    try
        ncwrite(outFile, PROFILE_VARS{v}, pStruct.vars(v).data);
    catch ME
        fprintf(2,...
            '%s: %s\n',...
            PROFILE_VARS,...
            ME.message);
        continue;
    end
    
end
