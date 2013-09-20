function mTime = epoch2datenum(epochTime)
%
% mTime = epoch2datenum(epochTime)
%
% Converts the unix/epoch timestamp to a matlab datenum datatype.
%
% SEE ALSO datenum datenum2epoch
% ============================================================================
% $RCSfile: epoch2datenum.m,v $
% $Source: /home/kerfoot/cvsroot/slocum/matlab/spt/bin/epoch2datenum.m,v $
% $Revision: 1.1.1.1 $
% $Date: 2013/09/13 18:51:18 $
% $Author: kerfoot $
% ============================================================================
%

% Calculate the number of days elapsed between January 1, 0000 and January 1, 
% 1970.  January 1, 1970 is the beginning of time in the unix world and is 
% referred to as the epoch.
epoch_offset = datenum(1970, 1, 1) - datenum(0000, 1, 0);

% Divide the input (epochTime) by the number of seconds in 1 day.
from_epoch = epochTime/(24 * 60 * 60);

% % % % % % Convert non-nan values only
% % % % % [r,c] = find(~isnan(epochTime));
% % % % % 
% % % % % % Add the 2 to get the datenum number.
% % % % % mTime(r,c) = epoch_offset + from_epoch(r,c);

mTime = epoch_offset + from_epoch;