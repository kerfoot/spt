function num_files = DbdGroup2TrajectoryNc(dgroup, varargin)

num_files = 0;
app = mfilename;

% Validate arguments
if isequal(nargin,0)
    error(sprintf('%s:nargin', app),...
        'No DbdGroup instance specified');
elseif ~isa(dgroup, 'DbdGroup')
    error(sprintf('%s:invalidArgument', app),...
        'First argument is not a DbdGroup instance');
elseif ~isequal(mod(length(varargin),2),0)
    error(sprintf('%s:varargin', app),...
        'Invalid number of name,value options specified');
end

% Default options
NC_TEMPLATE = which('IOOS_trajectory_template.nc');
OUTPUT_DIR = pwd;
INTERP_SENSORS = {};
INTERP_ALL_SENSORS = false;
CLOBBER = true;
WMO_ID = '';
% Process option
for x = 1:2:length(varargin)
    name = varargin{x};
    value = varargin{x+1};
    switch lower(name)
        case 'nctemplate'
            if ~ischar(value) || ~exist(value, 'file')
                fprintf('%s:invalidOption: Invalid NetCDF template specified\n',...
                    app);
                return;
            end
            NC_TEMPLATE = value;
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
        case 'wmoid'
            if ~ischar(value)
                warning(sprintf('%s:invalidOptionValue', app),...
                    'Value for option %s must be a string specifying a valid WMO id',...
                    name);
                continue;               
            end
            WMO_ID = value;
        otherwise
            error(sprintf('%s:invalidOption', app),...
                'Invalid option specified: %s',...
                name);
    end
end

% Make sure NC_TEMPLATE is valid
if isempty(NC_TEMPLATE)
    fprintf('%s:invalidOption: No NetCDF template specified: %s\n',...
        app,...
        NC_TEMPLATE);
    return;
elseif ~exist(NC_TEMPLATE, 'file')
    fprintf('%s:invalidOption: Invalid NetCDF template specified: %s\n',...
        app,...
        NC_TEMPLATE);
    return;
end
% Make sure there are segments in dgroup.newSegments
if isempty(dgroup.newSegments)
    fprintf(1,...
        'The DbdGroup does not contain any new segments (DbdGroup.newSegments)\n');
    return;
end

for s = 1:length(dgroup.newSegments)
    
    % 1. Find the Dbd instance
    [TF,dbd_ind] = ismember(dgroup.newSegments{s}, dgroup.segments);
    if ~TF
        continue;
    end
    
    dbd = dgroup.dbds(dbd_ind);
    
    % Write the NetCDF file if the dbd contains indexed profiles
    if isequal(dgroup.dbds(dbd_ind).numProfiles,0)
        continue;
    end
    
    fprintf(1,...
        '%s: Writing NetCDF\n',...
        dgroup.dbds(dbd_ind).segment);
    
    try
        nc_file = Dbd2TrajectoryNc(dbd,...
            'nctemplate', NC_TEMPLATE,...
            'outputdir', OUTPUT_DIR,...
            'interpsensors', INTERP_SENSORS,...
            'interpallsensors', INTERP_ALL_SENSORS,...
            'clobber', CLOBBER,...
            'wmoid', WMO_ID);
    catch ME
        warning(ME.identifier, ME.message);
        continue;
    end

    if ~isempty(nc_file)
        num_files = num_files + 1;
    end
end
