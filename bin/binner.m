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
% $Revision: 1.2 $
% $Date: 2013/09/26 20:55:02 $
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
        data(:,column) <= bin+halfWidth;
    
    % Take the mean excluding nans
    if any(binInds)
        
        % Data to bin
        t_data = data(binInds,:);
        % Find NaNs
        nans = isnan(t_data);
        % Count up the number we need to divide each column sum by
        denominator = sum(~isnan(t_data),1);
        % Replace 0 with 1 to prevent divide by 0 errors
        denominator(denominator == 0) = 1;
        % Set all NaN values in the array to 0
        t_data(nans) = 0;
        
        % Sum the raw data column-wise and divide by the number of non-NaN
        % points
        b_data = sum(t_data,1)./denominator;
        % Replace all column values where there were no non-NaN points with
        % NaN
        b_data(all(nans,1)) = NaN;
        
        binned(x,:) = b_data;
    end;

end;

% Replace column with bins
binned(:,column) = bins;
   

