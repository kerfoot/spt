function p = ioosTrajectoryNc2Profiles(ncFile)
%
% p = ioosTrajectoryNc2Profiles(ncFile)
%
% Returns a structured array containing individual profiles as determined
% from the profile_id variable in the ncFile, which must conform to the
% IOOS Trajectory conventions.
%
% See also plotTrajectoryProfiles
% ============================================================================
% $RCSfile: ioosTrajectoryNc2Profiles.m,v $
% $Source: /home/kerfoot/cvsroot/slocum/matlab/spt/export/nc/IOOS/trajectory/bin/ioosTrajectoryNc2Profiles.m,v $
% $Revision: 1.1 $
% $Date: 2014/04/02 13:23:09 $
% $Author: kerfoot $
% ============================================================================
%

app = mfilename;
p = [];

nci = ncinfo(ncFile);

ncVars = {nci.Variables.Name}';

% Confirm that the file contains profile data
[Y,I] = ismember('profile_id', ncVars);
if isequal(Y,0)
    error(sprintf('%s:missingVariable', app),...
        'Missing profile_id: Cannot create profile data structure.');
end

% profile_id should be an Nx1 variable
if ~isequal(length(nci.Variables(I).Dimensions),1)
    error(sprintf('%s:incorrectVariableDimension', app),...
        'profile_id is not properly dimensioned.');
end

coordVar = nci.Variables(I).Dimensions.Name;
pVars = {};
for v = 1:length(nci.Variables)
    
    % All variables should be an Nx1 variable
    if isempty(nci.Variables(v).Dimensions)
        continue;
    elseif ~isequal(length(nci.Variables(v).Dimensions),1)
        warning(sprintf('%s:incorrectVariableDimension', app),...
            '%s: variable should contain a single dimension.',...
            nci.Variables(v).Name);
        continue;
    end

    if ~strcmp(coordVar, nci.Variables(v).Dimensions.Name)
        continue;
    end
    
    pVars{end+1} = nci.Variables(v).Name;
    
end

% Initialize a matrix of NaNs to hold the variable data we need to pull out
data = nan(nci.Variables(I).Dimensions.Length,length(pVars));
for x = 1:length(pVars)
    data(:,x) = ncread(ncFile, pVars{x});
end

% Find the profile_id column in data
[Y,I] = ismember('profile_id', pVars);
if isequal(Y,0)
    return;
end

% Create a structured array mapping variable names to data arrays
pids = unique(data(:,I));
pids(isnan(pids)) = [];
for x = 1:length(pids)
    
    profileData = data(data(:,I) == pids(x),:);
    
    for z = 1:length(pVars)
        p(x).(pVars{z}) = profileData(:,z);
    end
    
end
    
    