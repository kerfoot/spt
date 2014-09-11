function addDbd(obj, dbdInstance)
%
% DbdGroup.addDbd(Dbd)
%
% Add a valid instance of the Dbd class to the DbdGroup.  The Dbd instance 
% is added to DbdGroup.dbds only if the instance contains sensors 
% (Dbd.sensors) and any new sensor units contained in the Dbd instance are 
% added to DbdGroup.sensorUnits.
%
% See also DbdGroup DbdGroup.removeDbd
% ============================================================================
% $RCSfile: addDbd.m,v $
% $Source: /home/kerfoot/cvsroot/slocum/matlab/spt/classes/@DbdGroup/addDbd.m,v $
% $Revision: 1.2 $
% $Date: 2013/10/07 15:35:45 $
% $Author: kerfoot $
% ============================================================================
% 

% Make sure we're adding an instance of the Dbd instance that
% is not already included
if ~isa(dbdInstance, 'Dbd')
    fprintf(2,...
        'DbdGroup:invalidDbd: Object is not a valid Dbd instance.\n');
    return;
elseif ismember(dbdInstance.segment, obj.segments)
    fprintf(2,...
        'DbdGroup:duplicateDbd:%s: Dbd instance is already a member of the DbdGroup.',...
        dbdInstance.segment);
    return;
elseif isempty(dbdInstance.sensors)
    fprintf(2,...
        'DbdGroup:emptyDbd:%s: Dbd instance does not contain any sensor data\n',...
        dbdInstance.segment);
    return;
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
