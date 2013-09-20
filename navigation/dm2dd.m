function decimal_degrees = dm2dd(coordinates)
%
% Usage: decimal_degrees = dm2dd(decimal_minutes)
%
% Convert gps coordinates from decimal minutes (DDMM.mmmm), also known as
% NMEA (National Marine Electronics Association) coordinates, to decimal 
% degrees (DD.dddd).
%
% See also dd2dm
% ============================================================================
% $RCSfile: dm2dd.m,v $
% $Source: /home/kerfoot/cvsroot/slocum/matlab/spt/navigation/dm2dd.m,v $
% $Revision: 1.1.1.1 $
% $Date: 2013/09/13 18:51:19 $
% $Author: kerfoot $
% ============================================================================
%

degrees = fix(coordinates/100) * 100;
minutes = (coordinates - degrees)/60;

decimal_degrees = (degrees/100) + minutes;
