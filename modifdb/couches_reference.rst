Modification des couches de référence
==============




Dans le répertoire ``/home/MYUSERLINUX/atlas/data/ref/`` (changer ``MYUSERLINUX`` par le nom de l'utilsateur linux), copier :

	- les fichiers du shapefile des limites du territoire ``monterritoire.shp`` 

	- les fichiers du shapefile des limites des communes ``mescommunes.shp``



Se placer dans le répertoire ``/home/MYUSERLINUX/atlas`` et lancer les commandes shell :

``ogr2ogr -f "ESRI Shapefile" -t_srs EPSG:3857 data/ref/monterritoire_3857.shp /home/MYUSERLINUX/atlas/data/ref/monterritoire.shp``







En BD :

``TRUNCATE TABLE atlas.t_layer_territoire;``

Lancer la commande shell :

``sudo -n -u postgres -s shp2pgsql -W "LATIN1" -s 3857 -D -I data/ref/monterritoire_3857.shp atlas.t_layer_territoire | sudo -n -u postgres -s psql -d geonatureatlas``

En BD :

``ALTER TABLE atlas.t_layer_territoire OWNER TO "geonatuser";``

``ALTER TABLE atlas.t_layer_territoire RENAME COLUMN geom TO the_geom;``

``CREATE INDEX index_gist_t_layer_territoire ON atlas.t_layer_territoire USING gist(the_geom);``

Lancer la commande shell :

``ogr2ogr -f "GeoJSON" -t_srs "EPSG:4326" ./static/custom/territoire.json /home/MYUSERLINUX/atlas/data/ref/monterritoire.shp``


Changement des communes
------------

Copier les fichiers du shapefile des limites des communes ``mescommunes.shp`` dans le répertoire ``/home/MYUSERLINUX/atlas/data/ref/`` (changer ``MYUSERLINUX`` par le nom de l'utilsateur linux).

Lancer la commande shell :

``ogr2ogr -f "ESRI Shapefile" -t_srs EPSG:3857 data/ref/communes_3857.shp /home/MYUSERLINUX/atlas/data/ref/mescommunes.shp``

En BD :

``TRUNCATE TABLE  atlas.l_communes;``

Lancer la commande shell :

``sudo -n -u postgres -s shp2pgsql -W "LATIN1" -s 3857 -D -I ./data/ref/communes_3857.shp atlas.l_communes | sudo -n -u postgres -s psql -d geonatureatlas``

En BD :

``ALTER TABLE atlas.l_communes RENAME COLUMN "nom_comm" TO commune_maj;``

``ALTER TABLE atlas.l_communes RENAME COLUMN  "insee_comm" TO insee;``

``ALTER TABLE atlas.l_communes RENAME COLUMN geom TO the_geom;``

``CREATE INDEX index_gist_t_layers_communes ON atlas.l_communes USING gist (the_geom);``

``ALTER TABLE atlas.l_communes OWNER TO "geonatuser";``


Changement des mailles
------------

Creation de la table atlas.t_mailles_territoire avec la taille de maille désirée (5 dans cet exemple). Pour cela on intersecte toutes les mailles avec le territoire.

En BD :

``TRUNCATE TABLE  atlas.t_mailles_territoire;

``CREATE TABLE atlas.t_mailles_territoire as SELECT m.geom AS the_geom, ST_AsGeoJSON(st_transform(m.geom, 4326)) as geojson_maille FROM atlas.t_mailles_5 m, atlas.t_layer_territoire t WHERE ST_Intersects(m.geom, t.the_geom);``

``CREATE INDEX index_gist_t_mailles_territoire ON atlas.t_mailles_territoire USING gist (the_geom);``

``ALTER TABLE atlas.t_mailles_territoire ADD COLUMN id_maille serial;``

``ALTER TABLE atlas.t_mailles_territoire ADD PRIMARY KEY (id_maille);``

``ALTER TABLE atlas.t_mailles_territoire OWNER TO "geonatuser";``























Changement des limites du territoire
------------

Copier les fichiers du shapefile des limites du territoire ``monterritoire.shp`` dans le répertoire ``/home/MYUSERLINUX/atlas/data/ref/`` (changer ``MYUSERLINUX`` par le nom de l'utilsateur linux). **Le shapefile doit avoir la mme structure que la table atlas.t_layer_territoire**

Se placer dans le répertoire ``/home/MYUSERLINUX/atlas`` et lancer la commande shell :

``ogr2ogr -f "ESRI Shapefile" -t_srs EPSG:3857 data/ref/monterritoire_3857.shp /home/MYUSERLINUX/atlas/data/ref/monterritoire.shp``


En BD :

``TRUNCATE TABLE  atlas.t_layer_territoire;``

``ALTER TABLE atlas.t_layer_territoire RENAME COLUMN the_geom TO geom;``


Lancer la commande shell :

``sudo -n -u postgres -s shp2pgsql -a -W "LATIN1" -s 3857 -D -I data/ref/monterritoire_3857.shp atlas.t_layer_territoire | sudo -n -u postgres -s psql -d geonatureatlas``

En BD :

``ALTER TABLE atlas.t_layer_territoire RENAME COLUMN geom TO the_geom;``

``REINDEX TABLE atlas.t_layer_territoire;``


Lancer la commande shell :

``ogr2ogr -f "GeoJSON" -t_srs "EPSG:4326" ./static/custom/territoire.json /home/MYUSERLINUX/atlas/data/ref/monterrtoire.shp``






Rafraichissement des données
------------

Raraichissement des vues matérialisées pour quelles prennent en compte les nouvelles limites de territoire, communes et mailles.

En BD :

``REFRESH MATERIALIZED VIEW atlas.vm_observations;``

``REFRESH MATERIALIZED VIEW atlas.vm_observations_mailles;``

``REFRESH MATERIALIZED VIEW atlas.vm_mois;``

``REFRESH MATERIALIZED VIEW atlas.vm_altitudes;``

``REFRESH MATERIALIZED VIEW atlas.vm_taxons;``

``REFRESH MATERIALIZED VIEW atlas.vm_search_taxon;``

``REFRESH MATERIALIZED VIEW atlas.vm_taxons_plus_observes;``

``REFRESH MATERIALIZED VIEW atlas.vm_communes;``

**Si la requête de rafraichissement de la vm_communes est trop longue à l'exécussion, recréer la VM sans la jointure sur le territoire. ATTENTION alors à n'avoir importer QUE les communes comprises dans l'emprise du territoire**

``DROP MATERIALIZED VIEW atlas.vm_communes;``

``CREATE MATERIALIZED VIEW atlas.vm_communes AS SELECT c.insee, c.commune_maj, c.the_geom, st_asgeojson(st_transform(c.the_geom, 4326)) AS commune_geojson FROM atlas.l_communes c WITH DATA;``

``ALTER TABLE atlas.vm_communes OWNER TO geonatuser;``

``GRANT ALL ON TABLE atlas.vm_communes TO geonatuser;``

``GRANT SELECT ON TABLE atlas.vm_communes TO geonatatlas;``

``CREATE INDEX index_gist_vm_communes_the_geom ON atlas.vm_communes USING gist (the_geom);``

``CREATE UNIQUE INDEX vm_communes_insee_idx ON atlas.vm_communes USING btree (insee COLLATE pg_catalog."default");``

