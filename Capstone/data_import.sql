-------------------------------------------------------------------------------
-- TABLE: WEATHER_STATION

-- build the weather_station table from the station_raw table
insert into weather_station
select distinct wban, callsign, climatedivisioncode, climatedivisionstatecode, name, state, location, latitude::numeric(18,6), longitude::numeric(18,6), groundheight::numeric(18,0), timezone::int
  from station_raw
 order by wban;

-- a little clean-up to remove some duplicate and extraneous data so we can create a primary key
delete from weather_station where coalesce(wban, '') = '';
delete from weather_station where wban = '93226' and station_location = 'PT POEDRAS BLANCA (SITE TERMINATED 1815Z, 6/8/05)';
delete from weather_station where wban = '26559' and latitude = 33.180280;
delete from weather_station where wban = '93138' and climatedivisioncode is null;
update weather_station
   set climatedivisionstatecode = null,
       station_name = 'SOLDONTA',
       state = 'AK',
       station_location = 'SOLDOTNA AIRPORT',
       latitude = 60.475830,
       longitude = -151.034170,
       groundheight = 113.000000,
       timezone = -9
 where wban = '26559'
ALTER TABLE public.weather_station ADD CONSTRAINT "PK_weather_station" PRIMARY KEY (wban);


-------------------------------------------------------------------------------
-- TABLE: ZIP_CODE

-- build the zip_code table from the zip_codes_raw table
insert into zip_code
select trim(upper(zipcode)),
       latitude::numeric(18,6),
       longitude::numeric(18,6),
       trim(upper(state)),
       trim(upper(city)),
       trim(upper(cityaliasname)),
       timezone,
       (case when daylightsaving = 'Y' then true else false end)
from zip_codes_raw;


-------------------------------------------------------------------------------
-- TABLE: WEATHER

-- build the weather table from the weather_hourly_raw table
-- - 'M' stands for 'missing' in the data, so we have to filter for that or our numeric conversions fail)
-- - we construct the full date time from three columns, the date, the time, and the timezone (from the weather_station table)
-- - there are a number of text codes in a few columns (winddirection, hourlyprecip, etc..) that require special filtering
-- - we convert 'T' for hourly precip (meaning 'trace') to 0.005 so we record that there was SOME precipitation but can still keep the column numeric
ALTER TABLE public.weather ALTER COLUMN rounded_date_time DROP NOT NULL;
insert into weather
select trim(upper(whr.wban)),
       (substring(date from 1 for 4) || '-' ||
        substring(date from 5 for 2) || '-' ||
        substring(date from 7 for 2) || ' ' ||
        substring(time from 1 for 2) || ':' ||
        substring(time from 3 for 2) || ':00' || ws.timezone)::timestamp with time zone,
       (case when trim(visibility) = '' or trim(visibility) = 'M' then null else visibility::numeric(18,5) end),
       trim(upper(weathertype)),
       (case when trim(drybulbfarenheit) = '' or trim(drybulbfarenheit) = 'M' then null else drybulbfarenheit::numeric(18,5) end),
       (case when trim(wetbulbfarenheit) = '' or trim(wetbulbfarenheit) = 'M' then null else wetbulbfarenheit::numeric(18,5) end),
       (case when trim(dewpointfarenheit) = '' or trim(dewpointfarenheit) = 'M' then null else dewpointfarenheit::numeric(18,5) end),
       (case when trim(relativehumidity) = '' or trim(relativehumidity) = 'M' then null else relativehumidity::numeric(18,5) end),
       (case when trim(windspeed) = '' or trim(windspeed) = 'M' then null else windspeed::numeric(18,5) end),
       (case when trim(winddirection) = '' or trim(winddirection) = 'M' or trim(winddirection) = 'VR' then null else winddirection::numeric(18,5) end),
       (case when trim(stationpressure) = '' or trim(stationpressure) = 'M' then null else stationpressure::numeric(18,5) end),
       trim(upper(recordtype)),
       (case when regexp_replace(trim(hourlyprecip), '(E\d)+', '') = '' or regexp_replace(trim(hourlyprecip), '(E\d)+', '') = 'M' then null
             when regexp_replace(trim(hourlyprecip), '(E\d)+', '') = 'T' then 0.005
             else regexp_replace(trim(hourlyprecip), '(E\d)+', '')::numeric(18,5) end),
       (case when trim(altimeter) = '' or trim(altimeter) = 'M' then null else altimeter::numeric(18,5) end)
  from weather_hourly_raw whr
 inner join weather_station ws
    on whr.wban = ws.wban
 where trim(upper(skycondition)) != 'M';

-- note that we get the rounded by hour date time by adding 30 minutes to the date time and truncating that time at the hour
update weather set rounded_date_time = date_trunc('hour', measurement_time + '30 minute'::interval);
ALTER TABLE weather ALTER COLUMN rounded_date_time SET NOT NULL;

-- The weather table contains several readings per hour per station.  To make the table easier to work with, we can 
-- group by the station and hour and take the average reading per hour.  This eliminates a lot of rows, and the hourly
-- weather resolution should still be good enough for our purposes.
select wban,
       rounded_date_time as date_time,
       avg(visibility)::numeric(5,2) as visibility,
       max(weather_type) as weather_type,
       avg(dry_bulb_celsius)::numeric(5,1) as dry_bulb_celsius,
       avg(wet_bulb_celsius)::numeric(5,1) as wet_bulb_celsius,
       avg(dew_point_celsius)::numeric(5,1) as dew_point_celsius,
       avg(relative_humidity)::numeric(4,0) as relative_humidity,
       avg(wind_speed)::numeric(4,0) as wind_speed,
       avg(wind_direction)::numeric(3,0) as wind_direction,
       avg(station_pressure)::numeric(5,2) as station_pressure,
       max(record_type) as record_type,
       avg(coalesce(hourly_precip, 0.00))::numeric(6,3) as hourly_precip,
       avg(altimeter)::numeric(7,2) as altimeter
  into weather_grouped
  from weather
 group by wban, rounded_date_time;

-- replace the weather table with our new weather_grouped table
drop table weather;
ALTER TABLE weather_grouped RENAME TO weather;
ALTER TABLE weather ADD CONSTRAINT "PK_weather" PRIMARY KEY (wban, date_time);

-- the weather_station table contains some entries that we have no weather data for; delete them
delete from weather_station where wban in (select ws.wban from weather_station ws left outer join weather w on ws.wban = w.wban where w.wban is null);

-------------------------------------------------------------------------------
-- TABLE: PACKAGE_ACTIVITY

/*
The "ActivityZip" column seems to be empty in our source activities table, which is unfortunate.  So instead we attempt to find the latitude and longitude based on the City and
State column.  Note that we also filter out "C", "M", "OR", and "EG" activities since they aren't useful for our purposes.  The "C", "M", and "OR" activities ("customer",
"manifest", and "origin" respectively) are generated either before or at the moment the package is in the hands of the carrier.  The "EG" activity is an internal activity
irrelevant to us here. The "R" activity ("rescheduled") represents an expected rescheduling, which we also aren't interested in.  We also filter out packages that are either
before 2015 or were shipped in the last few days of the year.  This is to make sure our entire (or almost our entire) data set represents packages that were delivered in 2015,
or *should* have been.
*/

-- we have no location information about the following activities, so they are useless to us
delete from activities where activitystate is null or activitycity is null;

-- the following packages are outside of our date range, so get rid of them
delete from activities where packageid in (select id from packages where COALESCE(ManifestDate, ClientTenderedDate, TenderedDate) < '2015-01-01' or COALESCE(ManifestDate, ClientTenderedDate, TenderedDate) > '2015-12-20');
delete from activities where packageid in (select id from packages where COALESCE(ScheduledDeliveryDate, LastScheduledDeliveryDate, OriginalScheduledDeliveryDate) is null);

-- the following activities are not of interest to us, so get rid of them
delete from activities where Discriminator in ('C', 'M', 'OR', 'EG', 'R');
delete from activities where discriminator is null;

-- clean up some city names
update activities set activitycity = 'DFW AIRPORT' where activitycity = 'DALLAS/FT. WORTH A/P';
update activities set activitycity = 'DFW AIRPORT' where activitycity = 'DFW2 AIRPORT';
update activities set activitycity = 'SAINT JOSEPH' where activitycity = 'ST. JOSEPH';
update activities set activitycity = 'SAINT CLAIRSVILLE' where activitycity = 'ST. CLAIRSVILLE';
update activities set activitycity = 'HOPE MILLS' where activitycity = 'HOPE MILLS';
update activities set activitycity = 'HASLET' where activitycity = 'HASLEP';

-- build the package_activity table from the activities table
-- note that we get the rounded by hour date time by adding 30 minutes to the date time and truncating that time at the hour
insert into package_activity
select trim(upper(p.trackingnumber)),
       (select (a.ActivityDate::text || '-' || time_zone)::timestamp with time zone
          from zip_code
         where state = activitystate
           and (city = activitycity or city_alias = activitycity)
         limit 1) as date_time,
       a.Discriminator,
       a.ActivityCity,
       a.ActivityState,
       (select latitude
          from zip_code
         where state = activitystate
           and (city = activitycity or city_alias = activitycity)
         limit 1) as latitude,
       (select longitude
          from zip_code
         where state = activitystate
           and (city = activitycity or city_alias = activitycity)
         limit 1) as longitude,
       (select date_trunc('hour', (a.ActivityDate::text || '-' || time_zone)::timestamp with time zone + '30 minute'::interval)
          from zip_code
         where state = activitystate
           and (city = activitycity or city_alias = activitycity)
         limit 1) as rounded_date_time
  from Activities a
  left join Packages p on p.Id = a.PackageId;

-- 0.04% records were not able to be matched with the zip_code table; drop them rather then spend the time matching them by hand
delete from package_activity where zip_code is null;

/*
We would like to add a primary key on (tracking_number, date_time, activity_code), but it appears that that is not unique
so we should delete the duplicated data.  To do so we add a tempoarary column of increasing numbers that will provide a
unique value per row.  We delete this temporary column when we're done.
*/
alter table package_activity add column temp_id serial;
delete from package_activity where temp_id not in
       (select min(temp_id)
         from package_activity
        group by tracking_number, date_time, activity_code);
ALTER TABLE package_activity ADD CONSTRAINT "PK_package_activity" PRIMARY KEY (tracking_number, date_time, activity_code);
alter table package_activity drop column temp_id;

-- there are a few package_activity records that correspond to packages we've removed from the package table; delete them
delete from package_activity where tracking_number not in (select tracking_number from package);

-- creating this foreign key ensures that the package_activity table only contains data that is also present in the package table
ALTER TABLE package_activity ADD CONSTRAINT "FK_tracking_number" FOREIGN KEY (tracking_number) REFERENCES package(tracking_number) ON UPDATE NO ACTION ON DELETE NO ACTION;


-------------------------------------------------------------------------------
-- TABLE: PACKAGE

-- the following packages are outside of our date range, so get rid of them
delete from packages where COALESCE(ManifestDate, ClientTenderedDate, TenderedDate) < '2015-01-01' or COALESCE(ManifestDate, ClientTenderedDate, TenderedDate) > '2015-12-20';
delete from packages where COALESCE(ScheduledDeliveryDate, LastScheduledDeliveryDate, OriginalScheduledDeliveryDate) is null;
delete from packages where COALESCE(servicedesc, '') = '';

-- build the package table from the packages table
insert into package
select upper(trim(trackingnumber)),
       COALESCE(ManifestDate, ClientTenderedDate, TenderedDate),
       COALESCE(ScheduledDeliveryDate, LastScheduledDeliveryDate, OriginalScheduledDeliveryDate),
       DeliveryDate,
       ServiceDesc
  from Packages p;
ALTER TABLE package ADD CONSTRAINT "PK_package" PRIMARY KEY (tracking_number);


-------------------------------------------------------------------------------
/*
We need further processing of the data.  We want to use a 3rd party module called PostGIS which adds
geospatial functions as an extension to a PostgreSQL database.  So we add new columns to the
package_activity and weather_station tables which will contain the latitude and longitude encoded
in a way the PostGIS tool expects.  Note that the PostGIS tool expects the longitude as the first
parameter, which is backwards from what we'd normally expect.
*/
alter table weather_station add column geo_location geometry;
update weather_station set geo_location = ST_Point(longitude, latitude);
alter table package_activity add column geo_location geometry;
update package_activity set geo_location = ST_Point(longitude, latitude);

/*
We then add a column to the package_activity table which will contain the closest weather station, which
we will calculate based on the position of the activity and the position of the weather stations.
*/
alter table package_activity add column closest_station_wban text;

-- now we need to populate the closest weather station for each package activity based on the latitude and longitude
update package_activity
   set closest_station_wban =
       (
          select ws.wban
            from weather_station ws
           order by ST_Distance(ws.geo_location, package_activity.geo_location)
           limit 1
       );

-- create some database foreign keys to ensure data integrity
ALTER TABLE package_activity ADD CONSTRAINT "FK_closest_station_wban" FOREIGN KEY (closest_station_wban) REFERENCES weather_station(wban) ON UPDATE NO ACTION ON DELETE NO ACTION;
ALTER TABLE package_activity ADD CONSTRAINT "FK_tracking_number" FOREIGN KEY (tracking_number) REFERENCES package(tracking_number) ON UPDATE NO ACTION ON DELETE NO ACTION;
ALTER TABLE weather ADD CONSTRAINT "FK_wban" FOREIGN KEY (wban) REFERENCES weather_station(wban) ON UPDATE NO ACTION ON DELETE NO ACTION;

-- we also notice that we are missing some weather observations for some of the package activity records at their closest station WBAN
-- locate these missing records
select distinct pa.rounded_date_time as date_time, pa.closest_station_wban as wban
  into missing_weather
  from package_activity pa
  left outer join weather w on w.wban = pa.closest_station_wban and w.date_time = pa.rounded_date_time
 where w.wban is null;

-- clear out the closest station data for the package activities that do not have corresponding weather data
update package_activity set closest_station_wban = null, station_distance_error = null
  from missing_weather mw
 where package_activity.closest_station_wban = mw.wban
   and package_activity.rounded_date_time = mw.date_time
   and closest_station_wban is not null;

-- now re-populate the closest_station_wban based on the 2nd closest station
update package_activity
   set closest_station_wban =
       (
          select ws.wban
            from weather_station ws
           order by ST_Distance(ws.geo_location, package_activity.geo_location)
           limit 1 offset 1
       )
  where closest_station_wban is null;

-- perform another round of looking for missing records
drop table missing_weather;
select distinct pa.rounded_date_time as date_time, pa.closest_station_wban as wban
  into missing_weather
  from package_activity pa
  left outer join weather w on w.wban = pa.closest_station_wban and w.date_time = pa.rounded_date_time
 where w.wban is null;
update package_activity set closest_station_wban = null, station_distance_error = null
  from missing_weather mw
 where package_activity.closest_station_wban = mw.wban
   and package_activity.rounded_date_time = mw.date_time
   and closest_station_wban is not null;
update package_activity
   set closest_station_wban =
       (
          select ws.wban
            from weather_station ws
           order by ST_Distance(ws.geo_location, package_activity.geo_location)
           limit 1 offset 2  -- 3rd closest
       )
  where closest_station_wban is null;

-- We repeated this process until all package_activity records had a corresponding weather record.  This took 10 rounds, but the vast majority
-- of records were fixed after two or three iterations.

-- add a station_distance_error column that shows the distance (in meters) between the centroid of the zip code associated with the package activity and the associated weather station
update package_activity
   set station_distance_error = ST_Distance(ws.geo_location::geography, package_activity.geo_location::geography)
  from weather_station ws
 where ws.wban = package_activity.closest_station_wban
   and station_distance_error is null;


-------------------------------------------------------------------------------
-- Create some smaller tables that represent a small sample of the data so we can play around with the data in R more quickly and easily.
-- Create a package_sample table with approximately 50,000 packages, and then create a package_activity_sample table with all activities
-- that belong to all sampled packages, and a weather_sample table that contains only weather records that are associated with the
-- records in the package_activity_sample table.

-- package_sample
SELECT 100.0 * (50000.0 / count(tracking_number)) FROM PACKAGE;  -- 2.166% of the table ~ 50k rows
SELECT *
  INTO package_sample
  FROM package TABLESAMPLE BERNOULLI (2.166);

-- activity_sample
SELECT pa.*
  INTO package_activity_sample
  FROM package_activity pa
 INNER JOIN package_sample ps on pa.tracking_number = ps.tracking_number;

-- weather_sample
SELECT w.*
  INTO weather_sample
  FROM weather w
 INNER JOIN package_activity_sample pas
    ON w.wban = pas.closest_station_wban
   AND w.date_time = pas.rounded_date_time

select * from package_activity_sample limit 10


-- output the CSV files (note we omit some of the columns that we constructed just to help us manage the data, but isn't relevant)
COPY (SELECT * FROM package_sample) To 'D:/Projects/DataScienceWorkshop/Capstone/sample_data/package_sample.csv' WITH CSV;
COPY (SELECT tracking_number, date_time, activity_code, city, state, zip_code, latitude, longitude, closest_station_wban, rounded_date_time, station_distance_error FROM package_activity_sample) To 'D:/Projects/DataScienceWorkshop/Capstone/sample_data/package_activity_sample.csv' WITH CSV;
COPY (SELECT * FROM weather_sample) To 'D:/Projects/DataScienceWorkshop/Capstone/sample_data/weather_sample.csv' WITH CSV;

