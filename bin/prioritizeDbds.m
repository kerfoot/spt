function fDbds = prioritizeDbds(dbdsList, varargin)
%
% fDbds = prioritizeDbds(dbdsList, varargin)
%
% Takes a list of glider ascii segment files of mixed type (*.sbd,
% *.dbd,...) and sorts the list to prioritize the files based on the file
% type.  The default sort order is:
%
%   dbd
%   sf_dbd
%   sbd
%   mbd
%   ebd
%   tbd
%   nbd
%
fDbds = {};

% Default prioritization order
dbdTypesOrder = {'dbd',...
    'sf_dbd',...
    'sbd',...
    'mbd',...
    'ebd',...
    'tbd',...
    'nbd',...
    }';

% Validate input arguments
if nargin < 1 || isempty(dbdsList)
    fprintf(2,...
        'Empty file list\n');
    return;
elseif ~isequal(mod(length(varargin),2),0)
    fprintf(2,...
        'Invalid number of options specified\n');
    return;
end
% Process options
for x = 1:2:length(varargin)
    name = varargin{x};
    value = varargin{x+1};
    switch lower(name)
        case 'types'
            if ~iscellstr(value)
                fprintf(2,...
                    'Value for %s must be a cell array of strings\n',...
                    name);
                return;
            end
            dbdTypesOrder = value;
        otherwise
            fprintf(2,...
                'Unknown option: %s\n',...
                name);
            return;
    end
end

% If the  list of filetypes with contains only letters, fix the regexps so 
% that they match more accurately
for x = 1:length(dbdTypesOrder)
    if ~isempty(regexp(dbdTypesOrder{x}, '^[a-z]+$', 'once'))
        dbdTypesOrder{x} = sprintf('_%s.m', dbdTypesOrder{x});
    end
end

for x = 1:length(dbdsList)
    
    % Strip off the path
    [~,dbdFile] = fileparts(dbdsList{x});
    % Strip off the filetype from the dbdFile
    tokens = regexp(dbdFile,...
        '^(.*\d{4}_\d{3}_\d+_\d+_)',...
        'tokens');
    if isempty(tokens)
        fprintf(2,...
            'Invalid file name: %s\n',...
            dbd);
        continue;
    end
    segment = tokens{1}{1};

    % Deal with multiple files from the same segment
    segInds = find(~cellfun(@isempty, regexp(dbdsList, segment)) == 1);
    if length(segInds) > 1
        isSeg = nan(length(segInds),1);
        for s = 1:length(segInds)
            [sameSeg{1:length(dbdTypesOrder)}] = deal(dbdsList{segInds(s)});
            isSeg(s) = find(~cellfun(@isempty, regexp(sameSeg, dbdTypesOrder)) == 1);
        end
        [~,I] = setdiff(isSeg, min(isSeg));
        dbdsList{segInds(I)} = '';
        
    end
end

% Create the filtered file list
fDbds = dbdsList(~cellfun(@isempty, dbdsList));
