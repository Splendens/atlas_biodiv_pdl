Modification des couches de référence
==============

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


Changement des communes
------------

Copier les fichiers du shapefile des limites des communes ``mescommunes.shp`` dans le répertoire ``/home/MYUSERLINUX/atlas/data/ref/`` (changer ``MYUSERLINUX`` par le nom de l'utilsateur linux). **Le shapefile doit avoir la même structure que la table atlas.l_communes**

Lancer la commande shell :

``ogr2ogr -f "ESRI Shapefile" -t_srs EPSG:3857 data/ref/communes_3857.shp /home/MYUSERLINUX/atlas/data/ref/mescommunes.shp``

En BD :

``TRUNCATE TABLE  atlas.l_communes;``

``ALTER TABLE atlas.l_communes RENAME COLUMN "the_geom" TO "geom";``

``ALTER TABLE atlas.l_communes RENAME COLUMN "commune_maj" TO "nom_comm";``

``ALTER TABLE atlas.l_communes RENAME COLUMN  "insee_comm" TO "insee";``


Lancer la commande shell :

``sudo -n -u postgres -s shp2pgsql -a -W "LATIN1" -s 3857 -D -I ./data/ref/communes_3857.shp atlas.l_communes | sudo -n -u postgres -s psql -d geonatureatlas``

En BD :

``ALTER TABLE atlas.l_communes RENAME COLUMN "nom_comm" TO "commune_maj";``

``ALTER TABLE atlas.l_communes RENAME COLUMN  "insee_comm" TO "insee";``

``ALTER TABLE atlas.l_communes RENAME COLUMN "geom" TO "the_geom";``

``REINDEX TABLE atlas.l_communes;``



Changement des mailles
------------

Peuplement de la table atlas.t_mailles_territoire avec les mailles, de la taille désirée (5km dans cet exemple); correspondant aux mailles présentes dans l'emprise du territoire. Pour cela on intersecte toutes les mailles de 5km avec le territoire.

En BD :

``TRUNCATE TABLE  atlas.t_mailles_territoire;``

``INSERT INTO atlas.t_mailles_territoire SELECT m.geom AS the_geom, ST_AsGeoJSON(st_transform(m.geom, 4326)) as geojson_maille FROM atlas.t_mailles_5 m, atlas.t_layer_territoire t WHERE ST_Intersects(m.geom, t.the_geom);``

``REINDEX TABLE atlas.t_mailles_territoire;``



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

