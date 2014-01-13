function addVelocities(obj, varargin)
%
% addVelocities(obj, varargin)
%
% Derive and add glider vertical velocity and along axis velocity.  Added 
% sensors are prepended with 'drv_' to denote that they are derived:
%
%   drv_vertical_velocity
%   drv_along_axis_velocity
%
% Velocity parameters are calculated using the timestamp and depth sensors
% specified in each Dbd instance.
%
% The Dbd class inherits from the Matlab handle class.  It is passed by 
% reference and not copied.  So there is no need to assign the altered Dbd
% instance to a return value, which is why one is not provided.
%
% All calculated values are included in the derived sensors.  The following
% options may be used to change this behavior:
%
%   'maxvel': SCALAR - set any derived velocity value that exceeds this
%       value to NaN.
%
% See also Dbd DbdGroup
% ============================================================================
% $RCSfile: addVelocities.m,v $
% $Source: /home/kerfoot/cvsroot/slocum/matlab/spt/util/addVelocities.m,v $
% $Revision: 1.1 $
% $Date: 2014/01/13 15:56:58 $
% $Author: kerfoot $
% ============================================================================
%

app = mfilename;

% Validate input args
if isequal(nargin,0)
    error(sprintf('%s:nargin', app),...
        'No Dbd or DbdGroup instance specified.');
elseif ~isa(obj, 'Dbd') && ~isa(obj, 'DbdGroup')
    error(sprintf('%s:invalidArgument', app),...
        'First argument must be a valid Dbd or DbdGroup instance.');
elseif ~isequal(mod(length(varargin),2),0)
    error(sprintf('%s:varargin', app),...
        'Invalid number of name,value options specified.');
end

%
WINDOW_SIZE = NaN;
MAX_VELOCITY = NaN;
% Process options
for x = 1:2:length(varargin)
    
    name = varargin{x};
    value = varargin{x+1};
    
    switch name
        case 'medfilt'
            if ~isequal(numel(value),1) || ~isnumeric(value) || value < 0
                error(sprintf('%s:invalidOptionValue', app),...
                    'The value for option %s must be a positive number.\n',...
                    name);
            end
            WINDOW_SIZE = value;
        case 'maxvel'
            if ~isequal(numel(value),1) || ~isnumeric(value) || value < 0
                error(sprintf('%s:invalidOptionValue', app),...
                    'The value for option %s must be a positive number.\n',...
                    name);
            end
            MAX_VELOCITY = value;
        otherwise
            error(sprintf('%s:invalidOption', app),...
                'Invalid option specified: %s\n',...
                name);
    end
end

% Process each Dbd instance individually in the event that the
% Dbd.timestmapSensor is a datenum and not epoch seconds
if isa(obj, 'Dbd')
    z = obj.toArray('sensors', 'nan');
    % Intialize an array of NaNs to hold calculated horizontal and
    % along_axis velocity, if m_pitch is present
    horiz = nan(obj.rows,1);
    along_axis = horiz;
    % Remove the dummy sensor
    z(:,3) = [];
    if ~isempty(regexp(obj.timestampSensor, '_datenum$', 'once'))
        z(:,1) = datenum2epoch(z(:,1));
    end
else
    r = 1;
    z = nan(sum(obj.rows),2);
    % Intialize an array of NaNs to hold calculated horizontal and
    % along_axis velocity, if m_pitch is present
    horiz = z(:,1);
    along_axis = horiz;
    for d = 1:length(obj.dbds)
        tmpZ = obj.dbds(d).toArray('sensors', 'nan');
        % Convert to seconds if Dbd.timestampSensor is a datenum
        if ~isempty(regexp(obj.dbds(d).timestampSensor, '_datenum$', 'once'))
            tmpZ(:,1) = datenum2epoch(tmpZ(:,1));
        end
        % Convert to decibars if Dbd.depthSensor is a in units of bar
        if ~isempty(regexp(obj.dbds(d).sensorUnits.(obj.dbds(d).depthSensor), '^bar$', 'once'))
            tmpZ(:,2) = tmpZ(:,2)*10;
        end
        z(r:obj.dbds(d).rows+r-1,:) = tmpZ(:,[1 2]);
        r = r + obj.dbds(d).rows;
    end
        
end

% Calculate the vertical velocity
vert = [NaN; diff(z(:,2))./diff(z(:,1))];

% If m_pitch is present, calculate the horizontal and along-axis velocity,
% assuming the glider is traveling exactly on it's angle of attack
if ismember('m_pitch', obj.sensors)
    pitch = obj.toArray('sensors', 'm_pitch');
    % Interpolate the m_pitch time series
    pitch(:,3) = interpTimeSeries(pitch(:,[1 3]));
    pitch(:,[1 2]) = [];
    theta = (pi/2) - abs(pitch);
    horiz = tan(theta) .* vert;
    along_axis = vert./cos(theta);
end
   
% Remove outliers if specified
if ~isnan(MAX_VELOCITY)
    vert(abs(vert) > MAX_VELOCITY) = NaN;
    horiz(abs(horiz) > MAX_VELOCITY) = NaN;
    along_axis(abs(along_axis) > MAX_VELOCITY) = NaN;
end

obj.addSensor('drv_vertical_velocity', vert, 'm s^-^1');
obj.addSensor('drv_horizontal_velocity', horiz, 'm s^-^1');
obj.addSensor('drv_along_axis_velocity', along_axis, 'm s^-^1');
    
