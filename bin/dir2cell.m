function file_list = dir2cell(directory_structure, directory)
%
% Usage: file_list = dir2cell(directory_structure, directory)
%
% Returns a cell array of strings containing the fully-qualified pathnames to 
% the files contained in the directory structure (as returned by dir.m) by
% appending the current working directory to each element.  An (optional)
% second argument (string) may be specified as the directory to append in
% place of the current working directory.
%
% See also dir
% ============================================================================
% $RCSfile: dir2cell.m,v $
% $Source: /home/kerfoot/cvsroot/slocum/matlab/spt/bin/dir2cell.m,v $
% $Revision: 1.1.1.1 $
% $Date: 2013/09/13 18:51:18 $
% $Author: kerfoot $
% ============================================================================
%

file_list = {};

% Validate arguments
if isequal(nargin,0) || nargin > 2
    fprintf(2,...
        'Only 2 arguments allowed.\n');
    return;
elseif isequal(nargin,1)
    directory = pwd;
elseif ~isstruct(directory_structure)
    fprintf(2,...
        'First argument must be a structured array returned by dir.m.\n');
    return;
elseif isequal(nargin,2) && ~ischar(directory)
    fprintf(2,...
        'Second argument must be a string.\n');
    return;
end

if isempty(directory_structure)
    return;
end

% Get the fully-qualified path to directory
[success,attrib] = fileattrib(directory);
if isequal(success,1)
    directory = attrib.Name;
end

% Create a cell array of the file entries from dirStruct.name
file_list = {directory_structure.name}';

% Prepend fileDir to each entry
for x = 1:length(file_list)
    file_list{x} = fullfile(directory, file_list{x});
end
