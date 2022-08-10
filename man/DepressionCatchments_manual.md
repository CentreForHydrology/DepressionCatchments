# DepressionCatchments

## Licence

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3 of the License, or
at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the 
GNU General Public License for more details.

## Intoduction

This program is intended to determine the catchments of depressions
in a DEM. It is intended for use in the Canadian Prairies, which
have millions of depressions which sometimes connect and allow
flow among them to the outlet.

This program is intended to work with other programs such as WDPM ((Shook et al., 2021).

## Use of the program

### Compiling

The source code is written in Fortran 95. To convert it to an executable, you will need a Fortran compiler.
The program has been successfully compiled using gfortran (https://gcc.gnu.org/wiki/GFortran) under Linux Mint. It is not known
if it will work with other compilers and/or operating systems.

The command to compile the program is  

`gfortran DepressionCatchments.f95 -o DepressionCatchments`  

### Data requirements

`DepressionCatchments` requires 2 input files. Note that all rasters are ArcGIS ASCII (.asc) files.

1. A Digital Elevation Model (DEM) file of the region. LiDAR based DEMs are preferred in the Canadian Prairies because of the flatness of the landscape.
2. Water file. This is a file showing areas of water in the DEM after filling. The program WDPM (Shook et al., 2021) works well to fill a DEM, if it is drained afterwards. An advantage of using WDPM is that you can partially fill a DEM to get the separate basins of depressions which merge. You can also use standard depression-filling algorithms in programs like SAGA (https://saga-gis.sourceforge.io/en/index.html). Once you have filled the depressions, you need to number the water areas. 
   This file can be created from the filled DEM using a program such as QGIS.

A fraction of the file might look like this:

```
-9999 -9999 0 0 0
-9999 0 0 0 0
-9999 0 0 2 0
-9999 0 0 2 2
-9999 0 0 2 0
-9999 0 0 2 0
```

where:
-9999 is the basin mask (missing values, i.e. the edge of the basin),  
0 is the upland (water free), and  
2 is the ID number of the depression.

Note that because the program is written in Fortran, all of the numbers, including the missing values
must be integers.

### Output

The area not draining into any depressions (i.e. draining to the outlet) of the basin
is written to the screen.

The program outputs a text file containing the ID number, Depression Area (m²) and Basin Area (m²) for each depression, e.g.  

```
   Depression  Depression       Basin
       Number        Area        Area
            1      2178.0         0.0
            2    139392.0     78408.0
            3      3267.0     52272.0
            4      5445.0     46827.0
...
```

Note that the basin is exclusive of the depression area, so the total catchment area of the 
depression is the sum of the Depression Area and the Basin Area.

## Running the program

`DepressionCatchments` has no user interface, and is run from the command line.
The files are specified on the command line as 
the DEM file, the water file, and the output file, i.e:  

`DepressionCatchments  mydem.asc water.asc outfile.txt`

## References

Shook, K., Spiteri, R.J., Pomeroy, J.W., Liu, T., Sharomi, O., 2021. WDPM: the Wetland DEM Ponding Model. Journal of Open Source Software 6, 2276. https://doi.org/10.21105/joss.02276
