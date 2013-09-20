function addDbdCtdSensors(dbd, varargin)
%
% addDbdCtdSensors(dbd, varargin)
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
%       dbd.depthSensor
%
% Options:
%   'temperaturesensor' [String]
%       Specify the temperature sensor to use in the calculations.  Units
%       must be in degrees Celsius
%   'conductivitysensor' [String]
%       Specify the conductivity sensor to use in the calculations.  Units
%       must be in S m^-1
%   'pressuresensor' [String]
%       Specify the pressure sensor to use in the calculations.  Units must
%       be in decibars
%
% See also Dbd
% ============================================================================
% $RCSfile: addDbdCtdSensors.m,v $
% $Source: /home/kerfoot/cvsroot/slocum/matlab/spt/util/addDbdCtdSensors.m,v $
% $Revision: 1.1.1.1 $
% $Date: 2013/09/13 18:51:19 $
% $Author: kerfoot $
% ============================================================================
%

app = mfilename;

% Validate input args
if isequal(nargin,0) || ~isa(dbd, 'Dbd')
    error(sprintf('%s:nargin', app),...
        'No Dbd instance specified.');
elseif ~isa(dbd, 'Dbd')
    error(sprintf('%s:invalidArgument', app),...
        'Dbd instance is invalid');
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
P_SENSOR = '';
% Process options
for x = 1:2:length(varargin)
    
    name = varargin{x};
    value = varargin{x+1};
    
    switch name
        case 'temperaturesensor'
            if ~ischar(value)
                error('addDbdCtdSensors:invalidOptionValue',...
                    'The value for option %s must be a string.\n',...
                    name);
            end
            T_SENSOR = value;
        case 'conductivitysensor'
            if ~ischar(value)
                error('addDbdCtdSensors:invalidOptionValue',...
                    'The value for option %s must be a string.\n',...
                    name);
            end
            C_SENSOR = value;
        case 'pressuresensor'
            if ~ischar(value)
                error('addDbdCtdSensors:invalidOptionValue',...
                    'The value for option %s must be a string.\n',...
                    name);
            end
            P_SENSOR = value;
        otherwise
            error('addDbdCtdSensors:invalidOption',...
                'Invalid option specified: %s\n',...
                name);
    end
end

SENSORS = dbd.sensors;

% We need a temperature, conductivity and pressure sensor to calculate:
%   salinity
%   density
%   sound velocity
% Use the first matching sensor in TEMPERATURE_SENSORS if one was not
% specified via 'temperaturesensor' option
if isempty(T_SENSOR)
    fprintf(1,...
        'Selecting default temperature sensor: ');
    [C,AI] = intersect(TEMPERATURE_SENSORS, SENSORS);
    if isempty(C)
        fprintf('\n');
        warning(sprintf('%s:sensorNotFound', app),...
            '%s: Dbd instance contains no water temperature sensors.\n',...
            dbd.segment);
        return;
    end
    T_SENSOR = TEMPERATURE_SENSORS{min(AI)};
    fprintf(1,...
        '%s\n',...
        T_SENSOR);
end
% Use the first matching sensor in CONDUCTIVITY_SENSORS if one was not
% specified via 'conductivitysensor' option
if isempty(C_SENSOR)
    fprintf(1,...
        'Selecting default conductivity sensor: ');
    [C,AI] = intersect(TEMPERATURE_SENSORS, SENSORS);
    if isempty(C)
        fprintf('\n');
        warning(sprintf('%s:sensorNotFound', app),...
            '%s: Dbd instance contains no water conductivity sensors.\n',...
            dbd.segment);
        return;
    end
    C_SENSOR = CONDUCTIVITY_SENSORS{min(AI)};
    fprintf(1,...
        '%s\n',...
        C_SENSOR);
end
% Use Dbd.depthSensor if no pressure sensor was specified via the
% 'pressuresensors' option
if isempty(P_SENSOR)
    fprintf(1,...
        'Using Dbd.depthSensor for pressure readings.\n');
    P_SENSOR = dbd.depthSensor;
end

% Make sure T_SENSOR, C_SENSOR and P_SENSOR are all contained in the Dbd
% instance
if ~ismember(T_SENSOR, SENSORS)
    warning(sprintf('%s:sensorNotFound', app),...
        '%s: Dbd instance does not contain the specified temperature sensor: %s.\n',...
        dbd.segment,...
        T_SENSOR);
    return;
elseif ~ismember(C_SENSOR, SENSORS)
    warning(sprintf('%s:sensorNotFound', app),...
        '%s: Dbd instance does not contain the specified conductivity sensor: %s.\n',...
        dbd.segment,...
        C_SENSOR);
elseif ~ismember(P_SENSOR, SENSORS)
    warning(sprintf('%s:sensorNotFound', app),...
        '%s: Dbd instance does not contain the specified pressure sensor: %s.\n',...
        dbd.segment,...
        P_SENSOR);
end

% Dump the CTD data
ctd = dbd.toArray('sensors', {C_SENSOR, T_SENSOR, P_SENSOR});

% Add the sea_water_temperature using the data from T_SENSOR
fprintf(1,...
    '%s: Adding drv_sea_water_temperature: %s\n',...
    dbd.segment,...
    T_SENSOR);
dbd.addSensor('drv_sea_water_temperature',...
    ctd(:,4),...   
    dbd.sensorUnits.(T_SENSOR));

% Add the sea_water_temperature using the data from T_SENSOR
fprintf(1,...
    '%s: Adding drv_sea_water_electrical_conductivity: %s\n',...
    dbd.segment,...
    C_SENSOR);
dbd.addSensor('drv_sea_water_electrical_conductivity',...
    ctd(:,3),...
    dbd.sensorUnits.(C_SENSOR));

% Calculate salinity
fprintf(1,...
    '%s: Deriving drv_sea_water_salinity\n',...
    dbd.segment);
salt = calculate_glider_salinity(ctd(:,3), ctd(:,4), ctd(:,5));
% Add it to the Dbd instance as drv_sea_water_salinity (CF standard name)
dbd.addSensor('drv_sea_water_salinity',...
    salt,...
    'PSU');

% Calculate density
fprintf(1,...
    '%s: Deriving drv_sea_water_density\n',...
    dbd.segment);
dens = sw_dens(salt, ctd(:,4), ctd(:,5));
% Add it to the Dbd instance as drv_sea_water_density (CF standard name)
dbd.addSensor('drv_sea_water_density',...
    dens,...
    'kg m^-^3');

% Calculate sound velocity
fprintf(1,...
    '%s: Deriving drv_speed_of_sound_in_seawater\n',...
    dbd.segment);
svel = sw_svel(salt, ctd(:,4), ctd(:,5));
% Add it to the Dbd instance as drv_speed_of_sound_in_seawater (CF standard
% name)
dbd.addSensor('drv_speed_of_sound_in_seawater',...
    svel,...
    'm s^-^1');

% Calculate potential temperature
fprintf(1,...
    '%s: Deriving drv_sea_water_potential_temperature\n',...
    dbd.segment);
ptemp = sw_ptmp(salt, ctd(:,4), ctd(:,5), 0);
% Add it to the Dbd instance as drv_sea_water_potential_temperature
dbd.addSensor('drv_sea_water_potential_temperature',...
    ptemp,...
    dbd.sensorUnits.(T_SENSOR));

