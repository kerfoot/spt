function dbd_struct = toStruct(obj, varargin)
%
% struct = toStruct(varargin)
%
% Returns a structured array mapping sensor names to the data arrays for all
% of the sensors contained in the DbdGroup instance.  Two additional fields, 
% 'timestamp' and 'depth' are also added and contain the timestamp and depth 
% values, respectively, for DbdGroup.timestampSensor and DbdGroup.depthSensor.
%
% If DbdGroup.fillTimes and/or DbdGroup.fillDepths are set to a valid interp1.m
% interpolation method, these sensor data arrays will contain interpolated
% data values.
%
% Options:
%   'sensors': a cell array of strings containing the sensor set to
%       include.  By default, all sensors in the DbdGroup instance are
%       included.
%   't0': single matlab datenum value specifying the minumum record
%       timestamp.
%   't1': single matlab datenum value specifying the maximum record
%       timestamp.
%
% See also DbdGroup struct
%
% ============================================================================
% $RCSfile: toStruct.m,v $
% $Source: /home/kerfoot/cvsroot/slocum/matlab/spt/classes/@DbdGroup/toStruct.m,v $
% $Revision: 1.1.1.1 $
% $Date: 2013/09/13 18:51:19 $
% $Author: kerfoot $
% ============================================================================
% 

dbd_struct = [];

% Validate inputs
% Validate inputs
if ~isa(obj, 'DbdGroup')
    error('DbdGroup:toStruct',...
        'Method can only be attached to the DbdGroup class');
elseif ~isequal(0, mod(length(varargin),2))
    error('toStruct:nargin',...
        'Invalid number of name,value options specified.');
end

% Default options
SENSOR_SET = obj.sensors;
T0 = obj.startDatenums(1);
T1 = obj.endDatenums(end);
% Process options
for x = 1:2:length(varargin)
    
    name = varargin{x};
    value = varargin{x+1};
    
    switch lower(name)
        case 'sensors'
            % value must be a string or cell array of strings
            if ~ischar(value) && ~iscellstr(value)
                error('toStruct:invalidDataType',...
                    'Value for option %s must be a string or cell array of strings.',...
                    name);
            elseif ischar(value)
                value = {value};
            end
            SENSOR_SET = unique(value);
        case 't0'
            if ~isequal(numel(value),1) || ~isnumeric(value)
                error('toArray:invalidDataType',...
                    'Value for option %s must be a numeric scalar.',...
                    name);
            end
            T0 = value;
        case 't1'
            if ~isequal(numel(value),1) || ~isnumeric(value)
                error('toArray:invalidDataType',...
                    'Value for option %s must be a numeric scalar.',...
                    value);
            end
            T1 = value;
        otherwise
            error('toStruct:invalidOption',...
                'Invalid option specified: %s.',...
                name);
    end
end

if isempty(SENSOR_SET)
    fprintf(2,...
        'No sensors were specified\n');
    return;
end

% Vertically concatenate SENSOR_SET into a list of sensor names
SENSOR_SET = SENSOR_SET(:);

% Get the data as an array and the sensor column order
[data, sensors] = obj.toArray('sensors', SENSOR_SET,...
    't0', T0,...
    't1', T1);

% Map the sensor names to their data arrays
for s = 1:length(sensors)
    dbd_struct.(sensors{s}) = data(:,s);
end

% Order the fields
dbd_struct = orderfields(dbd_struct);

