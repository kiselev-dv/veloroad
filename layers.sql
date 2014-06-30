--(select way,place,name from planet_osm_polygon where place in ('village', 'town', 'city')) as placep
--select geometry, tags->'place', tags->'name' from polygons where tags->'place' in ('village', 'town', 'city')

create table placep (
	geom geometry('MultiPolygon'),
	place text,
	name text
);

insert into placep select geometry, tags->'place', tags->'name' from polygons where tags->'place' in ('village', 'town', 'city');
----

--select way from planet_osm_polygon where \"natural\"='wood' or landuse = 'forest' or leisure='park') as forest
--select geometry from polygons where tags->'natural'='wood' or tags->'landuse' = 'forest' or tags->'leisure'='park'

create table forest (
	geom geometry('MultiPolygon')	
);

insert into forest select geometry from polygons where tags->'natural'='wood' or tags->'landuse' = 'forest' or tags->'leisure'='park';
----

--(select way from planet_osm_polygon where landuse in ('residential', 'commercial', 'industrial', 'farmyard') or amenity is not null or power is not null) as landuse
--select geometry, coalesce(tags->'landuse', tags->'amenity', tags->'power') from polygons where tags->'landuse' in ('residential', 'commercial', 'industrial', 'farmyard') or tags?'amenity' or tags?'power'
create table landuse (
	geom geometry('MultiPolygon'),	
  landuse text
);

insert into landuse select geometry, coalesce(tags->'landuse', tags->'amenity', tags->'power') from polygons where tags->'landuse' in ('residential', 'commercial', 'industrial', 'farmyard') or tags?'amenity' or tags?'power';
----

--(select way,waterway,name,ST_Length(way) as length from planet_osm_line where waterway in ('stream', 'river','drain','ditch','canal') and tunnel is null) as rivers
--select linestring, tags->'waterway', tags->'name', ST_Length(linestring) as length from ways where tags->'waterway' in ('stream', 'river','drain','ditch','canal') and not tags?'tunnel'
create table rivers (
	geom geometry('Linestring'),	
  waterway text,
  name text,
  length float
);

insert into rivers select linestring, tags->'waterway', tags->'name', ST_Length(linestring) as length from ways where tags->'waterway' in ('stream', 'river','drain','ditch','canal') and not tags?'tunnel';
-----

(select way,name,way_area from planet_osm_polygon where \"natural\"='water' or waterway='riverbank') as lakes

(select way,admin_level from planet_osm_roads where admin_level in ('6', '4', '2')) as admin

(select way,admin_level from planet_osm_roads where admin_level in ('4', '2')) as admin

(select way from planet_osm_polygon where building is not null) as buildings

(select way from planet_osm_line where power='line') as power

(select way, railway from planet_osm_line where railway in ('rail', 'narrow_gauge') and service is null and tunnel is null)

(select way, highway,(case when living_street is not null or service is not null then 1 else 0 end) as service from planet_osm_line where highway in ('path', 'cycleway', 'footway', 'service', 'track','pedestrian','living_street','residential', 'unclassified', 'tertiary', 'secondary', 'primary', 'trunk', 'motorway', 'tertiary_link', 'secondary_link', 'primary_link', 'trunk_link', 'motorway_link') and tunnel in ('yes', 'true', '1') order by z_order) as tunnels

(select way, highway,(case when living_street is not null or service is not null then 1 else 0 end) as service from planet_osm_line where highway in ('path', 'cycleway', 'footway', 'service', 'track','pedestrian','living_street','residential', 'unclassified', 'tertiary', 'secondary', 'primary', 'trunk', 'motorway', 'tertiary_link', 'secondary_link', 'primary_link', 'trunk_link', 'motorway_link') and (bridge is null or not bridge in ('yes', 'true', '1')) and (tunnel is null or not tunnel in ('yes', 'true', '1')) order by z_order) as highways

(select way, highway,(case when living_street is not null or service is not null then 1 else 0 end) as service from planet_osm_line where highway in ('path', 'cycleway', 'footway', 'service', 'track','pedestrian','living_street','residential', 'unclassified', 'tertiary', 'secondary', 'primary', 'trunk', 'motorway', 'tertiary_link', 'secondary_link', 'primary_link', 'trunk_link', 'motorway_link') and bridge in ('yes', 'true', '1') order by z_order) as bridges

(select way,name from planet_osm_point where railway='subway_entrance') as subway

(select way,place,coalesce(\"name:ru\", name) as name,(case when place='city' then 9 when place='town' then 8 when place='village' then 7 when place='hamlet' then 6 when place='suburb' then 5 when place='locality' then 4 when place in ('isolated_dwelling', 'allotments') then 3 else 0 end) as p_order, (case when coalesce(population, '')~E'^\\\\d+$' then population::int else 0 end) as pop from planet_osm_point where place in ('village', 'town', 'city', 'hamlet', 'suburb', 'locality', 'isolated_dwelling', 'island', 'allotments') order by p_order desc, pop desc) as places

(select way,railway,station,coalesce(\"name:ru\", name) as name,length(coalesce(\"name:ru\", name)) as len,(select 90+degrees(ST_Azimuth(ST_StartPoint(inter), ST_EndPoint(inter))) from (select ST_Intersection(r.way, ST_Buffer(p.way, 100)) as inter from planet_osm_line r where r.railway in ('rail', 'narrow_gauge') and r.way && ST_Buffer(p.way, 100) order by ST_Distance(r.way, p.way) limit 1) rr) as angle from planet_osm_point p where railway in ('station', 'halt') and (station is null or (station != 'subway' and station != 'disused'))) as stations

(select way, highway,(case when ref = 'А-118' then 'КАД' when length(ref) <= 5 then ref else null end) as ref,name from planet_osm_line where highway in ('tertiary', 'secondary', 'primary', 'trunk', 'motorway')) as highwaysh

(select way,waterway,name from planet_osm_line where waterway in ('river', 'canal') and tunnel is null) as rivers

(select * from (select ST_LineMerge(ST_Union(way)) as way, replace(replace(replace(replace(name, 'набережная', 'наб.'), 'улица', 'ул.'), 'проспект', 'пр.'), 'переулок', 'пер.') as name from (select way,name from planet_osm_line where highway in ('tertiary', 'secondary', 'primary') and way && ST_Expand(!bbox!, 0.1)) p group by name) pp order by ST_Length(way) desc) as highwaysl

(select way,way_area, name from planet_osm_polygon where leisure = 'park') as wol

(select place, name, ST_PointOnSurface(way) as way, way_area from planet_osm_polygon where place='island' order by way_area desc) as islands

(select way,way_area,replace(name,'озеро', 'оз.') as name from planet_osm_polygon where \"natural\" = 'water' and (water is null or water != 'river')) as wol

(select id+1 as id, (case when id<n or id>n*2+1 or (id-n > 1 and id < n*2) then '' when id < n*2 then cast((id-n)*scale as text) when id=n*2 then (n*scale)||' км' else 'Карта © OpenStreetMap' end) as label, id%2 as id2,\n(case when id < n then ST_MakeLine(st_project(st_project(pt, 1000*scale*n/2, -pi()/2), 1000*scale*id, pi()/2)::geometry,\nst_project(st_project(pt, 1000*scale*n/2, -pi()/2), 1000*scale*(id+1), pi()/2)::geometry)\nwhen id <= n*2 then st_project(st_project(pt, 1000*scale*n/2, -pi()/2), 1000*scale*(id-n), pi()/2)::geometry\nelse pt\nend) as way\nfrom\n(select 5 as n, 1 as scale, ST_SetSRID(ST_Point(30, 60), 4326) as pt) d,\ngenerate_series(0, 11) id) as scale

