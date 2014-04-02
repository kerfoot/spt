function p = checkIoosTrajectoryCompliance(ncFile, varargin)
%
% p = checkIoosTrajectoryCompliance(ncFile, varargin)
%
% Analyzes the specified IOOS Trajectory NetCDF file for compliance to the
% template located at:
%
%   https://github.com/IOOSProfilingGliders/Real-Time-File-Format/tree/master/template
%
% The compliance checking is crude and incomplete, but the output provides
% feedback on:
%   1. Global file attribute check
%   2. Required variables and attributes
%   3. Coordinate variables contain NO missing values
%   4. Variable conform to coordinate variable dimensions
%   5. The file contains at least 1 profile with valid records included in
%   the profile(s).
%
% The return value is a structured array containing individual profiles.
%
% See also ioosTrajectoryNc2Profiles plotTrajectoryProfiles
% ============================================================================
% $RCSfile: checkIoosTrajectoryCompliance.m,v $
% $Source: /home/kerfoot/cvsroot/slocum/matlab/spt/export/nc/IOOS/trajectory/qc/checkIoosTrajectoryCompliance.m,v $
% $Revision: 1.1 $
% $Date: 2014/04/02 13:23:10 $
% $Author: kerfoot $
% ============================================================================
%

p = [];
app = mfilename;

% Checks
% 1. Contains all global attributes
% 2. Contains all required variables
% 3. Contains all variable attributes
% 4. Coordinate variables contain NO missing values
% 5. trajectory coordinate variable set to 1
% 6. All variables conform to coordinate variable dimensions
% 6. profile_id:
%   - contains values
%   - produces profiles which have data

% Attempt to read the NC_FILE metadata
nci = ncinfo(ncFile);

% Create an instance of the GTrajectory class
NC_REF = GTrajectoryNc();

% Cell array of  global attributes
REF_ATTS = {NC_REF.getGlobalAttributes().Name}';
% Cell array of global attributes contained in the file
ncAtts = {nci.Attributes.Name}';

fprintf('==============================================================================\n');
fprintf('Checking compliance: %s\n',...
    ncFile);
fprintf('Reference template : %s\n',...
    NC_REF.schemaNcTemplate);
fprintf('==============================================================================\n');

% Loop through all refAtts and check for their existence in the NC_FILE
attCount = 0;
blankCount = 0;
fprintf('> Checking global file attributes...\n');
for x = 1:length(REF_ATTS)
    
    [Y,I] = ismember(REF_ATTS{x}, ncAtts);
    if isequal(Y,0)
        fprintf(2, 'ERROR: Missing required global attribute: %s\n',...
            REF_ATTS{x});        
        continue;
    end
    
    attCount = attCount + 1;
    
    % Make sure there is a value for the attribute
    if isempty(nci.Attributes(I).Value)
        fprintf(2, 'WARNING: Missing value for required global attribute: %s\n',...
            REF_ATTS{x});
        blankCount = blankCount + 1;
    end
    
end
fprintf('>> %0.0f/%0.0f required global attributes found.\n',...
    attCount,...
    length(REF_ATTS));
fprintf('>> %0.0f/%0.0f required global attributes are missing values.\n',...
    blankCount,...
    length(REF_ATTS));

% Check for required variables and associated variable attributes
ncVars = {nci.Variables.Name}';
REF_VARS = NC_REF.Variables();
varCount = 0;
for x = 1:length(REF_VARS)
    
    fprintf('------------------------------------------------------------------------------\n');
    
    [Y,I] = ismember(REF_VARS{x}, ncVars);
    if isequal(Y,0)
        fprintf(2, 'ERROR: Missing required variable: %s.\n',...
            REF_VARS{x});
        varCount = varCount + 1;
        continue;
    end
    
    varAttCount = 0;
    varAttBlankCount = 0;
    
    % Get the variable metadata from the template file
    REF_VAR_ATTS = {NC_REF.getVariableAttributes(REF_VARS{x}).Name}';
    ncVarAtts = {nci.Variables(I).Attributes.Name}';
    
    for a = 1:length(REF_VAR_ATTS)
        
        [Z,J] = ismember(REF_VAR_ATTS{a}, ncVarAtts);
        if isequal(Z,0)
            fprintf(2, 'ERROR: Missing required variable attribute: %s:%s.\n',...
                REF_VARS{x},...
                REF_VAR_ATTS{a});           
            continue;
        end
        
        varAttCount = varAttCount + 1;
        
        % Make sure there is a value for the attribute
        if isempty(nci.Variables(I).Attributes(J).Value)
            fprintf(2, 'WARNING: Missing value for required variable attribute: %s:%s.\n',...
                REF_VARS{x},...
                REF_VAR_ATTS{a});
            varAttBlankCount = varAttBlankCount + 1;
        end
       
    end
    
    fprintf('>> Variable %s: %0.0f/%0.0f required attributes found.\n',...
        REF_VARS{x},...
        varAttCount,...
        length(REF_VAR_ATTS));
    fprintf('>> Variable %s: %0.0f/%0.0f empty attributes.\n',...
        REF_VARS{x},...
        varAttBlankCount,...
        length(REF_VAR_ATTS));
        
end

% Check coordinate variables for missing values, which is not allowed
ncCoords = {nci.Dimensions.Name}';
for c = 1:length(ncCoords)
    data = ncread(ncFile, ncCoords{c});
    if any(isnan(data))
        fprintf(2, 'ERROR: Coordinate variable %s contains at least one missing value.\n',...
            ncCoords{c});
    elseif strcmp('trajectory', ncCoords{c})
        % trajectory coordinate treated special
        if ~isequal(length(data),1) || ~isequal(data,1)
            fprintf(2, 'ERROR: trajectory coordinate variable array must be scalar and equal to 1.\n');
        end
    end
end

% Check variables for proper length, based on coordinate variables
for v = 1:length(ncVars)

    if isempty(nci.Variables(v).Dimensions)
        fprintf(2, 'WARNING: Dimensionless variable: %s.\n',...
            ncVars{v});
        continue;
    end

    varCoords = {nci.Variables(v).Dimensions.Name}';
    [Y,AI,BI] = intersect(varCoords, ncCoords);
    if isempty(Y)
        continue;
    end

    for d = 1:length(Y)
        if ~isequal(nci.Variables(v).Dimensions(AI(d)).Length,...
                nci.Dimensions(BI(d)).Length)
            fprintf(2, 'ERROR: Variable %s does not conform to coordinate variable (%s) length.\n',...
                ncVars{v},...
                C_VAR.Name);
        end
    end
    
end
    
% Create the profiles data structure
p = ioosTrajectoryNc2Profiles(ncFile);
