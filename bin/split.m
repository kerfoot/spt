function pieces = split(wholeString, pat)
%
% Usage: pieces = split(string[, delimiter])
%
% Split a string on whitespace, returning the tokens.  The tokens are returned
% in a cell array.  The input string is returned in the cell array if the
% delimiter was not found.
%
% ============================================================================
% $RCSfile: split.m,v $
% $Source: /home/kerfoot/cvsroot/slocum/matlab/spt/bin/split.m,v $
% $Revision: 1.1.1.1 $
% $Date: 2013/09/13 18:51:18 $
% $Author: kerfoot $
% $Name:  $
% ============================================================================
%

% Script
caller = [mfilename '.m'];

% Return value
pieces = {};

% Validate input arguments
if isequal(nargin,0)
    disp([caller ' - Please specify a string to split']);
    return;
elseif ~ischar(wholeString)
    disp([caller ' - Please specify a string to split']);
    return;
elseif isequal(nargin,1)
    pat = '\s+';
elseif isequal(nargin,2) && ~ischar(pat)
    pat = '\s+';
end

% Split using regular expressions
lasterr('');
try
    t = regexp(wholeString, pat);
    
    if isempty(t)
        pieces{1} = wholeString;
        return;
    end
    
    % Place all tokens in pieces
    pieces{1} = wholeString(1:t(1)-1);
    for x = 1:length(t)-1
        pieces{end+1} = wholeString(t(x)+1:t(x+1)-1);
    end
    pieces{end+1} = wholeString(t(end)+1:end);
    
catch
    pieces = cellstr(wholeString);
    disp([caller ' - ' lasterr]);
    return;
end

