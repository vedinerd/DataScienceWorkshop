The raw data follows the schema as specified in raw_schema.txt and was located in a Microsoft SQL Server Express database (the package activity data) as well as QCLCD (Quality Controlled Local Climatological Data) from NOAA for all of 2015 (1).  Because of the limitations of the Express edition of the Microsoft SQL Server database, the first step performed was to import the data into a local PostgreSQL database, using the export features of Microsoft SQL Server combined with the COPY command in PostgreSQL.  Data coming out of Microsoft SQL Server included a 0x00 byte for NULL, as well as a CRLF pair for line termination, both of which was not handled well by PostgreSQL.  A simple text script stripped the 0x00 bytes from the data files and replaced the CRLF pairs with a single LF character.

Now that the data was in PostgreSQL, the next step was to filter the data for extraneous columns and rows and to make sure the data was all in the same format (all time stamps included the time zone, the locations of all package activities were geo-coded in a way compatible with the weather station locations, etc..)  This process is documented in the data_import.sql file.

After all the data cleaning has been done, we are left with 2,308,354 package records with 16,831,083 activity records, all to be correlated with 36,555,051 hourly weather records from 2,166 weather stations in the United States.

 
(1) http://www.ncdc.noaa.gov/orders/qclcd/



-- Looking at the package data, we find a handful (416 out of several million) that appear to be duplicated.
-- Choose one of the duplicates (the one with the smaller ID value) to get rid of.  We have to delete the associated
-- activities records because of the foreign key we set up.
delete from activities where packageid in (select min(id) from packages group by trackingnumber having count(*) > 1);
delete from packages where id in (select min(id) from packages group by trackingnumber having count(*) > 1);

-- clean up the zip code table
insert into zip_code
select trim(upper(zipcode)), latitude::numeric(18,6), longitude::numeric(18,6), trim(upper(state)), trim(upper(city)), trim(upper(cityaliasname)), timezone, (case when daylightsaving = 'Y' then true else false end)
from zip_codes_raw;



