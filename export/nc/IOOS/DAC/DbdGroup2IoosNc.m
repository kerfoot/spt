function num_files = DbdGroup2IoosNc(dgroup, trajectoryTs, varargin)
%
% num_files = DbdGroup2IoosNc(dgroup, trajectoryTs, varargin)
%
% Accepts a single profile contained in pStruct, returned from 
% mapIoosGliderFlatNcSensors.m, and writes a NetCDF file conforming to
% the IOOS National Glider Data Assembly Standard Specification, version 2.
%
% Options:
% 'clobber', [true or false]: by default, existing NetCDF files are not 
%   overwritten.  Set to true to overwrite existing files.
% 'ncschema', STRUCT: structured array mapping global NetCDF file
%   attributes to values.  If not specified, default values are taken from 
%   the NetCDF template file.
% 'outputdir', STRING: NetCDF files are written to the current working
%   directory.  Use this option to specify an alternate path.
% 'profiletype', STRING: type of profile to process.  Acceptable values are 'd'
%   (down), 'u' (up) or 'a' (all).  Default is all.
% 'startprofilenum', NUMBER: Number specifying the first value that should be
%   used for the NetCDF profile_id variable, which defaults to 1.  This value is
%   incremented for each subsequent profile.
% 
% See also mapIoosGliderFlatNcSensors writeIoosGliderFlatNc

num_files = 0;
app = mfilename;

% Validate arguments
if nargin < 2
    error(sprintf('%s:nargin', app),...
        'Please specify a DbdGroup and trajectory/deployment datenum value\n');
elseif ~isa(dgroup, 'DbdGroup')
    error(sprintf('%s:invalidArgument', app),...
        'First argument is not a DbdGroup instance');
elseif ~isequal(numel(trajectoryTs),1) || ~isnumeric(trajectoryTs)
    fprintf(2,...
        '%s: trajectoryTs must be a datenum value specifying the deployment start date/time\n',...
        app);
    return;
elseif ~isequal(mod(length(varargin),2),0)
    error(sprintf('%s:varargin', app),...
        'Invalid number of name,value options specified');
end

PROFILE_TYPES = {'a',...
    'd',...
    'u',...
    }';
% Default options
NC_SCHEMA = [];
OUTPUT_DIR = pwd;
INTERP_SENSORS = {};
INTERP_ALL_SENSORS = false;
CLOBBER = true;
PROFILE_TYPE = PROFILE_TYPES{1};
FIRST_PROFILE_NUM = 1;
% Process option
for x = 1:2:length(varargin)
    name = varargin{x};
    value = varargin{x+1};
    switch lower(name)
        case 'ncschema'
            if ~isstruct(value)
                fprintf('%s:invalidOption: Invalid NetCDF schema specified\n',...
                    app);
                return;
            end
            NC_SCHEMA = value;
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
            if isempty(value) || ~isequal(numel(value),1) || ~islogical(value)
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
        case 'profiletype'
            if ~ischar(value) || ~ismember(value, PROFILE_TYPES)
                fprintf(2,...
                    'Value for option %s must be either ''a'' | ''d'' | ''u''\n',...
                    name);
                return;
            end
            PROFILE_TYPE = value;
        case 'startprofilenum'
            if ~isequal(numel(value),1) || ~isnumeric(value)
                fprintf(2,...
                    'Value for option %s must be a single number\n',...
                    name);
                return;
            end
            FIRST_PROFILE_NUM = value;
        otherwise
            error(sprintf('%s:invalidOption', app),...
                'Invalid option specified: %s',...
                name);
    end
end

% Make sure there are segments in dgroup.newSegments
% See if we have new segments to process
if ~isstruct(dgroup.scratch) || ~isfield(dgroup.scratch, 'newNc')
    fprintf(2,...
        '%s: dgroup.scratch.newNc does not exist\n',...
        app);
    return;
elseif isempty(dgroup.scratch.newNc)
    fprintf(1,...
        'No new segments to process: dgroup.scratch.newNc\n');
    return;
end

pCount = FIRST_PROFILE_NUM;

% dgroup.newSegments contains the list of new segments to process in descending
% chronological order (most recent is listed first).  Sort this list in
% ascending chronological order so that the profile numbers are also sorted in
% ascending chronological order.
sortedSegments = sortDbds(dgroup.scratch.newNc);
for s = 1:length(sortedSegments)
    
    % 1. Find the Dbd instance
    [TF,dbd_ind] = ismember(sortedSegments{s}, dgroup.segments);
    if ~TF
        continue;
    end
    
    % Create a reference copy of the Dbd instance
    dbd = dgroup.dbds(dbd_ind);
    
    % Write the NetCDF file if the dbd contains indexed profiles
    if isequal(dgroup.dbds(dbd_ind).numProfiles,0)
        continue;
    end
    
    % Export the profile structure
    pStruct = dbd.toProfiles();
    
    % Remove downs or ups, if specified using the profiletype option
    switch PROFILE_TYPE
        case 'd'
            pMeta = cat(1, pStruct.meta);
            pTypes = cat(1, pMeta.direction);
            pStruct(pTypes == 'u') = [];
        case 'u'
            pMeta = cat(1, pStruct.meta);
            pTypes = cat(1, pMeta.direction);
            pStruct(pTypes == 'd') = [];
    end
    
    % Skip this Dbd instance if no profiles remain
    if isempty(pStruct)
        fprintf(1,...
            'Dbd instance (%s) contains no profiles of type: %s\n',...
            dbd.segment,...
            PROFILE_TYPE);
        continue;
    end
    
    % Map the glider sensor names to the NetCDF variables and return the
    % structured array of profiles
    ncStruct = mapIoosGliderFlatNcSensors(pStruct, trajectoryTs);
    
    % Update each .profile_id field of ncStruct with a new profile index
    % starting from FIRST_PROFILE_NUM
    for p = 1:length(ncStruct)
        ncVars = {ncStruct(p).vars.ncVarName};
        [~,pInd] = ismember('profile_id', ncVars);
        ncStruct(p).vars(pInd).data = pCount;
        pCount = pCount + 1;
    end
    
    fprintf(1,...
        'Writing NetCDF for segment: %s\n',...
        dgroup.dbds(dbd_ind).segment);
    
    for p = 1:length(ncStruct)
        
        try
            nc_file = writeIoosGliderFlatNc(ncStruct(p),...
                'ncschema', NC_SCHEMA,...
                'outdirectory', OUTPUT_DIR,...
                'clobber', CLOBBER);
        catch ME
            warning(ME.identifier, ME.message);
            continue;
        end
        
        if ~isempty(nc_file)
            num_files = num_files + 1;
        end
    end

    
end
