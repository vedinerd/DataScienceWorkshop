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
insert into package_activity
select trim(upper(p.trackingnumber)),
       (select (a.ActivityDate::text || '-' || time_zone)::timestamp with time zone
          from zip_code
         where state = activitystate
           and (city = activitycity or city_alias = activitycity)
         limit 1) as activity_date,
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
         limit 1) as longitude
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
CREATE INDEX ON package_activity (tracking_number, date_time, activity_code);
begin transaction;
delete from package_activity where temp_id not in
(select min(temp_id)
   from package_activity
  group by tracking_number, date_time, activity_code);
ALTER TABLE package_activity ADD CONSTRAINT "PK_package_activity" PRIMARY KEY (tracking_number, date_time, activity_code);
alter table package_activity drop column temp_id;
CREATE INDEX ON package(tracking_number);

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
CREATE INDEX ON package(tracking_number);


-------------------------------------------------------------------------------
/*
We need further processing of the data.  We want to use a 3rd party module called PostGIS which adds
geospatial functions as an extension to a PostgreSQL database.  So we add new columns to the
package_activity and weather_station tables which will contain the latitude and longitude encoded
in a way the PostGIS tool expects.  Note that the PostGIS tool expects the longitude as the first
parameter, which is backwards from what we'd normally expect.
*/
alter table weather_station add column position geometry;
update weather_station set position = ST_Point(longitude, latitude);
alter table package_activity add column position geometry;
update package_activity set position = ST_Point(longitude, latitude);

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
           order by ST_Distance(ws.position, package_activity.position)
           limit 1
       );

