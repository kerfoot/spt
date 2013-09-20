function km = nm2km(nautical_miles)
%
% Usage: kilometers = nm2km(nautical_miles)
%
% Convert nautical miles to kilomters.
%
% See also km2nm
% ============================================================================
% $RCSfile: nm2km.m,v $
% $Source: /home/kerfoot/cvsroot/slocum/matlab/spt/navigation/nm2km.m,v $
% $Revision: 1.1.1.1 $
% $Date: 2013/09/13 18:51:19 $
% $Author: kerfoot $
% ============================================================================
%

km = nautical_miles * 1.852;
