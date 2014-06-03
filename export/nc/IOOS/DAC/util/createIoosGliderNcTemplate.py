# This template is used to generate an empty (no data values) .nc file.  The
# .nc file may then be dumped to .cdl and .ncml.  A generic filename is used
# for the destination file.  Files containing actual glider data should follow
# the file naming conventions at:
# https://github.com/IOOSProfilingGliders/Real-Time-File-Format/wiki/Real-Time-File-Description#file-naming-convention
#
# Script to create example glider trajectory file.
# DIMENSIONS (SIZE):
#   time: (unlim)
#   trajectory: (traj_strlen)
# REQUIRED Variables
#   trajectory(traj_strlen): char
#   time(time): double
#   lat(time): double
#   lon(time): double
#   pressure(time): double
#   depth(time): double
#   temperature(time): double
#   conductivity(time): double
#   salinity(time): double
#   density(time): double
#   profile_id(): 16-bit int
#   profile_time(): 16-bit int
#   profile_lat(): 16-bit int
#   profile_lon(): 16-bit int
#   time_uv(): double
#   lat_uv(): double
#   lon_uv(): double
#   u(): double
#   v(): double
#
#   depth_qc(time): byte
#   lat_qc(time): byte
#   lon_qc(time): byte
#   pressure_qc(time): byte
#   conductivity_qc(time): byte
#   salinity_qc(time): byte
#   temperature_qc(time): byte
#   u_qc(time_uv): byte
#   v_qc(time_uv): byte
#   platform(nodim)
#   instrument_ctd(nodim)

import numpy as np
from datetime import datetime, timedelta
from netCDF4 import default_fillvals as NC_FILL_VALUES
from netCDF4 import num2date, date2num
from netCDF4 import Dataset
import time as t
import os

# list of variables we don't want to create qc flags for
NO_QC_VARS = ['time',
    'trajectory',
    'profile_id']

# NetCDF4 compression level (1 seems to be optimal, in terms of effort and
# result)
COMP_LEVEL = 1

# Name of output file
NC_FILE = 'IOOS_Glider_NetCDF_Flat_v1.0.nc';
if os.path.exists(NC_FILE):
    os.remove(NC_FILE)
nc = Dataset(NC_FILE,
    'w',
    format='NETCDF4_CLASSIC')

# Dimensions
TRAJECTORY_STRING = 'glider-YYYYmmddTHHMM'
time= nc.createDimension('time', None)
trajectory = nc.createDimension('traj_strlen', len(TRAJECTORY_STRING))

# Global file attributes
global_attributes = {
    'Metadata_Conventions' : 'CF-1.6, Unidata Dataset Discovery v1.0',
    'Conventions' : 'CF-1.6, Unidata Dataset Discovery v1.0',
    'acknowledgment' : 'This deployment supported by ...',
    'comment' : ' ',
    'contributor_name' : ' ', # Comma-separated list of names
    'contributor_role' : ' ', # Comma-separated list of contributor_name roles
    'creator_email' : ' ',
    'creator_name' : ' ',
    'creator_url' : ' ',
    'date_created' : ' ', # YYYY-mm-ddTHH:MM:SSZ
    'date_issued' : ' ', # YYYY-mm-ddTHH:MM:SSZ
    'date_modified' : ' ', # YYYY-mm-ddTHH:MM:SSZ
    'format_version' : NC_FILE,
    'history' : ' ',
    'id' : ' ',
    'institution' : ' ',
    'keywords' : 'AUVS > Autonomous Underwater Vehicles, Oceans > Ocean Pressure > Water Pressure, Oceans > Ocean Temperature > Water Temperature, Oceans > Salinity/Density > Conductivity, Oceans > Salinity/Density > Density, Oceans > Salinity/Density > Salinity',
    'keywords_vocabulary' : 'GCMD Science Keywords',
    'license' : 'This data may be redistributed and used without restriction.  Data provided as is with no expressed or implied assurance of quality assurance or quality control',
    'metadata_link' : ' ',
    'naming_authority' : 'edu.rutgers.marine',
    'platform_type' : 'Slocum Glider',
    'processing_level' : ' ',
    'project' : ' ',
    'publisher_email' : ' ',
    'publisher_name' : ' ',
    'publisher_url' : ' ',
    'references' : ' ',
    'sea_name' : ' ', # http://www.nodc.noaa.gov/General/NODC-Archive/seanamelist.txt
    'source' : 'Observational data from a profiling glider', 
    'standard_name_vocabulary' : 'CF-v25',
    'summary' : "The Rutgers University Coastal Ocean Observation Lab has deployed autonomous underwater gliders around the world since 1990.  Gliders are small, free-swimming, unmanned vehicles that use changes in buoyancy to move vertically and horizontally through the water column in a saw-tooth pattern. They are deployed for days to several months and gather detailed information about the physical, chemical and biological processes of the world's The Slocum glider was designed and oceans. built by Teledyne Webb Research Corporation, Falmouth, MA, USA.  This dataset contains observational sub-surface profile data of the water-column.",
    'title' : ' ', # glider-YYYYmmddTHHMM'
    }
# Add GLOBAL attributes
for k in sorted(global_attributes.keys()):
    nc.setncattr(k, global_attributes[k])

# QC_FLAGS Definitions
QC_FLAG_MEANINGS = "no_qc_performed good_data probably_good_data bad_data_that_are_potentially_correctable bad_data value_changed not_used not_used interpolated_value missing_value";
# Create array of unsigned 8-bit integers to use for _qc flag values
QC_FLAGS = np.arange(0,len(QC_FLAG_MEANINGS.split()), dtype=np.byte);

# Variable Definitions
# ----------------------------------------------------------------------------
# TIME
# time: no _Fill_Value since dimension
time = nc.createVariable('time',
    'f8',
    ('time',),
    zlib=True,
    complevel=COMP_LEVEL,
    fill_value=-999.)
# Dictionary of variable attributes.  Use a dictionary so that we can add the
# attributes in alphabetical order (not necessary, but makes it easier to find
# attributes that are in alphabetical order)
atts = {'ancillary_variables' : ' ',
    'calendar' : 'gregorian',
    'units' : 'seconds since 1970-01-01T00:00:00Z',
    'standard_name' : 'time',
    'long_name' : 'Time',
    'observation_type' : 'measured',
    }
for k in sorted(atts.keys()):
    time.setncattr(k, atts[k])

# trajectory
trajectory = nc.createVariable('trajectory',
    'S1',
    ('traj_strlen',))
# Dictionary of variable attributes.  Use a dictionary so that we can add the
# attributes in alphabetical order (not necessary, but makes it easier to find
# attributes that are in alphabetical order)
atts = {'cf_role' : 'trajectory_id',
    'long_name' : 'Trajectory Name',
    'comment' : 'A trajectory is a single glider deployment',
    'units' : '1',
    }
for k in sorted(atts.keys()):
    trajectory.setncattr(k, atts[k])

# Latitude
lat = nc.createVariable('lat',
    'f8',
    ('time',),
    zlib=True,
    complevel=COMP_LEVEL,
    fill_value=-999.)
# Variable attributes
atts = { 'units' : 'degrees_north',
    'standard_name' : 'latitude',
    'long_name' : 'Latitude',
    'valid_min' : -90.,
    'valid_max' : 90.,
    'observation_type' : 'measured',
    'ancillary_variables' : 'lat_qc',
    'platform' : 'platform',
    'comment' : 'Values are interpolated between measured GPS fixes',
    'reference' : 'WGS84', 
    'coordinate_reference_frame' : 'urn:ogc:crs:EPSG::4326', # GROOM manual, p16
    }
for k in sorted(atts.keys()):
    lat.setncattr(k, atts[k])

# Longitude
lon = nc.createVariable('lon',
    'f8',
    ('time',),
    zlib=True,
    complevel=COMP_LEVEL,
    fill_value=-999.)
# Dictionary of variable attributes.  Use a dictionary so that we can add the
# attributes in alphabetical order (not necessary, but makes it easier to find
# attributes that are in alphabetical order)
atts = {'units' : 'degrees_east',
    'standard_name' : 'longitude',
    'long_name' : 'Longitude',
    'valid_min' : -180.,
    'valid_max' : 180.,
    'observation_type' : 'measured',
    'ancillary_variables' : 'lon_qc',
    'platform' : 'platform',
    'comment' : 'Values are interpolated between measured GPS fixes',
    'reference' : 'WGS84', # GROOM manual, p16
    'coordinate_reference_frame' : 'urn:ogc:crs:EPSG::4326', # GROOM manual, p16
    }
for k in sorted(atts.keys()):
    lon.setncattr(k, atts[k])

# Pressure
pressure = nc.createVariable('pressure',
    'f8',
    ('time',),
    zlib=True,
    complevel=COMP_LEVEL,
    fill_value=-999.)
# Variable attributes
atts = {'units' : 'dbar',
    'standard_name' : 'sea_water_pressure',
    'valid_min' : 0,
    'valid_max' : 2000,
    'long_name' : 'Pressure',
    'reference_datum' : 'sea-surface',
    'positive' : 'down',
    'observation_type' : 'measured',
    'ancillary_variables' : 'pressure_qc',
    'platform' : 'platform',
    'instrument' : 'instrument_ctd',
    'accuracy' : ' ',
    'precision' : ' ',
    'resolution' : ' ',
    'comment' : ' ',
    }
for k in sorted(atts.keys()):
    pressure.setncattr(k, atts[k])

# Depth
depth = nc.createVariable('depth',
    'f8',
    ('time',),
    zlib=True,
    complevel=COMP_LEVEL,
    fill_value=-999.)
# Variable attributes
atts = {'units' : 'm',
    'standard_name' : 'depth',
    'valid_min' : 0,
    'valid_max' : 2000,
    'long_name' : 'Depth',
    'reference_datum' : 'sea-surface',
    'positive' : 'down',
    'observation_type' : 'calculated',
    'ancillary_variables' : 'depth_qc',
    'platform' : 'platform',
    'instrument' : 'instrument_ctd',
    'accuracy' : ' ',
    'precision' : ' ',
    'resolution' : ' ',
    'comment' : ' ',
    }
for k in sorted(atts.keys()):
    depth.setncattr(k, atts[k])

# Temperature
temperature = nc.createVariable('temperature',
    'f8',
    ('time',),
    zlib=True,
    complevel=COMP_LEVEL,
    fill_value=-999.)
# Variable attributes
atts = { 'units' : 'Celsius',
    'standard_name' : 'sea_water_temperature',
    'valid_min' : -5.,
    'valid_max' : 40.,
    'long_name' : 'Temperature',
    'observation_type' : 'measured',
    'ancillary_variables' : 'temperature_qc',
    'platform' : 'platform',
    'instrument' : 'instrument_ctd',
    'accuracy' : ' ',
    'precision' : ' ',
    'resolution' : ' ',
    }
for k in sorted(atts.keys()):
    temperature.setncattr(k, atts[k])

# Conductivity
conductivity = nc.createVariable('conductivity',
    'f8',
    ('time',),
    zlib=True,
    complevel=COMP_LEVEL,
    fill_value=-999.)
# Variable attributes
atts = { 'units' : 'S m-1',
    'standard_name' : 'sea_water_electrical_conductivity',
    'valid_min' : 0.,
    'valid_max' : 10.,
    'long_name' : 'Conductivity',
    'observation_type' : 'measured',
    'ancillary_variables' : 'conductivity_qc',
    'platform' : 'platform',
    'instrument' : 'instrument_ctd',
    'accuracy' : ' ',
    'precision' : ' ',
    'resolution' : ' ',
    }
for k in sorted(atts.keys()):
    conductivity.setncattr(k, atts[k])

# Salinity
salinity = nc.createVariable('salinity',
    'f8',
    ('time',),
    zlib=True,
    complevel=COMP_LEVEL,
    fill_value=-999.)
# Variable attributes
atts = { 'units' : '1e-3',
    'standard_name' : 'sea_water_salinity',
    'valid_min' : 0.,
    'valid_max' : 40.,
    'long_name' : 'Salinity',
    'observation_type' : 'calculated',
    'ancillary_variables' : 'salinity_qc',
    'platform' : 'platform',
    'instrument' : 'instrument_ctd',
    'accuracy' : ' ',
    'precision' : ' ',
    'resolution' : ' ',
    }
for k in sorted(atts.keys()):
    salinity.setncattr(k, atts[k])

# Density
density = nc.createVariable('density',
    'f8',
    ('time',),
    zlib=True,
    complevel=COMP_LEVEL,
    fill_value=-999.)
# Variable attributes
atts = {'units' : 'kg m-3',
    'standard_name' : 'sea_water_density',
    'valid_min' : 1015.,
    'valid_max' : 1040.,
    'long_name' : 'Density',
    'observation_type' : 'calculated',
    'ancillary_variables' : 'density_qc',
    'platform' : 'platform',
    'instrument' : 'instrument_ctd',
    'accuracy' : ' ',
    'precision' : ' ',
    'resolution' : ' ',
    }
for k in sorted(atts.keys()):
    density.setncattr(k, atts[k])

# profile_id
profile_id = nc.createVariable('profile_id',
    'i4',
    zlib=True,
    complevel=COMP_LEVEL,
    fill_value=-999.)
# Variable attributes
atts = {'comment' : 'Sequential profile number within the trajectory',
    'long_name' : 'Profile ID',
    'valid_min' : 1,
    'valid_max' : NC_FILL_VALUES['i4'],
    }
for k in sorted(atts.keys()):
    profile_id.setncattr(k, atts[k])

# profile_time
profile_time = nc.createVariable('profile_time',
    'f8',
    zlib=True,
    complevel=COMP_LEVEL,
    fill_value=-999.)
# Variable attributes
atts = {'units' : 'seconds since 1970-01-01T00:00:00Z',
    'standard_name' : 'time',
    'long_name' : 'Profile Center Time',
    'observation_type' : 'calculated',
    'platform' : 'platform',
    'comment' : 'Value is the mean timestamp of the profile',
    }
for k in sorted(atts.keys()):
    profile_time.setncattr(k, atts[k])

# profile_lat
profile_lat = nc.createVariable('profile_lat',
    'f8',
    zlib=True,
    complevel=COMP_LEVEL,
    fill_value=-999.)
# Variable attributes
atts = {'units' : 'degrees_north',
    'standard_name' : 'latitude',
    'long_name' : 'Profile Center Latitude',
    'valid_min' : -90.,
    'valid_max' : 90.,
    'observation_type' : 'calculated',
    'platform' : 'platform',
    'comment' : 'Value is interpolated to provide the center latitude of the profile',
    }
for k in sorted(atts.keys()):
    profile_lat.setncattr(k, atts[k])

# profile_lon
profile_lon = nc.createVariable('profile_lon',
    'f8',
    zlib=True,
    complevel=COMP_LEVEL,
    fill_value=-999.)
# Variable attributes
atts = {'units' : 'degrees_east',
    'standard_name' : 'longitude',
    'long_name' : 'Profile Center Longitude',
    'valid_min' : -180.,
    'valid_max' : 180.,
    'observation_type' : 'calculated',
    'platform' : 'platform',
    'comment' : 'Values are interpolated to provide the center longitude of the profile',
    }
for k in sorted(atts.keys()):
    profile_lon.setncattr(k, atts[k])

# time_uv
time_uv = nc.createVariable('time_uv',
    'f8',
    zlib=True,
    complevel=COMP_LEVEL,
    fill_value=-999.)
# Variable attributes
atts = {'calendar' : 'gregorian',
    'units' : 'seconds since 1970-01-01T00:00:00Z',
    'standard_name' : 'time',
    'long_name' : 'Time',
    'observation_type' : 'calculated',
    'comment' : 'The depth-averaged current is an estimate of the net current measured while the glider is underwater over all profiles contained in the segment.  Values are interpolated to provide the center timestamp of the profile',
    }
for k in sorted(atts.keys()):
    time_uv.setncattr(k, atts[k])
# ----------------------------------------------------------------------------

# lat_uv
lat_uv = nc.createVariable('lat_uv',
    'f8',
    zlib=True,
    complevel=COMP_LEVEL,
    fill_value=-999.)
# Variable attributes
atts = {'units' : 'degrees_north',
    'standard_name' : 'latitude',
    'long_name' : 'Latitude',
    'valid_min' : -90.,
    'valid_max' : 90.,
    'observation_type' : 'calculated',
    'platform' : 'platform',
    'comment' : 'The depth-averaged current is an estimate of the net current measured while the glider is underwater over all profiles contained in the segment.  Values are interpolated to provide the center latitude of the profile.',
    }
for k in sorted(atts.keys()):
    lat_uv.setncattr(k, atts[k])

# lon_uv
lon_uv = nc.createVariable('lon_uv',
    'f8',
    zlib=True,
    complevel=COMP_LEVEL,
    fill_value=-999.)
# Variable attributes
atts = {'units' : 'degrees_east',
    'standard_name' : 'longitude',
    'long_name' : 'Longitude',
    'valid_min' : -180.,
    'valid_max' : 180.,
    'observation_type' : 'calculated',
    'platform' : 'platform',
    'comment' : 'The depth-averaged current is an estimate of the net current measured while the glider is underwater over all profiles contained in the segment.  Values are interpolated to provide the center longitude of the profile.',
    }
for k in sorted(atts.keys()):
    lon_uv.setncattr(k, atts[k])

# u
u = nc.createVariable('u',
    'f8',
    zlib=True,
    complevel=COMP_LEVEL,
    fill_value=-999.)
# Variable attributes
atts = {'units' : 'm s-1',
    'standard_name' : 'eastward_sea_water_velocity',
    'valid_min' : -10.,
    'valid_max' : 10.,
    'long_name' : 'Depth-Averaged Eastward Sea Water Velocity',
    'observation_type' : 'calculated',
    'platform' : 'platform',
    'comment' : 'The depth-averaged current is an estimate of the net current measured while the glider is underwater over all profiles contained in the segment.  The value is reported for each profile in the underwater segment.',
    }
for k in sorted(atts.keys()):
    u.setncattr(k, atts[k])

# v
v = nc.createVariable('v',
    'f8',
    zlib=True,
    complevel=COMP_LEVEL,
    fill_value=-999.)
# Variable attributes
atts = {'units' : 'm s-1',
    'standard_name' : 'northward_sea_water_velocity',
    'valid_min' : -10.,
    'valid_max' : 10.,
    'long_name' : 'Depth-Averaged Northward Sea Water Velocity',
    'observation_type' : 'calculated',
    'platform' : 'platform',
    'comment' : 'The depth-averaged current is an estimate of the net current measured while the glider is underwater over all profiles contained in the segment.  The value is reported for each profile in the underwater segment.',
    }
for k in sorted(atts.keys()):
    v.setncattr(k, atts[k])

# platform
platform = nc.createVariable('platform',
    'i4',
    zlib=True,
    complevel=COMP_LEVEL,
    fill_value=-999.)
# Variable attributes
atts = {'id' : ' ',
	    'instrument' : 'instrument_ctd',
	    'long_name' : ' ',
	    'type' : 'platform',
	    'comment' : ' ',
	    'wmo_id' : ' ',
    }
for k in sorted(atts.keys()):
    platform.setncattr(k, atts[k])

# instrument_ctd
platform = nc.createVariable('instrument_ctd',
    'i4',
    zlib=True,
    complevel=COMP_LEVEL,
    fill_value=-999.)
# Variable attributes
atts = {'calibration_date' : ' ',
        'calibration_report' : ' ',
        'factory_calibrated' : ' ',
        'make_model' : 'Seabird GPCTD',
        'platform' : 'instrument_ctd',
        'long_name' : 'Seabird Glider Payload CTD',
        'type' : 'platform',
        'comment' : 'pumped CTD',
        'serial_number' : ' ',
    }
for k in sorted(atts.keys()):
    platform.setncattr(k, atts[k])

# Create QC variables for all previously added variables as long as they are
# not included in NO_QC_VARS or don't have a CF standard name
QC_ATTRIBUTES = {'long_name' : ' ',
	    'standard_name' : ' ',
	    'flag_meanings' : QC_FLAG_MEANINGS,
	    'valid_min' : QC_FLAGS[0],
	    'valid_max' : QC_FLAGS[-1],
	    'flag_values' : QC_FLAGS,
    };
for (varName, varObj) in nc.variables.items():

    if varName in NO_QC_VARS:
        continue

    if 'standard_name' not in varObj.ncattrs():
        continue

    newVar = nc.createVariable(varName + '_qc',
        'i1',
        varObj.dimensions,
        zlib=True,
        complevel=COMP_LEVEL,
        fill_value=NC_FILL_VALUES['i1'])

    varAtts = QC_ATTRIBUTES
    varAtts['long_name'] = varName + ' Quality Flag';
    varAtts['standard_name'] = varObj.standard_name + ' status_flag'

    for k in sorted(varAtts.keys()):
        newVar.setncattr(k, varAtts[k])


# Close the file
nc.close()
