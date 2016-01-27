-- Looking at the package data, we find a handful (416 out of several million) that appear to be duplicated.
-- Choose one of the duplicates (the one with the smaller ID value) to get rid of.  We have to delete the associated
-- activities records because of the foreign key we set up.
delete from activities where packageid in (select min(id) from packages group by trackingnumber having count(*) > 1);
delete from packages where id in (select min(id) from packages group by trackingnumber having count(*) > 1);

-- clean up the zip code table
insert into zip_code
select trim(upper(zipcode)), latitude::numeric(18,6), longitude::numeric(18,6), trim(upper(state)), trim(upper(city)), trim(upper(cityaliasname)), timezone, (case when daylightsaving = 'Y' then true else false end)
from zip_codes_raw;



