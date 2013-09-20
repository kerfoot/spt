function pStruct = toProfiles(obj, varargin)
%
% pStruct = DbdGroup.toProfiles(varargin)
%
% Creates a structured array in which each element of the array is an
% indexed profile taken from all DbdGroup instances in the DbdGroup.  Each
% element contains a 'meta' field, which contains the profile metadata.
% All other fields are sensor names and contain the individual sensor data
% arrays.
%
% Name/Value options:
%   't0': a datenum numeric scalar specifying the minimum timestmap for
%       exported profiles.
%   't1': a datenum numeric scalar specifying the minimum timestmap for
%       exported profiles.
%   'sensors': a string or cell array of strings containing the sensors to
%       include.  Any sensor name not contained in the Dbd instance results
%       in a NaN-filled column.
%   'squeeze': logical value which, if set to true, removes all rows from
%       the profile sensor array in which the Dbd.timestamp sensor AND
%       Dbd.depthSensor are NaN.  Default is false.
%   'depthbin': numeric scalar specifying a bin interval for binning the
%       profile data.  Default is no binning.
%
% See also DbdGroup DbdGroup.toArray
% ============================================================================
% $RCSfile: toProfiles.m,v $
% $Source: /home/kerfoot/cvsroot/slocum/matlab/spt/classes/@DbdGroup/toProfiles.m,v $
% $Revision: 1.1.1.1 $
% $Date: 2013/09/13 18:51:19 $
% $Author: kerfoot $
% ============================================================================
%

pStruct = [];

% Validate inputs
% Validate inputs
if ~isa(obj, 'DbdGroup')
    error('DbdGroup:toProfiles',...
        'Method can only be attached to the DbdGroup class');
elseif ~isequal(0, mod(length(varargin),2))
    error('DbdGroup:toProfiles:nargin',...
        'Invalid number of name,value options specified.');
end

% Process options
t0 = NaN;
t1 = NaN;
sensors = {};
SQUEEZE = false;
BIN_INC = NaN;
for x = 1:2:length(varargin)
    name = varargin{x};
    value = varargin{x+1};
    switch lower(name)
        case 't0'
            if ~isequal(numel(value),1) || ~isnumeric(value)
                error('DbdGroup:toProfiles:invalidDataType',...
                    'Value for option %s must be a numeric datenum scalar.',...
                    name);
            end
            t0 = value;
        case 't1'
            if ~isequal(numel(value),1) || ~isnumeric(value)
                error('DbdGroup:toProfiles:invalidDataType',...
                    'Value for option %s must be a numeric datenum scalar.',...
                    name);
            end
            t1 = value;
        case 'sensors'
            if ~ischar(value) && ~iscellstr(value)
                error('DbdGroup:toProfiles:invalidDataType',...
                    'Value for option %s must be a string or cell array of strings.',...
                    name);
            elseif ischar(value)
                value = {value};
            end
            sensors = value;
        case 'squeeze'
            if ~isequal(numel(value), 1) || ~islogical(value)
                error('DbdGroup:toProfiles:invalidDataType',...
                    'Value for option %s must be logical.',...
                    name);
            end
            SQUEEZE = value;
        case 'depthbin'
            if isempty(value) ||...
                    ~isequal(numel(value),1) ||...
                    ~isnumeric(value)
                error('DbdGroup:toProfiles:invalidDataType',...
                    'Value for option %s must be a number indicating the size of the depth bin.',...
                    name);
            elseif value <= 0
                error('DbdGroup:toProfiles:invalidDataType',...
                    'Value for option %s must be greater than 0.',...
                    name);
            end
            BIN_INC = value;
        otherwise
            fprintf(2,...
                'DbdGroup.%s: Invalid option: %s\n',...
                mfilename,...
                name);
            return;
    end
end

% Dump all sensors if none specified
if isempty(sensors)
    sensors = obj.sensors;
end
sensors = sensors(:);

% Find dbd instances that are within t0 and t1, if specified
startTs = obj.startDatenums;
endTs = obj.endDatenums;
dbd0 = (1:length(obj.dbds))';
if ~isnan(t0)
    dbd0 = find(endTs >= t0);
end
dbd1 = (1:length(obj.dbds))';
if ~isnan(t1)
    dbd1 = find(startTs <= t1);
end
% The intersection of dbd0 and dbd1 contains the dbd instance indices that
% fit within the specified time frame
r = intersect(dbd0, dbd1);
if isempty(r)
    warning('DbdGroup:toProfiles',...
        'The DbdGroup contains no Dbd instances withing the specified time frame.');
    return;
end

% Fill in the return array
for x = 1:length(r)
        
    dbdProfiles = obj.dbds(r(x)).toProfiles('sensors', sensors,...
        'squeeze', SQUEEZE,...
        'depthbin', BIN_INC);
    if isempty(dbdProfiles)
        continue;
    end
    
    pStruct = [pStruct dbdProfiles];
    
end
