function epochTime = datenum2epoch(mTime)
%
% epochTime = datenum2epoch(mTime)
%
% Converts the matlab datenum datatype to the corresponding unix/epoch time
% (number of seconds which have elapsed since January 1, 1970, UTC).
%
% SEE ALSO epoch2datenum
% ============================================================================
% $RCSfile: datenum2epoch.m,v $
% $Source: /home/kerfoot/cvsroot/slocum/matlab/spt/bin/datenum2epoch.m,v $
% $Revision: 1.1.1.1 $
% $Date: 2013/09/13 18:51:18 $
% $Author: kerfoot $
% ============================================================================
%

% Calculate the number of seconds in a day
SECONDS_PER_DAY = 60*60*24;

% Get the datenum number of January 1, 1970
epochStart = datenum(1970, 1, 1, 0, 0, 0);

% Subtract the epoch_start from input time (mTime) and multiply by the number 
% of seconds in 1 day to get the epoch (UTC) timestamp.
epochTime = (mTime - epochStart) * SECONDS_PER_DAY;
