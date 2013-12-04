function interpData = interpTimeSeries(timeSeries, varargin)
%
% interpData = interpTimeSeries(timeSeries, varargin)
%
% Fills in all NaN values in the 1 dimensional array using linear interpolation.  
% Values are not extrapolated beyond the last non-NaN value at either end of
% array.
%
% Options:
%   'extrapValue': number or NaN: specify an alternate value for extrapolation
%   'method': string specifying an alternate interpolation method used to
%       fill the missing values.  See interp1.m for valid methods.
%   'fillDups': remove and fill non-nan duplicate values.  Default is false.
%
% See also interp1
% ============================================================================
% $RCSfile: interpTimeSeries.m,v $
% $Source: /home/kerfoot/cvsroot/slocum/matlab/spt/bin/interpTimeSeries.m,v $
% $Revision: 1.2 $
% $Date: 2013/12/04 14:27:49 $
% $Author: kerfoot $
% ============================================================================
%

interpData = [];
caller = [mfilename '.m'];

% Validate input arguments
if isequal(nargin,0)
    disp([caller ' E: No args specified.']);
    return;
elseif ~isequal(size(timeSeries,2),2)
    fprintf(2,...
        '%s E: First argument must be a 2-D time series\n',...
        caller);
    return;
end

if ~isequal(mod(length(varargin),2),0)
    disp([caller ' E: Invalid number of name,value options specified.']);
    return;
end
% Default options settings
extrapValue = NaN;
fillDups = false;
interpMethod = 'linear';
allMethods = {'nearest',...
    'linear',...
    'spline',...
    'pchip',...
    'cubic',...
    'v5cubic',...
    }';
% Process options
for x = 1:2:length(varargin)
    name = varargin{x};
    value = varargin{x+1};
    switch lower(name)
        case 'extrapvalue'
            if ~isnumeric(value) || ~isequal(length(value),1)
                disp([caller ' E: ' name ' must be a single number or NaN.']);
                return;
            end
            extrapValue = value;
        case 'interpmethod'
            if ~ischar(value) ||...
                    ~ismember(value, allMethods)
                fprintf(2,...
                    'Pbd:%s:invalidInterpMethod - %s\n',...
                    mfilename,...
                    value);
                return;
            end
            interpMethod = value;
        case 'fillmethod'
            if ~ischar(value) ||...
                    ~ismember(value, allMethods)
                fprintf(2,...
                    'Pbd:%s:invalidInterpMethod - %s\n',...
                    mfilename,...
                    value);
                return;
            end
            interpMethod = value;
        case 'method'
            if ~ischar(value) ||...
                    ~ismember(value, allMethods)
                fprintf(2,...
                    'Pbd:%s:invalidInterpMethod - %s\n',...
                    mfilename,...
                    value);
                return;
            end
            interpMethod = value;
        case 'filldups'
            if ~isequal(numel(value),1) || ~islogical(value)
                fprintf(2,...
                    '%s E: %s must be a truth value (true or false).\n',...
                    caller,...
                    name);
                return;
            end
            fillDups = value;
        otherwise
            disp([caller ' E: Invalid name,option pair.']);
            return;
    end
end

% keep copy of original time series
origTimeSeries = timeSeries;

% Find all non-nan timestamp rows
not_nans = find(~isnan(timeSeries(:,1)));
% Sort the non-nan timestamps and set any out of order non-nan timestamp to
% NaN
[Y,I] = sort(timeSeries(not_nans,1));
out_of_order = find(diff(I) < 0);
if ~isempty(out_of_order)
    timeSeries(not_nans(I(out_of_order)),1) = NaN;
    not_nans = find(~isnan(timeSeries(:,1)));
end
% Find consective non-nan timestamp duplicate rows
dups = find(diff(timeSeries(not_nans,1)) == 0);
% Set the duplicate timestamps to NaN
timeSeries(not_nans(dups+1),1) = NaN;
% % % % % % Replace duplicate timestamps with nans
% % % % % timeSeries(diff(timeSeries(:,1)) == 0, 1) = NaN;
goodTs = find(~isnan(timeSeries(:,1)));
goodYo = timeSeries(all(~isnan(timeSeries),2),:);
if size(goodYo,1) < 3
    interpData = origTimeSeries(:,2);
else % Interpolate using method specified in .fillDepths
    try
        timeSeries(goodTs,2) = interp1(goodYo(:,1),...
            goodYo(:,2),...
            timeSeries(goodTs,1),...
            interpMethod,...
            NaN);
        interpData = timeSeries(:,2);
    catch ME
        interpData = origTimeSeries(:,2);
        fprintf(2,...
            '%s: %s\nStack Trace:\n',...
            ME.identifier,...
            ME.message);
    end
end
