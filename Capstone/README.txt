-------------------------------------------------------------------------------

The raw data follows the schema as specified in raw_schema.txt and was located 
in a Microsoft SQL Server Express database (the package activity data) as well 
as QCLCD (Quality Controlled Local Climatological Data) from NOAA for all of 
2015 [1].  Because of the limitations of the Express edition of the Microsoft 
SQL Server database, the first step performed was to import the data into a 
local PostgreSQL database, using the export features of Microsoft SQL Server 
combined with the COPY command in PostgreSQL.  Data coming out of Microsoft 
SQL Server included a 0x00 byte for NULL, as well as a CRLF pair for line 
termination, both of which was not handled well by PostgreSQL.  A simple text 
script stripped the 0x00 bytes from the data files and replaced the CRLF pairs 
with a single LF character.

Now that the data was in PostgreSQL, the next step was to filter the data for 
extraneous columns and rows and to make sure the data was all in the same 
format (all time stamps included the time zone, the locations of all package 
activities were geo-coded in a way compatible with the weather station 
locations, etc..)  This process is documented in the data_import.sql file.

After all the data cleaning has been done, we are left with 2,308,354 package 
records with 16,831,083 activity records, all to be correlated with 17,762,268 
hourly weather records from 2,166 weather stations in the United States.  A 
small sample of each table is provided in the sample_data/ folder.  Each table 
is in its own file.  The final data schema can be seen in the final_schema.txt 
file.  The package data does not spread over all of 2015, but instead is from 
roughly mid-June to the end of the year.  This is not ideal, since not all 
seasons are represented (spring is completely missed).  However, hopefully a 
large enough sample of different weather conditions are represented that some 
useful conclusions can be drawn from the data.

-------------------------------------------------------------------------------

[1] http://www.ncdc.noaa.gov/orders/qclcd/

