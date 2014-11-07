function dgroup = slice(obj, varargin)
%
% dgroup = slice(obj, varargin)
%
% Returns an instance of the DbdGroup class containing all Dbd instances in the
% original DbdGroup instance.  Use of the following options will limit the
% included Dbd instances to those falling within the specified time interval(s).
%
% The default behavior may be modified using name,value options pairs
%
%   't0': datenum specifying the minimum timestamp to include.
%   't1': datenum specifying the maximum timestamp to include.
%   
% See also DbdGroup
% 

app = mfilename;

dgroup = DbdGroup();

% Validate inputs
% Validate inputs
if ~isa(obj, 'DbdGroup')
    error(sprintf('%s:invalidClass', app),...
        'Method can only be attached to the Dbd class');
elseif ~isequal(mod(length(varargin),2),0)
    error(sprintf('%s:nargin', app),...
        'Invalid number of name,value options specified.');
end

% Process options
T0 = NaN;
T1 = NaN;
sensorSet = obj.sensors;
for x = 1:2:length(varargin)
    name = varargin{x};
    value = varargin{x+1};
    switch lower(name)
       case 't0'
           if ~isequal(numel(value),1) || ~isnumeric(value)
                error(sprintf('%s:invalidDataType', app),...
                    'Value for option %s must be a numeric datenum scalar.',...
                    name);
            end
            T0 = value;
        case 't1'
            if ~isequal(numel(value),1) || ~isnumeric(value)
                error(sprintf('%s:invalidDataType', app),...
                    'Value for option %s must be a numeric datenum scalar.',...
                    name);
            end
            T1 = value;
        case 'sensors'
            % sensorSet must be a string or cell array of strings
            if ~ischar(value) && ~iscellstr(value)
                error('Dbd:toArray:invalidDataType',...
                    'Value for option %s must be a string or cell array of strings.',...
                    name);
            elseif ischar(value)
                value = {value};
            end
            sensorSet = value;
        otherwise
            error('Dbd:toArray:invalidOption',...
                'Invalid option specified: %s.',...
                name);
    end
end

sensorSet = sensorSet(:);

% Find dbd instances that are within T0 and T1, if specified
dbd0 = (1:length(obj.dbds))';
if ~isnan(T0)
    dbd0 = find(obj.endDatenums >= T0);
end
dbd1 = (1:length(obj.dbds))';
if ~isnan(T1)
    dbd1 = find(obj.startDatenums <= T1);
end
% The intersection of dbd0 and dbd1 contains the dbd instance indices that
% fit within the specified time frame
r = intersect(dbd0, dbd1);
if isempty(r)
    warning(sprintf('%s:noData', app),...
        'No Dbd instances found within the specified time frame.');
    return;
end


% Add the Dbd instances to the DbdGroup instance
for x = 1:length(r)
    
    dgroup.addDbd(obj.dbds(r(x)));
    
end

