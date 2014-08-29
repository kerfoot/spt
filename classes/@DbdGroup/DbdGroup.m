classdef DbdGroup < handle
    %
    % obj = DbdGroup(dbd_files, varargin)
    %
    % Creates and instance of the DbdGroup class which organizes Dbd
    % instances.  An instance of the Dbd class is created for each file in
    % dbd_files and stored in the DbdGroup instance.
    %
    % By default, all sensors in the data file are stored in the instance, 
    % with the exception of sensors beginning with 'gld_dup_', as these are 
    % duplicate sensors added to the file during the binary to ascii merge 
    % process.
    %
    % All valid timestamp and depth sensors are always included in the
    % instance, regardless of whether an optional sensor list is specified via
    % the 'sensors' options.
    %
    % Options: default behavior may be modified using the following name/value
    % options:
    %   'dupsensors': true or false (false by default).  Set to true to
    %       include all sensors (even duplicates) in the instance.
    %   'sensors': cell array of sensor names to include in the instance.
    %       Non-existent sensors are ignored.
    %
    % Instance Properties:
    %   'segments'
    %   'sourceFiles'
    %   'bytes'
    %   'rows'
    %   'timestampSensors'
    %   'depthSensors'
    %   'startTimes'
    %   'endTimes'
    %   'sensors'
    %   'sensorUnits'
    %   'numProfiles'
    %   'dbds'
    %   'hasBoundingGps'
    %   'newSegments'
    %   'classVersion'
    %
    % Instance Methods:
    %   'addDbd'
    %   'addSensor'
    %   'deleteSensor'
    %   'plotTrack'
    %   'toArray'
    %   'toProfiles'
    %   'toStruct'
    %
    % See also Dbd
    % ============================================================================
    % $RCSfile: DbdGroup.m,v $
    % $Source: /home/kerfoot/cvsroot/slocum/matlab/spt/classes/@DbdGroup/DbdGroup.m,v $
    % $Revision: 1.4 $
    % $Date: 2013/12/06 21:09:04 $
    % $Author: kerfoot $
    % ============================================================================
    %
    
    % Properties are displayed as they are listed here, which is why there are
    % multiple property definitions with the same Access rights.
    properties (Dependent = true, SetAccess = private)
        segments = {};
        sourceFiles = {};
        bytes = [];
        rows = []; 
    end
    
    properties (Dependent = true)
        timestampSensors = {};
        depthSensors = {};
    end
    
    properties (Dependent = true, SetAccess = private)
        startTimes = {};
        endTimes = {};
        startDatenums = [];   
        endDatenums = [];
        sensors = {};
    end
        
    properties (GetAccess = public, SetAccess = private)
        sensorUnits = struct([]);
    end
    
    properties(Dependent = true, SetAccess = private)
        numProfiles = [];
    end
    
    properties (GetAccess = public, SetAccess = private)
        dbds = Dbd.empty(); %Emtpy array of Dbd instances
    end
    
    properties(Dependent = true, SetAccess = private)
        hasBoundingGps = [];
    end
    
    properties(SetAccess = public)
        newSegments = {};
        scratch = [];
    end
    
    % Constructor
    methods
        
        function obj = DbdGroup(sourceFiles, varargin)
            if isequal(nargin,0)
                return;
            end

            if ischar(sourceFiles)
                sourceFiles = {sourceFiles};
            elseif ~iscellstr(sourceFiles)
                error('DbdGroup:invalidArgument',...
                    'sourceFiles must be a string or cell array of strings.');
            end
            
            
            numDbds = length(sourceFiles);
            % Intialize an empty array of Dbd objects equal to the number of
            % source files
            obj.dbds = Dbd.empty();
            
            % Matlab requires us to fill in empty object arrays from bottom to
            % top.  We'll sort them later
            for f = 1:numDbds;
                try
                    dbd = Dbd(sourceFiles{f}, varargin{:});
                    if isequal(length(dbd.sensors),0)
                        continue;
                    end
                    % Add the Dbd instance
                    obj.addDbd(dbd);
                catch ME
                    fprintf(2,...
                        '%s: %s\n',...
                        ME.identifier,...
                        ME.message);
                end
               
            end
            
        end
        
    end
    
    % Get/Set methods
    methods
        
        % obj.segments
        function value = get.segments(obj)
            value = {};
            if isempty(obj.dbds)
                return;
            end
            value = {obj.dbds.segment}';
        end
        
        % obj.sourceFiles
        function value = get.sourceFiles(obj)
            value = {};
            if isempty(obj.dbds)
                return;
            end
            value = {obj.dbds.sourceFile}';
        end
        
        % obj.bytes
        function value = get.bytes(obj)
            value = [];
            if isempty(obj.dbds)
                return;
            end
            value = cat(1, obj.dbds.bytes);
        end
        
        % obj.rows
        function value = get.rows(obj)
            value = [];
            if isempty(obj.dbds)
                return;
            end
            value = cat(1, obj.dbds.rows);
        end
        
        % obj.timestampSensors
        function value = get.timestampSensors(obj)
            value = {};
            if isempty(obj.dbds)
                return;
            end
            value = {obj.dbds.timestampSensor}';
        end
        
        % obj.depthSensors
        function value = get.depthSensors(obj)
            value = {};
            if isempty(obj.dbds)
                return;
            end
            value = {obj.dbds.depthSensor}';
        end
        
        % obj.startTimes
        function value = get.startTimes(obj)
            value = {};
            if isempty(obj.dbds)
                return;
            end
            value = {obj.dbds.startTime}';
        end
        
        % obj.endTimes
        function value = get.endTimes(obj)
            value = {};
            if isempty(obj.dbds)
                return;
            end
            value = {obj.dbds.endTime}';
        end
        
        % obj.startDatenums
        function value = get.startDatenums(obj)
            value = [];
            if isempty(obj.dbds)
                return;
            end
            value = cat(1, obj.dbds.startDatenum);
        end
        
        % obj.endDatenums
        function value = get.endDatenums(obj)
            value = [];
            if isempty(obj.dbds)
                return;
            end
            value = cat(1, obj.dbds.endDatenum);
        end
        
        % obj.sensors
        function value = get.sensors(obj)
            value = {};
            if isempty(obj.dbds)
                return;
            end
            dbdGroup = [obj.dbds];
            value = unique(cat(1, dbdGroup.sensors));
        end
        
        % obj.numProfiles
        function value = get.numProfiles(obj)
            value = [];
            if isempty(obj.dbds)
                return;
            end
            value = cat(1, obj.dbds.numProfiles);
        end
        
        % obj.hasBoundingGps
        function value = get.hasBoundingGps(obj)
            value = [];
            if isempty(obj.dbds)
                return;
            end
            value = cat(1, obj.dbds.hasBoundingGps);
        end
             
        % obj.timestampSensors
        function set.timestampSensors(obj, sensors)
            if ischar(sensors)
                [tSensors{1:length(obj.dbds)}] = deal(sensors);
            elseif ~iscellstr(sensors)
                fprintf(1,...
                    'DbdGroup.timestampSensors: sensors must be a string or cell array of strings.\n');
                return;
            elseif ~isequal(length(sensors), length(obj.dbds))
                fprintf(1,...
                    'DbdGroup.timestampSensors: Cell array must have the same number of elements as Dbd instances.\n');
                return;
            else
                tSensors = sensors;
            end
            % Change each dbd.timestampSensor
            for x = 1:length(obj.dbds)
                obj.dbds(x).timestampSensor = tSensors{x};
            end
        end
        
        % obj.depthSensors
        function set.depthSensors(obj, sensors)
            if ischar(sensors)
                [zSensors{1:length(obj.dbds)}] = deal(sensors);
            elseif ~iscellstr(sensors)
                fprintf(1,...
                    'DbdGroup.depthSensors: sensors must be a string or cell array of strings.\n');
                return;
            elseif ~isequal(length(sensors), length(obj.dbds))
                fprintf(1,...
                    'DbdGroup.depthSensors: Cell array must have the same number of elements as Dbd instances.\n');
                return;
            else
                zSensors = sensors;
            end
            % Change each dbd.timestampSensor
            for x = 1:length(obj.dbds)
                obj.dbds(x).depthSensor = zSensors{x};
            end
        end

    end
end
