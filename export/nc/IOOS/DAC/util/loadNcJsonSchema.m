function ncSchema = loadNcJsonSchema(jsonFile, varargin)
%
% ncSchema = loadNcJsonSchema(jsonFile[, varargin])
%
% Parses jsonFile and returns a structured array representing the NetCDF
% file schema.  ncSchema is a structured array mimicing the output from
% ncinfo.  The following fields are included:
%
%   Dimensions
%   Attributes
%   Variables
%
% This function requires the JSONlab toolbox, located at:
%
%   http://iso2mesh.sourceforge.net/cgi-bin/index.cgi?jsonlab
%
% See also loadjson writeIoosGliderFlatNc 
%
% ============================================================================
% $RCSfile: loadNcJsonSchema.m,v $
% $Source: /home/kerfoot/cvsroot/slocum/matlab/spt/export/nc/IOOS/DAC/util/loadNcJsonSchema.m,v $
% $Revision: 1.1 $
% $Date: 2014/06/06 19:21:32 $
% $Author: kerfoot $
% ============================================================================
%

app = mfilename;
ncSchema = [];
REQUIRED_FIELDS = {'Dimensions',...
    'Attributes',...
    'Variables',...
    }';
if isequal(nargin,0)
    fprintf('%s:nargin: no JSON file specified\n',...
        app);
    return;
elseif ~exist(jsonFile, 'file')
    fprintf('%s:invalidArgument: file %s does not exist\n',...
        app,...
        jsonFile);
    return;
end

% Use the iso2mesh toolbox to load the json into a matlab structured array
try
    js = loadjson(jsonFile);
catch ME
    fprintf('%s:invalidJson: %s\n',...
        app,...
        ME.message);
end

% make sure js has the required fields
if ~isequal(length(REQUIRED_FIELDS), length(intersect(fieldnames(js), REQUIRED_FIELDS)))
    fprintf('%s:invalidStructure: parsed JSON file %s is missing one or more required fields\n',...
        app,...
        jsonFile);
    return;
end

% Create the Dimensions structure
ncSchema.Dimensions = [];
for x = 1:length(js.Dimensions)
    ncSchema.Dimensions(x).Name = js.Dimensions{x};
    ncSchema.Dimensions(x).Length = 0;
    ncSchema.Dimensions(x).Unlimited = false;
end

% Convert the js.Attributes cell array to a structured array
ncSchema.Attributes = [];
for x = 1:length(js.Attributes)
    ncSchema.Attributes = [ncSchema.Attributes js.Attributes{x}];
end

% Convert js.Variables cell array to a structured array mimicing the return
% value from ncread
for v = 1:length(js.Variables)
    
    ncSchema.Variables(v) = struct('Name', js.Variables{v}.Name,...
        'Attributes', struct('Name', '', 'Value', []));
    
    for a = 1:length(js.Variables{v}.Attributes)
        ncSchema.Variables(v).Attributes(a).Name = js.Variables{v}.Attributes{a}.Name;
        ncSchema.Variables(v).Attributes(a).Value = js.Variables{v}.Attributes{a}.Value;
    end
end
