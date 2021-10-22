# Raw Private Data

Store raw data in this folder as it is collected or downloaded if the data cannot be publicly redistributed. For example, data versioning and sharing my be restricted because of large file sizes, licensing, ethics, privacy, or confidentiality. Best practices are to include code to automate the process of downloading or simulating raw private data in the first step of the methods, or to include instructions here for accessing any private or restricted-access data.

## Instructions for accessing data


The OpenStreetMap data for this lab was downloaded on 2021-03-23 by Joseph Holler
It is available for the public to download from https://geography.middlebury.edu/jholler/data/dsmosm.osm
Using Windows, it was imported into a PostGIS database using one command line code, saved in the dsm_import.bat batch script for Windows
This batch script uses the dsm.style style file for the OSM2PGSQL program, which must be installed separately

Include instructions here, e.g., instructions to run the first code script in the `procedure/code` folder, or instructions on how to create or download the data.

*This folder is ignored by Git versioning* with the exception of this `readme.md` file by the following lines in `.gitignore`

```gitignore
# Ignore contents of private folder, with the exception of its readme file
private/**
!private/readme.md
```
