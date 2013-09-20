function salinity = calculate_glider_salinity(conductivity, temperature, pressure)
%
% USAGE : salinity = calculate_glider_salinity(cond, temp, pres) 
%
% Wrapper function to calculate glider salinity.  Units of inputs are:
%
%   conductivity:   S/m
%   temperature:    Celsius
%   pressure:       decibars
% 
% The matlab seawater toolbox must be installed to use this function.  Download
% url:
%
% http://woodshole.er.usgs.gov/operations/sea-mat/
%
% ============================================================================
% $RCSfile: calculate_glider_salinity.m,v $
% $Source: /home/kerfoot/cvsroot/slocum/matlab/spt/util/calculate_glider_salinity.m,v $
% $Revision: 1.1.1.1 $
% $Date: 2013/09/13 18:51:19 $
% $Author: kerfoot $
% ============================================================================
%

salinity = sw_salt(conductivity/(sw_c3515*0.1), temperature, pressure);

