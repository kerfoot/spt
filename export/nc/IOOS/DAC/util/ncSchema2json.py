from netCDF4 import Dataset
import numpy as np
import json

# NetCDF template to parse
NC_FILE = '../nc-template/IOOS_Glider_NetCDF_Flat_v1.0.nc'
# Output json file
JSON_FILE = '../json/IOOS_Glider_NetCDF_Flat_v1.0.json'

# Tuple of numpy data types
NUMPY_DTYPES = tuple(np.typeDict.values())

# Open the template for reading
dataset = Dataset(NC_FILE, 'r')

# Dimensions
dimensions = []
for dimName, dim in dataset.dimensions.items():
    dimensions.append(dimName)
   
# Global file attributes
gAttributes = []
for att in dataset.ncattrs():
    
    # Convert numpy datatypes to standard python datatypes to enable json 
    # serialization
    attValue = dataset.getncattr(att)
    if isinstance(attValue, np.ndarray):
        attValue = [np.asscalar(x) for x in attValue]
    elif isinstance(attValue, NUMPY_DTYPES):
        attValue = np.asscalar(attValue)
        
    gAttributes.append({'Name' : att,
        'Value' : dataset.getncattr(att)})
        
# Variables and attributes
variables = []
for varName, var in dataset.variables.items():
    
    variable = {'Name' : varName,
        'Dimensions' : var.dimensions,
        'Attributes' : []}
        
    for varAtt in var.ncattrs():
        
        # Convert numpy datatypes to standard python datatypes to enable json 
        # serialization
        attValue = var.getncattr(varAtt)
        if isinstance(attValue, np.ndarray):
            attValue = [np.asscalar(x) for x in attValue]
        elif isinstance(attValue, NUMPY_DTYPES):
            attValue = np.asscalar(attValue)
            
        variable['Attributes'].append({'Name' : varAtt,
            'Value' : attValue})
        
    variables.append(variable)
    
schema = {'Dimensions' : dimensions,
    'Attributes' : gAttributes,
    'Variables' : variables}

json.dump(schema, open(JSON_FILE, 'w'))

