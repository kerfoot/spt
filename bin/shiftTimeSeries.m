function shifted_ts = shiftTimeSeries(time_series, shift_seconds, varargin)
%
% shifted_ts = shiftTimeSeries(time_series, shift_seconds, varargin)
%
% Shifts the 2-column time-series data array by shift_seconds.  Negative
% values for shift_seconds shift backwards.
%
% The time-series data is assumed to be in datenum units.
%
% Options:
%   'timeunits': ['datenum', 'epoch']
%       Specify the units of the time-series.  Default is datenum.
%
% See also interp1 datenum
% ============================================================================
% $RCSfile: shiftTimeSeries.m,v $
% $Source: /home/kerfoot/cvsroot/slocum/matlab/spt/bin/shiftTimeSeries.m,v $
% $Revision: 1.1 $
% $Date: 2013/09/20 20:37:58 $
% $Author: kerfoot $
% ============================================================================
%

app = mfilename;

if nargin < 2
    error(sprintf('%s:nargin', app),...
        'Please specify a time-series and a shift increment');
elseif ~isequal(numel(shift_seconds),1) || ~isnumeric(shift_seconds)
    error(sprintf('%s:invalidArgument', app),...
        'The shift increment must be a numeric scalar.');
elseif ~isequal(mod(length(varargin),2),0)
    error(sprintf('%s:varargin', app),...
        'Invalid number of options specified.');
elseif isempty(time_series) || ~isequal(size(time_series,2),2)
    error(sprintf('%s:invalidArgument', app),...
        'The time-series must be a 2 column array.');
end

VALID_TIME_UNITS = {'datenum',...
    'epoch',...
    }';
TIME_UNITS = 'datenum';
for x = 1:2:length(varargin)
    name = varargin{x};
    value = varargin{x+1};
    
    switch lower(name)
        case 'timeunits'
            if ~ischar(value) || ~ismember(value, VALID_TIME_UNITS)
                error(sprintf('%s:invalidOption', app),...
                    'Value for option %s must be a valid time unit (''datenum'' or ''epoch'')',...
                    name);
            end
            TIME_UNITS = value;
        otherwise
            error(sprintf('%s:invalidOption', app),...
                'Invalid option specified: %s',...
                name);
    end
end

% Create a copy of the time-series
shifted_ts = time_series;

% Find the non-NaN timestamps
good_ts = find(~isnan(time_series(:,1)));
if length(good_ts) < 2
    fprintf(2,...
        '%s: Time-series contains less than 2 valid time stamps\n',...
        app);
    return;
end

% Replace duplicate time stamps with nans
dups = find(diff(time_series(good_ts,1)) == 0);
time_series(good_ts(dups+1),:) = NaN;

% Find the non-NaN timestamps with duplicates replaced by NaN
good_ts = find(all(~isnan(time_series),2));
if length(good_ts) < 2
    fprintf(2,...
        '%s: Time-series contains less than 2 valid records\n',...
        app);
    return;
end

% Convert the shift_seconds to datenum units if needed and store in
% SHIFT_VALUE
switch TIME_UNITS
    case 'datenum'
        SHIFT_VALUE = shift_seconds/86400;
    case 'epoch'
        SHIFT_VALUE = shift_seconds;
end

% Upldate the return value with the cleaned version of the original
% time-series
shifted_ts = time_series;

% Add the SHIFT_VALUE to the timestamps of the original time series
time_series(:,1) = time_series(:,1) + SHIFT_VALUE;

% Find all valid rows in the shifted time-series
r_shift = find(all(~isnan(time_series),2));
% Find all valid rows in the original time-series
r_orig = find(all(~isnan(shifted_ts),2));

% Interpolate to the new time-series

shifted_ts(r_orig,2) = interp1(time_series(r_shift,1),...
    time_series(r_shift,2),...
    shifted_ts(r_orig,1));
