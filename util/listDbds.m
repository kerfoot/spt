function dbd_files = listDbds(varargin)
%
% cellArray = listDbds(varargin)
%
% Returns a cell array of fully qualified and sorted (ascending) Slocum glider
% data *bd.m in the current working directory.
%
% Name,Value Options:
%   'dir': alternate location to look for files.  The current working
%       directory is searched by default.
%   'ext': glob string specifying the file types to search for (ie:
%       '*.dat', '.dat', '*.mrg', '.mrg').
%
% Although, any pattern may be used, known valid filetypes include:
%
%   'sbd'
%   'tbd'
%   'mbd'
%   'nbd'
%   'dbd'
%   'ebd'
%   'sf_dbd'
%
% See also sortDbds dir2cell
%============================================================================
% $RCSfile: listDbds.m,v $
% $Source: /home/kerfoot/cvsroot/slocum/matlab/spt/util/listDbds.m,v $
% $Revision: 1.1 $
% $Date: 2013/09/20 20:38:31 $
% $Author: kerfoot $
% ============================================================================
%

% Return value
dbd_files = {};

% Process options
if ~isequal(mod(length(varargin),2),0)
    fprintf(2,...
        'Invalid number of options specified.\n');
    return;
end
DBD_DIR = pwd;
DBD_GLOB = 'bd.m';
for x = 1:2:length(varargin)
    name = varargin{x};
    value = varargin{x+1};
    switch lower(name)
        case 'dir'
            if ~ischar(value)
                fprintf(2,...
                    'Value for %s must be a string\n',...
                    name);
                return;
            end
            DBD_DIR = value;
        case 'ext'
            if ~ischar(value)
                fprintf(2,...
                    'Value for option %s must be a string.\n',...
                    name);
                return;
            end
            DBD_GLOB = value;
        case 'extension'
            if ~ischar(value)
                fprintf(2,...
                    'Value for option %s must be a string.\n',...
                    name);
                return;
            end
            DBD_GLOB = value;
        otherwise
            fprintf(2,...
                'Unknown option specified: %s\n',...
                name);
            return
    end
end

if ~isdir(DBD_DIR)
    fprintf(2,...
        'Invalid directory specified: %s\n',...
        DBD_DIR);
    return;
end


% Try to get the absolute path to the specified directory
[success, msg] = fileattrib(DBD_DIR);
if isequal(success,1)
    DBD_DIR = msg.Name;
end

% Remove any '*' characters and convert the cell array to a string
DBD_GLOB = char(regexprep(DBD_GLOB, '\*', '', 'once'));

% Get a listing of the files ending with the DBD_GLOB pattern
file_list = dir(fullfile(DBD_DIR, ['*' DBD_GLOB]));

% Match entries with the following pattern: '_\d{4}_\d{1,3}_\d{1,3}_\d{1,3}_'
f = {file_list.name}';
match = regexp(f, '_\d{4}_\d{1,3}_\d{1,3}_\d{1,3}_');
% Eliminate entries that don't match
file_list(cellfun(@isempty, match)) = [];

% Make sure there are files left
if isempty(file_list)
    return;
end

% Create the fully-qualified paths and sort the files
dbd_files = sortDbds(dir2cell(file_list, DBD_DIR));
