function [results, sensorDataRange] = iterateDownUpProfileShifts(obj, SENSOR, varargin)
%
% [results, sensorDataRange] = iterateDownUpProfileShifts(Dbd, SENSOR, varargin)
%
% Shifts the sensor time-series contained in the Dbd instance by each of the 
% values in shiftIntervals, calculates the average up and down profile, 
% calculates the resulting area between the 2 averaged profiles and returns 
% the shift value resulting in the minimum area.
%
% The return values are a 2 column array containing the shift values and the 
% resulting areas between the averaged profiles (results) and the minimum and
% maximum range of the sensor time-series.
%
% Name, value options:
%   'plot': LOGICAL
%       Set to true to plot the results.  Default is false.
%   'intervals': NUMERIC ARRAY
%       Array containing the shift values (seconds) to iterate over.
%       Default is to shift from 0 to -3 seconds in 0.10 second intervals.
%
% See also Dbd profiles2polyArea
%

results = [];
sensorDataRange = [NaN NaN];

app = mfilename;

if nargin < 2
    error(sprintf('%s:nargin', app),...
        'Please specify a Dbd instance and a sensor to process');
elseif ~isa(obj, 'Dbd')
    error(sprintf('%s:invalidArgument', app),...
        'Object must be an instance of the Dbd class');
elseif ~ischar(SENSOR) || ~ismember(SENSOR, obj.sensors)
    error(sprintf('%s:invalidArgument', app),...
        'The second argument must be a string specifying a valid sensor to process');
elseif ~isequal(mod(length(varargin),2),0)
    error(sprintf('%s:varargin', app),...
        'Non-even number of options specified');
end

% Default options
PLOT = false;
SHIFTS = [0:-0.1:-3];
DEPTH_INTERVAL = 0.25;
VALIDATE_UPDOWN = NaN;
HAS_PROFILES = NaN;
% Process options
for x = 1:2:length(varargin)
    name = varargin{x};
    value = varargin{x+1};
    switch lower(name)
        case 'plot'
            if ~isequal(numel(value),1) || ~islogical(value)
                error(sprintf('%s:invalidOptionValue', app),...
                    'Value for option %s must be a logical value',...
                    name);
            end
            PLOT = value;
        case 'intervals'
            if ~all(isnumeric(value)) || ~isequal(min(size(value)),1)
                error(sprintf('%s:invalidOptionValue', app),...
                    'Value for option must be a 1-D array of shift intervals');
            end
            SHIFTS = value(:);
        case 'validateupdown'
            if ~isequal(numel(value),1) ||...
                    ~isnumeric(value) || ...
                    value < 0 || value > 1
                error(sprintf('%s:invalidOptionValue', app),...
                    'Value for option %s must be a positive number between 0 and 1',...
                    name);
            end
            VALIDATE_UPDOWN = value;
        case 'hasprofiles'
            if ~isequal(numel(value),1) ||...
                    ~isnumeric(value) || ...
                    value < 0 || value > 1
                error(sprintf('%s:invalidOptionValue', app),...
                    'Value for option %s must be a positive number between 0 and 1',...
                    name);
            end
            HAS_PROFILES = value;
        otherwise
            error(sprintf('%s:invalidOption', app),...
                'Invalid option specified: %s',...
                name);
    end
end

% Extract the raw sensor data array
RAW_DATA = obj.toArray('sensors', SENSOR);
% Eliminiate the second columsn (depth)
RAW_DATA(:,2) = [];

% Store the min and max data values
sensorDataRange = [min(RAW_DATA(:,2)) max(RAW_DATA(:,2))];

results = [SHIFTS(:) nan(length(SHIFTS),1)];
for x = 1:length(SHIFTS)
    
    SHIFT = SHIFTS(x);
    
    % Shift the sensor data
    shifted_data = shiftTimeSeries(RAW_DATA, SHIFT);
    
    % Add the sensor to the Dbd instance
    shifted_sensor = ['drv_shifted_' SENSOR];
    obj.addSensor(shifted_sensor, shifted_data(:,2), obj.sensorUnits.(SENSOR));
    
    % Average the downs and ups
    [dMean,uMean,~,~,~,~,numProfiles] =...
        obj.averageProfiles(shifted_sensor, 'depthbin', DEPTH_INTERVAL);
    
    if ~isnan(HAS_PROFILES)
        % Find the total number of profiles (downs and ups) in the instance
        pNum = max(numProfiles(:,3));
        dMean(numProfiles(:,1) < HAS_PROFILES*pNum,:) = [];
        uMean(numProfiles(:,2) < HAS_PROFILES*pNum,:) = [];
    end
    
    if isempty(dMean)
        warning(sprintf('%s:noDepthRecord', app),...
            '%s: The shifted (%0.2f) down profile has no valid records',...
            obj.segment,...
            SHIFT);
        continue;
    elseif isempty(uMean)
        warning(sprintf('%s:noDepthRecords', app),...
            '%s: The shifted (%0.2f) up profile has no valid records',...
            obj.segment,...
            SHIFT);
        continue;
    end
    
    % Calculate the area between the profiles
    results(x,2) = profiles2polyArea(dMean, uMean,...
        'validateupdown', VALIDATE_UPDOWN,...
        'plot', PLOT);
    
    if PLOT
        drawnow;
        pause(0.1);
    end
    
end