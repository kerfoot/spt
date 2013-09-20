function nm = rad2nm(radians)
%
% Usage: nautical_miles = rad2nm(radians)
%
% Convert radians to nautical miles.
% 
% See also nm2rad
% ============================================================================
% $RCSfile: rad2nm.m,v $
% $Source: /home/kerfoot/cvsroot/slocum/matlab/spt/navigation/rad2nm.m,v $
% $Revision: 1.1.1.1 $
% $Date: 2013/09/13 18:51:19 $
% $Author: kerfoot $
% ============================================================================
%

nm = 180*60/pi*radians;
