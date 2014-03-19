function [sensor_map, NC_TEMPLATE] = getTrajectorySensorMappings(NC_TEMPLATE)
%
% sensor_map = getTrajectorySensorMappings([NC_TEMPLATE])
%
% Returns a structured array mapping the IOOS Trajectory NetCDF variable
% names to native slocum glider sensor names.  If not specified, the 
% default NetCDF template is taken from the GTrajectory.schemaNcTemplate 
% property.  The standard NetCDF template can be found here:
%
% https://github.com/IOOSProfilingGliders/Real-Time-File-Format/tree/master/template
%
% NetCDF variable data is mapped to native Slocum glider sensors in
% getTrajectorySensorMappings.m, which is called by 
% selectDbdTrajectoryData.m.  Currently, you must add sensors to
% getTrajectorySensorMappings.m directly to change the default sensor
% mappings.
%
% See also selectDbdTrajectoryData GTrajectoryNc 
% ============================================================================
% $RCSfile: getTrajectorySensorMappings.m,v $
% $Source: /home/kerfoot/cvsroot/slocum/matlab/spt/export/nc/IOOS/trajectory/bin/getTrajectorySensorMappings.m,v $
% $Revision: 1.2 $
% $Date: 2014/03/19 20:08:10 $
% $Author: kerfoot $
% ============================================================================
%

app = mfilename;
sensor_map = [];

if isequal(nargin,0)
    NC_TEMPLATE = GTrajectoryNc().schemaNcTemplate;
    fprintf(1,...
        '%s: Using default NetCDF template: %s\n',...
        app,...
        NC_TEMPLATE);
end

if ~exist(NC_TEMPLATE, 'file')
    fprintf(2, '%s: Cannot locate the NetCDF template file: %s',...
        app,...
        NC_TEMPLATE);
end

% Read in the schema and use it to initialize the sensor mapping data
% structure
try
    nc_schema = ncinfo(NC_TEMPLATE);
catch ME
    fprintf(2,...
        '%s: %s\n',...
        ME.identifier,...
        ME.message);
    return;
end

nc_vars = {nc_schema.Variables.Name}';
for x = 1:length(nc_vars)
    sensor_map.(nc_vars{x}) = [];
end

% Add defaults sensor mappings
sensor_map.profile_id = {'drv_proInds',...
    }';

sensor_map.pressure = {'drv_sci_water_pressure',...
    'drv_m_water_pressure',...
    'drv_m_pressure',...
    }';

sensor_map.depth = {'drv_depth',...
    }';

sensor_map.lat = {'drv_m_gps_lat',...
    'drv_latitude',...
    }';

sensor_map.lon = {'drv_m_gps_lon',...
    'drv_longitude',...
    }';

sensor_map.conductivity = {'drv_sea_water_electrical_conductivity',...
    'drv_sci_water_cond',...
    'drv_m_water_cond',...
    }';

sensor_map.density = {'drv_sea_water_density',...
    }';

sensor_map.salinity = {'drv_sea_water_salinity',...
    }';

sensor_map.temperature = {'drv_sea_water_temperature',...
    'sci_water_temp',...
    'm_water_temp',...
    }';

sensor_map.u = {'drv_u',...
    }';

sensor_map.v = {'drv_v',...
    }';

    