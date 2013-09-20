function removeDbd(obj, segments)
%
% DbdGroup.removeDbd(segments)
%
% Remove Dbd instances, identified by segment names, from the DbdGroup.
%
% See also DbdGroup DbdGroup.addDbd
% ============================================================================
% $RCSfile: removeDbd.m,v $
% $Source: /home/kerfoot/cvsroot/slocum/matlab/spt/classes/@DbdGroup/removeDbd.m,v $
% $Revision: 1.1.1.1 $
% $Date: 2013/09/13 18:51:19 $
% $Author: kerfoot $
% ============================================================================
%


% Argument must be a string or cell array of strings
if ~isa(obj, 'DbdGroup')
    error('DbdGroup:plotTrack',...
        'Method can only be attached to the DbdGroup class');
elseif ischar(segments)
    segments = {segments};
elseif ~iscellstr(segments)
    error('DbdGroup:plotTrack',...
        'Segments must be a string or cell array of strings.');
end

[~,AI] = intersect(obj.segments, segments);

% Remove the Dbd instance if it is a member of the DbdGroup
if isempty(AI)
    warning('DbdGroup:removeDbd',...
        'The specified segment(s) is not a member of the DbdGroup instance.');
    return;
end

% Remove the instance
obj.dbds(AI) = [];

% Delete any of the removed segment names from obj.newSegments
[~,AI] = intersect(obj.newSegments, segments);
obj.newSegments(AI) = [];
