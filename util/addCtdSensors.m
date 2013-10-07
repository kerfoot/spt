function addCtdSensors(obj, varargin)
%
% addCtdSensors(obj, varargin)
%
% Derive and add salinity, density, potential temperature and sound velocity 
% sensor data to the Dbd instance using default temperature, conductivity and 
% pressure (Dbd.depthSensor) sensors.  The new sensors are derived from the
% Climate & Forecast Metadata Convention list of standard names, available
% here:
%   
%   http://cf-pcmdi.llnl.gov/documents/cf-standard-names/
%
% and are prepended with 'drv_' to denote that they are derived:
%
%   drv_sea_water_temperature (copy of data from the selected temperature
%       sensor)
%   drv_sea_water_salinity (copy of data from the selected conductivity
%       sensor)
%   drv_sea_water_density
%   drv_speed_of_sound_in_sea_water
%   drv_sea_water_potential_temperature
%
% The Dbd class inherits from the Matlab handle class.  It is passed by 
% reference and not copied.  So there is no need to assign the altered Dbd
% instance to a return value, which is why one is not provided.
%
% With no options specified, default sensors are selected, in order of 
% precedence, from the following list:
%
%   Temperature Sensors:
%       'sci_water_temp'
%       'm_water_temp'
%
%   Conductivity Sensors:
%       'sci_water_cond'
%       'm_water_cond'
%
%   Pressure Sensor:
%       obj.depthSensor
%
% Options:
%   'temperaturesensor' [String]
%       Specify the temperature sensor to use in the calculations.  Units
%       must be in degrees Celsius
%   'conductivitysensor' [String]
%       Specify the conductivity sensor to use in the calculations.  Units
%       must be in S m^-1
%
% See also Dbd DbdGroup
% ============================================================================
% $RCSfile: addCtdSensors.m,v $
% $Source: /home/kerfoot/cvsroot/slocum/matlab/spt/util/addCtdSensors.m,v $
% $Revision: 1.3 $
% $Date: 2013/10/07 15:55:50 $
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

% Valid temperature and conductivity sensors
TEMPERATURE_SENSORS = {'sci_water_temp',...
    'm_water_temp',...
    }';
CONDUCTIVITY_SENSORS = {'sci_water_cond',...
    'm_water_cond',...
    }';

% Default sensors to use for the calculation
T_SENSOR = '';
C_SENSOR = '';
% Process options
for x = 1:2:length(varargin)
    
    name = varargin{x};
    value = varargin{x+1};
    
    switch name
        case 'temperaturesensor'
            if ~ischar(value)
                error(sprintf('%s:invalidOptionValue', app),...
                    'The value for option %s must be a string.\n',...
                    name);
            end
            T_SENSOR = value;
        case 'conductivitysensor'
            if ~ischar(value)
                error(sprintf('%s:invalidOptionValue', app),...
                    'The value for option %s must be a string.\n',...
                    name);
            end
            C_SENSOR = value;
        otherwise
            error(sprintf('%s:invalidOption', app),...
                'Invalid option specified: %s\n',...
                name);
    end
end

SENSORS = obj.sensors;

% Use the first matching sensor in TEMPERATURE_SENSORS if one was not
% specified via 'temperaturesensor' option
if isempty(T_SENSOR)
    [C,AI] = intersect(TEMPERATURE_SENSORS, SENSORS);
    if isempty(C)
        warning(sprintf('%s:sensorNotFound', app),...
            '%s: Dbd instance contains no water temperature sensors.\n',...
            obj.segment);
        return;
    end
    T_SENSOR = TEMPERATURE_SENSORS{min(AI)};
end
% Use the first matching sensor in CONDUCTIVITY_SENSORS if one was not
% specified via 'conductivitysensor' option
if isempty(C_SENSOR)
    [C,AI] = intersect(TEMPERATURE_SENSORS, SENSORS);
    if isempty(C)
        warning(sprintf('%s:sensorNotFound', app),...
            '%s: Dbd instance contains no water conductivity sensors.\n',...
            obj.segment);
        return;
    end
    C_SENSOR = CONDUCTIVITY_SENSORS{min(AI)};

end

% Dump the CTD data
ctd = obj.toArray('sensors', {C_SENSOR, T_SENSOR});

% Add the sea_water_temperature using the data from T_SENSOR
fprintf(1,...
    'Adding drv_sea_water_temperature: %s\n',...
    T_SENSOR);
obj.addSensor('drv_sea_water_temperature',...
    ctd(:,4),...   
    obj.sensorUnits.(T_SENSOR));

% Add the sea_water_temperature using the data from T_SENSOR
fprintf(1,...
    'Adding drv_sea_water_electrical_conductivity: %s\n',...
    C_SENSOR);
obj.addSensor('drv_sea_water_electrical_conductivity',...
    ctd(:,3),...
    obj.sensorUnits.(C_SENSOR));

% Calculate salinity
salt = gliderCTP2Salinity(ctd(:,3), ctd(:,4), ctd(:,2));
% Add it to the Dbd instance as drv_sea_water_salinity (CF standard name)
obj.addSensor('drv_sea_water_salinity',...
    salt,...
    'PSU');

% Calculate density
dens = sw_dens(salt, ctd(:,4), ctd(:,2));
% Add it to the Dbd instance as drv_sea_water_density (CF standard name)
obj.addSensor('drv_sea_water_density',...
    dens,...
    'kg m^-^3');

% Calculate sound velocity
svel = sw_svel(salt, ctd(:,4), ctd(:,2));
% Add it to the Dbd instance as drv_speed_of_sound_in_seawater (CF standard
% name)
obj.addSensor('drv_speed_of_sound_in_seawater',...
    svel,...
    'm s^-^1');

% Calculate potential temperature
ptemp = sw_ptmp(salt, ctd(:,4), ctd(:,2), 0);
% Add it to the Dbd instance as drv_sea_water_potential_temperature
obj.addSensor('drv_sea_water_potential_temperature',...
    ptemp,...
    obj.sensorUnits.(T_SENSOR));

