Modification des couches de référence
==============

Changement des limites du territoire
------------

Copier les fichiers du shapefile des limites du territoire ``monterritoire.shp`` dans le répertoire ``/home/MYUSERLINUX/atlas/data/ref/`` (changer ``MYUSERLINUX`` par le nom de l'utilsateur linux).

Se placer dans le répertoire ``/home/MYUSERLINUX/atlas`` et lancer la commande shell :

``ogr2ogr -f "ESRI Shapefile" -t_srs EPSG:3857 data/ref/monterritoire_3857.shp /home/MYUSERLINUX/atlas/data/ref/monterritoire.shp``


En BD :

``TRUNCATE TABLE  atlas.t_layer_territoire;``

Lancer la commande shell :

``sudo -n -u postgres -s shp2pgsql -W "LATIN1" -s 3857 -D -I data/ref/monterritoire_3857.shp atlas.t_layer_territoire | sudo -n -u postgres -s psql -d geonatureatlas``

En BD :

``ALTER TABLE atlas.t_layer_territoire OWNER TO "geonatuser";``

``ALTER TABLE atlas.t_layer_territoire RENAME COLUMN geom TO the_geom;``

``CREATE INDEX index_gist_t_layer_territoire ON atlas.t_layer_territoire USING gist(the_geom);``

Lancer la commande shell :

``ogr2ogr -f "GeoJSON" -t_srs "EPSG:4326" ./static/custom/terrtoire.json /home/MYUSERLINUX/atlas/data/ref/monterrtoire.shp``


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






