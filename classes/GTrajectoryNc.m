classdef GTrajectoryNc < handle
    
    properties (Dependent = true, SetAccess = private)
        Variables = {};
        CoordinateVariables = {};
    end
        
    properties(Access = private)
        templateSchema = [];
        exportSchema = [];
        varData = [];
        dimensionVars = {};
        schemaNcTemplate = 'glider_trajectory_uv_template_v.0.0.nc';
        className = mfilename;
    end
    
    methods
        function obj = GTrajectoryNc(varargin)
            %
            % obj = GTrajectoryNc([nc_file])
            %
            % Create and instance of the GTrajectoryNc class using the schema
            % contained in the default NetCDF template file or specified
            % via an optional existing NetCDF file.
            
            % Argument validation
            if isequal(nargin,0)
                % Default NetCDF template file
                NC_TEMPLATE = obj.schemaNcTemplate;
            else
                % User-specified NetCDF file
                if isempty(varargin{1}) || ~ischar(varargin{1})
                    error(sprintf('%s:invalidArg', obj.className),...
                        'Value for template must be a non-empty string specifying the location of a valid .nc template file.');
                end
                NC_TEMPLATE = varargin{1};
            end
            
            % Make sure the file exists
            if ~exist(NC_TEMPLATE, 'file')
                error(sprintf('%s:fileNotFound', obj.className),...
                    'Cannot locate NetCDF template: %s',...
                    NC_TEMPLATE);
            end

            % Try to import the schema from the template file
            try
                % Non-mutable schema read directly from the NetCDF template
                % files
                obj.templateSchema = ncinfo(NC_TEMPLATE);
                
                % Copy the template NetCDF schema to obj.exportSchema,
                % which will be the NetCDF schema used for writing the
                % NetCDF file.  All subsequent modifications (ie:
                % variables, attributes, etc.) will be checked agains
                % obj.templateSchema and then added to obj.exportSchema
                % after being validated.
                obj.exportSchema = obj.templateSchema;
            catch ME
                error(ME);
            end

            % Store the names of the dimension variables
            obj.dimensionVars = {obj.exportSchema.Dimensions.Name}';
            
            % Intialize the private obj.varData to a structured array
            % mapping obj.Variables to empty arrays
            vars = obj.Variables();
            for v = 1:length(vars)
                obj.varData.(vars{v}) = [];
            end
            
        end
    end
    
    % Get methods
    methods        
        % get.Variables(obj): retrieve the variables contained in the NetCDF 
        % schema structure
        function value = get.Variables(obj)
            value = {obj.exportSchema.Variables.Name}';
        end
        
        function value = get.CoordinateVariables(obj)
            value = obj.dimensionVars;
        end
        
        function atts = getVariableAttributes(obj, var_name)
            %
            % atts = getVariableAttributes(var_name)
            %
            % Retrieve the variable attributes for the specified var_name, if 
            % the variable exists.  The return value is a structured array
            % with Name and Value fields.
            
            % Initialize return value
            atts = [];
            
            % Return if the variable name is invalid
            v_index = obj.isVariable(var_name);
            if isequal(v_index,0)
                return;
            end
            
            % Select the variable attributes
            atts = obj.exportSchema.Variables(v_index).Attributes;
        end
        
        function atts = getGlobalAttributes(obj)
            %
            % atts = getGlobalAttributes()
            %
            % Retrieve the global file attributes.  The return value is a
            % structured array with Name and Value fields.
            
            atts = obj.exportSchema.Attributes;
        end
        
        function schema = getVariableSchema(obj, var_name)
            %
            % s = getVariableSchema(var_name)
            %
            % Retrieve the variable schema for the specified var_name, if the
            % variable exists.
            
            % Initialize return value
            schema = [];
            
            % Return if the variable name is invalid
            v_index = obj.isVariable(var_name);
            if isequal(v_index,0)
                return;
            end
            
            % Select the variable schema
            schema = obj.exportSchema.Variables(v_index);
            
        end
        
        function data = getVariableData(obj, var_name)
            %
            % data = getVariableData(var_name)
            %
            % Retrieve the data array for the specified var_name
            
            % Select the index of the specified variable schema
            v_index = obj.isVariable(var_name);
            % Return if the variable name is invalid
            if isequal(v_index,0)
                return;
            end
            
            % Fetch the data
            data = obj.varData.(var_name);
            
        end
        
        function dims = getVariableDims(obj, var_name)
            %
            % dims = obj.getVariableDims(var_name)
            %
            % Returns an array containing the dimensions of the specified
            % variable.  If the specified variable is dimensionless, NaN is
            % returned.
            
            dims = NaN;
            
            % Select the index of the specified variable schema
            v_index = obj.isVariable(var_name);
            % Return if the variable name is invalid
            if isequal(v_index,0)
                return;
            end
            
            % Special case of dimensionless variable 
            if isempty(obj.exportSchema.Variables(v_index).Dimensions)
                return;
            end
            
            % Get the list of variable dimensions
            var_coords = {obj.exportSchema.Variables(v_index).Dimensions.Name}';
            
            % Initialize the dimension array
            dims = zeros(1, length(var_coords));
            
            % Store the coordinate variable dimensions for the specified
            % variable
            for d = 1:length(var_coords)
                dims(d) = size(obj.varData.(var_coords{d}),d);
            end
            
        end
        
        function data = getAllVariableData(obj)
            %
            % struct = getAllVariableData()
            %
            % Returns a structured array mapping variable names to the
            % corresponding variable data array.
            
            data = obj.varData;
        end
        
    end
    
    % Set methods
    methods
        function deleteVariable(obj, var_name)
            %
            % nc.deleteVariable(var_name)
            %
            % Delete the variable schema describing the var_name variable
            % from the NetCDF schema.  No action is taken if var_name is
            % not the name of a valid variable in the schema.
            
            % Attempt to retrieve the variable schema
            s = obj.getVariableSchema(var_name);
            % Return if the variable name is invalid
            if isempty(s)
                return;
            end
            
            % Prevent deletion of dimension variables (obj.dimensionVars)
            if ismember(s.Name, obj.dimensionVars)
                error(sprintf('%s:InvalidOperation', obj.className),...
                    'Variable (%s) is a dimension and cannot be deleted',...
                    s.Name);
            end
            
            % Select the index of the specified variable schema
            v_index = obj.isVariable(s.Name);
            % Return if the variable name is invalid
            if isequal(v_index,0)
                return;
            end
            
            % Remove the element from the obj.exportSchema.Variables data
            % structure
            obj.exportSchema.Variables(v_index) = [];
            % Remove the variable data if it exists
            obj.varData = rmfield(obj.varData, var_name);
            
        end
        
% % % % %         function addVariable(obj, schema)
% % % % %         end
        
        function addVariableData(obj, var_name, data)
            %
            % obj.addVariableData(var_name, data)
            %
            % Add the array specified in the data argument to the NetCDF
            % file schema under the specified var_name.  Coordinate
            % variable dimensions are verified before adding the data.  The
            % data array is not added if the dimensions are not identical.
            %
            % Data must be added to any unlimited dimension/coordinate
            % variable before adding variable data that contains that
            % dimension.  The dimensions of the data array must correspond
            % to the variables dimension variables except for unlimited
            % dimensions.
            
            % Attempt to retrieve the variable schema
            s = obj.getVariableSchema(var_name);
            % Return if the variable name is invalid
            if isempty(s)
                return;
            end
            
            % Is the variable a coordinate variable?
            [is_dim, v_index] = ismember(s.Name, obj.dimensionVars);
            
            % For each dimension contained in the variable schema
            % (s.Dimensions): FACTOR OUT INTO private
            % obj.validateVarDimensions
            %   1. Check to make sure that the Dimension variable already has 
            %       data (obj.varData).  If not, error.
            %   2. If the Dimension variable has data, compare the size to
            %       that of the function 'data' argument.  Throw an error
            %       if they are not the same size
            var_dimensions = obj.getVariableDims(var_name);
            data_dims = size(data);
            
            % Special case of a row vector: if the number of var_dimensions
            % is equal to 1, convert data to a row vector and remove the
            % second element (the number of columns, which is equal to 1)
            % from var_dimensions
            if isequal(length(var_dimensions),1)
                data = data(:);
                data_dims = length(data);
            end

            % Special case: adding data to a coordinate variable.
            % Coordinate variables must be a 1-D array
            if is_dim
                % Special case of coordinate variable, which cannot
                % have more than 1 dimension

                % Rearrange the data array into a row vector
                data = data(:);
                
                % Number of elements in the data array
                r = length(data);
                
                % Prevent resizing non unlimited coordinate variables if
                % data does not have the same number of elements as the
                % coordinate variable schema
                % (obj.exportSchema.Dimensions(v_index).Length)
                if ~obj.exportSchema.Dimensions(v_index).Unlimited &&...
                        ~isequal(obj.exportSchema.Dimensions(v_index).Length, r)
                    error(sprintf('%s:fixedSizeDimensionVariable', obj.className),...
                        '%s is a fixed size coordinate variable, as specified in the NetCDF template, and cannot be resized',...
                        var_name);
                end
                
                % Store the dimensions for comparison to data_dims
                var_dimensions(1) = r;

            else % Data variable case
                
                if any(isequal(var_dimensions,0))
                    error(sprintf('%s:emptyDimension', obj.className),...
                        '%s: One or more coordinates for this variable are empty',...
                        var_name,...
                        s.Dimensions(v_index).Name);
                end

            end
            
            % Compare the size of the data array to that of the dimensions
            if ~isequal(var_dimensions, data_dims)
                error(sprintf('%s:dimensionSizes', obj.className),...
                    'The %s data array does not match the size of one or more coordinate variables',...
                    var_name);
            end
            
            % Add the data as long as the dimensions match up
            obj.varData.(var_name) = data;
            
        end
        
        function setVariableAttribute(obj, var_name, attribute_name, attribute_value)
            %
            % obj.setVariableAttribute(var_name, attribute_name, attribute_value)
            %
            % Add a new attribute or replace the value of an existing 
            % for the specified variable, which must exist.
            
            % Validate the args
            if ~isequal(nargin,4)
                error(sprintf('%s:invalidArgument', obj.className),...
                    '2 arguments are required');
            elseif ~ischar(var_name)
                error(sprintf('%s:invalidArgument', obj.className),...
                    'Variable must be a string');
            elseif ~ischar(attribute_name)
                error(sprintf('%s:invalidArgument', obj.className),...
                    'Attribute name must be a string');
            end
            
            % Make sure the variable exists in the file schema
            v_index = obj.isVariable(var_name);
            if isequal(v_index,0)
                return;
            end
            
            % Get the variable attributes
            atts = obj.getVariableAttributes(var_name);
            % Create the list of attribute names
            att_names = {atts.Name}';
            % Search the list to see if attribute is already present.  If
            % it is, replace it.  If it's not, add it
            [TF,LOC] = ismember(attribute_name, att_names);
            if TF
                obj.exportSchema.Variables(v_index).Attributes(LOC).Value =...
                    attribute_value;
            else
                obj.exportSchema.Variables(v_index).Attributes(end+1).Name =...
                    attribute_name;
                obj.exportSchema.Variables(v_index).Attributes(end).Value =...
                    attribute_value;
            end
            
            % Sort the attributes in alphabetical order
            % Get the global attributes structured array
            atts = obj.getVariableAttributes(var_name);
            % Create the list of attribute names
            att_names = {atts.Name}';
            % Get the sort order
            [~,I] = sort(att_names);
            % Reorder the elements of the Attributes structured array
            obj.exportSchema.Variables(v_index).Attributes =...
                obj.exportSchema.Variables(v_index).Attributes(I);
        end
        
        function setGlobalAttribute(obj, attribute_name, attribute_value)
            %
            % obj.setGlobalAttribute(attribute_name, attribute_value)
            %
            % Add a new global file attribute or replace the value of an 
            % existing global file attribute.
            
            % Validate the args
            if ~isequal(nargin,3)
                error(sprintf('%s:invalidArgument', obj.className),...
                    '2 arguments are required');
            elseif ~ischar(attribute_name)
                error(sprintf('%s:invalidArgument', obj.className),...
                    'Attribute name must be a string');
            end
            
            % Get the global attributes structured array
            atts = obj.getGlobalAttributes();
            % Create the list of attribute names
            att_names = {atts.Name}';
            % Search the list to see if attribute is already present.  If
            % it is, replace it.  If it's not, add it
            [TF,LOC] = ismember(attribute_name, att_names);
            if TF
                obj.exportSchema.Attributes(LOC).Value = attribute_value;
            else
                obj.exportSchema.Attributes(end+1).Name = attribute_name;
                obj.exportSchema.Attributes(end).Value = attribute_value;
            end
            
            % Sort the attributes in alphabetical order
            % Get the global attributes structured array
            atts = obj.getGlobalAttributes();
            % Create the list of attribute names
            att_names = {atts.Name}';
            % Get the sort order
            [~,I] = sort(att_names);
            % Reorder the elements of the Attributes structured array
            obj.exportSchema.Attributes = obj.exportSchema.Attributes(I);
        end
        
    end
    
    % Export methods
    methods
        function schema = dumpSchema(obj)
            schema = obj.exportSchema;
        end
        
        function success = toNc(obj, nc_filename)
            
            % Argument validation
            if ~isequal(nargin,2)
                error(sprintf('%s:nargin', obj.className),...
                    'No output filename specified');
            elseif isempty(nc_filename) || ~ischar(nc_filename)
                error(sprintf('%s:invalidArgument', obj.className),...
                    'Output filename must be a non-empty string');
            elseif exist(nc_filename, 'file')
                error(sprintf('%s:fileExists', obj.className),...
                    'Cannot clobber existing file: %s',...
                    nc_filename);
            end
            
            % Intialize return value
            success = false;
            
            try
                % Create the file using the NetCDF schema
                % (obj.exportSchema)
                fprintf(1,...
                    'Creating NetCDF file...');
                ncwriteschema(nc_filename, obj.exportSchema);
                fprintf(1,...
                    'Created.\n');
            catch ME
                fprintf(1,...
                    'Failed.\n');
                error(ME.identifier, ME.message);
            end
            
% % % % %             fprintf(1,...
% % % % %                 'Writing variable data to file...\n');
            
            % Loop through the schema variables (obj.Variables) and write
            % variable data (obj.varData) as long as the array is not empty
            vars = obj.Variables;
            
            for v = 1:length(vars)
                
                % No data written if the variable is a container
                % (dimensionless) variable
                if isempty(obj.exportSchema.Variables(v).Dimensions)
                    continue;
                end
                
                % If the variable does not have data associated with it,
                % assume all fill values (NaN) shaped to the coordinate
                % variable dimensions
                if isempty(obj.varData.(vars{v}))
                    fprintf(1,...
                        '%s: Variable contains no data.  Using _FillValue.\n',...
                        vars{v});
                    var_dims = obj.getVariableDims(vars{v});
                    if isequal(length(var_dims),1)
                        var_dims(2) = 1;
                    end
                    var_data = nan(var_dims);
                else
                    var_data = obj.varData.(vars{v});
                end
                
% % % % %                 if isempty(obj.varData.(vars{v}))
% % % % %                     fprintf(2,...
% % % % %                         '%s: Variable contains no data.\n',...
% % % % %                         vars{v});
% % % % %                     continue;
% % % % %                 end
                
                fprintf(1,...
                    'Writing %s data...',...
                    vars{v});
                try
                    ncwrite(nc_filename, vars{v}, var_data);
                    fprintf(1,...
                        'Written.\n');
                catch ME
                    fprintf(2,...
                        'Failed.\n');
                    % Delete the incomplete file
                    delete(nc_filename);
                    error(ME.identifier, ME.message);
                end
            end
            
            success = true;
            
        end
    end
    
    methods (Access = private)
        
        % LOC = isVariable(obj, var_name)
        function LOC = isVariable(obj, var_name)
            % Get the list of variables contained in the schema
            nc_vars = obj.Variables();
            
            % Search for the specified variable name
            [TF,LOC] = ismember(var_name, nc_vars);
            if ~any(TF)
                warning(sprintf('%s:VariableNotFound', obj.className),...
                    'Schema does not contain variable: %s', var_name);
            end
        end
        
    end
    
% % % % %     methods (Static)
% % % % %         function schema = createVariableSchema()
% % % % %             schema = struct('Name', [],...
% % % % %                 'Dimensions', [],...
% % % % %                 'Datatype', [],...
% % % % %                 'Attributes', [],...
% % % % %                 'ChunkSize', [],...
% % % % %                 'FillValue', [],...
% % % % %                 'DeflateLevel', [],...
% % % % %                 'Shuffle', []);
% % % % %         end
% % % % %     end
    
end
