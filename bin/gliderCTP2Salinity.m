function salinity = gliderCTP2Salinity(conductivity, temperature, pressure)
%
% USAGE : salinity = gliderCTP2Salinity(cond, temp, pres) 
%
% Wrapper function to calculate glider salinity.  Units of inputs are:
%
%   conductivity:   S/m
%   temperature:    Celsius
%   pressure:       decibars
% 
% The CSIRO matlab seawater toolbox must be installed to use this function.  
% Download url:
%
% http://marine.rutgers.edu/~kerfoot/slocum/code/seawater_ver3_3.tar
%
% ============================================================================
% $RCSfile: gliderCTP2Salinity.m,v $
% $Source: /home/kerfoot/cvsroot/slocum/matlab/spt/bin/gliderCTP2Salinity.m,v $
% $Revision: 1.1 $
% $Date: 2013/10/07 15:55:00 $
% $Author: kerfoot $
% ============================================================================
%

salinity = sw_salt(conductivity/(sw_c3515*0.1), temperature, pressure);

