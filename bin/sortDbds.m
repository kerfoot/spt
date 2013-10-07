function sorted_dbds = sortDbds(unsorted_dbds)
%
% Usage: sorted_dbds = sortDbds(unsorted_dbds)
%
% Attempts to sort Slocum glider data files contained in unsorted_dbs, a cell
% array of filenames, in ascending order based upon the following sequence: 
% year, julian day, mission, segment.  For the sort to succeed, the input
% filenames must contain the following string:
%
%   yyyy_ddd_m[mm]_s[ss]_
%
% where:
%   yyyy : four-digit year
%   ddd  : three-digit julian day
%   m[mm]: one to three-digit mission number
%   s[ss]: one to three-digit segment number
%
% This file format is the default naming convention for renamed
% (rename_dbd_files) 8.3 Slocum glider data files.
%
% The return value is a sorted cell array of strings
%
% See also dir2cell
% ============================================================================
% $RCSfile: sortDbds.m,v $
% $Source: /home/kerfoot/cvsroot/slocum/matlab/spt/bin/sortDbds.m,v $
% $Revision: 1.3 $
% $Date: 2013/10/04 13:00:59 $
% $Author: kerfoot $
% $Name:  $
% ============================================================================
% 

caller = [mfilename '.m'];

sorted_dbds = {};
if ~iscellstr(unsorted_dbds)
    fprintf(2,...
        'Input argument must be a cell array of dbd filenames.\n');
    return;
end

% Intialize the sorting matrix
sortMatrix = nan(length(unsorted_dbds), 4);
for x = 1:length(unsorted_dbds)
    [~, f_name] = fileparts(unsorted_dbds{x});
    
    % Use a regular expression to grab the year, julian day, mission and
    % segment numbers from the filename:
    % REGEXP:
    %   - must begin with an underscore
    %   - first token must begin with the number 1 or 2 and contain exactly 4
    %   digits.
    %   - second, third and fourth token must contain between 1 and 3 digits
    %   - ALL tokens must be separated from each other by an underscore
    parts = regexp(f_name,...
        '_([1|2]\d{3})_(\d{1,3})_(\d{1,3})_(\d{1,3})_?',...
        'tokens');

    % make sure we have a minimum of tokens
    if isempty(parts)
        disp([caller ' W - Invalid segment name.']);
        continue;
    end

    % Convert the parts to double-precision for sorting
    sortMatrix(x,:) = str2double(parts{1});
    
end
% Remove NaNs
sortMatrix(any(isnan(sortMatrix),2),:) = [];

% Sort the resulting matrix
[Y,I] = sortrows(sortMatrix);
sorted_dbds = unsorted_dbds(I);

