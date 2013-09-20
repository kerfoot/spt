function smoothed_data = pmsmooth(data, windowSize)
% poorman's smoothing function
%
% smoothed_data = pmsmooth(data, windowSize)
%
% Moving average smoothing function.  windowSize should be odd.  If it is
% not, 1 is added
%

h = ones(1,windowSize)/windowSize;      % equiv to a moving average window

smoothed_data = filter(h, 1, data);