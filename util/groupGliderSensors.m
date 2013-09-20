function sensorGroups = groupGliderSensors(sensorSet)
%
% sensorGroups = groupGliderSensors(sensorSet)
%
% Divide the current sensor set (cell array) into 2 groups:
%   sensorGroups.sci: cell array containing the sensors which may be useful
%       for analyzing the glider deploymentfrom a scientific point of view
%   sensorGroups.eng: miscellaneous sensors most likely used for analyzing a
%       glider deployment from an engineering point of view.
%
% Sensor selection is done using regular expressions.
%
% ============================================================================
% $RCSfile: groupGliderSensors.m,v $
% $Source: /home/kerfoot/cvsroot/slocum/matlab/spt/util/groupGliderSensors.m,v $
% $Revision: 1.1.1.1 $
% $Date: 2013/09/13 18:51:19 $
% $Author: kerfoot $
% ============================================================================
%

sensorGroups = [];

if ~isequal(nargin,1) || ~iscellstr(sensorSet) || isempty(sensorSet)
    fprintf(2,...
        'sensorSet argument must be a non-empty cell array of strings\n');
    return;
end

% Patterns to search for non-science critical sensors
tokens = {'^gld_dup_',...
    '^u_',...
    '^x_',...
    '^dc_',...
    '^f_',...
    '^s_',...
    '^xs_',...
    '^m_iridium_',...
    '_state$',...
    '_ver$',...
    }';

pat = '';
for x = 1:length(tokens)
    pat = sprintf('%s%s|',...
        pat,...
        tokens{x});
end
    
% Removing the trailing pipe
pat(end) = [];

% Search for bad sensors
r = regexp(sensorSet, pat);

sensorGroups.sci = sensorSet(cellfun(@isempty, r));
sensorGroups.eng = sensorSet(~cellfun(@isempty, r));
