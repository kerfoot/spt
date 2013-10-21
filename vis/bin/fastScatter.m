function [h, cbH] = fastScatter(X, Y, C, varargin)
% 
% USAGE: [h, c_h] = fastScatter(X, Y, C, varargin)
% 
% A MUCH faster and less memory intensive version of Matlab's scatter.m 
% function.
% 
% Optional arguments, in the form of 'name', value pairs can be used to 
% customize the output of the plot:
%   
%   'colormap' - integer: specifies the number of rows in the colormap used 
%                   for plotting.  Default is 64 rows.
%   'clim'     - [min max]: specify the minimum and maximum values for 
%                   color-scaling the plots.  Defaults to [min(C) max(C)].
%   'colorbar' - ['horiz'|'vert'|'none']: specify the type of colorbar to 
%                   use (or none at all).  Default is 'horiz'.
%   'marker'   - a structure containing one or both of the following fields
%                   along with a value:
%                   .Marker = valid marker type - Default is '.'
%                   .MarkerSize = integer - Default is 8
%                   .Tag - assign a tag to the plotted points - default tag is
%                   'default_scatter'
%
% ============================================================================
% $RCSfile: fastScatter.m,v $
% $Source: /home/kerfoot/cvsroot/slocum/matlab/spt/vis/bin/fastScatter.m,v $
% $Revision: 1.1 $
% $Date: 2013/10/10 18:57:16 $
% $Author: kerfoot $
% ============================================================================
%

app = [mfilename '.m'];

% Initialize output arguments
h = [];
cbH = [];

% Validate args
if isempty(X) || isempty(Y) || isempty(C)
    error(sprintf('%s:invalidArgument', app),...
        'One or more of the input arrays are empty');
elseif ~isequal(length(X), length(Y)) || ~isequal(length(X), length(C))
    error(sprintf('%s:invalidArgument', app),...
        'One or more input arrays are badly sized');
elseif ~isequal(mod(length(varargin),2),0)
    error(sprintf('%s:invalidOption', app),...
        'Invalid number of name,value option pairs specified');
end;

COLORBAR_TYPES = {'none',...
    'vert',...
    'horiz',...
    }';
            
% Default option values
colorMap = jet(64); % Default colormap
valueRange = [min(C) max(C)]; % min and max values
markerProps = struct( 'Marker', 'o',...
    'MarkerSize', 5,...
    'LineStyle', 'None',...
    'Tag', 'default_scatter'); % Default marker properties
colorbarType = 'none'; % colorbar orientation

% Process the options      
for x = 1:2:length(varargin)
    
    name  = varargin{x};
    value = varargin{x+1};

    switch lower(name)
        case 'colormap'
            if ~isnumeric(value) ||...
                    isempty(value) ||...
                    ~isequal(size(value,2), 3)
                error(sprintf('%s:invalidOptionValue', app),...
                    'Value for option %s must be an Mx3 array',...
                    name);
            end
            colorMap = value;
        case 'clim'
            if ~isnumeric(value) ||...
                    ~isequal(numel(value),2)
                error(sprintf('%s:invalidOptionValue', app),...
                    'Value for option %s must be an 2-element numeric array',...
                    name);
            end
            valueRange = [min(value) max(value)];
        case 'colorbar'
            if ~ischar(value) ||...
                    ~ismember(value, COLORBAR_TYPES)
                error(sprintf('%s:invalidOptionValue', app),...
                    'Value for option %s must be an one of the following:',...
                    name);
            end
            colorbarType = value;
        case 'marker'
            if ~isstruct(value)
                error(sprintf('%s:invalidOptionValue', app),...
                    'Value for option %s must be a structure containing line properties',...
                    name);
            end
            marker_props = fieldnames(value);
            for z = 1:length(marker_props)
                markerProps.(marker_props{z}) = value.(marker_props{z});
            end

        otherwise
            error(sprintf('%s:invalidOption', app),...
                'Invalid option specified: %s',...
                name);
    end
end

% Get rid of rows for which at least one column is NaN
XYC = [X Y C];
XYC(any(isnan(XYC),2),:) = [];
% Get rid of infinites
XYC(any(isinf(XYC),2),:) = [];

if isempty(XYC)
    return;
end

% Make sure the input arays of Mx1
X = XYC(:,1);
Y = XYC(:,2);
C = XYC(:,3);

% Make sure the color range has finite values
% % % % cRange(cRange < -realmin) = min(XYC(:,3));
% % % % cRange(cRange > realmax) = max(XYC(:,3));
caxis(valueRange);

set(gca,...
    'NextPlot', 'add');

% Set the ranges for determining marker color
color_ranges = linspace( min(valueRange), max(valueRange), size(colorMap,1) )';

% Determine the color bin and plot the data ==================================

% Minimum color limit
ind = find(C <= color_ranges(1));
if ~isempty(ind)
    markerProps.Color = colorMap(1,:);
    
    % Plot the points
    plot(X(ind), Y(ind), markerProps);
    
    % Delete points to speed things up
    X(ind,:) = [];
    Y(ind,:) = [];
    C(ind,:) = [];
end;

for x = 1:length(color_ranges) - 1
    
    ind = find(C > color_ranges(x) & C <= color_ranges(x + 1));
    
    if ~isempty(ind)
        
        markerProps.Color = colorMap(x+1,:);
        markerProps.MarkerFaceColor = markerProps.Color;
        markerProps.MarkerEdgeColor = markerProps.Color;
        
        % Plot the points
        plot(X(ind), Y(ind), markerProps);
        
        % Delete points to speed things up
        X(ind,:) = [];
        Y(ind,:) = [];
        C(ind,:) = [];
        
    end;
    
end;

% Maximum color limit
ind = find(C > color_ranges(end));
if ~isempty(ind)
    
    markerProps.Color = colorMap(end,:);
    
    % Plot the points
    plot(X(ind), Y(ind), markerProps);
    
    % Delete points to speed things up
    X(ind) = [];
    Y(ind) = [];
    C(ind) = [];
end;


% Set the colormap
colormap(colorMap);
axis('tight');
set(gca, 'ydir', 'reverse');

switch colorbarType
    case 'vert'
        cbH = colorbar(colorbarType);
    case 'horiz'
        cbH = colorbar(colorbarType);
end


% Fetch the handles to each plotted point to return
h = findobj('Tag', markerProps.Tag);
