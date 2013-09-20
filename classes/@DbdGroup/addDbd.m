function addDbd(obj, dbdInstance)
%
% DbdGroup.addDbd(Dbd)
%
% Add an instance of the Dbd class to the DbdGroup.  The Dbd instance is
% added to DbdGroup.dbds and any new sensor units contained in the Dbd
% instance are added to DbdGroup.sensorUnits.
%
% See also DbdGroup DbdGroup.removeDbd
% ============================================================================
% $RCSfile: addDbd.m,v $
% $Source: /home/kerfoot/cvsroot/slocum/matlab/spt/classes/@DbdGroup/addDbd.m,v $
% $Revision: 1.1.1.1 $
% $Date: 2013/09/13 18:51:19 $
% $Author: kerfoot $
% ============================================================================
% 

% Make sure we're adding an instance of the Dbd instance that
% is not already included
if ~isa(dbdInstance, 'Dbd')
    error('DbdGroup:invalidDbd',...
        'Only Dbd instances may be added to the DbdGroup.');
elseif ismember(dbdInstance.segment, obj.segments)
    error('DbdGroup:duplicateDbd',...
        'Dbd instance is already a member of the DbdGroup.');
end

% Add it to obj.dbds
obj.dbds(end+1) = dbdInstance;

% Place the newly added segment name in obj.newSegments
obj.newSegments{end+1} = dbdInstance.segment;
obj.newSegments = obj.newSegments(:);
% Sort the segments in reverse chronological order (latest segment first)
obj.newSegments = flipud(sortDbds(obj.newSegments));

% Add the units for any new sensors contained in the Dbd instance to
% obj.sensorUnits
newUnits = setdiff(fieldnames(dbdInstance.sensorUnits),...
    fieldnames(obj.sensorUnits));
for u = 1:length(newUnits)
    obj.sensorUnits(1).(newUnits{u}) =...
        dbdInstance.sensorUnits.(newUnits{u});
end

% Sort the Dbd instances
[~,I] = sort(cat(1, obj.dbds.startDatenum));
obj.dbds = obj.dbds(I);
