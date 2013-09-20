function binned = binner(data, column, binSize, varargin)
%
% binned = binner(data, column, bin_size[, varargin])
%
% Bins the columns in the data argument with reference to column in bin_size
% increment.
%
% ============================================================================
% $RCSfile: binner.m,v $
% $Source: /home/kerfoot/cvsroot/slocum/matlab/spt/bin/binner.m,v $
% $Revision: 1.1.1.1 $
% $Date: 2013/09/13 18:51:18 $
% $Author: kerfoot $
% $Name:  $
% ============================================================================
%

binned = [];

% Check input args
if nargin < 3
    fprintf(2, '3 arguments are required.');
    return;
elseif isempty(data)
    fprintf(2, 'Nothing to bin!\n');
    return;
elseif column > size(data,2)
    fprintf(2, 'Bin column index exceeds number of columns.\n');
    return;
end

% Get rid of NaNs in the bin column
data(isnan(data(:,column)),:) = [];

% Make sure the bin column has at least 2 non-NaN values
if size(data,1) < 2
    fprintf(1, 'Data matrix must contain at least 2 non-NaN rows.\n');
    return;
end
binArray = data(:,column);
% Set up the bins
bins = (floor(min(binArray)):binSize:ceil(max(binArray)))';
% Bin size
halfWidth = binSize/2;

% Intialize binned matrix
binned = nan(length(bins), size(data,2));

for x = 1:length(bins)
    
    % Current bin
    bin = bins(x);
    
    % Find all rows within this bin +/- halfWidth
    binInds = data(:,column) > bin-halfWidth &...
        data(:,column) <= bin + halfWidth;
    
    % Take the mean
    if any(binInds)
        binned(x,:) = mean(data(binInds,:),1);
    end;

end;

% Replace column with bins
binned(:,column) = bins;
   

