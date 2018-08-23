--drop table truck_dwdh;
--create table truck_dwdh as
alter table truck_dwdh
add column if not exists pmp_truck_dwdh_2015 numeric;

with determine_delay_hours as(
select i.*,
case when (i.tmc_code = t.tmc)
	then t.miles
	else o.miles
	end as miles,
o.aadt,

case when (i.reference_speed*0.75 > i.speed)
  THEN (1/6)
  ELSE 0
end as delay_hours,
o.geom
from tmacog_tmcs as o
full outer join npmrds2012to2016truck10min_no_null as i
on o.tmc = i.tmc_code
full join tmc_identification as t on t.tmc = i.tmc_code
--where i.cvalue > 10
--where date_part('hour', measurement_tstamp)  =  --and date_part('hour', measurement_tstamp)  <= 14
),
pmp_truck_dwdh_2015 as
(select
tmc_code,
round(sum(delay_hours*miles),2) as pmp_truck_dwdh_2015
from determine_delay_hours
where (date_part('hour', measurement_tstamp)  > 13 and date_part('hour', measurement_tstamp)  < 18 ) and
(extract(dow from measurement_tstamp )>0 and extract(dow from measurement_tstamp ) < 6) and --Mon-Fri
date_part('year', measurement_tstamp) = 2015
group by tmc_code
)

--for pm Peak 2-6PM

update truck_dwdh as cl
set pmp_truck_dwdh_2015 = pmp_truck_dwdh_2015.pmp_truck_dwdh_2015
from pmp_truck_dwdh_2015
where cl.tmc_code = pmp_truck_dwdh_2015.tmc_code ;--and (date_part('hour', measurement_tstamp)  > 8 and date_part('hour', measurement_tstamp)  < 14);
