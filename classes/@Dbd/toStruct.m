function dbd_struct = toStruct(obj, varargin)
%
% struct = toStruct(varargin)
%
% Returns a structured array mapping sensor names to the data arrays for all
% of the sensors contained in the Dbd instance.  Two additional fields, 
% 'timestamp' and 'depth' are also added and contain the timestamp and depth 
% values, respectively, for Dbd.timestampSensor and Dbd.depthSensor.
%
% If Dbd.fillTimes and/or Dbd.fillDepths are set to a valid interp1.m
% interpolation method, these sensor data arrays will contain interpolated
% data values.
%
% Options:
%   'sensors': a cell array of strings containing the sensor set to
%       include.  By default, all sensors in the DbdGroup instance are
%       included.
%
% See also Dbd struct
%
% ============================================================================
% $RCSfile: toStruct.m,v $
% $Source: /home/kerfoot/cvsroot/slocum/matlab/spt/classes/@Dbd/toStruct.m,v $
% $Revision: 1.1.1.1 $
% $Date: 2013/09/13 18:51:19 $
% $Author: kerfoot $
% ============================================================================
% 

dbd_struct = [];

% Validate inputs
% Validate inputs
if ~isa(obj, 'Dbd')
    error('Dbd:toStruct',...
        'Method can only be attached to the Dbd class');
elseif ~isequal(0, mod(length(varargin),2))
    error('toStruct:nargin',...
        'Invalid number of name,value options specified.');
end

% Default options
SENSOR_SET = obj.sensors;

% Process options
for x = 1:2:length(varargin)
    
    name = varargin{x};
    value = varargin{x+1};
    
    switch lower(name)
        case 'sensors'
            % value must be a string or cell array of strings
            if ~ischar(value) && ~iscellstr(value)
                error('Dbd:toStruct:invalidDataType',...
                    'Value for option %s must be a string or cell array of strings.',...
                    name);
            elseif ischar(value)
                value = {value};
            end
            SENSOR_SET = unique(value);
        otherwise
            error('Dbd:toStruct:invalidOption',...
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
[data, sensors] = obj.toArray('sensors', SENSOR_SET);

% Map the sensor names to their data arrays
for s = 1:length(sensors)
    dbd_struct.(sensors{s}) = data(:,s);
end

% Order the fields
dbd_struct = orderfields(dbd_struct);

