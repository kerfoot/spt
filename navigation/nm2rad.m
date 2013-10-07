function radians = nm2rad(nautical_miles)
%
% Usage: radians = nm2rad(nautical_miles)
%
% Convert nautical miles to radians.
%
% See also rad2nm
% ============================================================================
% $RCSfile: nm2rad.m,v $
% $Source: /home/kerfoot/cvsroot/slocum/matlab/spt/navigation/nm2rad.m,v $
% $Revision: 1.1.1.1 $
% $Date: 2013/09/13 18:51:19 $
% $Author: kerfoot $
% ============================================================================
%

radians = pi/(180*60)*nautical_miles;
