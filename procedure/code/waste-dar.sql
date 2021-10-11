```
Pollution Pathways: Waste Sites and Impervious Surfaces in Dar es Salaam
Data from the ResilienceAcademy (https://resilienceacademy.ac.tz/data/) and OpenStreetMap (https://www.openstreetmap.org/#map=12/-6.8162/39.2203)

Emma Waugh
Open Source GIScience
October 2021
```

/* PART (1) impervious surface density */
/* select all paved roads from OSM roads data */
CREATE TABLE impervroads
AS
SELECT osm_id, way
FROM planet_osm_roads
WHERE surface = 'paved' OR surface = 'asphalt';

/* select all paved surfaces and buildings from OSM polygon data */
CREATE TABLE impervpoly
AS
SELECT osm_id
FROM planet_osm_polygon
WHERE surface = 'paved' OR surface = 'asphalt' OR building = 'yes';

/* combine roads and polygons, while also buffering roads and reprojecting both */
/* 10m (5m buffer both directions) was determined as a reasonable size for a road based on visual inspection via satellite imagery */
CREATE TABLE impervsurf
AS
SELECT osm_id, st_buffer(st_transform(way, 32737), 5)::geometry(multipolygon,32737) AS geom FROM impervroads
UNION
SELECT osm_id, st_transform(way, 32737)::geometry(multipolygon,32737) AS geom FROM impervpoly;

/* reproject wards shapefile to 32737 to make it compatible with impervsurf */
CREATE TABLE wards_repro
AS
SELECT wards.id, wards.ward_name, wards.totalpop, st_transform(geom, 32737)::geometry(multipolygon, 32737) AS geom FROM wards;

/* join impervious surface data to wards geometry using st_intersects */
/* (inner join to make sure theyre all inside ward boundaries) */
/* st_multi() used to make geometry type match column type, which is multipolygon in this case */
CREATE TABLE impervsurf_withward
AS
SELECT impervsurf2.osm_id, st_multi(st_intersection(impervsurf2.geom, wards_repro.geom))::geometry(multipolygon, 32737) AS geom, wards_repro.ward_name
FROM impervsurf2 INNER JOIN wards_repro
ON st_intersects(impervsurf2.geom, wards_repro.geom);

/* aggregate (dissolve) geometries by ward, creating a multipart feature for each ward */
CREATE TABLE impervsurf_byward
AS
SELECT ward_name, st_union(impervsurf_withward.geom)::geometry(multipolygon, 32737) AS geom
FROM impervsurf_withward
GROUP BY ward_name;

/* calculate total area of impervious surfaces by ward */
ALTER TABLE impervsurf_byward
ADD COLUMN impervarea int;

UPDATE impervsurf_byward
SET impervarea = st_area(geom);

/* join impervious surface data back to original ward geometry */
ALTER TABLE wards_repro
ADD COLUMN impervarea int;

UPDATE wards_repro
SET impervarea = impervsurf_byward.impervarea
FROM impervsurf_byward
WHERE impervsurf_byward.ward_name = wards_repro.ward_name;

/* calculate proportion of impervious surface area by ward */
ALTER TABLE wards_repro
ADD COLUMN propimperv real;

UPDATE wards_repro
SET propimperv = impervarea / st_area(geom)::real;

/* PART (2) waste site density */
/* select all waste sites, including name and info about cleanup method */
CREATE TABLE waste_repro
AS
SELECT waste.waste_site, waste.clean_up_m, st_transform(waste.geom, 32737)::geometry(point, 32737) AS geom FROM waste;

/* join waste sites data to wards geometry */
CREATE TABLE waste_withward
AS
SELECT wards_repro.ward_name, waste_repro.waste_site, waste_repro.clean_up_m, st_multi(waste_repro.geom)::geometry(multipoint, 32737) AS geom, wards_repro
FROM waste_repro INNER JOIN wards_repro
ON st_intersects(waste_repro.geom, wards_repro.geom);

/* aggregate geometries by wards, counting waste sites. st_multi() used to make geometry type match column type, which is multipoint in this case */
CREATE TABLE waste_byward
AS
SELECT ward_name, st_multi(st_union(waste_withward.geom))::geometry(multipoint, 32737) AS geom, count(ward_name)
FROM waste_withward
GROUP BY ward_name;

/* join waste site info back to original ward geometry */
ALTER TABLE wards_repro
ADD COLUMN wastecount int;

UPDATE wards_repro
SET wastecount = waste_byward.count
FROM waste_byward
WHERE waste_byward.ward_name = wards_repro.ward_name;

/* calculate waste site density by ward */
ALTER TABLE wards_repro
ADD COLUMN waste_density real;

UPDATE wards_repro
SET waste_density = wastecount / st_area(geom)::real;
