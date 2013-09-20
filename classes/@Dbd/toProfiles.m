function pStruct = toProfiles(obj, varargin)
%
% pStruct = Dbd.toProfiles(varargin)
%
% Creates a structured array in which each element of the array is an
% indexed profile taken from the Dbd instance.  Each element contains a 'meta'
% field, which contains the profile metadata.  All other fields are sensor 
% names and contain the individual sensor data arrays.
%
% Name/Value options:
%   'sensors': a string or cell array of strings containing the sensors to
%       include.  Any sensor name not contained in the Dbd instance results
%       in a NaN-filled column.
%   'squeeze': logical value which, if set to true, removes all rows from
%       the profile sensor array in which the Dbd.timestamp sensor AND
%       Dbd.depthSensor are NaN.  Default is false.
%   'depthbin': numeric scalar specifying a bin interval for binning the
%       profile data.  Default is no binning.
%
% See also Dbd Dbd.toArray
% ============================================================================
% $RCSfile: toProfiles.m,v $
% $Source: /home/kerfoot/cvsroot/slocum/matlab/spt/classes/@Dbd/toProfiles.m,v $
% $Revision: 1.1.1.1 $
% $Date: 2013/09/13 18:51:19 $
% $Author: kerfoot $
% ============================================================================
%

pStruct = [];

% Validate inputs
if ~isa(obj, 'Dbd')
    error('Dbd:toProfiles',...
        'Method can only be attached to the Dbd class');
elseif ~isequal(0, mod(length(varargin),2))
    error('Dbd:toProfiles:nargin',...
        'Invalid number of name,value options specified.');
end

metaFields = {'glider',...
    'segment',...
    'sourceFile',...
    'the8x3filename',...
    'timestampSensor',...
    'depthSensor',...
    }';

% Defaults
sensors = obj.sensors;
SQUEEZE = false;
BIN_INC = NaN;
% Process options
for x = 1:2:length(varargin)
    
    name = varargin{x};
    value = varargin{x+1};
    
    switch lower(name)
        case 'sensors'
            if ~ischar(value) && ~iscellstr(value)
                error('Dbd:toProfiles:invalidDataType',...
                    'Value for option %s must be a string or cell array of strings.',...
                    name);
            elseif ischar(value)
                value = {value};
            end
            sensors = value;
        case 'squeeze'
            if ~isequal(numel(value), 1) || ~islogical(value)
                error('Dbd:toProfiles:invalidDataType',...
                    'Value for option %s must be logical.',...
                    name);
            end
            SQUEEZE = value;
        case 'depthbin'
            if isempty(value) ||...
                    ~isequal(numel(value),1) ||...
                    ~isnumeric(value)
                error('Dbd:toProfiles:invalidDataType',...
                    'Value for option %s must be a number indicating the size of the depth bin.',...
                    name);
            elseif value <= 0
                error('Dbd:toProfiles:invalidDataType',...
                    'Value for option %s must be greater than 0.',...
                    name);
            end
            BIN_INC = value;
        otherwise
            error('Dbd:toProfiles:invalidOption',...
                'Invalid option specified: %s.',...
                name);
    end
end

if isempty(obj.profileInds)
    return;
end

% Export the sensor data
[data, sensors] = obj.toArray('sensors', sensors);
if isempty(data)
    return;
end

for p = 1:size(obj.profileInds,1)
        
    r0 = obj.profileInds(p,1);
    r1 = obj.profileInds(p,2);
    
    % Grab the profile data
    pData = data(r0:r1,:);
    
    % Bin the data into BIN_INC depths if BIN_INC is not nan.
    if ~isnan(BIN_INC)
        pData = binner(pData, 2, BIN_INC);
        % Binning may result in rows for which all colums except for the depth
        % bin column are nans.  Eliminate these
        cols = setdiff(1:size(pData,2), 2);
        pData(all(isnan(pData(:,cols)),2),:) = [];
    end
    
    % If SQUEEZE is true, eliminate any row for which either the
    % obj.timestampSensor or obj.depthSensor is NaN
    if SQUEEZE
        pData(any(isnan(pData(:,1:2)),2),:) = [];
    end
    
    % Add metadata first
    meta = [];
    for m = 1:length(metaFields)
        meta.(metaFields{m}) = obj.(metaFields{m});
    end
    pStruct(p).meta = meta;
    
    % Add the sensor data
    for s = 1:length(sensors)
        pStruct(p).(sensors{s}) = pData(:,s);
    end
    
    % Add profile start and end times to pStruct(p).meta
    t = pStruct(p).timestamp;
    if isempty(regexp(obj.timestampSensor, '_datenum$', 'once'))
        t = epoch2datenum(t);
    end
    pStruct(p).meta.startDatenum = min(t);
    pStruct(p).meta.endDatenum = max(t);
    pStruct(p).meta.startTime = datestr(pStruct(p).meta.startDatenum,...
        'yyyy-mm-dd HH:MM:SS');
    pStruct(p).meta.endTime = datestr(pStruct(p).meta.endDatenum,...
        'yyyy-mm-dd HH:MM:SS');
    % Add profile min/max depths
    pStruct(p).meta.minDepth = min(pStruct(p).depth);
    pStruct(p).meta.maxDepth = max(pStruct(p).depth);
    
    % Calculate the mean lon and lat and add them as the meta field
    % 'lonLat'
    gps = obj.toArray('sensors', {'drv_longitude', 'drv_latitude'});
    gps(any(isnan(gps(:,[3 4])),2),:) = [];
    if isempty(gps)
        pStruct(p).meta.lonLat = [NaN NaN];
    else
        pStruct(p).meta.lonLat = mean(gps(:,[3 4]));
    end
    
    % If BIN_INC was specified, replace the original obj.depthSensor depths 
    % with the binned depths
    if ~isnan(BIN_INC)
        pStruct(p).(obj.depthSensor) = pData(:,2);
    end
    
    % Determine profile direction and add to pStruct(p).meta
    z = pStruct(p).depth(~isnan(pStruct(p).depth));
    switch z(1) - z(end) < 0
        case 1
            pStruct(p).meta.direction = 'd';
        case 0
            pStruct(p).meta.direction = 'u';
        otherwise
            pStruct(p).meta.direction = '?';
    end
    
end

