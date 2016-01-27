
copy zip_codes_raw from E'C:\\zip_codes.txt' WITH NULL '';

insert into zip_code

insert into zip_code
select zipcode, latitude::numeric(18,6), longitude::numeric(18,6), state, city, cityaliasname, timezone, (case when daylightsaving = 'Y' then true else false end)
from zip_codes_raw
where primaryrecord = 'P';

select * from zip_code


select * from activities limit 100


-- Looking at the data, we find a handful (416 out of several million) that appear to be duplicated.  Choose one of the duplicates (the one with the smaller ID value) to get rid of.
delete from activities where packageid in (select min(id) from packages group by trackingnumber having count(*) > 1);
delete from packages where id in (select min(id) from packages group by trackingnumber having count(*) > 1);



-- we only need a subset of the available data; 


select p.Id, COALESCE(ManifestDate, ClientTenderedDate, TenderedDate) as ShipDate,
       COALESCE(ScheduledDeliveryDate, LastScheduledDeliveryDate, OriginalScheduledDeliveryDate) AS ScheduledDeliveryDate,
       DeliveryDate as ActualDeliveryDate, ServiceDesc as ServiceDescription,
       a1.City as OriginCity, a1.State as OriginState, a2.City as DestinationCity, a2.State as DestinationState
  from Packages p
inner join Addresses a1 on p.ShipperAddressId = a1.Id
inner join Addresses a2 on p.OriginalDestinationAddressId = a2.Id
where COALESCE(ManifestDate, ClientTenderedDate, TenderedDate) >= '2015-01-01'
  and COALESCE(ManifestDate, ClientTenderedDate, TenderedDate) < '2015-12-20'
  and COALESCE(ScheduledDeliveryDate, LastScheduledDeliveryDate, OriginalScheduledDeliveryDate) is not null;

select * from Packages where id in



-- The "ActivityZip" column seems to be empty in our source data, which is unfortunate.  So instead we attempt to find the latitude and longitude based on the City and State column.
-- Note that we also filter out "C", "M", "OR", and "EG" activities since they aren't useful for our purposes.  The "C", "M", and "OR" activities ("customer", "manifest", and "origin"
-- respectively) are generated either before or at the moment the package is in the hands of the carrier.  The "EG" activity is an internal activity irrelevant to us here. The "R"
-- activity ("rescheduled") represents an expected rescheduling, which we also aren't interested in.  We also filter out packages that are either before 2015 or were shipped in the
-- last few days of the year.  This is to make sure our entire (or almost our entire) data set represents packages that were delivered in 2015, or *should* have been.


insert into package_activity
select p.trackingnumber,
       (select (a.ActivityDate::text || '-' || time_zone)::timestamp with time zone
          from zip_code
         where state = activitystate
           and (city = activitycity or city_alias = activitycity)
         limit 1) as activity_date,
       a.Discriminator as ActivityCode,
       a.ActivityCity, a.ActivityState,
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
  left join Packages p on p.Id = a.PackageId

limit 1000

select a.* from activities a inner join packages p on p.id = a.packageid where trackingnumber = '1Z6981XW0178838202'

select * from activities where activitycity like '%/%'



select * from zip_code where city = 'DALLAS'



vacuum full analyze verbose activities;


-- we have no location information about the following activities, so they are useless to us
delete from activities where activitystate is null or activitycity is null;

-- the following packages are outside of our date range, so get rid of them
delete from activities where packageid in (select id from packages where COALESCE(ManifestDate, ClientTenderedDate, TenderedDate) < '2015-01-01' or COALESCE(ManifestDate, ClientTenderedDate, TenderedDate) > '2015-12-20');
delete from activities where packageid in (select id from packages where COALESCE(ScheduledDeliveryDate, LastScheduledDeliveryDate, OriginalScheduledDeliveryDate) is null);
delete from packages where COALESCE(ManifestDate, ClientTenderedDate, TenderedDate) < '2015-01-01' or COALESCE(ManifestDate, ClientTenderedDate, TenderedDate) > '2015-12-20';
delete from packages where COALESCE(ScheduledDeliveryDate, LastScheduledDeliveryDate, OriginalScheduledDeliveryDate) is null;

-- the following activities are not of interest to us, so get rid of them
delete from activities where Discriminator in ('C', 'M', 'OR', 'EG', 'R');

-- clean up some city names
update activities set activitycity = 'DFW AIRPORT' where activitycity = 'DALLAS/FT. WORTH A/P';
update activities set activitycity = 'DFW AIRPORT' where activitycity = 'DFW2 AIRPORT';




select activitycity, activitystate, activitycountry, code
  from activities a
  left outer join zip_code z on a.activitycity = z.city or a.activitycity = z.city_alias
 where zip_code is null
 limit 10




select * from activities where packageid = 863914

select count(*) from activities where activitycity is null

26369287
 5848104


CREATE INDEX ON packages (COALESCE(ScheduledDeliveryDate, LastScheduledDeliveryDate, OriginalScheduledDeliveryDate));

vacuum full analyze verbose zip_code

select a.id
  from Activities a
  left join Packages p on p.Id = a.PackageId
  left outer join zip_code zc on zc.state = a.activitystate and (zc.city = a.activitycity or zc.city_alias = a.activitycity)
 where COALESCE(ManifestDate, ClientTenderedDate, TenderedDate) >= '2015-01-01'
   and COALESCE(ManifestDate, ClientTenderedDate, TenderedDate) < '2015-12-20'
   and COALESCE(ScheduledDeliveryDate, LastScheduledDeliveryDate, OriginalScheduledDeliveryDate) is not null
   and a.Discriminator not in ('C', 'M', 'OR', 'EG', 'R')
group by a.id
limit 10






select * from zip_code where state not in ('PR', 'AE', 'AP', 'AA', 'VI') and time_zone < 5


  left outer join zip_code zc on zc.state = a.activitystate and zc.city = a.activitystate

limit 10

select * from zip_code where city = 'NORWICH' and state = 'CT'

select * from zip_codes_raw limit 10

truncate table zip_code



-- clean up the zip code table
insert into zip_code
select trim(upper(zipcode)), latitude::numeric(18,6), longitude::numeric(18,6), trim(upper(state)), trim(upper(city)), trim(upper(cityaliasname)), timezone, (case when daylightsaving = 'Y' then true else false end)
from zip_codes_raw

where primaryrecord = 'P';

select * from zip_code




select * from zip_code where city = 'COVENTRY' and state = 'CT'




select * from activities limit 10

update activities 



18477050

   
 limit 10



select * from activities where activityzip is not null

select * from zip_code limit 1000



(case p.CarrierId when 1 then 'UPS' when 2 then 'FedEx' when 3 then 'GSO' end)



CREATE TABLE public.package_activity
(
tracking_number text not null,
date_time timestamp with time zone not null,
activity_code text not null,
city text,
state text,
zip_code text,
latitude numeric(18,6),
longitude numeric(18,6)
)


'R', 'V'


select * from packages where id in ('31646',
'31839',
'31861',
'31956',
'31967',
'31967',
'31967'
)

select * from activities where packageid = 31839 order by activitydate

CREATE INDEX idx_pkg_ship_addr
   ON public.packages (ShipperAddressId ASC NULLS LAST);
CREATE INDEX idx_pkg_org_dest_addr
   ON public.packages (OriginalDestinationAddressId ASC NULLS LAST);









select distinct discriminator from activities
select count(distinct packageid) from activities where discriminator = 'R' limit 1000




OD
EX
DL
C
V
M
OR
T
R
EG



   zip_code text not null,
   latitude numeric(18,6) not null,
   longitude numeric(18,6) not null,
   state text not null,
   city text not null,
   city_alias text not null,
   time_zone int not null,
   daylight_saving boolean not null


select * from zip_Codes_raw

update zip_codes_raw set primaryrecord = null where primaryrecord != 'P'


select * from zipcode where primaryrecord










select * from
(select distinct zcw.zipcode, (case when p.zipcode is null then null else 'Y' end) as has_primary from
(select distinct zipcode
  from zip_codes_raw) zcw
left outer join
(select distinct zipcode
  from zip_codes_raw
 where primaryrecord is not null) p
 on zcw.zipcode = p.zipcode) dt
where dt.has_primary is null;
-> (empty result)

select count(distinct zipcode) from zip_codes_raw
-> 41802
select count(distinct zipcode) from zip_codes_raw where primaryrecord = 'P'
-> 41802


and p.zipcode is null


select * from zip_codes_raw where zipcode = '29260'





select * from weather_station


insert into weather_station
select distinct wban, callsign, climatedivisioncode, climatedivisionstatecode, name, state, location, latitude::numeric(18,6), longitude::numeric(18,6), groundheight::numeric(18,0), timezone::int
from station_raw
order by wban




select count(*) from weather_hourly_raw


51,518,931


32.623300,-116.472800
32.626100,-116.468100

https://www.google.com/maps/@32.623300,-116.472800,15z
https://www.google.com/maps/@32.626100,-116.468100,15z

select * from weather_station


insert into weather
select wo.wban,
       measurement_time,
       ws.timezone,
       (measurement_time::text || ws.timezone)::timestamp with time zone,
       visibility, weather_type, dry_bulb_celsius, wet_bulb_celsius, dew_point_celsius, relative_humidity, wind_speed, wind_direction, station_pressure, record_type, hourly_precip, altimeter
  from weather_old wo
 inner join weather_station ws on ws.wban = wo.wban
order by wban desc

  limit 100000

select * from activities where packageid = 3

1Z6981XW0178838266





select * from packages limit 10

select * from weather limit 10

select * from weather_station where wban = '24023'


delete from weather_station where wban = '93226' and station_location = 'PT POEDRAS BLANCA (SITE TERMINATED 1815Z, 6/8/05)'
delete from weather_station where wban = '26559' and latitude = 33.180280
delete from weather_station where wban = '93138' and climatedivisioncode is null


select * from weather_station where wban in (select wban from weather_station group by wban having count(*) > 1) order by wban

insert into weather_station values ('26559','SXQ','50','SOLDONTA','AK','SOLDOTNA AIRPORT',60.475830,-151.034170,113,-9)

select * from weather_station



ALTER TABLE public.weather
  DROP CONSTRAINT "PK_weather";



ALTER TABLE public.weather_station
  ADD CONSTRAINT "PK_weather_station" PRIMARY KEY (wban);

ALTER TABLE public.packages
  ADD CONSTRAINT "PK_packages" PRIMARY KEY (id);

ALTER TABLE public.activities ADD CONSTRAINT "FK_package_id" FOREIGN KEY (packageid) REFERENCES public.packages (id) ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE public.weather ADD CONSTRAINT "FK_wban" FOREIGN KEY (wban) REFERENCES public.weather_station (wban) ON UPDATE NO ACTION ON DELETE NO ACTION;

CREATE INDEX idx_pkg_trackingnumber
   ON public.packages (trackingnumber ASC NULLS LAST);







select * from weather where wban = '00110' order by measurement_time


select * from activities limit 10

select * from packages limit 10

select * from addresses limit 10





select * from weather where wban = '00103' order by measurement_time


select record_type, count(*) from weather group by record_type

delete from weather where record_type != 'AA'


Detail: Key (wban, measurement_time)=(00103, 2015-01-10 23:11:00) is duplicated.




insert into weather
select trim(upper(wban)),
(substring(date from 1 for 4)
 || '-' ||
 substring(date from 5 for 2)
 || '-' ||
 substring(date from 7 for 2)
 || ' ' ||
 substring(time from 1 for 2)
 || ':' ||
 substring(time from 3 for 2)
 || ':00')::timestamp,
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
 (case when regexp_replace(trim(hourlyprecip), '(E\d)+', '') = '' or regexp_replace(trim(hourlyprecip), '(E\d)+', '') = 'M' then null when regexp_replace(trim(hourlyprecip), '(E\d)+', '') = 'T' then 0.005 else regexp_replace(trim(hourlyprecip), '(E\d)+', '')::numeric(18,5) end),
 (case when trim(altimeter) = '' or trim(altimeter) = 'M' then null else altimeter::numeric(18,5) end)
from weather_hourly_raw
where trim(upper(skycondition)) != 'M';


truncate table weather_hourly_raw




select * from weather limit 10000 where hourly_precip > 0 limit 10


select hourlyprecip, replace(hourlyprecip, 'E2E2', '') from weather_hourly_raw where hourlyprecip like '%E2E2%'

select hourlyprecip, regexp_replace(trim(hourlyprecip), '(E\d)+', '') from weather_hourly_raw where hourlyprecip like '%E%'


replace(hourlyprecip, 'E2E2', '')



truncate table weather_hourly_raw;




select * from weather where measurement_time >= '2015-11-01'



select count(*) from weather






select * from weather limit 10


select * from weather_hourly_raw where hourlyprecip = '  T' limit 100
select * from weather_hourly_raw where hourlyprecip = '0.01' limit 100


select * from weather_hourly_raw where 







select * from weather_hourly_raw limit 10000


-- Table: public.weather_hourly_raw

DROP TABLE public.station_raw


wban, callsign, climatedivisioncode, climatedivisionstatecode, name, state, location, latitude, longitude, groundheight, timezone

CREATE TABLE public.weather_station
(
wban text,
callsign text,
climatedivisioncode text,
climatedivisionstatecode text,
station_name text,
state text,
station_location text,
latitude numeric(18,6),
longitude numeric(18,6),
groundheight numeric(18,0),
timezone int
)
WITH (
  OIDS=FALSE
);



CREATE TABLE public.package_activity
(
tracking_number text not null,
date_time timestamp with time zone not null,
activity_code text not null,
city text,
state text,
latitude numeric(18,6),
longitude numeric(18,6)
)
WITH (
  OIDS=FALSE
);





-- Table: public.weather_old

-- DROP TABLE public.weather_old;

CREATE TABLE public.weather
(
  wban text NOT NULL,
  measurement_time timestamp with time zone NOT NULL,
  visibility numeric(5,2),
  weather_type text,
  dry_bulb_celsius numeric(5,1),
  wet_bulb_celsius numeric(5,1),
  dew_point_celsius numeric(5,1),
  relative_humidity numeric(4,0),
  wind_speed numeric(4,0),
  wind_direction numeric(3,0),
  station_pressure numeric(5,2),
  record_type text,
  hourly_precip numeric(6,3),
  altimeter numeric(7,2),
  CONSTRAINT "FK_wban" FOREIGN KEY (wban)
      REFERENCES public.weather_station (wban) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
)
WITH (
  OIDS=FALSE
);
ALTER TABLE public.weather
  OWNER TO postgres;




create table zip_code (
   zip_code text not null,
   latitude numeric(18,6) not null,
   longitude numeric(18,6) not null,
   state text not null,
   city text not null,
   city_alias text not null,
   time_zone int not null,
   daylight_saving boolean not null
)




create table zip_codes_raw (
	zipcode text null,
	primaryrecord text null,
	population int null,
	householdsperzipcode int null,
	whitepopulation int null,
	blackpopulation int null,
	hispanicpopulation int null,
	asianpopulation int null,
	hawaiianpopulation smallint null,
	indianpopulation smallint null,
	otherpopulation int null,
	malepopulation int null,
	femalepopulation int null,
	personsperhousehold real null,
	averagehousevalue int null,
	incomeperhousehold int null,
	latitude real null,
	longitude real null,
	elevation smallint null,
	state text null,
	statefullname text null,
	citytype text null,
	cityaliasabbreviation text null,
	areacode text null,
	city text null,
	cityaliasname text null,
	county text null,
	countyfips smallint null,
	statefips smallint null,
	timezone smallint null,
	daylightsaving text null,
	msa smallint null,
	pmsa smallint null,
	csa smallint null,
	cbsa int null,
	cbsa_div int null,
	cbsa_type text null,
	cbsa_name text null,
	msa_name text null,
	pmsa_name text null,
	region text null,
	division text null,
	mailingname text null,
	preferredlastlinekey text null,
	classificationcode text null,
	multicounty text null,
	csaname text null,
	cbsa_div_name text null,
	citystatekey text null,
	cityaliascode text null,
	citymixedcase text null,
	cityaliasmixedcase text null,
	stateansi smallint null,
	countyansi smallint null,
	facilitycode text null,
	citydeliveryindicator text null,
	carrierrouteratesortation text null,
	financenumber int null,
	uniquezipname text null,
	id int not null,
	is_valid bit null
)




