--VUES MATERIALISEES--

--Copie du contenu de taxref (à partir du schéma taxonomie de TaxHub)

--DROP materialized view taxonomie.vm_taxref;
CREATE materialized view atlas.vm_taxref AS
SELECT * FROM taxonomie.taxref;
create unique index on atlas.vm_taxref (cd_nom);
create index on atlas.vm_taxref (cd_ref);
create index on atlas.vm_taxref (cd_taxsup);
create index on atlas.vm_taxref (lb_nom);
create index on atlas.vm_taxref (nom_complet);
create index on atlas.vm_taxref (nom_valide);



--Tous les organismes

--DROP MATERIALIZED VIEW atlas.vm_organismes;
CREATE MATERIALIZED VIEW atlas.vm_organismes AS 
 SELECT o.id_organisme,
    o.nom_organisme
   FROM synthese.bib_organismes o;
create unique index on atlas.vm_organismes (id_organisme);



--Toutes les observations

--DROP materialized view atlas.vm_observations;
CREATE MATERIALIZED VIEW atlas.vm_observations AS
    SELECT s.id_synthese AS id_observation,
        s.insee,
        s.dateobs,
        s.observateurs,
        s.id_organisme,
        s.altitude_retenue,
        s.the_geom_point::geometry('POINT',3857),
        s.effectif_total,
        tx.cd_ref,
        st_asgeojson(ST_Transform(ST_SetSrid(s.the_geom_point, 3857), 4326)) as geojson_point
    FROM synthese.syntheseff s
    LEFT JOIN atlas.vm_taxref tx ON tx.cd_nom = s.cd_nom
    JOIN atlas.t_layer_territoire m ON ST_Intersects(m.the_geom, s.the_geom_point)
    WHERE s.supprime = FALSE
    AND s.diffusable = TRUE;

create unique index on atlas.vm_observations (id_observation);
create index on atlas.vm_observations (cd_ref);
create index on atlas.vm_observations (insee);
create index on atlas.vm_observations (altitude_retenue);
create index on atlas.vm_observations (dateobs);
CREATE INDEX index_gist_vm_observations_the_geom_point ON atlas.vm_observations USING gist (the_geom_point);


--Tous les taxons ayant au moins une observation

--DROP MATERIALIZED VIEW atlas.vm_taxons;
CREATE MATERIALIZED VIEW atlas.vm_taxons AS
 WITH obs_min_taxons AS (
         SELECT vm_observations.cd_ref,
            min(date_part('year'::text, vm_observations.dateobs)) AS yearmin,
            max(date_part('year'::text, vm_observations.dateobs)) AS yearmax,
            COUNT(vm_observations.id_observation) AS nb_obs
           FROM atlas.vm_observations
          GROUP BY vm_observations.cd_ref
        ), tx_ref AS (
         SELECT tx_1.cd_ref,
            tx_1.regne,
            tx_1.phylum,
            tx_1.classe,
            tx_1.ordre,
            tx_1.famille,
            tx_1.cd_taxsup,
            tx_1.lb_nom,
            tx_1.lb_auteur,
            tx_1.nom_complet,
            tx_1.nom_valide,
            tx_1.nom_vern,
            tx_1.nom_vern_eng,
            tx_1.group1_inpn,
            tx_1.group2_inpn,
            tx_1.nom_complet_html,
            tx_1.id_rang
           FROM atlas.vm_taxref tx_1
          WHERE (tx_1.cd_ref IN ( SELECT obs_min_taxons.cd_ref
                   FROM obs_min_taxons)) AND tx_1.cd_nom = tx_1.cd_ref
        ), my_taxons AS (
         SELECT DISTINCT n.cd_ref,
            pat.valeur_attribut AS patrimonial,
            pr.valeur_attribut  AS protection_stricte
           FROM tx_ref n
             LEFT JOIN taxonomie.cor_taxon_attribut pat ON pat.cd_ref = n.cd_ref AND pat.id_attribut = 1
             LEFT JOIN taxonomie.cor_taxon_attribut pr ON pr.cd_ref = n.cd_ref AND pr.id_attribut = 2
          WHERE n.cd_ref IN ( SELECT obs_min_taxons.cd_ref
                   FROM obs_min_taxons)
        )
 SELECT tx.cd_ref,
    tx.regne,
    tx.phylum,
    tx.classe,
    tx.ordre,
    tx.famille,
    tx.cd_taxsup,
    tx.lb_nom,
    tx.lb_auteur,
    tx.nom_complet,
    tx.nom_valide,
    tx.nom_vern,
    tx.nom_vern_eng,
    tx.group1_inpn,
    tx.group2_inpn,
    tx.nom_complet_html,
    tx.id_rang,
    t.patrimonial,
    t.protection_stricte,
    omt.yearmin,
    omt.yearmax,
    omt.nb_obs
   FROM tx_ref tx
     LEFT JOIN obs_min_taxons omt ON omt.cd_ref = tx.cd_ref
     LEFT JOIN my_taxons t ON t.cd_ref = tx.cd_ref
WITH DATA;
CREATE UNIQUE INDEX ON atlas.vm_taxons (cd_ref);

--Classes d'altitudes, modifiables selon votre contexte

--DROP TABLE atlas.bib_altitudes;
CREATE TABLE atlas.bib_altitudes
(
  id_altitude integer NOT NULL,
  altitude_min integer NOT NULL,
  altitude_max integer NOT NULL,
  label_altitude character varying(255),
  CONSTRAINT bib_altitudes_pk PRIMARY KEY (id_altitude)
);

INSERT INTO atlas.bib_altitudes VALUES(1,0,499);
INSERT INTO atlas.bib_altitudes VALUES(2,500,999);
INSERT INTO atlas.bib_altitudes VALUES(3,1000,1499);
INSERT INTO atlas.bib_altitudes VALUES(4,1500,1999);
INSERT INTO atlas.bib_altitudes VALUES(5,2000,2499);
INSERT INTO atlas.bib_altitudes VALUES(6,2500,2999);
INSERT INTO atlas.bib_altitudes VALUES(7,3000,3499);
INSERT INTO atlas.bib_altitudes VALUES(8,3500,3999);
INSERT INTO atlas.bib_altitudes VALUES(9,4000,4102);
UPDATE atlas.bib_altitudes set label_altitude = '_' || altitude_min || '_' || altitude_max+1;


-- Fonction qui permet de créer la VM contenant le nombre d'observations par classes d'altitude pour chaque taxon

-- DROP FUNCTION atlas.create_vm_altitudes();

CREATE OR REPLACE FUNCTION atlas.create_vm_altitudes()
  RETURNS text AS
$BODY$
  DECLARE
    monsql text;
    mesaltitudes RECORD;

  BEGIN
    DROP MATERIALIZED VIEW IF EXISTS atlas.vm_altitudes;

    monsql = 'CREATE materialized view atlas.vm_altitudes AS WITH ';

    FOR mesaltitudes IN SELECT * FROM atlas.bib_altitudes ORDER BY id_altitude LOOP
      IF mesaltitudes.id_altitude = 1 THEN
        monsql = monsql || 'alt' || mesaltitudes.id_altitude ||' AS (SELECT cd_ref, count(*) as nb FROM atlas.vm_observations WHERE altitude_retenue <' || mesaltitudes.altitude_max || ' GROUP BY cd_ref) ';
      ELSE
        monsql = monsql || ',alt' || mesaltitudes.id_altitude ||' AS (SELECT cd_ref, count(*) as nb FROM atlas.vm_observations WHERE altitude_retenue BETWEEN ' || mesaltitudes.altitude_min || ' AND ' || mesaltitudes.altitude_max || ' GROUP BY cd_ref)';
      END IF;
    END LOOP;

    monsql = monsql || ' SELECT DISTINCT o.cd_ref';

    FOR mesaltitudes IN SELECT * FROM atlas.bib_altitudes LOOP
      monsql = monsql || ',COALESCE(a' ||mesaltitudes.id_altitude || '.nb::integer, 0) as '|| mesaltitudes.label_altitude;
    END LOOP;

    monsql = monsql || ' FROM atlas.vm_observations o';

    FOR mesaltitudes IN SELECT * FROM atlas.bib_altitudes LOOP
      monsql = monsql || ' LEFT JOIN alt' || mesaltitudes.id_altitude ||' a' || mesaltitudes.id_altitude || ' ON a' || mesaltitudes.id_altitude || '.cd_ref = o.cd_ref';
    END LOOP;

    monsql = monsql || ' WHERE o.cd_ref is not null ORDER BY o.cd_ref;';

    EXECUTE monsql;
    create unique index on atlas.vm_altitudes (cd_ref);

    RETURN monsql;

  END;

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

select atlas.create_vm_altitudes();


-- Taxons observés et de tous leurs synonymes (utilisés pour la recherche d'une espèce)

CREATE MATERIALIZED VIEW atlas.vm_search_taxon AS
SELECT tx.cd_nom, tx.cd_ref, COALESCE(tx.lb_nom || ' | ' || tx.nom_vern, tx.lb_nom) AS nom_search FROM atlas.vm_taxref tx JOIN atlas.vm_taxons t ON t.cd_ref = tx.cd_ref;
create UNIQUE index on atlas.vm_search_taxon(cd_nom);
create index on atlas.vm_search_taxon(cd_ref);
create index on atlas.vm_search_taxon(nom_search);


-- Nombre d'observations mensuelles pour chaque taxon observé

CREATE materialized view atlas.vm_mois AS
WITH
_01 AS (SELECT cd_ref, count(*) as nb FROM atlas.vm_observations WHERE date_part('month'::text, dateobs) = '01' GROUP BY cd_ref),
_02 AS (SELECT cd_ref, count(*) as nb FROM atlas.vm_observations WHERE date_part('month'::text, dateobs) = '02' GROUP BY cd_ref),
_03 AS (SELECT cd_ref, count(*) as nb FROM atlas.vm_observations WHERE date_part('month'::text, dateobs) = '03' GROUP BY cd_ref),
_04 AS (SELECT cd_ref, count(*) as nb FROM atlas.vm_observations WHERE date_part('month'::text, dateobs) = '04' GROUP BY cd_ref),
_05 AS (SELECT cd_ref, count(*) as nb FROM atlas.vm_observations WHERE date_part('month'::text, dateobs) = '05' GROUP BY cd_ref),
_06 AS (SELECT cd_ref, count(*) as nb FROM atlas.vm_observations WHERE date_part('month'::text, dateobs) = '06' GROUP BY cd_ref),
_07 AS (SELECT cd_ref, count(*) as nb FROM atlas.vm_observations WHERE date_part('month'::text, dateobs) = '07' GROUP BY cd_ref),
_08 AS (SELECT cd_ref, count(*) as nb FROM atlas.vm_observations WHERE date_part('month'::text, dateobs) = '08' GROUP BY cd_ref),
_09 AS (SELECT cd_ref, count(*) as nb FROM atlas.vm_observations WHERE date_part('month'::text, dateobs) = '09' GROUP BY cd_ref),
_10 AS (SELECT cd_ref, count(*) as nb FROM atlas.vm_observations WHERE date_part('month'::text, dateobs) = '10' GROUP BY cd_ref),
_11 AS (SELECT cd_ref, count(*) as nb FROM atlas.vm_observations WHERE date_part('month'::text, dateobs) = '11' GROUP BY cd_ref),
_12 AS (SELECT cd_ref, count(*) as nb FROM atlas.vm_observations WHERE date_part('month'::text, dateobs) = '12' GROUP BY cd_ref)

SELECT DISTINCT o.cd_ref
  ,COALESCE(a.nb::integer, 0) as _01
  ,COALESCE(b.nb::integer, 0) as _02
  ,COALESCE(c.nb::integer, 0) as _03
  ,COALESCE(d.nb::integer, 0) as _04
  ,COALESCE(e.nb::integer, 0) as _05
  ,COALESCE(f.nb::integer, 0) as _06
  ,COALESCE(g.nb::integer, 0) as _07
  ,COALESCE(h.nb::integer, 0) as _08
  ,COALESCE(i.nb::integer, 0) as _09
  ,COALESCE(j.nb::integer, 0) as _10
  ,COALESCE(k.nb::integer, 0) as _11
  ,COALESCE(l.nb::integer, 0) as _12
FROM atlas.vm_observations o
LEFT JOIN _01 a ON a.cd_ref =  o.cd_ref
LEFT JOIN _02 b ON b.cd_ref =  o.cd_ref
LEFT JOIN _03 c ON c.cd_ref =  o.cd_ref
LEFT JOIN _04 d ON d.cd_ref =  o.cd_ref
LEFT JOIN _05 e ON e.cd_ref =  o.cd_ref
LEFT JOIN _06 f ON f.cd_ref =  o.cd_ref
LEFT JOIN _07 g ON g.cd_ref =  o.cd_ref
LEFT JOIN _08 h ON h.cd_ref =  o.cd_ref
LEFT JOIN _09 i ON i.cd_ref =  o.cd_ref
LEFT JOIN _10 j ON j.cd_ref =  o.cd_ref
LEFT JOIN _11 k ON k.cd_ref =  o.cd_ref
LEFT JOIN _12 l ON l.cd_ref =  o.cd_ref
WHERE o.cd_ref is not null
ORDER BY o.cd_ref;
CREATE UNIQUE INDEX ON atlas.vm_mois (cd_ref);


-- Communes contenues entièrement dans le territoire

CREATE MATERIALIZED VIEW atlas.vm_communes AS
SELECT c.insee,
c.commune_maj,
c.the_geom,
st_asgeojson(st_transform(c.the_geom, 4326)) as commune_geojson
FROM atlas.l_communes c
JOIN atlas.t_layer_territoire t ON ST_CONTAINS(ST_BUFFER(t.the_geom,200), c.the_geom);

CREATE UNIQUE INDEX on atlas.vm_communes (insee);
CREATE INDEX index_gist_vm_communes_the_geom ON atlas.vm_communes USING gist (the_geom);


-- Rangs de taxref ordonnés

CREATE TABLE atlas.bib_taxref_rangs (
    id_rang character(4) NOT NULL,
    nom_rang character varying(20) NOT NULL,
    tri_rang integer
);
INSERT INTO atlas.bib_taxref_rangs (id_rang, nom_rang, tri_rang) VALUES ('Dumm', 'Domaine', 1);
INSERT INTO atlas.bib_taxref_rangs (id_rang, nom_rang, tri_rang) VALUES ('SPRG', 'Super-Règne', 2);
INSERT INTO atlas.bib_taxref_rangs  (id_rang, nom_rang, tri_rang) VALUES ('KD  ', 'Règne', 3);
INSERT INTO atlas.bib_taxref_rangs  (id_rang, nom_rang, tri_rang) VALUES ('SSRG', 'Sous-Règne', 4);
INSERT INTO atlas.bib_taxref_rangs  (id_rang, nom_rang, tri_rang) VALUES ('IFRG', 'Infra-Règne', 5);
INSERT INTO atlas.bib_taxref_rangs  (id_rang, nom_rang, tri_rang) VALUES ('PH  ', 'Embranchement', 6);
INSERT INTO atlas.bib_taxref_rangs  (id_rang, nom_rang, tri_rang) VALUES ('SBPH', 'Sous-Phylum', 7);
INSERT INTO atlas.bib_taxref_rangs  (id_rang, nom_rang, tri_rang) VALUES ('IFPH', 'Infra-Phylum', 8);
INSERT INTO atlas.bib_taxref_rangs  (id_rang, nom_rang, tri_rang) VALUES ('DV  ', 'Division', 9);
INSERT INTO atlas.bib_taxref_rangs  (id_rang, nom_rang, tri_rang) VALUES ('SBDV', 'Sous-division', 10);
INSERT INTO atlas.bib_taxref_rangs  (id_rang, nom_rang, tri_rang) VALUES ('SPCL', 'Super-Classe', 11);
INSERT INTO atlas.bib_taxref_rangs  (id_rang, nom_rang, tri_rang) VALUES ('CLAD', 'Cladus', 12);
INSERT INTO atlas.bib_taxref_rangs  (id_rang, nom_rang, tri_rang) VALUES ('CL  ', 'Classe', 13);
INSERT INTO atlas.bib_taxref_rangs  (id_rang, nom_rang, tri_rang) VALUES ('SBCL', 'Sous-Classe', 14);
INSERT INTO atlas.bib_taxref_rangs  (id_rang, nom_rang, tri_rang) VALUES ('IFCL', 'Infra-classe', 15);
INSERT INTO atlas.bib_taxref_rangs  (id_rang, nom_rang, tri_rang) VALUES ('LEG ', 'Legio', 16);
INSERT INTO atlas.bib_taxref_rangs  (id_rang, nom_rang, tri_rang) VALUES ('SPOR', 'Super-Ordre', 17);
INSERT INTO atlas.bib_taxref_rangs  (id_rang, nom_rang, tri_rang) VALUES ('COH ', 'Cohorte', 18);
INSERT INTO atlas.bib_taxref_rangs  (id_rang, nom_rang, tri_rang) VALUES ('OR  ', 'Ordre', 19);
INSERT INTO atlas.bib_taxref_rangs  (id_rang, nom_rang, tri_rang) VALUES ('SBOR', 'Sous-Ordre', 20);
INSERT INTO atlas.bib_taxref_rangs  (id_rang, nom_rang, tri_rang) VALUES ('IFOR', 'Infra-Ordre', 21);
INSERT INTO atlas.bib_taxref_rangs  (id_rang, nom_rang, tri_rang) VALUES ('SPFM', 'Super-Famille', 22);
INSERT INTO atlas.bib_taxref_rangs  (id_rang, nom_rang, tri_rang) VALUES ('FM  ', 'Famille', 23);
INSERT INTO atlas.bib_taxref_rangs  (id_rang, nom_rang, tri_rang) VALUES ('SBFM', 'Sous-Famille', 24);
INSERT INTO atlas.bib_taxref_rangs  (id_rang, nom_rang, tri_rang) VALUES ('TR  ', 'Tribu', 26);
INSERT INTO atlas.bib_taxref_rangs  (id_rang, nom_rang, tri_rang) VALUES ('SSTR', 'Sous-Tribu', 27);
INSERT INTO atlas.bib_taxref_rangs  (id_rang, nom_rang, tri_rang) VALUES ('GN  ', 'Genre', 28);
INSERT INTO atlas.bib_taxref_rangs  (id_rang, nom_rang, tri_rang) VALUES ('SSGN', 'Sous-Genre', 29);
INSERT INTO atlas.bib_taxref_rangs  (id_rang, nom_rang, tri_rang) VALUES ('SC  ', 'Section', 30);
INSERT INTO atlas.bib_taxref_rangs  (id_rang, nom_rang, tri_rang) VALUES ('SBSC', 'Sous-Section', 31);
INSERT INTO atlas.bib_taxref_rangs  (id_rang, nom_rang, tri_rang) VALUES ('SER', 'Série', 32);
INSERT INTO atlas.bib_taxref_rangs  (id_rang, nom_rang, tri_rang) VALUES ('SSER', 'Sous-Série', 33);
INSERT INTO atlas.bib_taxref_rangs  (id_rang, nom_rang, tri_rang) VALUES ('AGES', 'Agrégat', 34);
INSERT INTO atlas.bib_taxref_rangs  (id_rang, nom_rang, tri_rang) VALUES ('ES  ', 'Espèce', 35);
INSERT INTO atlas.bib_taxref_rangs  (id_rang, nom_rang, tri_rang) VALUES ('SMES', 'Semi-espèce', 36);
INSERT INTO atlas.bib_taxref_rangs  (id_rang, nom_rang, tri_rang) VALUES ('MES ', 'Micro-Espèce',37);
INSERT INTO atlas.bib_taxref_rangs  (id_rang, nom_rang, tri_rang) VALUES ('SSES', 'Sous-espèce', 38);
INSERT INTO atlas.bib_taxref_rangs  (id_rang, nom_rang, tri_rang) VALUES ('NAT ', 'Natio', 39);
INSERT INTO atlas.bib_taxref_rangs  (id_rang, nom_rang, tri_rang) VALUES ('VAR ', 'Variété', 40);
INSERT INTO atlas.bib_taxref_rangs  (id_rang, nom_rang, tri_rang) VALUES ('SVAR ', 'Sous-Variété', 41);
INSERT INTO atlas.bib_taxref_rangs  (id_rang, nom_rang, tri_rang) VALUES ('FO  ', 'Forme', 42);
INSERT INTO atlas.bib_taxref_rangs  (id_rang, nom_rang, tri_rang) VALUES ('SSFO', 'Sous-Forme', 43);
INSERT INTO atlas.bib_taxref_rangs  (id_rang, nom_rang, tri_rang) VALUES ('FOES', 'Forma species', 44);
INSERT INTO atlas.bib_taxref_rangs  (id_rang, nom_rang, tri_rang) VALUES ('LIN ', 'Linea', 45);
INSERT INTO atlas.bib_taxref_rangs  (id_rang, nom_rang, tri_rang) VALUES ('CLO ', 'Clône', 46);
INSERT INTO atlas.bib_taxref_rangs  (id_rang, nom_rang, tri_rang) VALUES ('RACE', 'Race', 47);
INSERT INTO atlas.bib_taxref_rangs  (id_rang, nom_rang, tri_rang) VALUES ('CAR ', 'Cultivar', 48);
INSERT INTO atlas.bib_taxref_rangs  (id_rang, nom_rang, tri_rang) VALUES ('MO  ', 'Morpha', 49);
INSERT INTO atlas.bib_taxref_rangs  (id_rang, nom_rang, tri_rang) VALUES ('AB  ', 'Abberatio',50);
--n'existe plus dans taxref V9
INSERT INTO atlas.bib_taxref_rangs  (id_rang, nom_rang) VALUES ('CVAR', 'Convariété');
INSERT INTO atlas.bib_taxref_rangs  (id_rang, nom_rang) VALUES ('HYB ', 'Hybride');
--non documenté dans la doc taxref
INSERT INTO atlas.bib_taxref_rangs  (id_rang, nom_rang, tri_rang) VALUES ('SPTR', 'Supra-Tribu', 25);
INSERT INTO atlas.bib_taxref_rangs  (id_rang, nom_rang) VALUES ('SCO ', '?');
INSERT INTO atlas.bib_taxref_rangs  (id_rang, nom_rang) VALUES ('PVOR', '?');
INSERT INTO atlas.bib_taxref_rangs  (id_rang, nom_rang) VALUES ('SSCO', '?');


-- Médias de chaque taxon

CREATE MATERIALIZED VIEW atlas.vm_medias AS
    SELECT id_media,
           cd_ref,
           titre,
           url,
           chemin,
           auteur,
           desc_media,
           date_media,
           id_type
   FROM taxonomie.t_medias;
CREATE UNIQUE INDEX ON atlas.vm_medias (id_media);


-- Attributs de chaque taxon (description, commentaire, milieu et chorologie)

CREATE MATERIALIZED VIEW atlas.vm_cor_taxon_attribut AS
    SELECT id_attribut,
           valeur_attribut,
           cd_ref
    FROM taxonomie.cor_taxon_attribut
    WHERE id_attribut IN (100, 101, 102, 103);
CREATE UNIQUE INDEX ON atlas.vm_cor_taxon_attribut (cd_ref,id_attribut);

-- 12 taxons les plus observés sur la période en cours (par défaut -15 jours +15 jours toutes années confondues)

CREATE MATERIALIZED VIEW atlas.vm_taxons_plus_observes AS
SELECT count(*) AS nb_obs,
  obs.cd_ref,
  tax.lb_nom,
  tax.group2_inpn,
  tax.nom_vern,
  m.id_media,
  m.url,
  m.chemin,
  m.id_type
 FROM atlas.vm_observations obs
   JOIN atlas.vm_taxons tax ON tax.cd_ref = obs.cd_ref
   LEFT JOIN atlas.vm_medias m ON m.cd_ref = obs.cd_ref AND m.id_type = 1
WHERE date_part('day'::text, obs.dateobs) >= date_part('day'::text, 'now'::text::date - 15) AND date_part('month'::text, obs.dateobs) = date_part('month'::text, 'now'::text::date - 15) OR date_part('day'::text, obs.dateobs) <= date_part('day'::text, 'now'::text::date + 15) AND date_part('month'::text, obs.dateobs) = date_part('day'::text, 'now'::text::date + 15)
GROUP BY obs.cd_ref, tax.lb_nom, tax.nom_vern, m.url, m.chemin, tax.group2_inpn, m.id_type, m.id_media
ORDER BY (count(*)) DESC
LIMIT 12;
-- DROP INDEX atlas.vm_taxons_plus_observes_cd_ref_idx;

CREATE UNIQUE INDEX vm_taxons_plus_observes_cd_ref_idx
  ON atlas.vm_taxons_plus_observes
  USING btree
  (cd_ref);


--Fonction qui permet de lister tous les taxons enfants d'un taxon

CREATE OR REPLACE FUNCTION atlas.find_all_taxons_childs(id integer)
  RETURNS SETOF integer AS
$BODY$
 --Param : cd_nom ou cd_ref d'un taxon quelque soit son rang
 --Retourne le cd_nom de tous les taxons enfants sous forme d'un jeu de données utilisable comme une table
 --Usage SELECT atlas.find_all_taxons_childs(197047);
 --ou SELECT * FROM atlas.vm_taxons WHERE cd_ref IN(SELECT * FROM atlas.find_all_taxons_childs(197047))
  DECLARE
    inf RECORD;
    c integer;
  BEGIN
    SELECT INTO c count(*) FROM atlas.vm_taxref WHERE cd_taxsup = id;
    IF c > 0 THEN
        FOR inf IN
      WITH RECURSIVE descendants AS (
        SELECT tx1.cd_nom FROM atlas.vm_taxref tx1 WHERE tx1.cd_taxsup = id
      UNION ALL
      SELECT tx2.cd_nom FROM descendants d JOIN atlas.vm_taxref tx2 ON tx2.cd_taxsup = d.cd_nom
      )
      SELECT cd_nom FROM descendants
  LOOP
      RETURN NEXT inf.cd_nom;
  END LOOP;
    END IF;
  END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100
  ROWS 1000;


--Fonction pour rafraichir toutes les vues matérialisées d'un schéma

--USAGE : SELECT RefreshAllMaterializedViews('atlas');
CREATE OR REPLACE FUNCTION RefreshAllMaterializedViews(schema_arg TEXT DEFAULT 'public')
RETURNS INT AS $$
DECLARE
    r RECORD;
BEGIN
    RAISE NOTICE 'Refreshing materialized view in schema %', schema_arg;
    FOR r IN SELECT matviewname FROM pg_matviews WHERE schemaname = schema_arg
    LOOP
        RAISE NOTICE 'Refreshing %.%', schema_arg, r.matviewname;
        --EXECUTE 'REFRESH MATERIALIZED VIEW ' || schema_arg || '.' || r.matviewname; --Si vous utilisez une version inférieure à PostgreSQL 9.4
        EXECUTE 'REFRESH MATERIALIZED VIEW CONCURRENTLY ' || schema_arg || '.' || r.matviewname;
    END LOOP;

    RETURN 1;
END
$$ LANGUAGE plpgsql;





/*******************************************/
/****** Atlas par mailles communales *******/
/*******************************************/

/* Communes simplifiées */
CREATE TABLE atlas.l_communes_simpli200 AS
with poly as (
        select insee, (st_dump(the_geom)).* 
        from atlas.l_communes
) select d.insee, baz.geom 
 from ( 
        select (st_dump(st_polygonize(distinct geom))).geom as geom
        from (
                select (st_dump(st_simplifyPreserveTopology(st_linemerge(st_union(geom)), 200))).geom as geom
                from (
                        select st_exteriorRing((st_dumpRings(geom)).geom) as geom
                        from poly
                ) as foo
        ) as bar
) as baz,
poly d
where st_intersects(d.geom, baz.geom)
and st_area(st_intersection(d.geom, baz.geom))/st_area(baz.geom) > 0.5;

ALTER TABLE atlas.l_communes_simpli200  OWNER TO geonatuser;
GRANT ALL ON TABLE atlas.l_communes_simpli200 TO geonatuser;
GRANT SELECT ON TABLE atlas.l_communes_simpli200 TO geonatatlas;


CREATE INDEX sidx_l_communes_simpli200 ON atlas.l_communes_simpli200 USING gist (geom);

/* VM observations par commune */
ALTER TABLE  atlas.l_communes_simpli400 ADD COLUMN geojson_commune text

UPDATE  atlas.l_communes_simpli400 a SET geojson_commune = ST_AsGeoJSON(st_transform(a.geom, 4326))


 ogr2ogr -f "GeoJSON" -t_srs "EPSG:4326" ./static/custom/territoire.json $limit_shp



CREATE TABLE atlas.l_communes_simpli AS
  SELECT
    insee,
    (st_union(geom)) as the_geom

  FROM atlas.l_communes_simpli400
  GROUP BY insee
WITH DATA;


ALTER TABLE atlas.l_communes_simpli  OWNER TO geonatuser;
GRANT ALL ON TABLE atlas.l_communes_simpli TO geonatuser;
GRANT SELECT ON TABLE atlas.l_communes_simpli TO geonatatlas;


/* VM observations par commune */
ALTER TABLE  atlas.l_communes_simpli ADD COLUMN geojson_commune text;

UPDATE  atlas.l_communes_simpli a SET geojson_commune = ST_AsGeoJSON(st_transform(a.the_geom, 4326));




-- Materialized View: atlas.vm_observations_communes

-- DROP MATERIALIZED VIEW atlas.vm_observations_communes;


CREATE MATERIALIZED VIEW atlas.vm_observations_communes AS 
 SELECT obs.cd_ref,
    obs.id_observation,
    c.insee,
    c.the_geom,
    c.geojson_commune
   FROM atlas.vm_observations obs
     JOIN atlas.l_communes_simpli c ON c.insee = obs.insee
WITH DATA;

ALTER TABLE atlas.vm_observations_communes OWNER TO geonatuser;
GRANT ALL ON TABLE atlas.vm_observations_communes TO geonatuser;
GRANT SELECT ON TABLE atlas.vm_observations_communes TO geonatatlas;


-- Index: atlas.index_gist_atlas_vm_observations_communes_geom

-- DROP INDEX atlas.index_gist_atlas_vm_observations_communes_geom;

CREATE INDEX index_gist_atlas_vm_observations_communes_geom
  ON atlas.vm_observations_communes
  USING gist
  (the_geom);

-- Index: atlas.vm_observations_communes_cd_ref_idx

-- DROP INDEX atlas.vm_observations_communes_cd_ref_idx;

CREATE INDEX vm_observations_communes_cd_ref_idx
  ON atlas.vm_observations_communes
  USING btree
  (cd_ref);

-- Index: atlas.vm_observations_communes_geojson_commune_idx

-- DROP INDEX atlas.vm_observations_communes_geojson_commune_idx;

/*CREATE INDEX vm_observations_communes_geojson_commune_idx
  ON atlas.vm_observations_communes
  USING btree
  (geojson_commune COLLATE pg_catalog."default");*/

-- Index: atlas.vm_observations_communes_insee_idx

-- DROP INDEX atlas.vm_observations_communes_insee_idx;

CREATE INDEX vm_observations_communes_insee_idx
  ON atlas.vm_observations_communes
  USING btree
  (insee);

-- Index: atlas.vm_observations_communes_id_observation_idx

-- DROP INDEX atlas.vm_observations_communes_id_observation_idx;

CREATE UNIQUE INDEX vm_observations_communes_id_observation_idx
  ON atlas.vm_observations_communes
  USING btree
  (id_observation);








/**************************************/
/****** STATISTIQUES POUR ATLAS *******/
/**************************************/



/* stats nb obs par structure pour chaque cd_ref */


-- Materialized View: atlas.vm_stats_orga_taxon
-- DROP MATERIALIZED VIEW atlas.vm_stats_orga_taxon;


CREATE MATERIALIZED VIEW atlas.vm_stats_orga_taxon AS 
 WITH 
        _03 AS /*CEN Pays de la Loire*/
        (
         SELECT vm_observations.cd_ref,
            count(*) AS nb
           FROM atlas.vm_observations
          WHERE vm_observations.id_organisme = 3
          GROUP BY vm_observations.cd_ref
        ), 
        _04 AS /*PNR Normandie Maine*/
        (
         SELECT vm_observations.cd_ref,
            count(*) AS nb
           FROM atlas.vm_observations
          WHERE vm_observations.id_organisme = 4
          GROUP BY vm_observations.cd_ref
        ), 
        _05 AS /*GRETIA*/
        (
         SELECT vm_observations.cd_ref,
            count(*) AS nb
           FROM atlas.vm_observations
          WHERE vm_observations.id_organisme = 5
          GROUP BY vm_observations.cd_ref
        ), 
        _06 AS /*CBN de Brest*/
        (
         SELECT vm_observations.cd_ref,
            count(*) AS nb
           FROM atlas.vm_observations
          WHERE vm_observations.id_organisme = 6
          GROUP BY vm_observations.cd_ref
        ), 
        _09 AS /*DREAL Pays de la Loire*/
        (
         SELECT vm_observations.cd_ref,
            count(*) AS nb
           FROM atlas.vm_observations
          WHERE vm_observations.id_organisme = 9
          GROUP BY vm_observations.cd_ref
        ), 
        _70 AS /*URCPIE*/
        (
         SELECT vm_observations.cd_ref,
            count(*) AS nb
           FROM atlas.vm_observations
          WHERE vm_observations.id_organisme = 70
          GROUP BY vm_observations.cd_ref
        ), 
        _80 AS /*Coordi. LPO*/
        (
         SELECT vm_observations.cd_ref,
            count(*) AS nb
           FROM atlas.vm_observations
          WHERE vm_observations.id_organisme = 80
          GROUP BY vm_observations.cd_ref
        ), 
        _81 AS /*LPO Anjou*/
        (
         SELECT vm_observations.cd_ref,
            count(*) AS nb
           FROM atlas.vm_observations
          WHERE vm_observations.id_organisme = 81
          GROUP BY vm_observations.cd_ref
        ), 
        _82 AS /*LPO Loire-Atlantique*/
        (
         SELECT vm_observations.cd_ref,
            count(*) AS nb
           FROM atlas.vm_observations
          WHERE vm_observations.id_organisme = 82
          GROUP BY vm_observations.cd_ref
        ),
        _83 AS /*LPO Vendée*/
        (
         SELECT vm_observations.cd_ref,
            count(*) AS nb
           FROM atlas.vm_observations
          WHERE vm_observations.id_organisme = 83
          GROUP BY vm_observations.cd_ref
        ), 
        _84 AS /*LPO Sarthe*/
        (
         SELECT vm_observations.cd_ref,
            count(*) AS nb
           FROM atlas.vm_observations
          WHERE vm_observations.id_organisme = 84
          GROUP BY vm_observations.cd_ref
        )
 SELECT DISTINCT o.cd_ref,
    COALESCE(a.nb::integer, 0) AS _03,
    COALESCE(b.nb::integer, 0) AS _04,
    COALESCE(c.nb::integer, 0) AS _05,
    COALESCE(d.nb::integer, 0) AS _06,
    COALESCE(e.nb::integer, 0) AS _09,
    COALESCE(f.nb::integer, 0) AS _70,
    COALESCE(g.nb::integer, 0) AS _80,
    COALESCE(h.nb::integer, 0) AS _81,
    COALESCE(i.nb::integer, 0) AS _82,
    COALESCE(j.nb::integer, 0) AS _83,
    COALESCE(k.nb::integer, 0) AS _84
   FROM atlas.vm_observations o
     LEFT JOIN _03 a ON a.cd_ref = o.cd_ref /*CEN Pays de la Loire*/
     LEFT JOIN _04 b ON b.cd_ref = o.cd_ref /*PNR Normandie Maine*/
     LEFT JOIN _05 c ON c.cd_ref = o.cd_ref /*GRETIA*/
     LEFT JOIN _06 d ON d.cd_ref = o.cd_ref /*CBN de Brest*/
     LEFT JOIN _09 e ON e.cd_ref = o.cd_ref /*DREAL Pays de la Loire*/
     LEFT JOIN _70 f ON f.cd_ref = o.cd_ref /*URCPIE*/
     LEFT JOIN _80 g ON g.cd_ref = o.cd_ref /*Coordi. LPO*/
     LEFT JOIN _81 h ON h.cd_ref = o.cd_ref /*LPO Anjou*/
     LEFT JOIN _82 i ON i.cd_ref = o.cd_ref /*LPO Loire-Atlantique*/
     LEFT JOIN _83 j ON j.cd_ref = o.cd_ref /*LPO Vendée*/
     LEFT JOIN _84 k ON k.cd_ref = o.cd_ref /*LPO Sarthe*/
  WHERE o.cd_ref IS NOT NULL
  ORDER BY o.cd_ref
WITH DATA;

ALTER TABLE atlas.vm_stats_orga_taxon
  OWNER TO geonatuser;
GRANT ALL ON TABLE atlas.vm_stats_orga_taxon TO geonatuser;
GRANT SELECT ON TABLE atlas.vm_stats_orga_taxon TO geonatatlas;

-- Index: atlas.vm_stats_orga_taxon_cd_ref_idx

-- DROP INDEX atlas.vm_stats_orga_taxon_cd_ref_idx;

CREATE UNIQUE INDEX vm_stats_orga_taxon_cd_ref_idx
  ON atlas.vm_stats_orga_taxon
  USING btree (cd_ref);






/* stats nb obs par structure pour chaque commune */


-- Materialized View: atlas.vm_stats_orga_comm
-- DROP MATERIALIZED VIEW atlas.vm_stats_orga_comm;


CREATE MATERIALIZED VIEW atlas.vm_stats_orga_comm AS 
 WITH 
        _03 AS /*CEN Pays de la Loire*/
        (
         SELECT vm_observations.insee,
            count(*) AS nb
           FROM atlas.vm_observations
          WHERE vm_observations.id_organisme = 3
          GROUP BY vm_observations.insee
        ), 
        _04 AS /*PNR Normandie Maine*/
        (
         SELECT vm_observations.insee,
            count(*) AS nb
           FROM atlas.vm_observations
          WHERE vm_observations.id_organisme = 4
          GROUP BY vm_observations.insee
        ), 
        _05 AS /*GRETIA*/
        (
         SELECT vm_observations.insee,
            count(*) AS nb
           FROM atlas.vm_observations
          WHERE vm_observations.id_organisme = 5
          GROUP BY vm_observations.insee
        ), 
        _06 AS /*CBN de Brest*/
        (
         SELECT vm_observations.insee,
            count(*) AS nb
           FROM atlas.vm_observations
          WHERE vm_observations.id_organisme = 6
          GROUP BY vm_observations.insee
        ), 
        _09 AS /*DREAL Pays de la Loire*/
        (
         SELECT vm_observations.insee,
            count(*) AS nb
           FROM atlas.vm_observations
          WHERE vm_observations.id_organisme = 9
          GROUP BY vm_observations.insee
        ), 
        _70 AS /*URCPIE*/
        (
         SELECT vm_observations.insee,
            count(*) AS nb
           FROM atlas.vm_observations
          WHERE vm_observations.id_organisme = 70
          GROUP BY vm_observations.insee
        ), 
        _80 AS /*Coordi. LPO*/
        (
         SELECT vm_observations.insee,
            count(*) AS nb
           FROM atlas.vm_observations
          WHERE vm_observations.id_organisme = 80
          GROUP BY vm_observations.insee
        ), 
        _81 AS /*LPO Anjou*/
        (
         SELECT vm_observations.insee,
            count(*) AS nb
           FROM atlas.vm_observations
          WHERE vm_observations.id_organisme = 81
          GROUP BY vm_observations.insee
        ), 
        _82 AS /*LPO Loire-Atlantique*/
        (
         SELECT vm_observations.insee,
            count(*) AS nb
           FROM atlas.vm_observations
          WHERE vm_observations.id_organisme = 82
          GROUP BY vm_observations.insee
        ),
        _83 AS /*LPO Vendée*/
        (
         SELECT vm_observations.insee,
            count(*) AS nb
           FROM atlas.vm_observations
          WHERE vm_observations.id_organisme = 83
          GROUP BY vm_observations.insee
        ), 
        _84 AS /*LPO Sarthe*/
        (
         SELECT vm_observations.insee,
            count(*) AS nb
           FROM atlas.vm_observations
          WHERE vm_observations.id_organisme = 84
          GROUP BY vm_observations.insee
        )
 SELECT DISTINCT o.insee,
    COALESCE(a.nb::integer, 0) AS _03,
    COALESCE(b.nb::integer, 0) AS _04,
    COALESCE(c.nb::integer, 0) AS _05,
    COALESCE(d.nb::integer, 0) AS _06,
    COALESCE(e.nb::integer, 0) AS _09,
    COALESCE(f.nb::integer, 0) AS _70,
    COALESCE(g.nb::integer, 0) AS _80,
    COALESCE(h.nb::integer, 0) AS _81,
    COALESCE(i.nb::integer, 0) AS _82,
    COALESCE(j.nb::integer, 0) AS _83,
    COALESCE(k.nb::integer, 0) AS _84
   FROM atlas.vm_observations o
     LEFT JOIN _03 a ON a.insee = o.insee /*CEN Pays de la Loire*/
     LEFT JOIN _04 b ON b.insee = o.insee /*PNR Normandie Maine*/
     LEFT JOIN _05 c ON c.insee = o.insee /*GRETIA*/
     LEFT JOIN _06 d ON d.insee = o.insee /*CBN de Brest*/
     LEFT JOIN _09 e ON e.insee = o.insee /*DREAL Pays de la Loire*/
     LEFT JOIN _70 f ON f.insee = o.insee /*URCPIE*/
     LEFT JOIN _80 g ON g.insee = o.insee /*Coordi. LPO*/
     LEFT JOIN _81 h ON h.insee = o.insee /*LPO Anjou*/
     LEFT JOIN _82 i ON i.insee = o.insee /*LPO Loire-Atlantique*/
     LEFT JOIN _83 j ON j.insee = o.insee /*LPO Vendée*/
     LEFT JOIN _84 k ON k.insee = o.insee /*LPO Sarthe*/
  WHERE o.insee IS NOT NULL
  ORDER BY o.insee
WITH DATA;

ALTER TABLE atlas.vm_stats_orga_comm
  OWNER TO geonatuser;
GRANT ALL ON TABLE atlas.vm_stats_orga_comm TO geonatuser;
GRANT SELECT ON TABLE atlas.vm_stats_orga_comm TO geonatatlas;

-- Index: atlas.vm_stats_orga_comm_insee_idx

-- DROP INDEX atlas.vm_stats_orga_comm_insee_idx;

CREATE UNIQUE INDEX vm_stats_orga_comm_insee_idx
  ON atlas.vm_stats_orga_comm
  USING btree (insee);






/* stats nb obs par structure pour chaque departement */


-- Materialized View: atlas.vm_stats_orga_dpt
-- DROP MATERIALIZED VIEW atlas.vm_stats_orga_dpt;

CREATE MATERIALIZED VIEW atlas.vm_stats_orga_dpt AS 

 SELECT DISTINCT left(insee,2) AS num_dpt,
    SUM(_03) AS _03, /*CEN Pays de la Loire*/
    SUM(_04) AS _04, /*PNR Normandie Maine*/
    SUM(_05) AS _05, /*GRETIA*/
    SUM(_06) AS _06, /*CBN de Brest*/
    SUM(_09) AS _09, /*DREAL Pays de la Loire*/
    SUM(_70) AS _70, /*URCPIE*/
    SUM(_80) AS _80, /*Coordi. LPO*/
    SUM(_81) AS _81, /*LPO Anjou*/
    SUM(_82) AS _82, /*LPO Loire-Atlantique*/
    SUM(_83) AS _83, /*LPO Vendée*/
    SUM(_84) AS _84 /*LPO Sarthe*/

   FROM atlas.vm_stats_orga_comm
 
  GROUP BY num_dpt
  ORDER BY num_dpt

WITH DATA;

ALTER TABLE atlas.vm_stats_orga_dpt
  OWNER TO geonatuser;
GRANT ALL ON TABLE atlas.vm_stats_orga_dpt TO geonatuser;
GRANT SELECT ON TABLE atlas.vm_stats_orga_dpt TO geonatatlas;

-- Index: atlas.vm_stats_orga_dpt_idx

-- DROP INDEX atlas.vm_stats_orga_dpt_idx;

CREATE UNIQUE INDEX vm_stats_orga_dpt_idx
  ON atlas.vm_stats_orga_dpt
  USING btree (num_dpt);





/* stats nb obs par structure pour la région */


-- Materialized View: atlas.vm_stats_orga_pdl
-- DROP MATERIALIZED VIEW atlas.vm_stats_orga_pdl;


CREATE MATERIALIZED VIEW atlas.vm_stats_orga_pdl AS 

 SELECT 'Pays de la Loire'::text AS nom_region,
    SUM(_03) AS _03, /*CEN Pays de la Loire*/
    SUM(_04) AS _04, /*PNR Normandie Maine*/
    SUM(_05) AS _05, /*GRETIA*/
    SUM(_06) AS _06, /*CBN de Brest*/
    SUM(_09) AS _09, /*DREAL Pays de la Loire*/
    SUM(_70) AS _70, /*URCPIE*/
    SUM(_80) AS _80, /*Coordi. LPO*/
    SUM(_81) AS _81, /*LPO Anjou*/
    SUM(_82) AS _82, /*LPO Loire-Atlantique*/
    SUM(_83) AS _83, /*LPO Vendée*/
    SUM(_84) AS _84  /*LPO Sarthe*/

   FROM atlas.vm_stats_orga_dpt

   WHERE num_dpt = '44'
        OR num_dpt = '49'
        OR num_dpt = '53'
        OR num_dpt = '72'
        OR num_dpt = '85'

WITH DATA;

ALTER TABLE atlas.vm_stats_orga_pdl
  OWNER TO geonatuser;
GRANT ALL ON TABLE atlas.vm_stats_orga_pdl TO geonatuser;
GRANT SELECT ON TABLE atlas.vm_stats_orga_pdl TO geonatatlas;










-------------------------------------------------------
-------------------------------------------------------
-------------------------------------------------------
-------------------------------------------------------
/* stats nb TAXON par BD pour chaque commune */
-------------------------------------------------------
-------------------------------------------------------
-------------------------------------------------------
-------------------------------------------------------



-- Materialized View: atlas.vm_stats_orga_comm
-- DROP MATERIALIZED VIEW atlas.vm_stats_orga_comm;


CREATE MATERIALIZED VIEW atlas.vm_stats_orga_comm AS 
 WITH 
        _03 AS /*CEN Pays de la Loire*/
        (
         SELECT vm_observations.insee,
            count(*) AS nbobs,
            count(distinct vm_observations.cd_ref) AS nbtaxon
          FROM atlas.vm_observations
          WHERE vm_observations.id_organisme = 3
          GROUP BY vm_observations.insee
        ), 
        _04 AS /*PNR Normandie Maine*/
        (
         SELECT vm_observations.insee,
            count(*) AS nbobs,
            count(distinct vm_observations.cd_ref) AS nbtaxon
          FROM atlas.vm_observations
          WHERE vm_observations.id_organisme = 4
          GROUP BY vm_observations.insee
        ), 
        _05 AS /*GRETIA*/
        (
         SELECT vm_observations.insee,
            count(*) AS nbobs,
            count(distinct vm_observations.cd_ref) AS nbtaxon
          FROM atlas.vm_observations
          WHERE vm_observations.id_organisme = 5
          GROUP BY vm_observations.insee
        ), 
        _06 AS /*CBN de Brest*/
        (
          SELECT vm_observations.insee,
            count(*) AS nbobs,
            count(distinct vm_observations.cd_ref) AS nbtaxon
          FROM atlas.vm_observations
          WHERE vm_observations.id_organisme = 6
          GROUP BY vm_observations.insee
        ), 
        _09 AS /*DREAL Pays de la Loire*/
        (
         SELECT vm_observations.insee,
            count(*) AS nbobs,
            count(distinct vm_observations.cd_ref) AS nbtaxon
          FROM atlas.vm_observations
          WHERE vm_observations.id_organisme = 9
          GROUP BY vm_observations.insee
        ), 
        _70 AS /*URCPIE*/
        (
         SELECT vm_observations.insee,
            count(*) AS nbobs,
            count(distinct vm_observations.cd_ref) AS nbtaxon
          FROM atlas.vm_observations
          WHERE vm_observations.id_organisme = 70
          GROUP BY vm_observations.insee
        ), 
        _80 AS /*Coordi. LPO*/
        (
         SELECT vm_observations.insee,
            count(*) AS nbobs,
            count(distinct vm_observations.cd_ref) AS nbtaxon
          FROM atlas.vm_observations
          WHERE vm_observations.id_organisme = 80
          GROUP BY vm_observations.insee
        ), 
        _81 AS /*LPO Anjou*/
        (
         SELECT vm_observations.insee,
            count(*) AS nbobs,
            count(distinct vm_observations.cd_ref) AS nbtaxon
          FROM atlas.vm_observations
          WHERE vm_observations.id_organisme = 81
          GROUP BY vm_observations.insee
        ), 
        _82 AS /*LPO Loire-Atlantique*/
        (
         SELECT vm_observations.insee,
            count(*) AS nbobs,
            count(distinct vm_observations.cd_ref) AS nbtaxon
          FROM atlas.vm_observations
          WHERE vm_observations.id_organisme = 82
          GROUP BY vm_observations.insee
        ),
        _83 AS /*LPO Vendée*/
        (
         SELECT vm_observations.insee,
            count(*) AS nbobs,
            count(distinct vm_observations.cd_ref) AS nbtaxon
          FROM atlas.vm_observations
          WHERE vm_observations.id_organisme = 83
          GROUP BY vm_observations.insee
        ), 
        _84 AS /*LPO Sarthe*/
        (
         SELECT vm_observations.insee,
            count(*) AS nbobs,
            count(distinct vm_observations.cd_ref) AS nbtaxon
          FROM atlas.vm_observations
          WHERE vm_observations.id_organisme = 84
          GROUP BY vm_observations.insee
        )
 SELECT DISTINCT o.insee,
    COALESCE(a.nbobs::integer, 0) AS _03nbobs,
    COALESCE(a.nbtaxon::integer, 0) AS _03nbtaxon,
    COALESCE(b.nbobs::integer, 0) AS _04nbobs,
    COALESCE(b.nbtaxon::integer, 0) AS _04nbtaxon,
    COALESCE(c.nbobs::integer, 0) AS _05nbobs,
    COALESCE(c.nbtaxon::integer, 0) AS _05nbtaxon,
    COALESCE(d.nbobs::integer, 0) AS _06nbobs,
    COALESCE(d.nbtaxon::integer, 0) AS _06nbtaxon,
    COALESCE(e.nbobs::integer, 0) AS _09nbobs,
    COALESCE(e.nbtaxon::integer, 0) AS _09nbtaxon,
    COALESCE(f.nbobs::integer, 0) AS _70nbobs,
    COALESCE(f.nbtaxon::integer, 0) AS _70nbtaxon,
    COALESCE(g.nbobs::integer, 0) AS _80nbobs,
    COALESCE(g.nbtaxon::integer, 0) AS _80nbtaxon,
    COALESCE(h.nbobs::integer, 0) AS _81nbobs,
    COALESCE(h.nbtaxon::integer, 0) AS _81nbtaxon,
    COALESCE(i.nbobs::integer, 0) AS _82nbobs,
    COALESCE(i.nbtaxon::integer, 0) AS _82nbtaxon,
    COALESCE(j.nbobs::integer, 0) AS _83nbobs,
    COALESCE(j.nbtaxon::integer, 0) AS _83nbtaxon,
    COALESCE(k.nbobs::integer, 0) AS _84nbobs,
    COALESCE(k.nbtaxon::integer, 0) AS _84nbtaxon
   FROM atlas.vm_observations o
     LEFT JOIN _03 a ON a.insee = o.insee /*CEN Pays de la Loire*/
     LEFT JOIN _04 b ON b.insee = o.insee /*PNR Normandie Maine*/
     LEFT JOIN _05 c ON c.insee = o.insee /*GRETIA*/
     LEFT JOIN _06 d ON d.insee = o.insee /*CBN de Brest*/
     LEFT JOIN _09 e ON e.insee = o.insee /*DREAL Pays de la Loire*/
     LEFT JOIN _70 f ON f.insee = o.insee /*URCPIE*/
     LEFT JOIN _80 g ON g.insee = o.insee /*Coordi. LPO*/
     LEFT JOIN _81 h ON h.insee = o.insee /*LPO Anjou*/
     LEFT JOIN _82 i ON i.insee = o.insee /*LPO Loire-Atlantique*/
     LEFT JOIN _83 j ON j.insee = o.insee /*LPO Vendée*/
     LEFT JOIN _84 k ON k.insee = o.insee /*LPO Sarthe*/
  WHERE o.insee IS NOT NULL
  ORDER BY o.insee
WITH DATA;

ALTER TABLE atlas.vm_stats_orga_comm
  OWNER TO geonatuser;
GRANT ALL ON TABLE atlas.vm_stats_orga_comm TO geonatuser;
GRANT SELECT ON TABLE atlas.vm_stats_orga_comm TO geonatatlas;

-- Index: atlas.vm_stats_orga_comm_insee_idx

-- DROP INDEX atlas.vm_stats_orga_comm_insee_idx;

CREATE UNIQUE INDEX vm_stats_orga_comm_insee_idx
  ON atlas.vm_stats_orga_comm
  USING btree (insee);





/* stats nb TAXONJ par BD pour chaque departement */


-- Materialized View: atlas.vm_stats_orga_dpt
-- DROP MATERIALIZED VIEW atlas.vm_stats_orga_dpt;

CREATE MATERIALIZED VIEW atlas.vm_stats_orga_dpt AS 

 SELECT DISTINCT left(insee,2) AS num_dpt,
    SUM(_03nbobs) AS _03nbobs, /*CEN Pays de la Loire*/
    SUM(_03nbtaxon) AS _03nbtaxon, /*CEN Pays de la Loire*/
    SUM(_04nbobs) AS _04nbobs, /*PNR Normandie Maine*/
    SUM(_04nbtaxon) AS _04nbtaxon, /*PNR Normandie Maine*/
    SUM(_05nbobs) AS _05nbobs, /*GRETIA*/
    SUM(_05nbtaxon) AS _05nbtaxon, /*GRETIA*/
    SUM(_06nbobs) AS _06nbobs, /*CBN de Brest*/
    SUM(_06nbtaxon) AS _06nbtaxon, /*CBN de Brest*/
    SUM(_09nbobs) AS _09nbobs, /*DREAL Pays de la Loire*/
    SUM(_09nbtaxon) AS _09nbtaxon, /*DREAL Pays de la Loire*/
    SUM(_70nbobs) AS _70nbobs, /*URCPIE*/
    SUM(_70nbtaxon) AS _70nbtaxon, /*URCPIE*/
    SUM(_80nbobs) AS _80nbobs, /*Coordi. LPO*/
    SUM(_80nbtaxon) AS _80nbtaxon, /*Coordi. LPO*/
    SUM(_81nbobs) AS _81nbobs, /*LPO Anjou*/
    SUM(_81nbtaxon) AS _81nbtaxon, /*LPO Anjou*/
    SUM(_82nbobs) AS _82nbobs, /*LPO Loire-Atlantique*/
    SUM(_82nbtaxon) AS _82nbtaxon, /*LPO Loire-Atlantique*/
    SUM(_83nbobs) AS _83nbobs, /*LPO Vendée*/
    SUM(_83nbtaxon) AS _83nbtaxon, /*LPO Vendée*/
    SUM(_84nbobs) AS _84nbobs, /*LPO Sarthe*/
    SUM(_84nbtaxon) AS _84nbtaxon /*LPO Sarthe*/

   FROM atlas.vm_stats_orga_comm
 
  GROUP BY num_dpt
  ORDER BY num_dpt

WITH DATA;

ALTER TABLE atlas.vm_stats_orga_dpt
  OWNER TO geonatuser;
GRANT ALL ON TABLE atlas.vm_stats_orga_dpt TO geonatuser;
GRANT SELECT ON TABLE atlas.vm_stats_orga_dpt TO geonatatlas;

-- Index: atlas.vm_stats_orga_dpt_idx

-- DROP INDEX atlas.vm_stats_orga_dpt_idx;

CREATE UNIQUE INDEX vm_stats_orga_dpt_idx
  ON atlas.vm_stats_orga_dpt
  USING btree (num_dpt);




-------------------------------------------------------
-------------------------------------------------------
-------------------------------------------------------
-------------------------------------------------------
/* stats nb TAXON par BD pour la région */
-------------------------------------------------------
-------------------------------------------------------
-------------------------------------------------------
-------------------------------------------------------


-- Materialized View: atlas.vm_stats_orga_pdl
-- DROP MATERIALIZED VIEW atlas.vm_stats_orga_pdl;


CREATE MATERIALIZED VIEW atlas.vm_stats_orga_pdl AS 

 SELECT 'Pays de la Loire'::text AS nom_region,
    SUM(_03nbobs) AS _03nbobs, /*CEN Pays de la Loire*/
    SUM(_03nbtaxon) AS _03nbtaxon, /*CEN Pays de la Loire*/
    SUM(_04nbobs) AS _04nbobs, /*PNR Normandie Maine*/
    SUM(_04nbtaxon) AS _04nbtaxon, /*PNR Normandie Maine*/
    SUM(_05nbobs) AS _05nbobs, /*GRETIA*/
    SUM(_05nbtaxon) AS _05nbtaxon, /*GRETIA*/
    SUM(_06nbobs) AS _06nbobs, /*CBN de Brest*/
    SUM(_06nbtaxon) AS _06nbtaxon, /*CBN de Brest*/
    SUM(_09nbobs) AS _09nbobs, /*DREAL Pays de la Loire*/
    SUM(_09nbtaxon) AS _09nbtaxon, /*DREAL Pays de la Loire*/
    SUM(_70nbobs) AS _70nbobs, /*URCPIE*/
    SUM(_70nbtaxon) AS _70nbtaxon, /*URCPIE*/
    SUM(_80nbobs) AS _80nbobs, /*Coordi. LPO*/
    SUM(_80nbtaxon) AS _80nbtaxon, /*Coordi. LPO*/
    SUM(_81nbobs) AS _81nbobs, /*LPO Anjou*/
    SUM(_81nbtaxon) AS _81nbtaxon, /*LPO Anjou*/
    SUM(_82nbobs) AS _82nbobs, /*LPO Loire-Atlantique*/
    SUM(_82nbtaxon) AS _82nbtaxon, /*LPO Loire-Atlantique*/
    SUM(_83nbobs) AS _83nbobs, /*LPO Vendée*/
    SUM(_83nbtaxon) AS _83nbtaxon, /*LPO Vendée*/
    SUM(_84nbobs) AS _84nbobs,  /*LPO Sarthe*/
    SUM(_84nbtaxon) AS _84nbtaxon  /*LPO Sarthe*/

   FROM atlas.vm_stats_orga_dpt

   WHERE num_dpt = '44'
        OR num_dpt = '49'
        OR num_dpt = '53'
        OR num_dpt = '72'
        OR num_dpt = '85'

WITH DATA;

ALTER TABLE atlas.vm_stats_orga_pdl
  OWNER TO geonatuser;
GRANT ALL ON TABLE atlas.vm_stats_orga_pdl TO geonatuser;
GRANT SELECT ON TABLE atlas.vm_stats_orga_pdl TO geonatatlas;















/* stats nb obs par group2_inpn pour chaque commune */

-- Materialized View: atlas.vm_stats_group2inpn_comm
-- DROP MATERIALIZED VIEW atlas.vm_stats_group2inpn_comm;

CREATE MATERIALIZED VIEW atlas.vm_stats_group2inpn_comm AS 
 WITH cd_ref AS (
         SELECT vm_taxref.cd_ref, vm_taxref.group2_inpn
         FROM atlas.vm_taxref 
         WHERE vm_taxref.cd_ref = vm_taxref.cd_nom 
         ),
        Acanthocephales AS (
         SELECT s.insee, count(*) AS nb
         FROM atlas.vm_observations s
            LEFT JOIN cd_ref tx ON tx.cd_ref = s.cd_ref
         WHERE tx.group2_inpn = 'Acanthocéphales'
          GROUP BY s.insee
        ), 
        Algues_brunes AS (
         SELECT s.insee, count(*) AS nb
         FROM atlas.vm_observations s
           LEFT JOIN cd_ref tx ON tx.cd_ref = s.cd_ref
         WHERE tx.group2_inpn = 'Algues brunes'
          GROUP BY s.insee
        ), 
        Algues_rouges AS (
         SELECT s.insee, count(*) AS nb
         FROM atlas.vm_observations s
            LEFT JOIN cd_ref tx ON tx.cd_ref = s.cd_ref
         WHERE tx.group2_inpn = 'Algues rouges'
          GROUP BY s.insee
        ), 
        Algues_vertes AS (
         SELECT s.insee, count(*) AS nb
         FROM atlas.vm_observations s
            LEFT JOIN cd_ref tx ON tx.cd_ref = s.cd_ref
         WHERE tx.group2_inpn = 'Algues vertes'
          GROUP BY s.insee
        ), 
        Amphibiens AS (
         SELECT s.insee, count(*) AS nb
         FROM atlas.vm_observations s
            LEFT JOIN cd_ref tx ON tx.cd_ref = s.cd_ref
         WHERE tx.group2_inpn = 'Amphibiens'
          GROUP BY s.insee
        ), 
        Angiospermes AS (
         SELECT s.insee, count(*) AS nb
         FROM atlas.vm_observations s
            LEFT JOIN cd_ref tx ON tx.cd_ref = s.cd_ref
         WHERE tx.group2_inpn = 'Angiospermes'
          GROUP BY s.insee
        ), 
        Annelides AS (
         SELECT s.insee, count(*) AS nb
         FROM atlas.vm_observations s
            LEFT JOIN cd_ref tx ON tx.cd_ref = s.cd_ref
         WHERE tx.group2_inpn = 'Annélides'
          GROUP BY s.insee
        ), 
        Arachnides AS (
         SELECT s.insee, count(*) AS nb
         FROM atlas.vm_observations s
            LEFT JOIN cd_ref tx ON tx.cd_ref = s.cd_ref
         WHERE tx.group2_inpn = 'Arachnides'
          GROUP BY s.insee
        ), 
        Ascidies AS (
         SELECT s.insee, count(*) AS nb
         FROM atlas.vm_observations s
            LEFT JOIN cd_ref tx ON tx.cd_ref = s.cd_ref
         WHERE tx.group2_inpn = 'Ascidies'
          GROUP BY s.insee
        ), 
        Autres AS (
         SELECT s.insee, count(*) AS nb
         FROM atlas.vm_observations s
            LEFT JOIN cd_ref tx ON tx.cd_ref = s.cd_ref
         WHERE tx.group2_inpn = 'Autres'
          GROUP BY s.insee
        ), 
        Bivalves AS (
         SELECT s.insee, count(*) AS nb
         FROM atlas.vm_observations s
            LEFT JOIN cd_ref tx ON tx.cd_ref = s.cd_ref
         WHERE tx.group2_inpn = 'Bivalves'
          GROUP BY s.insee
        ), 
        Cephalopodes AS (
         SELECT s.insee, count(*) AS nb
         FROM atlas.vm_observations s
            LEFT JOIN cd_ref tx ON tx.cd_ref = s.cd_ref
         WHERE tx.group2_inpn = 'Céphalopodes'
          GROUP BY s.insee
        ), 
        Crustaces AS (
         SELECT s.insee, count(*) AS nb
         FROM atlas.vm_observations s
            LEFT JOIN cd_ref tx ON tx.cd_ref = s.cd_ref
         WHERE tx.group2_inpn = 'Crustacés'
          GROUP BY s.insee
        ), 
        Diatomees AS (
         SELECT s.insee, count(*) AS nb
         FROM atlas.vm_observations s
            LEFT JOIN cd_ref tx ON tx.cd_ref = s.cd_ref
         WHERE tx.group2_inpn = 'Diatomées'
          GROUP BY s.insee
        ), 
        Entognathes AS (
         SELECT s.insee, count(*) AS nb
         FROM atlas.vm_observations s
            LEFT JOIN cd_ref tx ON tx.cd_ref = s.cd_ref
         WHERE tx.group2_inpn = 'Entognathes'
          GROUP BY s.insee
        ), 
        Fougeres AS (
         SELECT s.insee, count(*) AS nb
         FROM atlas.vm_observations s
            LEFT JOIN cd_ref tx ON tx.cd_ref = s.cd_ref
         WHERE tx.group2_inpn = 'Fougères'
          GROUP BY s.insee
        ), 
        Gasteropodes AS (
         SELECT s.insee, count(*) AS nb
         FROM atlas.vm_observations s
            LEFT JOIN cd_ref tx ON tx.cd_ref = s.cd_ref
         WHERE tx.group2_inpn = 'Gastéropodes'
          GROUP BY s.insee
        ), 
        Gymnospermes AS (
         SELECT s.insee, count(*) AS nb
         FROM atlas.vm_observations s
            LEFT JOIN cd_ref tx ON tx.cd_ref = s.cd_ref
         WHERE tx.group2_inpn = 'Gymnospermes'
          GROUP BY s.insee
        ), 
        Hepatiques_Anthocerotes AS (
         SELECT s.insee, count(*) AS nb
         FROM atlas.vm_observations s
            LEFT JOIN cd_ref tx ON tx.cd_ref = s.cd_ref
         WHERE tx.group2_inpn = 'Hépatiques et Anthocérotes'
          GROUP BY s.insee
        ), 
        Hydrozoaires AS (
         SELECT s.insee, count(*) AS nb
         FROM atlas.vm_observations s
            LEFT JOIN cd_ref tx ON tx.cd_ref = s.cd_ref
         WHERE tx.group2_inpn = 'Hydrozoaires'
          GROUP BY s.insee
        ), 
        Insectes AS (
         SELECT s.insee, count(*) AS nb
         FROM atlas.vm_observations s
            LEFT JOIN cd_ref tx ON tx.cd_ref = s.cd_ref
         WHERE tx.group2_inpn = 'Insectes'
          GROUP BY s.insee
        ), 
        Lichens AS (
         SELECT s.insee, count(*) AS nb
         FROM atlas.vm_observations s
            LEFT JOIN cd_ref tx ON tx.cd_ref = s.cd_ref
         WHERE tx.group2_inpn = 'Lichens'
          GROUP BY s.insee
        ), 
        Mammiferes AS (
         SELECT s.insee, count(*) AS nb
         FROM atlas.vm_observations s
            LEFT JOIN cd_ref tx ON tx.cd_ref = s.cd_ref
         WHERE tx.group2_inpn = 'Mammifères'
          GROUP BY s.insee
        ), 
        Mousses AS (
         SELECT s.insee, count(*) AS nb
         FROM atlas.vm_observations s
            LEFT JOIN cd_ref tx ON tx.cd_ref = s.cd_ref
         WHERE tx.group2_inpn = 'Mousses'
          GROUP BY s.insee
        ), 
        Myriapodes AS (
         SELECT s.insee, count(*) AS nb
         FROM atlas.vm_observations s
            LEFT JOIN cd_ref tx ON tx.cd_ref = s.cd_ref
         WHERE tx.group2_inpn = 'Myriapodes'
          GROUP BY s.insee
        ), 
        Nematodes AS (
         SELECT s.insee, count(*) AS nb
         FROM atlas.vm_observations s
            LEFT JOIN cd_ref tx ON tx.cd_ref = s.cd_ref
         WHERE tx.group2_inpn = 'Nématodes'
          GROUP BY s.insee
        ), 
        Nemertes AS (
         SELECT s.insee, count(*) AS nb
         FROM atlas.vm_observations s
            LEFT JOIN cd_ref tx ON tx.cd_ref = s.cd_ref
         WHERE tx.group2_inpn = 'Némertes'
          GROUP BY s.insee
        ), 
        Octocoralliaires AS (
         SELECT s.insee, count(*) AS nb
         FROM atlas.vm_observations s
            LEFT JOIN cd_ref tx ON tx.cd_ref = s.cd_ref
         WHERE tx.group2_inpn = 'Octocoralliaires'
          GROUP BY s.insee
        ), 
        Oiseaux AS (
         SELECT s.insee, count(*) AS nb
         FROM atlas.vm_observations s
            LEFT JOIN cd_ref tx ON tx.cd_ref = s.cd_ref
         WHERE tx.group2_inpn = 'Oiseaux'
          GROUP BY s.insee
        ), 
        Plathelminthes AS (
         SELECT s.insee, count(*) AS nb
         FROM atlas.vm_observations s
            LEFT JOIN cd_ref tx ON tx.cd_ref = s.cd_ref
         WHERE tx.group2_inpn = 'Plathelminthes'
          GROUP BY s.insee
        ), 
        Poissons AS (
         SELECT s.insee, count(*) AS nb
         FROM atlas.vm_observations s
            LEFT JOIN cd_ref tx ON tx.cd_ref = s.cd_ref
         WHERE tx.group2_inpn = 'Poissons'
          GROUP BY s.insee
        ), 
        Pycnogonides AS (
         SELECT s.insee, count(*) AS nb
         FROM atlas.vm_observations s
            LEFT JOIN cd_ref tx ON tx.cd_ref = s.cd_ref
         WHERE tx.group2_inpn = 'Pycnogonides'
          GROUP BY s.insee
        ), 
        Reptiles AS (
         SELECT s.insee, count(*) AS nb
         FROM atlas.vm_observations s
            LEFT JOIN cd_ref tx ON tx.cd_ref = s.cd_ref
         WHERE tx.group2_inpn = 'Reptiles'
          GROUP BY s.insee
        ), 
        Scleractiniaires AS (
         SELECT s.insee, count(*) AS nb
         FROM atlas.vm_observations s
            LEFT JOIN cd_ref tx ON tx.cd_ref = s.cd_ref
         WHERE tx.group2_inpn = 'Scléractiniaires'
          GROUP BY s.insee
        )
 SELECT DISTINCT o.insee,
    COALESCE(a.nb::integer, 0) AS Acanthocephales,
    COALESCE(b.nb::integer, 0) AS Algues_brunes,
    COALESCE(c.nb::integer, 0) AS Algues_rouges,
    COALESCE(d.nb::integer, 0) AS Algues_vertes,
    COALESCE(e.nb::integer, 0) AS Amphibiens,
    COALESCE(f.nb::integer, 0) AS Angiospermes,
    COALESCE(g.nb::integer, 0) AS Annelides,
    COALESCE(h.nb::integer, 0) AS Arachnides,
    COALESCE(i.nb::integer, 0) AS Ascidies,
    COALESCE(j.nb::integer, 0) AS Autres,
    COALESCE(k.nb::integer, 0) AS Bivalves,
    COALESCE(l.nb::integer, 0) AS Cephalopodes,
    COALESCE(m.nb::integer, 0) AS Crustaces,
    COALESCE(n.nb::integer, 0) AS Diatomees,
    COALESCE(p.nb::integer, 0) AS Entognathes,
    COALESCE(q.nb::integer, 0) AS Fougeres,
    COALESCE(r.nb::integer, 0) AS Gasteropodes,
    COALESCE(s.nb::integer, 0) AS Gymnospermes,
    COALESCE(t.nb::integer, 0) AS Hepatiques_Anthocerotes,
    COALESCE(u.nb::integer, 0) AS Hydrozoaires,
    COALESCE(v.nb::integer, 0) AS Insectes,
    COALESCE(w.nb::integer, 0) AS Lichens,
    COALESCE(x.nb::integer, 0) AS Mammiferes,
    COALESCE(y.nb::integer, 0) AS Mousses,
    COALESCE(z.nb::integer, 0) AS Myriapodes,
    COALESCE(ab.nb::integer, 0) AS Nematodes,
    COALESCE(ac.nb::integer, 0) AS Nemertes,
    COALESCE(ad.nb::integer, 0) AS Octocoralliaires,
    COALESCE(ae.nb::integer, 0) AS Oiseaux,
    COALESCE(af.nb::integer, 0) AS Plathelminthes,
    COALESCE(ag.nb::integer, 0) AS Poissons,
    COALESCE(ah.nb::integer, 0) AS Pycnogonides,
    COALESCE(ai.nb::integer, 0) AS Reptiles,
    COALESCE(aj.nb::integer, 0) AS Scleractiniaires

    FROM atlas.vm_observations o

     LEFT JOIN Acanthocephales a ON a.insee = o.insee
     LEFT JOIN Algues_brunes b ON b.insee = o.insee
     LEFT JOIN Algues_rouges c ON c.insee = o.insee
     LEFT JOIN Algues_vertes d ON d.insee = o.insee
     LEFT JOIN Amphibiens e ON e.insee = o.insee
     LEFT JOIN Angiospermes f ON f.insee = o.insee
     LEFT JOIN Annelides g ON g.insee = o.insee
     LEFT JOIN Arachnides h ON h.insee = o.insee
     LEFT JOIN Ascidies i ON i.insee = o.insee
     LEFT JOIN Autres j ON j.insee = o.insee
     LEFT JOIN Bivalves k ON k.insee = o.insee
     LEFT JOIN Cephalopodes l ON l.insee = o.insee
     LEFT JOIN Crustaces m ON m.insee = o.insee
     LEFT JOIN Diatomees n ON n.insee = o.insee
     LEFT JOIN Entognathes p ON p.insee = o.insee
     LEFT JOIN Fougeres q ON q.insee = o.insee
     LEFT JOIN Gasteropodes r ON r.insee = o.insee
     LEFT JOIN Gymnospermes s ON s.insee = o.insee
     LEFT JOIN Hepatiques_Anthocerotes t ON t.insee = o.insee
     LEFT JOIN Hydrozoaires u ON u.insee = o.insee
     LEFT JOIN Insectes v ON v.insee = o.insee
     LEFT JOIN Lichens w ON w.insee = o.insee
     LEFT JOIN Mammiferes x ON x.insee = o.insee
     LEFT JOIN Mousses y ON y.insee = o.insee
     LEFT JOIN Myriapodes z ON z.insee = o.insee
     LEFT JOIN Nematodes ab ON ab.insee = o.insee
     LEFT JOIN Nemertes ac ON ac.insee = o.insee
     LEFT JOIN Octocoralliaires ad ON ad.insee = o.insee
     LEFT JOIN Oiseaux ae ON ae.insee = o.insee
     LEFT JOIN Plathelminthes af ON af.insee = o.insee
     LEFT JOIN Poissons ag ON ag.insee = o.insee
     LEFT JOIN Pycnogonides ah ON ah.insee = o.insee
     LEFT JOIN Reptiles ai ON ai.insee = o.insee
     LEFT JOIN Scleractiniaires aj ON aj.insee = o.insee

  WHERE o.insee IS NOT NULL
  ORDER BY o.insee
WITH DATA;

ALTER TABLE atlas.vm_stats_group2inpn_comm
  OWNER TO geonatuser;
GRANT ALL ON TABLE atlas.vm_stats_group2inpn_comm TO geonatuser;
GRANT SELECT ON TABLE atlas.vm_stats_group2inpn_comm TO geonatatlas;

-- Index: atlas.vm_stats_group2inpn_comm_insee_idx

-- DROP INDEX atlas.vm_stats_group2inpn_comm_insee_idx;

CREATE UNIQUE INDEX vm_stats_group2inpn_comm_insee_idx
  ON atlas.vm_stats_group2inpn_comm
  USING btree (insee);





/* stats nb obs par group2_inpn pour chaque departement */

-- Materialized View: atlas.vm_stats_group2inpn_dpt
-- DROP MATERIALIZED VIEW atlas.vm_stats_group2inpn_dpt;

CREATE MATERIALIZED VIEW atlas.vm_stats_group2inpn_dpt AS 

 SELECT DISTINCT left(insee,2) AS num_dpt,
    SUM(Acanthocephales) AS Acanthocephales, 
    SUM(Algues_brunes) AS Algues_brunes, 
    SUM(Algues_rouges) AS Algues_rouges,
    SUM(Algues_vertes) AS Algues_vertes,
    SUM(Amphibiens) AS Amphibiens,
    SUM(Angiospermes) AS Angiospermes,
    SUM(Annelides) AS Annelides, 
    SUM(Arachnides) AS Arachnides,
    SUM(Ascidies) AS Ascidies,
    SUM(Autres) AS Autres, 
    SUM(Bivalves) AS Bivalves,
    SUM(Cephalopodes) AS Cephalopodes, 
    SUM(Crustaces) AS Crustaces,
    SUM(Diatomees) AS Diatomees,
    SUM(Entognathes) AS Entognathes, 
    SUM(Fougeres) AS Fougeres,
    SUM(Gasteropodes) AS Gasteropodes, 
    SUM(Gymnospermes) AS Gymnospermes,
    SUM(Hepatiques_Anthocerotes) AS Hepatiques_Anthocerotes,
    SUM(Hydrozoaires) AS Hydrozoaires, 
    SUM(Insectes) AS Insectes,
    SUM(Lichens) AS Lichens, 
    SUM(Mammiferes) AS Mammiferes,
    SUM(Mousses) AS Mousses,
    SUM(Myriapodes) AS Myriapodes, 
    SUM(Nematodes) AS Nematodes, 
    SUM(Nemertes) AS Nemertes,
    SUM(Octocoralliaires) AS Octocoralliaires,
    SUM(Oiseaux) AS Oiseaux, 
    SUM(Plathelminthes) AS Plathelminthes, 
    SUM(Poissons) AS Poissons,
    SUM(Pycnogonides) AS Pycnogonides,
    SUM(Reptiles) AS Reptiles, 
    SUM(Scleractiniaires) AS Scleractiniaires 

   FROM atlas.vm_stats_group2inpn_comm
 
  GROUP BY num_dpt
  ORDER BY num_dpt

WITH DATA;

ALTER TABLE atlas.vm_stats_group2inpn_dpt
  OWNER TO geonatuser;
GRANT ALL ON TABLE atlas.vm_stats_group2inpn_dpt TO geonatuser;
GRANT SELECT ON TABLE atlas.vm_stats_group2inpn_dpt TO geonatatlas;

-- Index: atlas.vm_stats_group2inpn_dpt_idx

-- DROP INDEX atlas.vm_stats_group2inpn_dpt_idx;

CREATE UNIQUE INDEX vm_stats_group2inpn_dpt_idx
  ON atlas.vm_stats_group2inpn_dpt
  USING btree (num_dpt);





/* stats nb obs par group2_inpn pour la région */

-- Materialized View: atlas.vm_stats_group2inpn_pdl
-- DROP MATERIALIZED VIEW atlas.vm_stats_group2inpn_pdl;


CREATE MATERIALIZED VIEW atlas.vm_stats_group2inpn_pdl AS 

 SELECT 'Pays de la Loire'::text AS nom_region,
    SUM(Acanthocephales) AS Acanthocephales, 
    SUM(Algues_brunes) AS Algues_brunes, 
    SUM(Algues_rouges) AS Algues_rouges,
    SUM(Algues_vertes) AS Algues_vertes,
    SUM(Amphibiens) AS Amphibiens,
    SUM(Angiospermes) AS Angiospermes,
    SUM(Annelides) AS Annelides, 
    SUM(Arachnides) AS Arachnides,
    SUM(Ascidies) AS Ascidies,
    SUM(Autres) AS Autres, 
    SUM(Bivalves) AS Bivalves,
    SUM(Cephalopodes) AS Cephalopodes, 
    SUM(Crustaces) AS Crustaces,
    SUM(Diatomees) AS Diatomees,
    SUM(Entognathes) AS Entognathes, 
    SUM(Fougeres) AS Fougeres,
    SUM(Gasteropodes) AS Gasteropodes, 
    SUM(Gymnospermes) AS Gymnospermes,
    SUM(Hepatiques_Anthocerotes) AS Hepatiques_Anthocerotes,
    SUM(Hydrozoaires) AS Hydrozoaires, 
    SUM(Insectes) AS Insectes,
    SUM(Lichens) AS Lichens, 
    SUM(Mammiferes) AS Mammiferes,
    SUM(Mousses) AS Mousses,
    SUM(Myriapodes) AS Myriapodes, 
    SUM(Nematodes) AS Nematodes, 
    SUM(Nemertes) AS Nemertes,
    SUM(Octocoralliaires) AS Octocoralliaires,
    SUM(Oiseaux) AS Oiseaux, 
    SUM(Plathelminthes) AS Plathelminthes, 
    SUM(Poissons) AS Poissons,
    SUM(Pycnogonides) AS Pycnogonides,
    SUM(Reptiles) AS Reptiles, 
    SUM(Scleractiniaires) AS Scleractiniaires 

   FROM atlas.vm_stats_group2inpn_dpt

   WHERE num_dpt = '44' OR num_dpt = '49' OR num_dpt = '53' OR num_dpt = '72' OR num_dpt = '85'

WITH DATA;

ALTER TABLE atlas.vm_stats_group2inpn_pdl
  OWNER TO geonatuser;
GRANT ALL ON TABLE atlas.vm_stats_group2inpn_pdl TO geonatuser;
GRANT SELECT ON TABLE atlas.vm_stats_group2inpn_pdl TO geonatatlas;







/* stats nb d'especes differentes par group2_inpn pour chaque commune */

-- Materialized View: atlas.vm_stats_espece_group2inpn_comm
-- DROP MATERIALIZED VIEW atlas.vm_stats_espece_group2inpn_comm;

CREATE MATERIALIZED VIEW atlas.vm_stats_espece_group2inpn_comm AS 
 

 WITH cd_ref AS (
         SELECT vm_taxref.cd_ref, vm_taxref.group2_inpn
         FROM atlas.vm_taxref 
         WHERE vm_taxref.cd_ref = vm_taxref.cd_nom 
         ),

        somme_a AS (
         SELECT DISTINCT
            o.cd_ref,
            o.insee,
            COUNT(o.cd_ref) AS nb, 
            t.group2_inpn
        FROM atlas.vm_observations o
        JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
        AND t.group2_inpn = 'Acanthocéphales'
        GROUP BY o.cd_ref, o.insee, t.group2_inpn
        ),
        Acanthocephales AS (
            select count(*) as nb,
            insee
            from somme_a
            group by insee
        ), 
     
        somme_b AS (
         SELECT DISTINCT
            o.cd_ref,
            o.insee,
            COUNT(o.cd_ref) AS nb, 
            t.group2_inpn
        FROM atlas.vm_observations o
        JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
        AND t.group2_inpn = 'Algues brunes'
        GROUP BY o.cd_ref, o.insee, t.group2_inpn
        ),
        Algues_brunes AS (
            select count(*) as nb,
            insee
            from somme_b
            group by insee
        ), 

        somme_c AS (
         SELECT DISTINCT
            o.cd_ref,
            o.insee,
            COUNT(o.cd_ref) AS nb, 
            t.group2_inpn
        FROM atlas.vm_observations o
        JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
        AND t.group2_inpn = 'Algues rouges'
        GROUP BY o.cd_ref, o.insee, t.group2_inpn
        ),
        Algues_rouges AS (
            select count(*) as nb,
            insee
            from somme_c
            group by insee
        ), 

        somme_d AS (
         SELECT DISTINCT
            o.cd_ref,
            o.insee,
            COUNT(o.cd_ref) AS nb, 
            t.group2_inpn
        FROM atlas.vm_observations o
        JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
        AND t.group2_inpn = 'Algues vertes'
        GROUP BY o.cd_ref, o.insee, t.group2_inpn
        ),
        Algues_vertes AS (
            select count(*) as nb,
            insee
            from somme_d
            group by insee
        ), 

       somme_e AS (
         SELECT DISTINCT
            o.cd_ref,
            o.insee,
            COUNT(o.cd_ref) AS nb, 
            t.group2_inpn
        FROM atlas.vm_observations o
        JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
        AND t.group2_inpn = 'Amphibiens'
        GROUP BY o.cd_ref, o.insee, t.group2_inpn
        ),
        Amphibiens AS (
            select count(*) as nb,
            insee
            from somme_e
            group by insee
        ), 

        somme_f AS (
         SELECT DISTINCT
            o.cd_ref,
            o.insee,
            COUNT(o.cd_ref) AS nb, 
            t.group2_inpn
        FROM atlas.vm_observations o
        JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
        AND t.group2_inpn = 'Angiospermes'
        GROUP BY o.cd_ref, o.insee, t.group2_inpn
        ),
        Angiospermes AS (
            select count(*) as nb,
            insee
            from somme_f
            group by insee
        ), 

        somme_g AS (
         SELECT DISTINCT
            o.cd_ref,
            o.insee,
            COUNT(o.cd_ref) AS nb, 
            t.group2_inpn
        FROM atlas.vm_observations o
        JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
        AND t.group2_inpn = 'Annélides'        
        GROUP BY o.cd_ref, o.insee, t.group2_inpn
        ),
        Annelides AS (
            select count(*) as nb,
            insee
            from somme_g
            group by insee
        ),

        somme_h AS (
         SELECT DISTINCT
            o.cd_ref,
            o.insee,
            COUNT(o.cd_ref) AS nb, 
            t.group2_inpn
        FROM atlas.vm_observations o
        JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
        AND t.group2_inpn = 'Arachnides'        
        GROUP BY o.cd_ref, o.insee, t.group2_inpn
        ),
        Arachnides AS (
            select count(*) as nb,
            insee
            from somme_h
            group by insee
        ),

        somme_i AS (
         SELECT DISTINCT
            o.cd_ref,
            o.insee,
            COUNT(o.cd_ref) AS nb, 
            t.group2_inpn
        FROM atlas.vm_observations o
        JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
        AND t.group2_inpn = 'Ascidies'        
        GROUP BY o.cd_ref, o.insee, t.group2_inpn
        ),
        Ascidies AS (
            select count(*) as nb,
            insee
            from somme_i
            group by insee
        ),

        somme_j AS (
         SELECT DISTINCT
            o.cd_ref,
            o.insee,
            COUNT(o.cd_ref) AS nb, 
            t.group2_inpn
        FROM atlas.vm_observations o
        JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
        AND t.group2_inpn = 'Autres'        
        GROUP BY o.cd_ref, o.insee, t.group2_inpn
        ),
        Autres AS (
            select count(*) as nb,
            insee
            from somme_j
            group by insee
        ),

        somme_k AS (
         SELECT DISTINCT
            o.cd_ref,
            o.insee,
            COUNT(o.cd_ref) AS nb, 
            t.group2_inpn
        FROM atlas.vm_observations o
        JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
        AND t.group2_inpn = 'Bivalves'        
        GROUP BY o.cd_ref, o.insee, t.group2_inpn
        ),
        Bivalves AS (
            select count(*) as nb,
            insee
            from somme_k
            group by insee
        ),

        somme_l AS (
         SELECT DISTINCT
            o.cd_ref,
            o.insee,
            COUNT(o.cd_ref) AS nb, 
            t.group2_inpn
        FROM atlas.vm_observations o
        JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
        AND t.group2_inpn = 'Céphalopodes'        
        GROUP BY o.cd_ref, o.insee, t.group2_inpn
        ),
        Cephalopodes AS (
            select count(*) as nb,
            insee
            from somme_l
            group by insee
        ),

        somme_m AS (
         SELECT DISTINCT
            o.cd_ref,
            o.insee,
            COUNT(o.cd_ref) AS nb, 
            t.group2_inpn
        FROM atlas.vm_observations o
        JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
        AND t.group2_inpn = 'Crustacés'        
        GROUP BY o.cd_ref, o.insee, t.group2_inpn
        ),
        Crustaces AS (
            select count(*) as nb,
            insee
            from somme_m
            group by insee
        ),

        somme_n AS (
         SELECT DISTINCT
            o.cd_ref,
            o.insee,
            COUNT(o.cd_ref) AS nb, 
            t.group2_inpn
        FROM atlas.vm_observations o
        JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
        AND t.group2_inpn = 'Diatomées'        
        GROUP BY o.cd_ref, o.insee, t.group2_inpn
        ),
        Diatomees AS (
            select count(*) as nb,
            insee
            from somme_n
            group by insee
        ),

        somme_p AS (
         SELECT DISTINCT
            o.cd_ref,
            o.insee,
            COUNT(o.cd_ref) AS nb, 
            t.group2_inpn
        FROM atlas.vm_observations o
        JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
        AND t.group2_inpn = 'Entognathes'        
        GROUP BY o.cd_ref, o.insee, t.group2_inpn
        ),
        Entognathes AS (
            select count(*) as nb,
            insee
            from somme_p
            group by insee
        ),

        somme_q AS (
         SELECT DISTINCT
            o.cd_ref,
            o.insee,
            COUNT(o.cd_ref) AS nb, 
            t.group2_inpn
        FROM atlas.vm_observations o
        JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
        AND t.group2_inpn = 'Fougères'        
        GROUP BY o.cd_ref, o.insee, t.group2_inpn
        ),
        Fougeres AS (
            select count(*) as nb,
            insee
            from somme_q
            group by insee
        ),

        somme_r AS (
         SELECT DISTINCT
            o.cd_ref,
            o.insee,
            COUNT(o.cd_ref) AS nb, 
            t.group2_inpn
        FROM atlas.vm_observations o
        JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
        AND t.group2_inpn = 'Gastéropodes'        
        GROUP BY o.cd_ref, o.insee, t.group2_inpn
        ),
        Gasteropodes AS (
            select count(*) as nb,
            insee
            from somme_r
            group by insee
        ),

        somme_s AS (
         SELECT DISTINCT
            o.cd_ref,
            o.insee,
            COUNT(o.cd_ref) AS nb, 
            t.group2_inpn
        FROM atlas.vm_observations o
        JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
        AND t.group2_inpn = 'Gymnospermes'        
        GROUP BY o.cd_ref, o.insee, t.group2_inpn
        ),
        Gymnospermes AS (
            select count(*) as nb,
            insee
            from somme_s
            group by insee
        ),

        somme_t AS (
         SELECT DISTINCT
            o.cd_ref,
            o.insee,
            COUNT(o.cd_ref) AS nb, 
            t.group2_inpn
        FROM atlas.vm_observations o
        JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
        AND t.group2_inpn = 'Hépatiques et Anthocérotes'        
        GROUP BY o.cd_ref, o.insee, t.group2_inpn
        ),
        Hepatiques_Anthocerotes AS (
            select count(*) as nb,
            insee
            from somme_t
            group by insee
        ),

        somme_u AS (
         SELECT DISTINCT
            o.cd_ref,
            o.insee,
            COUNT(o.cd_ref) AS nb, 
            t.group2_inpn
        FROM atlas.vm_observations o
        JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
        AND t.group2_inpn = 'Hydrozoaires'        
        GROUP BY o.cd_ref, o.insee, t.group2_inpn
        ),
        Hydrozoaires AS (
            select count(*) as nb,
            insee
            from somme_u
            group by insee
        ),

        somme_v AS (
         SELECT DISTINCT
            o.cd_ref,
            o.insee,
            COUNT(o.cd_ref) AS nb, 
            t.group2_inpn
        FROM atlas.vm_observations o
        JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
        AND t.group2_inpn = 'Insectes'        
        GROUP BY o.cd_ref, o.insee, t.group2_inpn
        ),
        Insectes AS (
            select count(*) as nb,
            insee
            from somme_v
            group by insee
        ),

        somme_w AS (
         SELECT DISTINCT
            o.cd_ref,
            o.insee,
            COUNT(o.cd_ref) AS nb, 
            t.group2_inpn
        FROM atlas.vm_observations o
        JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
        AND t.group2_inpn = 'Lichens'        
        GROUP BY o.cd_ref, o.insee, t.group2_inpn
        ),
        Lichens AS (
            select count(*) as nb,
            insee
            from somme_w
            group by insee
        ),

        somme_x AS (
         SELECT DISTINCT
            o.cd_ref,
            o.insee,
            COUNT(o.cd_ref) AS nb, 
            t.group2_inpn
        FROM atlas.vm_observations o
        JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
        AND t.group2_inpn = 'Mammifères'        
        GROUP BY o.cd_ref, o.insee, t.group2_inpn
        ),
        Mammiferes AS (
            select count(*) as nb,
            insee
            from somme_x
            group by insee
        ),

        somme_y AS (
         SELECT DISTINCT
            o.cd_ref,
            o.insee,
            COUNT(o.cd_ref) AS nb, 
            t.group2_inpn
        FROM atlas.vm_observations o
        JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
        AND t.group2_inpn = 'Mousses'        
        GROUP BY o.cd_ref, o.insee, t.group2_inpn
        ),
        Mousses AS (
            select count(*) as nb,
            insee
            from somme_y
            group by insee
        ),

        somme_z AS (
         SELECT DISTINCT
            o.cd_ref,
            o.insee,
            COUNT(o.cd_ref) AS nb, 
            t.group2_inpn
        FROM atlas.vm_observations o
        JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
        AND t.group2_inpn = 'Myriapodes'        
        GROUP BY o.cd_ref, o.insee, t.group2_inpn
        ),
        Myriapodes AS (
            select count(*) as nb,
            insee
            from somme_z
            group by insee
        ),

        somme_ab AS (
         SELECT DISTINCT
            o.cd_ref,
            o.insee,
            COUNT(o.cd_ref) AS nb, 
            t.group2_inpn
        FROM atlas.vm_observations o
        JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
        AND t.group2_inpn = 'Nématodes'        
        GROUP BY o.cd_ref, o.insee, t.group2_inpn
        ),
        Nematodes AS (
            select count(*) as nb,
            insee
            from somme_ab
            group by insee
        ),

        somme_ac AS (
         SELECT DISTINCT
            o.cd_ref,
            o.insee,
            COUNT(o.cd_ref) AS nb, 
            t.group2_inpn
        FROM atlas.vm_observations o
        JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
        AND t.group2_inpn = 'Némertes'        
        GROUP BY o.cd_ref, o.insee, t.group2_inpn
        ),
        Nemertes AS (
            select count(*) as nb,
            insee
            from somme_ac
            group by insee
        ),

        somme_ad AS (
         SELECT DISTINCT
            o.cd_ref,
            o.insee,
            COUNT(o.cd_ref) AS nb, 
            t.group2_inpn
        FROM atlas.vm_observations o
        JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
        AND t.group2_inpn = 'Octocoralliaires'        
        GROUP BY o.cd_ref, o.insee, t.group2_inpn
        ),
        Octocoralliaires AS (
            select count(*) as nb,
            insee
            from somme_ad
            group by insee
        ),

        somme_ae AS (
         SELECT DISTINCT
            o.cd_ref,
            o.insee,
            COUNT(o.cd_ref) AS nb, 
            t.group2_inpn
        FROM atlas.vm_observations o
        JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
        AND t.group2_inpn = 'Oiseaux'        
        GROUP BY o.cd_ref, o.insee, t.group2_inpn
        ),
        Oiseaux AS (
            select count(*) as nb,
            insee
            from somme_ae
            group by insee
        ),

        somme_af AS (
         SELECT DISTINCT
            o.cd_ref,
            o.insee,
            COUNT(o.cd_ref) AS nb, 
            t.group2_inpn
        FROM atlas.vm_observations o
        JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
        AND t.group2_inpn = 'Plathelminthes'        
        GROUP BY o.cd_ref, o.insee, t.group2_inpn
        ),
        Plathelminthes AS (
            select count(*) as nb,
            insee
            from somme_af
            group by insee
        ),

        somme_ag AS (
         SELECT DISTINCT
            o.cd_ref,
            o.insee,
            COUNT(o.cd_ref) AS nb, 
            t.group2_inpn
        FROM atlas.vm_observations o
        JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
        AND t.group2_inpn = 'Poissons'        
        GROUP BY o.cd_ref, o.insee, t.group2_inpn
        ),
        Poissons AS (
            select count(*) as nb,
            insee
            from somme_ag
            group by insee
        ),

        somme_ah AS (
         SELECT DISTINCT
            o.cd_ref,
            o.insee,
            COUNT(o.cd_ref) AS nb, 
            t.group2_inpn
        FROM atlas.vm_observations o
        JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
        AND t.group2_inpn = 'Pycnogonides'        
        GROUP BY o.cd_ref, o.insee, t.group2_inpn
        ),
        Pycnogonides AS (
            select count(*) as nb,
            insee
            from somme_ah
            group by insee
        ),

        somme_ai AS (
         SELECT DISTINCT
            o.cd_ref,
            o.insee,
            COUNT(o.cd_ref) AS nb, 
            t.group2_inpn
        FROM atlas.vm_observations o
        JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
        AND t.group2_inpn = 'Reptiles'        
        GROUP BY o.cd_ref, o.insee, t.group2_inpn
        ),
        Reptiles AS (
            select count(*) as nb,
            insee
            from somme_ai
            group by insee
        ),

        somme_aj AS (
         SELECT DISTINCT
            o.cd_ref,
            o.insee,
            COUNT(o.cd_ref) AS nb, 
            t.group2_inpn
        FROM atlas.vm_observations o
        JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
        AND t.group2_inpn = 'Scléractiniaires'        
        GROUP BY o.cd_ref, o.insee, t.group2_inpn
        ),
        Scleractiniaires AS (
            select count(*) as nb,
            insee
            from somme_aj
            group by insee
        )



 SELECT DISTINCT o.insee,
    COALESCE(a.nb::integer, 0) AS Acanthocephales,
    COALESCE(b.nb::integer, 0) AS Algues_brunes,
    COALESCE(c.nb::integer, 0) AS Algues_rouges,
    COALESCE(d.nb::integer, 0) AS Algues_vertes,
    COALESCE(e.nb::integer, 0) AS Amphibiens,
    COALESCE(f.nb::integer, 0) AS Angiospermes,
    COALESCE(g.nb::integer, 0) AS Annelides,
    COALESCE(h.nb::integer, 0) AS Arachnides,
    COALESCE(i.nb::integer, 0) AS Ascidies,
    COALESCE(j.nb::integer, 0) AS Autres,
    COALESCE(k.nb::integer, 0) AS Bivalves,
    COALESCE(l.nb::integer, 0) AS Cephalopodes,
    COALESCE(m.nb::integer, 0) AS Crustaces,
    COALESCE(n.nb::integer, 0) AS Diatomees,
    COALESCE(p.nb::integer, 0) AS Entognathes,
    COALESCE(q.nb::integer, 0) AS Fougeres,
    COALESCE(r.nb::integer, 0) AS Gasteropodes,
    COALESCE(s.nb::integer, 0) AS Gymnospermes,
    COALESCE(t.nb::integer, 0) AS Hepatiques_Anthocerotes,
    COALESCE(u.nb::integer, 0) AS Hydrozoaires,
    COALESCE(v.nb::integer, 0) AS Insectes,
    COALESCE(w.nb::integer, 0) AS Lichens,
    COALESCE(x.nb::integer, 0) AS Mammiferes,
    COALESCE(y.nb::integer, 0) AS Mousses,
    COALESCE(z.nb::integer, 0) AS Myriapodes,
    COALESCE(ab.nb::integer, 0) AS Nematodes,
    COALESCE(ac.nb::integer, 0) AS Nemertes,
    COALESCE(ad.nb::integer, 0) AS Octocoralliaires,
    COALESCE(ae.nb::integer, 0) AS Oiseaux,
    COALESCE(af.nb::integer, 0) AS Plathelminthes,
    COALESCE(ag.nb::integer, 0) AS Poissons,
    COALESCE(ah.nb::integer, 0) AS Pycnogonides,
    COALESCE(ai.nb::integer, 0) AS Reptiles,
    COALESCE(aj.nb::integer, 0) AS Scleractiniaires

    FROM atlas.vm_observations o

     LEFT JOIN Acanthocephales a ON a.insee = o.insee
     LEFT JOIN Algues_brunes b ON b.insee = o.insee
     LEFT JOIN Algues_rouges c ON c.insee = o.insee
     LEFT JOIN Algues_vertes d ON d.insee = o.insee
     LEFT JOIN Amphibiens e ON e.insee = o.insee
     LEFT JOIN Angiospermes f ON f.insee = o.insee
     LEFT JOIN Annelides g ON g.insee = o.insee
     LEFT JOIN Arachnides h ON h.insee = o.insee
     LEFT JOIN Ascidies i ON i.insee = o.insee
     LEFT JOIN Autres j ON j.insee = o.insee
     LEFT JOIN Bivalves k ON k.insee = o.insee
     LEFT JOIN Cephalopodes l ON l.insee = o.insee
     LEFT JOIN Crustaces m ON m.insee = o.insee
     LEFT JOIN Diatomees n ON n.insee = o.insee
     LEFT JOIN Entognathes p ON p.insee = o.insee
     LEFT JOIN Fougeres q ON q.insee = o.insee
     LEFT JOIN Gasteropodes r ON r.insee = o.insee
     LEFT JOIN Gymnospermes s ON s.insee = o.insee
     LEFT JOIN Hepatiques_Anthocerotes t ON t.insee = o.insee
     LEFT JOIN Hydrozoaires u ON u.insee = o.insee
     LEFT JOIN Insectes v ON v.insee = o.insee
     LEFT JOIN Lichens w ON w.insee = o.insee
     LEFT JOIN Mammiferes x ON x.insee = o.insee
     LEFT JOIN Mousses y ON y.insee = o.insee
     LEFT JOIN Myriapodes z ON z.insee = o.insee
     LEFT JOIN Nematodes ab ON ab.insee = o.insee
     LEFT JOIN Nemertes ac ON ac.insee = o.insee
     LEFT JOIN Octocoralliaires ad ON ad.insee = o.insee
     LEFT JOIN Oiseaux ae ON ae.insee = o.insee
     LEFT JOIN Plathelminthes af ON af.insee = o.insee
     LEFT JOIN Poissons ag ON ag.insee = o.insee
     LEFT JOIN Pycnogonides ah ON ah.insee = o.insee
     LEFT JOIN Reptiles ai ON ai.insee = o.insee
     LEFT JOIN Scleractiniaires aj ON aj.insee = o.insee


  WHERE o.insee IS NOT NULL
  ORDER BY o.insee

WITH DATA;

ALTER TABLE atlas.vm_stats_espece_group2inpn_comm
  OWNER TO geonatuser;
GRANT ALL ON TABLE atlas.vm_stats_espece_group2inpn_comm TO geonatuser;
GRANT SELECT ON TABLE atlas.vm_stats_espece_group2inpn_comm TO geonatatlas;

-- Index: atlas.vm_stats_espece_group2inpn_comm_insee_idx

-- DROP INDEX atlas.vm_stats_espece_group2inpn_comm_insee_idx;

CREATE UNIQUE INDEX vm_stats_espece_group2inpn_comm_insee_idx
  ON atlas.vm_stats_espece_group2inpn_comm
  USING btree (insee);





/* stats nb obs par group2_inpn pour chaque departement */

-- Materialized View: atlas.vm_stats_espece_group2inpn_dpt
-- DROP MATERIALIZED VIEW atlas.vm_stats_espece_group2inpn_dpt;

CREATE MATERIALIZED VIEW atlas.vm_stats_espece_group2inpn_dpt AS 

 SELECT DISTINCT left(insee,2) AS num_dpt,
    SUM(Acanthocephales) AS Acanthocephales, 
    SUM(Algues_brunes) AS Algues_brunes, 
    SUM(Algues_rouges) AS Algues_rouges,
    SUM(Algues_vertes) AS Algues_vertes,
    SUM(Amphibiens) AS Amphibiens,
    SUM(Angiospermes) AS Angiospermes,
    SUM(Annelides) AS Annelides, 
    SUM(Arachnides) AS Arachnides,
    SUM(Ascidies) AS Ascidies,
    SUM(Autres) AS Autres, 
    SUM(Bivalves) AS Bivalves,
    SUM(Cephalopodes) AS Cephalopodes, 
    SUM(Crustaces) AS Crustaces,
    SUM(Diatomees) AS Diatomees,
    SUM(Entognathes) AS Entognathes, 
    SUM(Fougeres) AS Fougeres,
    SUM(Gasteropodes) AS Gasteropodes, 
    SUM(Gymnospermes) AS Gymnospermes,
    SUM(Hepatiques_Anthocerotes) AS Hepatiques_Anthocerotes,
    SUM(Hydrozoaires) AS Hydrozoaires, 
    SUM(Insectes) AS Insectes,
    SUM(Lichens) AS Lichens, 
    SUM(Mammiferes) AS Mammiferes,
    SUM(Mousses) AS Mousses,
    SUM(Myriapodes) AS Myriapodes, 
    SUM(Nematodes) AS Nematodes, 
    SUM(Nemertes) AS Nemertes,
    SUM(Octocoralliaires) AS Octocoralliaires,
    SUM(Oiseaux) AS Oiseaux, 
    SUM(Plathelminthes) AS Plathelminthes, 
    SUM(Poissons) AS Poissons,
    SUM(Pycnogonides) AS Pycnogonides,
    SUM(Reptiles) AS Reptiles, 
    SUM(Scleractiniaires) AS Scleractiniaires 

   FROM atlas.vm_stats_espece_group2inpn_comm
 
  GROUP BY num_dpt
  ORDER BY num_dpt

WITH DATA;

ALTER TABLE atlas.vm_stats_espece_group2inpn_dpt
  OWNER TO geonatuser;
GRANT ALL ON TABLE atlas.vm_stats_espece_group2inpn_dpt TO geonatuser;
GRANT SELECT ON TABLE atlas.vm_stats_espece_group2inpn_dpt TO geonatatlas;

-- Index: atlas.vm_stats_espece_group2inpn_dpt_idx

-- DROP INDEX atlas.vm_stats_espece_group2inpn_dpt_idx;

CREATE UNIQUE INDEX vm_stats_espece_group2inpn_dpt_idx
  ON atlas.vm_stats_espece_group2inpn_dpt
  USING btree (num_dpt);





/* stats nb obs par group2_inpn pour la région */

-- Materialized View: atlas.vm_stats_espece_group2inpn_pdl
-- DROP MATERIALIZED VIEW atlas.vm_stats_espece_group2inpn_pdl;


CREATE MATERIALIZED VIEW atlas.vm_stats_espece_group2inpn_pdl AS 

 SELECT 'Pays de la Loire'::text AS nom_region,
    SUM(Acanthocephales) AS Acanthocephales, 
    SUM(Algues_brunes) AS Algues_brunes, 
    SUM(Algues_rouges) AS Algues_rouges,
    SUM(Algues_vertes) AS Algues_vertes,
    SUM(Amphibiens) AS Amphibiens,
    SUM(Angiospermes) AS Angiospermes,
    SUM(Annelides) AS Annelides, 
    SUM(Arachnides) AS Arachnides,
    SUM(Ascidies) AS Ascidies,
    SUM(Autres) AS Autres, 
    SUM(Bivalves) AS Bivalves,
    SUM(Cephalopodes) AS Cephalopodes, 
    SUM(Crustaces) AS Crustaces,
    SUM(Diatomees) AS Diatomees,
    SUM(Entognathes) AS Entognathes, 
    SUM(Fougeres) AS Fougeres,
    SUM(Gasteropodes) AS Gasteropodes, 
    SUM(Gymnospermes) AS Gymnospermes,
    SUM(Hepatiques_Anthocerotes) AS Hepatiques_Anthocerotes,
    SUM(Hydrozoaires) AS Hydrozoaires, 
    SUM(Insectes) AS Insectes,
    SUM(Lichens) AS Lichens, 
    SUM(Mammiferes) AS Mammiferes,
    SUM(Mousses) AS Mousses,
    SUM(Myriapodes) AS Myriapodes, 
    SUM(Nematodes) AS Nematodes, 
    SUM(Nemertes) AS Nemertes,
    SUM(Octocoralliaires) AS Octocoralliaires,
    SUM(Oiseaux) AS Oiseaux, 
    SUM(Plathelminthes) AS Plathelminthes, 
    SUM(Poissons) AS Poissons,
    SUM(Pycnogonides) AS Pycnogonides,
    SUM(Reptiles) AS Reptiles, 
    SUM(Scleractiniaires) AS Scleractiniaires 

   FROM atlas.vm_stats_group2inpn_dpt

   WHERE num_dpt = '44' OR num_dpt = '49' OR num_dpt = '53' OR num_dpt = '72' OR num_dpt = '85'

WITH DATA;

ALTER TABLE atlas.vm_stats_espece_group2inpn_pdl
  OWNER TO geonatuser;
GRANT ALL ON TABLE atlas.vm_stats_espece_group2inpn_pdl TO geonatuser;
GRANT SELECT ON TABLE atlas.vm_stats_espece_group2inpn_pdl TO geonatatlas;



