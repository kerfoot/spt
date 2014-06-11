function imageCount = plotDbdGroupProfileAverages(dgroup, sensor, varargin)
%
% imageCount = plotDbdGroupSensorAverages(dgroup, sensor, varargin)
%
% Calculates and plots the profiles, down and upcast averages and standard
% deviations for the specified sensor.  The set of profiles is taken from each
% of the Dbd instances contained in dgroup.dbds and an image is created only if
% the instance contains indexed profiles.
%
% The images are written to the current working directory.
%
% Name,value Options:
%   outdirectory: STRING - alternate location for writing the images.
%
% See also DbdGroup Dbd.averageProfiles
% ============================================================================
% $RCSfile: plotDbdGroupProfileAverages.m,v $
% $Source: /home/kerfoot/cvsroot/slocum/matlab/spt/vis/plotDbdGroupProfileAverages.m,v $
% $Revision: 1.1 $
% $Date: 2014/06/11 20:03:20 $
% $Author: kerfoot $
% ============================================================================
%

app = mfilename;
imageCount = 0;

% Validate input args
if ~isa(dgroup, 'DbdGroup')
    error(sprintf('%s:invalidClass', app),...
        'Specified instance is not of the DbdGroup class.');
elseif nargin < 2
    error(sprintf('%s:nargin', app),...
        'No sensor specified.');
elseif ~ismember(sensor, dgroup.sensors)
    fprintf(1,...
        '%s is not sensor in the Dbd instance.',...
        sensorName);
    return;
end

% Default options
IMG_DIR = pwd;
VERBOSE = false;
XLIM = [];
YLIM = [];
for x = 1:2:length(varargin)
    name = varargin{x};
    value = varargin{x+1};
    
    switch lower(name)
        case 'outdirectory'
            if ~ischar(value) || isempty(value) || ~isdir(value)
                fprintf(2,...
                    'The value for option %s must be a string specifying an existing directory\n',...
                    name);
                return;
            end
            IMG_DIR = value;
        case 'verbose'
            if ~isequal(numel(value),1) || ~islogical(value)
                fprintf(2,...
                    'The value for option %s must be a single logical value\n',...
                    name);
                return;
            end
            VERBOSE = value;
        case 'xlim'
            if ~isequal(numel(value),2) || all(~isnumeric(value))
                fprintf(2,...
                    'The value for option %s must be a 2 element array containing min and max values\n',...
                    name);
                return;
            end
            XLIM = value;
        case 'ylim'
            if ~isequal(numel(value),2) || all(~isnumeric(value))
                fprintf(2,...
                    'The value for option %s must be a 2 element array containing min and max values\n',...
                    name);
                return;
            end
            YLIM = value;
        otherwise
            fprintf(2,...
                'Invalid option specified: %s\n',...
                name);
            return;
    end
end

numProfiles = dgroup.numProfiles;

if VERBOSE
    fprintf(1,...
        'Image destination: %s\n',...
        IMG_DIR);
end
    
for x = 1:length(dgroup.dbds)
    
    if isequal(numProfiles(x),0)
        continue;
    end
    
    dgroup.dbds(x).averageProfiles(sensor, 'plot', true);
    
    imgName = [dgroup.dbds(x).the8x3filename...
        '-'...
        dgroup.dbds(x).segment...
        '-'...
        sensor...
        '-avg.png'];
    
    if VERBOSE
        fprintf(1,...
            'Printing image: %s\n',...
            imgName);
    end
    
    if ~isempty(XLIM)
        set(findobj(gcf, 'type', 'axes'), 'xlim', XLIM);
    end
    if ~isempty(YLIM)
        set(findobj(gcf, 'type', 'axes'), 'ylim', YLIM);
    end
    
    print(gcf, '-dpng', '-r300', fullfile(IMG_DIR, imgName));
    
    close(gcf);
    
    imageCount = imageCount + 1;
    
end

    