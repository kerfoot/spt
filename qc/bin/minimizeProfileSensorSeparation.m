function bestShifts = minimizeProfileSensorSeparation(dgroup, sensor, shiftIntervals, varargin)
%
% bestShifts = minimizeProfileSensorSeparation(dgroup, sensor, shiftIntervals, varargin)
%
% Shifts the sensor time-series contained in each Dbd instance of the
% DbdGroup by each of the values in shiftIntervals, calculates the average up 
% and down profile, calculates the resulting area between the 2 averaged
% profiles and returns the shift value resulting in the minimum area.
%
% The return value is a 2 column array containing the optimum shift value
% and the resulting areas between the averaged profiles.
%
% Name, value options:
%   'plot': LOGICAL
%       Set to true to plot the results.  Default is false.
%
% See also DbdGroup iterateDowUpProfileShifts


app = mfilename;
bestShifts = [];

if nargin < 3
    fprintf(2,...
        '%s: 3 arguments required\n',...
        app);
elseif ~isa(dgroup, 'DbdGroup')
    fprintf(2,...
        '%s: DbdGroup instance required\n',...
        app);
    return;
elseif ~ischar(sensor) || isempty(sensor) || ~ismember(sensor, dgroup.sensors)
    fprintf(2,...
        '%s: Invalid sensor specified\n',...
        app);
    return;
elseif isempty(shiftIntervals) || ~all(isnumeric(shiftIntervals))
    fprintf(2,...
        '%s: shiftIntervals must be an array of increasing time shift values\n',...
        app);
    return;
end

% Default options
PLOT_FLAG = false;
for x = 1:2:length(varargin)
    name = varargin{x};
    value = varargin{x+1};
    
    switch lower(name)
        case 'plot'
            if ~isequal(numel(value),1) || ~islogical(value)
                fprintf(2,...
                    '%s: Value for option %s must be a logical scalar.\n',...
                    app,...
                    name);
                return;
            end
            PLOT_FLAG = value;
        otherwise
            fprintf(2,...
                '%s: Invalid option specified: %s.\n',...
                app,...
                name);
    end
end

bestShifts = nan(length(dgroup.dbds), 2);

for x = 1:length(dgroup.dbds)
    
    if ~ismember(sensor, dgroup.dbds(x).sensors)
        continue;
    elseif dgroup.dbds(x).numProfiles < 2
        continue;
    end
    
    [results, sensorDataRange] = iterateDownUpProfileShifts(dgroup.dbds(x),...
        sensor,...
        'intervals', shiftIntervals,...
        'plot', PLOT_FLAG);
    
    [Y,I] = min(results(:,2));
    
    bestShifts(x,:) = results(I,:);
    
end

    