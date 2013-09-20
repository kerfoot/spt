function [data, columns] = toArray(obj, varargin)
%
% [data, sensor_names] = toArray([varargin])
%
% Returns the dataset (data) contained in the DbdGroup instance as an MxN 
% array.  All sensors (DbdGroup.sensors) are included by default and are 
% returned in the columns cell array.  The first 2 elements in the cell
% array are 'timestamp' and 'depth' and contain copies of the timestamp and
% depth/pressure values of Dbd.timestampSensor and Dbd.depthSensor,
% respectively.
%
% The default behavior may be modified using name,value options pairs
%
%   'sensors': 'sensors': a cell array of strings containing the sensors to include.  Any 
%       sensor name not contained in the Dbd instance results in a NaN-filled 
%       column.
%   't0': datenum specifying the minimum timestamp to include.
%   't1': datenum specifying the maximum timestamp to include.
%   
% See also DbdGroup
% ============================================================================
% $RCSfile: toArray.m,v $
% $Source: /home/kerfoot/cvsroot/slocum/matlab/spt/classes/@DbdGroup/toArray.m,v $
% $Revision: 1.1.1.1 $
% $Date: 2013/09/13 18:51:19 $
% $Author: kerfoot $
% ============================================================================
% 

app = mfilename;

data = [];
columns = {};

% Validate inputs
% Validate inputs
if ~isa(obj, 'DbdGroup')
    error(sprintf('%s:invalidClass', app),...
        'Method can only be attached to the Dbd class');
elseif ~isequal(mod(length(varargin),2),0)
    error(sprintf('%s:nargin', app),...
        'Invalid number of name,value options specified.');
end

% Process options
T0 = NaN;
T1 = NaN;
sensorSet = obj.sensors;
for x = 1:2:length(varargin)
    name = varargin{x};
    value = varargin{x+1};
    switch lower(name)
       case 't0'
           if ~isequal(numel(value),1) || ~isnumeric(value)
                error(sprintf('%s:invalidDataType', app),...
                    'Value for option %s must be a numeric datenum scalar.',...
                    name);
            end
            T0 = value;
        case 't1'
            if ~isequal(numel(value),1) || ~isnumeric(value)
                error(sprintf('%s:invalidDataType', app),...
                    'Value for option %s must be a numeric datenum scalar.',...
                    name);
            end
            T1 = value;
        case 'sensors'
            % sensorSet must be a string or cell array of strings
            if ~ischar(value) && ~iscellstr(value)
                error('Dbd:toArray:invalidDataType',...
                    'Value for option %s must be a string or cell array of strings.',...
                    name);
            elseif ischar(value)
                value = {value};
            end
            sensorSet = value;
        otherwise
            error('Dbd:toArray:invalidOption',...
                'Invalid option specified: %s.',...
                name);
    end
end

sensorSet = sensorSet(:);

% Find dbd instances that are within T0 and T1, if specified
% % % % % startTs = obj.startDatenums;
% % % % % endTs = obj.endDatenums;
dbd0 = (1:length(obj.dbds))';
if ~isnan(T0)
    dbd0 = find(obj.endDatenums >= T0);
end
dbd1 = (1:length(obj.dbds))';
if ~isnan(T1)
    dbd1 = find(obj.startDatenums <= T1);
end
% The intersection of dbd0 and dbd1 contains the dbd instance indices that
% fit within the specified time frame
r = intersect(dbd0, dbd1);
if isempty(r)
    warning(sprintf('%s:noData', app),...
        'No Dbd instances within the specified time frame.');
    return;
end

% Initialize the return data array to NaNs
data = nan(sum(obj.rows(r)), length(sensorSet) + 3);

% Fill in the data array
r0 = 1;
r1 = 0;
for x = 1:length(r)
    
    r1 = r1 + obj.dbds(r(x)).rows;
        
    [dbdData, dbdSensors] = obj.dbds(r(x)).toArray('sensors', sensorSet);
    % All date searches are done using matlab datenum values.  If the Dbd
    % instance is in unix time (ie: doesn't end in _datenum), convert the
    % 'timestamp' (value from dbdData(:,1)) to datenum and prepend a column to
    % dbdData containing datenum values.  If the Dbd instance timestamp is
    % already in datenum units, just prepend it to dbdData
    if isempty(regexp(obj.dbds(r(x)).timestampSensor, '_datenum$', 'once'))
        dbdData = [epoch2datenum(dbdData(:,1)) dbdData];
    else
        dbdData = dbdData(:,[1 1:length(dbdSensors)]);
    end
    
    data(r0:r1,:) = dbdData;
    
    r0 = r1 + 1;
    
end

% Multiple segments, when joined together, may have out-of-order timestamps
% (much more common in older dbd files) across these segments. To preserve the 
% raw dataset, replace out-of-order timestamps with NaN.  Here's how we find
% out-of-order timestamps:
% 1. Sort column 1 (always the timestamp column) and keep the sort order,
%   I.
% 2. Take the difference of the sort order, diff(I).
% 3. Non-increasing or out-of-order timestamps have a diff(I) <= 0.  Set all
%   values in the row where I(diff(I) <= 0) timestamps to NaN.
% This should result in an array of only increasing timestamps or NaN
%   values.
[~,I] = sort(data(:,1));
% Eliminate I values that correspond to NaN values
I(isnan(data(I,1))) = [];
data(I(diff(I) <= 0),:) = NaN;

% data now contains all of the records from the Dbd instances that are
% within t0 and t1.  This may include rows at the beginning and end that
% fall outside of the specified time interval.
data(data(:,1) < T0,:) = [];
data(data(:,1) > T1,:) = [];
% Remove the first column from data as it was used to filter out bad time
% values using datenum units.
data(:,1) = [];

% Copy the list of sensors and prepend timestamp
columns = [{'timestamp', 'depth'}'; sensorSet];

