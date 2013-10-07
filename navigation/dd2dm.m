function decimal_minutes = dd2dm(coordinates)
%
% Usage: decimal_minutes = dd2dm(decimal_degrees)
%
% Convert gps coordinates from decimal degrees (DD.dddd) to decimal minutes
% (DDMM.mmmm), also know as NMEA (National Marine Electronics Association)
% coordinates.
%
% See also dm2dd
%============================================================================
% $RCSfile: dd2dm.m,v $
% $Source: /home/kerfoot/cvsroot/slocum/matlab/spt/navigation/dd2dm.m,v $
% $Revision: 1.1.1.1 $
% $Date: 2013/09/13 18:51:19 $
% $Author: kerfoot $
% ============================================================================
%

degrees = fix(coordinates);

decimal_minutes = (degrees * 100)+((coordinates - degrees)*60);
