SPT: Slocum Power Tools
=======================
A library of Matlab routines for loading, manipulating and visualizing Slocum 
glider data files

    John Kerfoot
    Institute of Marine & Coastal Sciences, Rutgers University
    kerfoot@marine.rutgers.edu
    (848) 932-3344

Documentation for this toolbox is available on the [Wiki](https://github.com/kerfoot/spt/wiki).

Background
----------

This toolbox provides 2 core classes, *Dbd* and *DbdGroup*, which provide a
mechanism for manipulating individual data files as well as groups of data
files, respectively.  There are also a variety of utility routines for, among
other things:

+ Conversion of Matlab dates to unix dates
+ Convertion of NMEA GPS coordinates to and from decimal degrees
+ File operations
+ Exporting data to a variety of data structures and file formats
+ Plotting data sets

The toolbox currently uses the [CSIRO Matlab EOS-80 Seawater Library](http://www.cmar.csiro.au/datacentre/ext_docs/seawater.htm) to derive oceanic properties from the raw glider measurements.  
    
A copy of the last stable version can also be found [here](http://marine.rutgers.edu/~kerfoot/slocum/code/seawater_ver3_3.tar).

Development of the [CSIRO Matlab EOS-80 Seawater Library](http://www.cmar.csiro.au/datacentre/ext_docs/seawater.htm) toolbox has been stopped in favor of the Gibbs SeaWater
(GSW) Oceanographic Toolbox of the International Thermodynamic Equation of
Seawater (TEOS-10), which can be found [here](http://www.teos-10.org/software/gsw_matlab_v3_02.zip).

As of <b>August 2014</b>, I have not made the switch to the GSW toolbox.

