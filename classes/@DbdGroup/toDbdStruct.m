function dbd_struct = toDbdStruct(obj, varargin)
%
% struct = toStruct(varargin)
%
% Returns a structured array mapping sensor names to column indices for the
% data contained in dbd_struct.data.  All sensors contained in the DbdGroup
% instance are included.  Two additional fields, 'timestamp' and 'depth' are 
% also added and contain the timestamp and depth values, respectively, for 
% DbdGroup.timestampSensor and DbdGroup.depthSensor.
%
% If DbdGroup.fillTimes and/or DbdGroup.fillDepths are set to a valid interp1.m
% interpolation method, these sensor data arrays will contain interpolated
% data values.
%
% Options:
%   'sensors': a cell array of strings containing the sensor set to
%       include.  By default, all sensors in the DbdGroupGroup instance are
%       included.
%   't0': single matlab datenum value specifying the minumum profile time
%       to be included.
%   't1': single matlab datenum value specifying the maximum profile time
%       to be included.
%
% See also DbdGroup struct2data
%
% ============================================================================
% $RCSfile: toDbdStruct.m,v $
% $Source: /home/kerfoot/cvsroot/slocum/matlab/spt/classes/@DbdGroup/toDbdStruct.m,v $
% $Revision: 1.1.1.1 $
% $Date: 2013/09/13 18:51:19 $
% $Author: kerfoot $
% ============================================================================
% 

app = mfilename;

dbd_struct = [];

% Validate inputs
if ~isa(obj, 'DbdGroup')
    error(sprintf('%s:invalidClass', app),...
        'Method can only be attached to the DbdGroup class');
elseif ~isequal(0, mod(length(varargin),2))
    error(sprintf('%s:nargin', app),...
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
                error('DbdGroup:toStruct:invalidDataType',...
                    'Value for option %s must be a string or cell array of strings.',...
                    name);
            elseif ischar(value)
                value = {value};
            end
            SENSOR_SET = value;
        case 't0'
            if ~isequal(numel(value),1) || ~isnumeric(value)
                error('DbdGroup:toGrid2d:invalidDataType',...
                    'Value for option %s must be a numeric datenum scalar.',...
                    name);
            end
            T0 = value;
        case 't1'
            if ~isequal(numel(value),1) || ~isnumeric(value)
                error('DbdGroup:toGrid2d:invalidDataType',...
                    'Value for option %s must be a numeric datenum scalar.',...
                    name);
            end
            T1 = value;
        otherwise
            error('DbdGroup:toStruct:invalidOption',...
                'Invalid option specified: %s.',...
                name);
    end
end

% Vertically concatenate SENSOR_SET into a list of sensor names
SENSOR_SET = SENSOR_SET(:);

% Get the data as an array and the sensor column order
[data, sensors] = obj.toArray('sensors', SENSOR_SET,...
    't0', T0,...
    't1', T1);
if isempty(data);
    return;
end

% Add the sensor names as fields of struct and store the column order
for s = 1:length(sensors)
    dbd_struct.(sensors{s}) = s;
end

% Order the fields
dbd_struct = orderfields(dbd_struct);

% Add the data
dbd_struct.data = data;

% Create and add the source info
dbd_struct.source = {obj.segment,...
    1,...
    obj.rows,...
    obj.the8x3filename,...
    obj.filetype,...
    obj.startTime,...
    obj.bytes};

% Create and add the metdata
dbd_struct.meta.glider = obj.glider;
dbd_struct.meta.deployDate = [];
dbd_struct.meta.recoverDate = [];
dbd_struct.meta.project = '';
dbd_struct.meta.sensorPackages = dbd_struct([]);
dbd_struct.meta.comments = {};
dbd_struct.meta.deploymentStatus = '';
dbd_struct.meta.recovered = [];
dbd_struct.meta.qc = '';
configParams = struct('DEPTH_SENSOR', obj.depthSensor,...
    'PRESSURE_SENSOR', obj.depthSensor,...
    'TIMESTAMP_SENSOR', obj.timestampSensor);
dbd_struct.meta.configParams = configParams;
dbd_struct.meta.fileType = 'DbdGroup';
dbd_struct.meta.filename = '';
dbd_struct.meta.sensorUnits = obj.sensorUnits;
