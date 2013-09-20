function dbd_struct = toDbdStruct(obj, varargin)
%
% struct = toStruct(varargin)
%
% Returns a structured array mapping sensor names to column indices for the
% data contained in dbd_struct.data.  All sensors contained in the Dbd
% instance are included.  Two additional fields, 'timestamp' and 'depth' are 
% also added and contain the timestamp and depth values, respectively, for 
% Dbd.timestampSensor and Dbd.depthSensor.
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
% See also Dbd struct2data
%
% ============================================================================
% $RCSfile: toDbdStruct.m,v $
% $Source: /home/kerfoot/cvsroot/slocum/matlab/spt/classes/@Dbd/toDbdStruct.m,v $
% $Revision: 1.1.1.1 $
% $Date: 2013/09/13 18:51:19 $
% $Author: kerfoot $
% ============================================================================
% 

app = mfilename;

dbd_struct = [];

% Validate inputs
% Validate inputs
if ~isa(obj, 'Dbd')
    error(sprintf('%s:invalidClass', app),...
        'Method can only be attached to the Dbd class');
elseif ~isequal(0, mod(length(varargin),2))
    error(sprintf('%s:nargin', app),...
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
                error(sprintf('%s:invalidDataType', app),...
                    'Value for option %s must be a string or cell array of strings.',...
                    name);
            elseif ischar(value)
                value = {value};
            end
            SENSOR_SET = value;
        otherwise
            error(sprintf('%s:invalidOption', app),...
                'Invalid option specified: %s.',...
                name);
    end
end

% Vertically concatenate SENSOR_SET into a list of sensor names
SENSOR_SET = SENSOR_SET(:);

% Get the data as an array and the sensor column order
[data, sensors] = obj.toArray('sensors', SENSOR_SET);

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
dbd_struct.meta.fileType = 'Dbd';
dbd_struct.meta.filename = '';
dbd_struct.meta.sensorUnits = obj.sensorUnits;
