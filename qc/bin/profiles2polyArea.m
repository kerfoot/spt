function [pArea, downUpProfiles] = profiles2polyArea(downProfile, upProfile, varargin)
%
% [pArea, downUpProfiles] = profiles2polyArea(downProfile, upProfile, varargin)
%
% Calculates the area between the 2 profiles.
%
% Options:
%   'mingoodvalues': 0 < VALUE < 1
%       If specified, the up profile is subtracted from the down profile
%       and the number of negative values must be less than VALUE*number of
%       points.  Used as a sanity check to ensure that the down profile is
%       lower in vertical space than the up profile.
%   'plot': LOGICAL
%       Set to true to plot the results.  Default is false.
%
% ============================================================================
% $RCSfile: averageProfiles.m,v $
% $Source: /home/kerfoot/cvsroot/slocum/matlab/spt/classes/@Dbd/averageProfiles.m,v $
% $Revision: 1.2 $
% $Date: 2014/01/13 15:53:56 $
% $Author: kerfoot $
% ============================================================================
%

app = mfilename;

pArea = NaN;

% Validate input arguments
if nargin < 2
    error(sprintf('%s:nargin', app),...
        'Invalid number of input arguments specified');
elseif ~isequal(mod(length(varargin),2),0)
    error(sprintf('%s:varargin', app),...
        'Non-even number of options specified');
end

if ~isequal(size(downProfile,2),2) || ~isequal(size(upProfile,2),2)
    warning(sprintf('%s:inputArgs', app),...
        'The profile array(s) must contain 2 columns\n');
    return;
end

% Default options
PLOT = false;
VALIDATE_UPDOWN = NaN;
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
        case 'validateupdown'
            if ~isequal(numel(value),1) ||...
                    ~isnumeric(value) || ...
                    value < 0 || value > 1
                error(sprintf('%s:invalidOptionValue', app),...
                    'Value for option %s must be a positive number between 0 and 1',...
                    name);
            end
            VALIDATE_UPDOWN = value;
        otherwise
            error(sprintf('%s:invalidOption', app),...
                'Invalid option specified: %s',...
                name);
    end
end

% Sort the profiles in ascending depth order (column 1)
downProfile = sortrows(downProfile,1);
upProfile = sortrows(upProfile,1);
% Make sure we have common depth intervals to compare
[C,AI,BI] = intersect(downProfile(:,1), upProfile(:,1));
if isempty(C)
    warning(sprintf('%s:commonDepths', app),...
        'The down and up profiles do not contain any common depths\n');
    return;
end

downUpProfiles = [downProfile(AI,:) upProfile(BI,2)];

downUpProfiles(any(isnan(downUpProfiles(:,[2 3])),2),:) = [];
if isempty(downUpProfiles)
    return;
end

downUpDiff = downUpProfiles(:,2) - downUpProfiles(:,2);
if ~isnan(VALIDATE_UPDOWN) &&...
        length(find(downUpDiff < 0)) > length(downUpDiff)*VALIDATE_UPDOWN
    warning(sprintf('%s:mismatchedDownUpProfiles', app),...
        'The down profile is already above the up profile\n');
    return
end

Y = [downUpProfiles(:,1); flipud(downUpProfiles(:,1))];
X = [downUpProfiles(:,2); flipud(downUpProfiles(:,3))];
[X,Y] = poly2cw(X,Y);

% Calculate the area of the polygons
pArea = polyarea(X,Y);

if ~PLOT
    return;
end

% Plot the polygon if specified via the 'plot', true option
[faces, vertices] = poly2fv(X,Y);

f = findobj('Tag', 'profilePolygon');
if isempty(f)
    f = figure('PaperPosition', [0 0 8 11.5],...
        'Tag', 'profilePolygon');
    axes('NextPlot', 'Add',...
        'YDir', 'reverse',...
        'Box', 'On',...
        'TickDir', 'out',...
        'LineWidth', 1);
end

% Clear the current axes
cla;

figure(f);

patch('Faces', faces,...
    'Vertices', vertices,...
    'FaceColor', 'b',...
    'EdgeColor', 'none',...
    'FaceAlpha', 0.2);
        
