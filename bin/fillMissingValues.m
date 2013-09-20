function filledData = fillMissingValues(data, varargin)
%
% Usage: filledData = fillMissingValues(data, varargin)
%
% Fills in all NaN values in the 1 dimensional array using linear interpolation.  
% Values are not extrapolated beyond the last non-NaN value at either end of
% array.
%
% Options:
%   'extrapValue': number or NaN: specify an alternate value for extrapolation
%   'fillMethod': string specifying an alternate interpolation method used to
%       fill the missing values.  See interp1.m for valid methods.
%   'fillDups': remove and fill non-nan duplicate values.  Default is false.
%
% See also interp1
% ============================================================================
% $RCSfile: fillMissingValues.m,v $
% $Source: /home/kerfoot/cvsroot/slocum/matlab/spt/bin/fillMissingValues.m,v $
% $Revision: 1.1.1.1 $
% $Date: 2013/09/13 18:51:18 $
% $Author: kerfoot $
% ============================================================================
%

filledData = [];
caller = [mfilename '.m'];

% Validate input arguments
if isequal(nargin,0)
    disp([caller ' E: No args specified.']);
    return;
elseif ~isequal(min(size(data)),1)
    disp([caller ' E: array must be 1 dimensional.']);
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
            if ~ischar(value)
                disp([caller...
                    ' E: '...
                    name...
                    ' must be a string specifying a valid interp1 method.']);
                return;
            elseif ~any(strcmp(value, allMethods))
                disp([caller...
                    ' E: Invalid interp1 method specified ('...
                    value...
                    ')']);
                return;
            end
            interpMethod = value;
        case 'fillmethod'
            if ~ischar(value)
                disp([caller...
                    ' E: '...
                    name...
                    ' must be a string specifying a valid interp1 method.']);
                return;
            elseif ~any(strcmp(value, allMethods))
                disp([caller...
                    ' E: Invalid interp1 method specified ('...
                    value...
                    ')']);
                return;
            end
            interpMethod = value;
        case 'method'
            if ~ischar(value)
                disp([caller...
                    ' E: '...
                    name...
                    ' must be a string specifying a valid interp1 method.']);
                return;
            elseif ~any(strcmp(value, allMethods))
                disp([caller...
                    ' E: Invalid interp1 method specified ('...
                    value...
                    ')']);
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

% Fill in missing values
filledData = data(:);

% Create an array the same length as data
iT = (1:length(data(:,1)))';

% Find all non-nan rows
r = find(~isnan(data));
% Find consecutive duplicate values in the non-NaN rows
dups = find(diff(data(r)) == 0);
% Set all dups to nan so that they will be filled
data(r(dups+1)) = NaN;
% Logical indexing of missing values
i = isnan(data);

if ~any(i)
% % % % %     fprintf(1, '%s W: No missing values found (NaN).\n',...
% % % % %         caller);
    return;
end

% Don't interpolate if we have less than 2 non-nan values
if length(find(~isnan(data))) < 2
    return;
end

try
    filledData(i) = interp1(iT(~i),...
        data(~i,1),...
        iT(i),...
        interpMethod,...
        extrapValue);
catch ME
    fprintf(2,...
        '%s: %s\nStack Trace:\n',...
        ME.identifier,...
        ME.message);
    ME.stack
end