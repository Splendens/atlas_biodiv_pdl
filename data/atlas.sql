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

CREATE UNIQUE INDEX vm_organismes_idx
  ON atlas.vm_organismes
  USING btree  (id_organisme);


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


/* stats nb obs par structure pour chaque EPCI */


CREATE MATERIALIZED VIEW atlas.vm_stats_orga_epci AS 
 WITH _03 AS (
        SELECT vm_epci.nom_epci_simple,
            count(*) AS nbobs,
            count(DISTINCT vm_observations.cd_ref) AS nbtaxon
        FROM atlas.vm_observations
          JOIN atlas.vm_taxons ON vm_taxons.cd_ref = vm_observations.cd_ref
          JOIN atlas.l_communes_epci ON l_communes_epci.insee = vm_observations.insee
          JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
        WHERE vm_observations.id_organisme = 3
        GROUP BY vm_epci.nom_epci_simple
        ), _04 AS (
        SELECT vm_epci.nom_epci_simple,
            count(*) AS nbobs,
            count(DISTINCT vm_observations.cd_ref) AS nbtaxon
        FROM atlas.vm_observations
          JOIN atlas.vm_taxons ON vm_taxons.cd_ref = vm_observations.cd_ref
          JOIN atlas.l_communes_epci ON l_communes_epci.insee = vm_observations.insee
          JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
        WHERE vm_observations.id_organisme = 4
        GROUP BY vm_epci.nom_epci_simple
        ), _05 AS (
        SELECT vm_epci.nom_epci_simple,
            count(*) AS nbobs,
            count(DISTINCT vm_observations.cd_ref) AS nbtaxon
        FROM atlas.vm_observations
          JOIN atlas.vm_taxons ON vm_taxons.cd_ref = vm_observations.cd_ref
          JOIN atlas.l_communes_epci ON l_communes_epci.insee = vm_observations.insee
          JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
        WHERE vm_observations.id_organisme = 5
        GROUP BY vm_epci.nom_epci_simple
        ), _06 AS (
        SELECT vm_epci.nom_epci_simple,
            count(*) AS nbobs,
            count(DISTINCT vm_observations.cd_ref) AS nbtaxon
        FROM atlas.vm_observations
          JOIN atlas.vm_taxons ON vm_taxons.cd_ref = vm_observations.cd_ref
          JOIN atlas.l_communes_epci ON l_communes_epci.insee = vm_observations.insee
          JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
        WHERE vm_observations.id_organisme = 6
        GROUP BY vm_epci.nom_epci_simple
        ), _09 AS (
        SELECT vm_epci.nom_epci_simple,
            count(*) AS nbobs,
            count(DISTINCT vm_observations.cd_ref) AS nbtaxon
        FROM atlas.vm_observations
          JOIN atlas.vm_taxons ON vm_taxons.cd_ref = vm_observations.cd_ref
          JOIN atlas.l_communes_epci ON l_communes_epci.insee = vm_observations.insee
          JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
        WHERE vm_observations.id_organisme = 9
        GROUP BY vm_epci.nom_epci_simple
        ), _70 AS (
        SELECT vm_epci.nom_epci_simple,
            count(*) AS nbobs,
            count(DISTINCT vm_observations.cd_ref) AS nbtaxon
        FROM atlas.vm_observations
          JOIN atlas.vm_taxons ON vm_taxons.cd_ref = vm_observations.cd_ref
          JOIN atlas.l_communes_epci ON l_communes_epci.insee = vm_observations.insee
          JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
        WHERE vm_observations.id_organisme = 70
        GROUP BY vm_epci.nom_epci_simple
        ), _80 AS (
        SELECT vm_epci.nom_epci_simple,
            count(*) AS nbobs,
            count(DISTINCT vm_observations.cd_ref) AS nbtaxon
        FROM atlas.vm_observations
          JOIN atlas.vm_taxons ON vm_taxons.cd_ref = vm_observations.cd_ref
          JOIN atlas.l_communes_epci ON l_communes_epci.insee = vm_observations.insee
          JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
        WHERE vm_observations.id_organisme = 80
        GROUP BY vm_epci.nom_epci_simple
        ), _81 AS (
        SELECT vm_epci.nom_epci_simple,
            count(*) AS nbobs,
            count(DISTINCT vm_observations.cd_ref) AS nbtaxon
        FROM atlas.vm_observations
          JOIN atlas.vm_taxons ON vm_taxons.cd_ref = vm_observations.cd_ref
          JOIN atlas.l_communes_epci ON l_communes_epci.insee = vm_observations.insee
          JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
        WHERE vm_observations.id_organisme = 81
        GROUP BY vm_epci.nom_epci_simple
        ), _82 AS (
        SELECT vm_epci.nom_epci_simple,
            count(*) AS nbobs,
            count(DISTINCT vm_observations.cd_ref) AS nbtaxon
        FROM atlas.vm_observations
          JOIN atlas.vm_taxons ON vm_taxons.cd_ref = vm_observations.cd_ref
          JOIN atlas.l_communes_epci ON l_communes_epci.insee = vm_observations.insee
          JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
        WHERE vm_observations.id_organisme = 82
        GROUP BY vm_epci.nom_epci_simple
        ), _83 AS (
        SELECT vm_epci.nom_epci_simple,
            count(*) AS nbobs,
            count(DISTINCT vm_observations.cd_ref) AS nbtaxon
        FROM atlas.vm_observations
          JOIN atlas.vm_taxons ON vm_taxons.cd_ref = vm_observations.cd_ref
          JOIN atlas.l_communes_epci ON l_communes_epci.insee = vm_observations.insee
          JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
        WHERE vm_observations.id_organisme = 83
        GROUP BY vm_epci.nom_epci_simple
        ), _84 AS (
        SELECT vm_epci.nom_epci_simple,
            count(*) AS nbobs,
            count(DISTINCT vm_observations.cd_ref) AS nbtaxon
        FROM atlas.vm_observations
          JOIN atlas.vm_taxons ON vm_taxons.cd_ref = vm_observations.cd_ref
          JOIN atlas.l_communes_epci ON l_communes_epci.insee = vm_observations.insee
          JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
        WHERE vm_observations.id_organisme = 84
        GROUP BY vm_epci.nom_epci_simple
        )
 SELECT DISTINCT o.nom_epci_simple,
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
   FROM atlas.vm_epci o

     LEFT JOIN _03 a ON a.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN _04 b ON b.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN _05 c ON c.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN _06 d ON d.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN _09 e ON e.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN _70 f ON f.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN _80 g ON g.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN _81 h ON h.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN _82 i ON i.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN _83 j ON j.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN _84 k ON k.nom_epci_simple = o.nom_epci_simple
  WHERE o.nom_epci_simple IS NOT NULL
  ORDER BY o.nom_epci_simple

WITH DATA;

ALTER TABLE atlas.vm_stats_orga_epci
  OWNER TO geonatuser;
GRANT ALL ON TABLE atlas.vm_stats_orga_epci TO geonatuser;
GRANT SELECT ON TABLE atlas.vm_stats_orga_epci TO geonatatlas;

-- Index: atlas.vm_stats_orga_epci_insee_idx

-- DROP INDEX atlas.vm_stats_orga_epci_insee_idx;

CREATE UNIQUE INDEX vm_stats_orga_epci_nomsimple_idx
  ON atlas.vm_stats_orga_epci
  USING btree
  (nom_epci_simple COLLATE pg_catalog."default");





/* stats nb obs par structure pour chaque departement */


-- Materialized View: atlas.vm_stats_orga_dpt
-- DROP MATERIALIZED VIEW atlas.vm_stats_orga_dpt;
CREATE MATERIALIZED VIEW atlas.vm_stats_orga_dpt AS 
  WITH 
        _03 AS /*CEN Pays de la Loire*/
        (
         SELECT left(vm_observations.insee,2) AS num_dpt,
            count(*) AS nbobs,
            count(DISTINCT vm_observations.cd_ref) AS nbtaxon
           FROM atlas.vm_observations
           JOIN atlas.vm_taxons t ON t.cd_ref=vm_observations.cd_ref
          WHERE vm_observations.id_organisme = 3
          GROUP BY left(vm_observations.insee,2)
        ), 
        _04 AS /*PNR Normandie Maine*/
        (
         SELECT left(vm_observations.insee,2) AS num_dpt,
            count(*) AS nbobs,
            count(DISTINCT vm_observations.cd_ref) AS nbtaxon
           FROM atlas.vm_observations
           JOIN atlas.vm_taxons t ON t.cd_ref=vm_observations.cd_ref
          WHERE vm_observations.id_organisme = 4
          GROUP BY left(vm_observations.insee,2)
        ), 
        _05 AS /*GRETIA*/
        (
         SELECT left(vm_observations.insee,2) AS num_dpt,
            count(*) AS nbobs,
            count(DISTINCT vm_observations.cd_ref) AS nbtaxon
           FROM atlas.vm_observations
           JOIN atlas.vm_taxons t ON t.cd_ref=vm_observations.cd_ref
          WHERE vm_observations.id_organisme = 5
          GROUP BY left(vm_observations.insee,2)
        ), 
        _06 AS /*CBN de Brest*/
        (
         SELECT left(vm_observations.insee,2) AS num_dpt,
            count(*) AS nbobs,
            count(DISTINCT vm_observations.cd_ref) AS nbtaxon
           FROM atlas.vm_observations
           JOIN atlas.vm_taxons t ON t.cd_ref=vm_observations.cd_ref
          WHERE vm_observations.id_organisme = 6
          GROUP BY left(vm_observations.insee,2)
        ), 
        _09 AS /*DREAL Pays de la Loire*/
        (
         SELECT left(vm_observations.insee,2) AS num_dpt,
            count(*) AS nbobs,
            count(DISTINCT vm_observations.cd_ref) AS nbtaxon
           FROM atlas.vm_observations
           JOIN atlas.vm_taxons t ON t.cd_ref=vm_observations.cd_ref
          WHERE vm_observations.id_organisme = 9
          GROUP BY left(vm_observations.insee,2)
        ), 
        _70 AS /*URCPIE*/
        (
         SELECT left(vm_observations.insee,2) AS num_dpt,
            count(*) AS nbobs,
            count(DISTINCT vm_observations.cd_ref) AS nbtaxon
           FROM atlas.vm_observations
           JOIN atlas.vm_taxons t ON t.cd_ref=vm_observations.cd_ref
          WHERE vm_observations.id_organisme = 70
          GROUP BY left(vm_observations.insee,2)
        ), 
        _80 AS /*Coordi. LPO*/
        (
         SELECT left(vm_observations.insee,2) AS num_dpt,
            count(*) AS nbobs,
            count(DISTINCT vm_observations.cd_ref) AS nbtaxon
           FROM atlas.vm_observations
           JOIN atlas.vm_taxons t ON t.cd_ref=vm_observations.cd_ref
          WHERE vm_observations.id_organisme = 80
          GROUP BY left(vm_observations.insee,2)
        ), 
        _81 AS /*LPO Anjou*/
        (
         SELECT left(vm_observations.insee,2) AS num_dpt,
            count(*) AS nbobs,
            count(DISTINCT vm_observations.cd_ref) AS nbtaxon
           FROM atlas.vm_observations
           JOIN atlas.vm_taxons t ON t.cd_ref=vm_observations.cd_ref
          WHERE vm_observations.id_organisme = 81
          GROUP BY left(vm_observations.insee,2)
        ), 
        _82 AS /*LPO Loire-Atlantique*/
        (
        SELECT left(vm_observations.insee,2) AS num_dpt,
            count(*) AS nbobs,
            count(DISTINCT vm_observations.cd_ref) AS nbtaxon
           FROM atlas.vm_observations
           JOIN atlas.vm_taxons t ON t.cd_ref=vm_observations.cd_ref
          WHERE vm_observations.id_organisme = 82
          GROUP BY left(vm_observations.insee,2)
        ),
        _83 AS /*LPO Vendée*/
        (
         SELECT left(vm_observations.insee,2) AS num_dpt,
            count(*) AS nbobs,
            count(DISTINCT vm_observations.cd_ref) AS nbtaxon
           FROM atlas.vm_observations
           JOIN atlas.vm_taxons t ON t.cd_ref=vm_observations.cd_ref
          WHERE vm_observations.id_organisme = 83
          GROUP BY left(vm_observations.insee,2)
        ), 
        _84 AS /*LPO Sarthe*/
        (
         SELECT left(vm_observations.insee,2) AS num_dpt,
            count(*) AS nbobs,
            count(DISTINCT vm_observations.cd_ref) AS nbtaxon
           FROM atlas.vm_observations
           JOIN atlas.vm_taxons t ON t.cd_ref=vm_observations.cd_ref
          WHERE vm_observations.id_organisme = 84
          GROUP BY left(vm_observations.insee,2)
        )
 SELECT DISTINCT left(o.insee,2)::text AS num_dpt,
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
     LEFT JOIN _03 a ON a.num_dpt = left(o.insee,2) /*CEN Pays de la Loire*/
     LEFT JOIN _04 b ON b.num_dpt = left(o.insee,2) /*PNR Normandie Maine*/
     LEFT JOIN _05 c ON c.num_dpt = left(o.insee,2) /*GRETIA*/
     LEFT JOIN _06 d ON d.num_dpt = left(o.insee,2) /*CBN de Brest*/
     LEFT JOIN _09 e ON e.num_dpt = left(o.insee,2) /*DREAL Pays de la Loire*/
     LEFT JOIN _70 f ON f.num_dpt = left(o.insee,2) /*URCPIE*/
     LEFT JOIN _80 g ON g.num_dpt = left(o.insee,2) /*Coordi. LPO*/
     LEFT JOIN _81 h ON h.num_dpt = left(o.insee,2) /*LPO Anjou*/
     LEFT JOIN _82 i ON i.num_dpt = left(o.insee,2) /*LPO Loire-Atlantique*/
     LEFT JOIN _83 j ON j.num_dpt = left(o.insee,2) /*LPO Vendée*/
     LEFT JOIN _84 k ON k.num_dpt = left(o.insee,2) /*LPO Sarthe*/
  WHERE o.insee IS NOT NULL
  ORDER BY num_dpt
WITH DATA;

ALTER TABLE atlas.vm_stats_orga_dpt
  OWNER TO geonatuser;
GRANT ALL ON TABLE atlas.vm_stats_orga_dpt TO geonatuser;
GRANT SELECT ON TABLE atlas.vm_stats_orga_dpt TO geonatatlas;

-- Index: atlas.vm_stats_orga_dpt_num_dpt_idx

-- DROP INDEX atlas.vm_stats_orga_dpt_num_dpt_idx;

CREATE UNIQUE INDEX vm_stats_orga_dpt_num_dpt_idx
  ON atlas.vm_stats_orga_dpt
  USING btree (num_dpt);



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
          JOIN atlas.vm_taxons ON vm_taxons.cd_ref = vm_observations.cd_ref
          WHERE vm_observations.id_organisme = 3
          GROUP BY vm_observations.insee
        ), 
        _04 AS /*PNR Normandie Maine*/
        (
         SELECT vm_observations.insee,
            count(*) AS nbobs,
            count(distinct vm_observations.cd_ref) AS nbtaxon
          FROM atlas.vm_observations
          JOIN atlas.vm_taxons ON vm_taxons.cd_ref = vm_observations.cd_ref
          WHERE vm_observations.id_organisme = 4
          GROUP BY vm_observations.insee
        ), 
        _05 AS /*GRETIA*/
        (
         SELECT vm_observations.insee,
            count(*) AS nbobs,
            count(distinct vm_observations.cd_ref) AS nbtaxon
          FROM atlas.vm_observations
          JOIN atlas.vm_taxons ON vm_taxons.cd_ref = vm_observations.cd_ref
          WHERE vm_observations.id_organisme = 5
          GROUP BY vm_observations.insee
        ), 
        _06 AS /*CBN de Brest*/
        (
          SELECT vm_observations.insee,
            count(*) AS nbobs,
            count(distinct vm_observations.cd_ref) AS nbtaxon
          FROM atlas.vm_observations
          JOIN atlas.vm_taxons ON vm_taxons.cd_ref = vm_observations.cd_ref
          WHERE vm_observations.id_organisme = 6
          GROUP BY vm_observations.insee
        ), 
        _09 AS /*DREAL Pays de la Loire*/
        (
         SELECT vm_observations.insee,
            count(*) AS nbobs,
            count(distinct vm_observations.cd_ref) AS nbtaxon
          FROM atlas.vm_observations
          JOIN atlas.vm_taxons ON vm_taxons.cd_ref = vm_observations.cd_ref
          WHERE vm_observations.id_organisme = 9
          GROUP BY vm_observations.insee
        ), 
        _70 AS /*URCPIE*/
        (
         SELECT vm_observations.insee,
            count(*) AS nbobs,
            count(distinct vm_observations.cd_ref) AS nbtaxon
          FROM atlas.vm_observations
          JOIN atlas.vm_taxons ON vm_taxons.cd_ref = vm_observations.cd_ref
          WHERE vm_observations.id_organisme = 70
          GROUP BY vm_observations.insee
        ), 
        _80 AS /*Coordi. LPO*/
        (
         SELECT vm_observations.insee,
            count(*) AS nbobs,
            count(distinct vm_observations.cd_ref) AS nbtaxon
          FROM atlas.vm_observations
          JOIN atlas.vm_taxons ON vm_taxons.cd_ref = vm_observations.cd_ref
          WHERE vm_observations.id_organisme = 80
          GROUP BY vm_observations.insee
        ), 
        _81 AS /*LPO Anjou*/
        (
         SELECT vm_observations.insee,
            count(*) AS nbobs,
            count(distinct vm_observations.cd_ref) AS nbtaxon
          FROM atlas.vm_observations
          JOIN atlas.vm_taxons ON vm_taxons.cd_ref = vm_observations.cd_ref
          WHERE vm_observations.id_organisme = 81
          GROUP BY vm_observations.insee
        ), 
        _82 AS /*LPO Loire-Atlantique*/
        (
         SELECT vm_observations.insee,
            count(*) AS nbobs,
            count(distinct vm_observations.cd_ref) AS nbtaxon
          FROM atlas.vm_observations
          JOIN atlas.vm_taxons ON vm_taxons.cd_ref = vm_observations.cd_ref
          WHERE vm_observations.id_organisme = 82
          GROUP BY vm_observations.insee
        ),
        _83 AS /*LPO Vendée*/
        (
         SELECT vm_observations.insee,
            count(*) AS nbobs,
            count(distinct vm_observations.cd_ref) AS nbtaxon
          FROM atlas.vm_observations
          JOIN atlas.vm_taxons ON vm_taxons.cd_ref = vm_observations.cd_ref
          WHERE vm_observations.id_organisme = 83
          GROUP BY vm_observations.insee
        ), 
        _84 AS /*LPO Sarthe*/
        (
         SELECT vm_observations.insee,
            count(*) AS nbobs,
            count(distinct vm_observations.cd_ref) AS nbtaxon
          FROM atlas.vm_observations
          JOIN atlas.vm_taxons ON vm_taxons.cd_ref = vm_observations.cd_ref
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



/* stats nb obs par group2_inpn pour chaque EPCI */

-- Materialized View: atlas.vm_stats_group2inpn_epci

-- DROP MATERIALIZED VIEW atlas.vm_stats_group2inpn_epci;

CREATE MATERIALIZED VIEW atlas.vm_stats_group2inpn_epci AS 
 WITH cd_ref AS (
         SELECT vm_taxref.cd_ref,
            vm_taxref.group2_inpn
           FROM atlas.vm_taxref
          WHERE vm_taxref.cd_ref = vm_taxref.cd_nom
        ), acanthocephales AS (
         SELECT vm_epci.nom_epci_simple,
            count(*) AS nb
           FROM atlas.vm_observations s_1
             JOIN atlas.l_communes_epci ON l_communes_epci.insee = s_1.insee
             JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
             LEFT JOIN cd_ref tx ON tx.cd_ref = s_1.cd_ref
          WHERE tx.group2_inpn::text = 'Acanthocéphales'::text
          GROUP BY vm_epci.nom_epci_simple
        ), algues_brunes AS (
         SELECT vm_epci.nom_epci_simple,
            count(*) AS nb
           FROM atlas.vm_observations s_1
             JOIN atlas.l_communes_epci ON l_communes_epci.insee = s_1.insee
             JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
             LEFT JOIN cd_ref tx ON tx.cd_ref = s_1.cd_ref
          WHERE tx.group2_inpn::text = 'Algues brunes'::text
          GROUP BY vm_epci.nom_epci_simple
        ), algues_rouges AS (
         SELECT vm_epci.nom_epci_simple,
            count(*) AS nb
           FROM atlas.vm_observations s_1
             JOIN atlas.l_communes_epci ON l_communes_epci.insee = s_1.insee
             JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
             LEFT JOIN cd_ref tx ON tx.cd_ref = s_1.cd_ref
          WHERE tx.group2_inpn::text = 'Algues rouges'::text
          GROUP BY vm_epci.nom_epci_simple
        ), algues_vertes AS (
         SELECT vm_epci.nom_epci_simple,
            count(*) AS nb
           FROM atlas.vm_observations s_1
             JOIN atlas.l_communes_epci ON l_communes_epci.insee = s_1.insee
             JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
             LEFT JOIN cd_ref tx ON tx.cd_ref = s_1.cd_ref
          WHERE tx.group2_inpn::text = 'Algues vertes'::text
          GROUP BY vm_epci.nom_epci_simple
        ), amphibiens AS (
         SELECT vm_epci.nom_epci_simple,
            count(*) AS nb
           FROM atlas.vm_observations s_1
             JOIN atlas.l_communes_epci ON l_communes_epci.insee = s_1.insee
             JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
             LEFT JOIN cd_ref tx ON tx.cd_ref = s_1.cd_ref
          WHERE tx.group2_inpn::text = 'Amphibiens'::text
          GROUP BY vm_epci.nom_epci_simple
        ), angiospermes AS (
         SELECT vm_epci.nom_epci_simple,
            count(*) AS nb
           FROM atlas.vm_observations s_1
             JOIN atlas.l_communes_epci ON l_communes_epci.insee = s_1.insee
             JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
             LEFT JOIN cd_ref tx ON tx.cd_ref = s_1.cd_ref
          WHERE tx.group2_inpn::text = 'Angiospermes'::text
          GROUP BY vm_epci.nom_epci_simple
        ), annelides AS (
         SELECT vm_epci.nom_epci_simple,
            count(*) AS nb
           FROM atlas.vm_observations s_1
             JOIN atlas.l_communes_epci ON l_communes_epci.insee = s_1.insee
             JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
             LEFT JOIN cd_ref tx ON tx.cd_ref = s_1.cd_ref
          WHERE tx.group2_inpn::text = 'Annélides'::text
          GROUP BY vm_epci.nom_epci_simple
        ), arachnides AS (
         SELECT vm_epci.nom_epci_simple,
            count(*) AS nb
           FROM atlas.vm_observations s_1
             JOIN atlas.l_communes_epci ON l_communes_epci.insee = s_1.insee
             JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
             LEFT JOIN cd_ref tx ON tx.cd_ref = s_1.cd_ref
          WHERE tx.group2_inpn::text = 'Arachnides'::text
          GROUP BY vm_epci.nom_epci_simple
        ), ascidies AS (
         SELECT vm_epci.nom_epci_simple,
            count(*) AS nb
           FROM atlas.vm_observations s_1
             JOIN atlas.l_communes_epci ON l_communes_epci.insee = s_1.insee
             JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
             LEFT JOIN cd_ref tx ON tx.cd_ref = s_1.cd_ref
          WHERE tx.group2_inpn::text = 'Ascidies'::text
          GROUP BY vm_epci.nom_epci_simple
        ), autres AS (
         SELECT vm_epci.nom_epci_simple,
            count(*) AS nb
           FROM atlas.vm_observations s_1
             JOIN atlas.l_communes_epci ON l_communes_epci.insee = s_1.insee
             JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
             LEFT JOIN cd_ref tx ON tx.cd_ref = s_1.cd_ref
          WHERE tx.group2_inpn::text = 'Autres'::text
          GROUP BY vm_epci.nom_epci_simple
        ), bivalves AS (
         SELECT vm_epci.nom_epci_simple,
            count(*) AS nb
           FROM atlas.vm_observations s_1
             JOIN atlas.l_communes_epci ON l_communes_epci.insee = s_1.insee
             JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
             LEFT JOIN cd_ref tx ON tx.cd_ref = s_1.cd_ref
          WHERE tx.group2_inpn::text = 'Bivalves'::text
          GROUP BY vm_epci.nom_epci_simple
        ), cephalopodes AS (
         SELECT vm_epci.nom_epci_simple,
            count(*) AS nb
           FROM atlas.vm_observations s_1
             JOIN atlas.l_communes_epci ON l_communes_epci.insee = s_1.insee
             JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
             LEFT JOIN cd_ref tx ON tx.cd_ref = s_1.cd_ref
          WHERE tx.group2_inpn::text = 'Céphalopodes'::text
          GROUP BY vm_epci.nom_epci_simple
        ), crustaces AS (
         SELECT vm_epci.nom_epci_simple,
            count(*) AS nb
           FROM atlas.vm_observations s_1
             JOIN atlas.l_communes_epci ON l_communes_epci.insee = s_1.insee
             JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
             LEFT JOIN cd_ref tx ON tx.cd_ref = s_1.cd_ref
          WHERE tx.group2_inpn::text = 'Crustacés'::text
          GROUP BY vm_epci.nom_epci_simple
        ), diatomees AS (
         SELECT vm_epci.nom_epci_simple,
            count(*) AS nb
           FROM atlas.vm_observations s_1
             JOIN atlas.l_communes_epci ON l_communes_epci.insee = s_1.insee
             JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
             LEFT JOIN cd_ref tx ON tx.cd_ref = s_1.cd_ref
          WHERE tx.group2_inpn::text = 'Diatomées'::text
          GROUP BY vm_epci.nom_epci_simple
        ), entognathes AS (
         SELECT vm_epci.nom_epci_simple,
            count(*) AS nb
           FROM atlas.vm_observations s_1
             JOIN atlas.l_communes_epci ON l_communes_epci.insee = s_1.insee
             JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
             LEFT JOIN cd_ref tx ON tx.cd_ref = s_1.cd_ref
          WHERE tx.group2_inpn::text = 'Entognathes'::text
          GROUP BY vm_epci.nom_epci_simple
        ), fougeres AS (
         SELECT vm_epci.nom_epci_simple,
            count(*) AS nb
           FROM atlas.vm_observations s_1
             JOIN atlas.l_communes_epci ON l_communes_epci.insee = s_1.insee
             JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
             LEFT JOIN cd_ref tx ON tx.cd_ref = s_1.cd_ref
          WHERE tx.group2_inpn::text = 'Fougères'::text
          GROUP BY vm_epci.nom_epci_simple
        ), gasteropodes AS (
         SELECT vm_epci.nom_epci_simple,
            count(*) AS nb
           FROM atlas.vm_observations s_1
             JOIN atlas.l_communes_epci ON l_communes_epci.insee = s_1.insee
             JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
             LEFT JOIN cd_ref tx ON tx.cd_ref = s_1.cd_ref
          WHERE tx.group2_inpn::text = 'Gastéropodes'::text
          GROUP BY vm_epci.nom_epci_simple
        ), gymnospermes AS (
         SELECT vm_epci.nom_epci_simple,
            count(*) AS nb
           FROM atlas.vm_observations s_1
             JOIN atlas.l_communes_epci ON l_communes_epci.insee = s_1.insee
             JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
             LEFT JOIN cd_ref tx ON tx.cd_ref = s_1.cd_ref
          WHERE tx.group2_inpn::text = 'Gymnospermes'::text
          GROUP BY vm_epci.nom_epci_simple
        ), hepatiques_anthocerotes AS (
         SELECT vm_epci.nom_epci_simple,
            count(*) AS nb
           FROM atlas.vm_observations s_1
             JOIN atlas.l_communes_epci ON l_communes_epci.insee = s_1.insee
             JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
             LEFT JOIN cd_ref tx ON tx.cd_ref = s_1.cd_ref
          WHERE tx.group2_inpn::text = 'Hépatiques et Anthocérotes'::text
          GROUP BY vm_epci.nom_epci_simple
        ), hydrozoaires AS (
         SELECT vm_epci.nom_epci_simple,
            count(*) AS nb
           FROM atlas.vm_observations s_1
             JOIN atlas.l_communes_epci ON l_communes_epci.insee = s_1.insee
             JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
             LEFT JOIN cd_ref tx ON tx.cd_ref = s_1.cd_ref
          WHERE tx.group2_inpn::text = 'Hydrozoaires'::text
          GROUP BY vm_epci.nom_epci_simple
        ), insectes AS (
         SELECT vm_epci.nom_epci_simple,
            count(*) AS nb
           FROM atlas.vm_observations s_1
             JOIN atlas.l_communes_epci ON l_communes_epci.insee = s_1.insee
             JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
             LEFT JOIN cd_ref tx ON tx.cd_ref = s_1.cd_ref
          WHERE tx.group2_inpn::text = 'Insectes'::text
          GROUP BY vm_epci.nom_epci_simple
        ), lichens AS (
         SELECT vm_epci.nom_epci_simple,
            count(*) AS nb
           FROM atlas.vm_observations s_1
             JOIN atlas.l_communes_epci ON l_communes_epci.insee = s_1.insee
             JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
             LEFT JOIN cd_ref tx ON tx.cd_ref = s_1.cd_ref
          WHERE tx.group2_inpn::text = 'Lichens'::text
          GROUP BY vm_epci.nom_epci_simple
        ), mammiferes AS (
         SELECT vm_epci.nom_epci_simple,
            count(*) AS nb
           FROM atlas.vm_observations s_1
             JOIN atlas.l_communes_epci ON l_communes_epci.insee = s_1.insee
             JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
             LEFT JOIN cd_ref tx ON tx.cd_ref = s_1.cd_ref
          WHERE tx.group2_inpn::text = 'Mammifères'::text
          GROUP BY vm_epci.nom_epci_simple
        ), mousses AS (
         SELECT vm_epci.nom_epci_simple,
            count(*) AS nb
           FROM atlas.vm_observations s_1
             JOIN atlas.l_communes_epci ON l_communes_epci.insee = s_1.insee
             JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
             LEFT JOIN cd_ref tx ON tx.cd_ref = s_1.cd_ref
          WHERE tx.group2_inpn::text = 'Mousses'::text
          GROUP BY vm_epci.nom_epci_simple
        ), myriapodes AS (
         SELECT vm_epci.nom_epci_simple,
            count(*) AS nb
           FROM atlas.vm_observations s_1
             JOIN atlas.l_communes_epci ON l_communes_epci.insee = s_1.insee
             JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
             LEFT JOIN cd_ref tx ON tx.cd_ref = s_1.cd_ref
          WHERE tx.group2_inpn::text = 'Myriapodes'::text
          GROUP BY vm_epci.nom_epci_simple
        ), nematodes AS (
         SELECT vm_epci.nom_epci_simple,
            count(*) AS nb
           FROM atlas.vm_observations s_1
             JOIN atlas.l_communes_epci ON l_communes_epci.insee = s_1.insee
             JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
             LEFT JOIN cd_ref tx ON tx.cd_ref = s_1.cd_ref
          WHERE tx.group2_inpn::text = 'Nématodes'::text
          GROUP BY vm_epci.nom_epci_simple
        ), nemertes AS (
         SELECT vm_epci.nom_epci_simple,
            count(*) AS nb
           FROM atlas.vm_observations s_1
             JOIN atlas.l_communes_epci ON l_communes_epci.insee = s_1.insee
             JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
             LEFT JOIN cd_ref tx ON tx.cd_ref = s_1.cd_ref
          WHERE tx.group2_inpn::text = 'Némertes'::text
          GROUP BY vm_epci.nom_epci_simple
        ), octocoralliaires AS (
         SELECT vm_epci.nom_epci_simple,
            count(*) AS nb
           FROM atlas.vm_observations s_1
             JOIN atlas.l_communes_epci ON l_communes_epci.insee = s_1.insee
             JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
             LEFT JOIN cd_ref tx ON tx.cd_ref = s_1.cd_ref
          WHERE tx.group2_inpn::text = 'Octocoralliaires'::text
          GROUP BY vm_epci.nom_epci_simple
        ), oiseaux AS (
         SELECT vm_epci.nom_epci_simple,
            count(*) AS nb
           FROM atlas.vm_observations s_1
             JOIN atlas.l_communes_epci ON l_communes_epci.insee = s_1.insee
             JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
             LEFT JOIN cd_ref tx ON tx.cd_ref = s_1.cd_ref
          WHERE tx.group2_inpn::text = 'Oiseaux'::text
          GROUP BY vm_epci.nom_epci_simple
        ), plathelminthes AS (
         SELECT vm_epci.nom_epci_simple,
            count(*) AS nb
           FROM atlas.vm_observations s_1
             JOIN atlas.l_communes_epci ON l_communes_epci.insee = s_1.insee
             JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
             LEFT JOIN cd_ref tx ON tx.cd_ref = s_1.cd_ref
          WHERE tx.group2_inpn::text = 'Plathelminthes'::text
          GROUP BY vm_epci.nom_epci_simple
        ), poissons AS (
         SELECT vm_epci.nom_epci_simple,
            count(*) AS nb
           FROM atlas.vm_observations s_1
             JOIN atlas.l_communes_epci ON l_communes_epci.insee = s_1.insee
             JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
             LEFT JOIN cd_ref tx ON tx.cd_ref = s_1.cd_ref
          WHERE tx.group2_inpn::text = 'Poissons'::text
          GROUP BY vm_epci.nom_epci_simple
        ), pycnogonides AS (
         SELECT vm_epci.nom_epci_simple,
            count(*) AS nb
           FROM atlas.vm_observations s_1
             JOIN atlas.l_communes_epci ON l_communes_epci.insee = s_1.insee
             JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
             LEFT JOIN cd_ref tx ON tx.cd_ref = s_1.cd_ref
          WHERE tx.group2_inpn::text = 'Pycnogonides'::text
          GROUP BY vm_epci.nom_epci_simple
        ), reptiles AS (
         SELECT vm_epci.nom_epci_simple,
            count(*) AS nb
           FROM atlas.vm_observations s_1
             JOIN atlas.l_communes_epci ON l_communes_epci.insee = s_1.insee
             JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
             LEFT JOIN cd_ref tx ON tx.cd_ref = s_1.cd_ref
          WHERE tx.group2_inpn::text = 'Reptiles'::text
          GROUP BY vm_epci.nom_epci_simple
        ), scleractiniaires AS (
         SELECT vm_epci.nom_epci_simple,
            count(*) AS nb
           FROM atlas.vm_observations s_1
             JOIN atlas.l_communes_epci ON l_communes_epci.insee = s_1.insee
             JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
             LEFT JOIN cd_ref tx ON tx.cd_ref = s_1.cd_ref
          WHERE tx.group2_inpn::text = 'Scléractiniaires'::text
          GROUP BY vm_epci.nom_epci_simple
        )
 SELECT DISTINCT o.nom_epci_simple,
    COALESCE(a.nb::integer, 0) AS acanthocephales,
    COALESCE(b.nb::integer, 0) AS algues_brunes,
    COALESCE(c.nb::integer, 0) AS algues_rouges,
    COALESCE(d.nb::integer, 0) AS algues_vertes,
    COALESCE(e.nb::integer, 0) AS amphibiens,
    COALESCE(f.nb::integer, 0) AS angiospermes,
    COALESCE(g.nb::integer, 0) AS annelides,
    COALESCE(h.nb::integer, 0) AS arachnides,
    COALESCE(i.nb::integer, 0) AS ascidies,
    COALESCE(j.nb::integer, 0) AS autres,
    COALESCE(k.nb::integer, 0) AS bivalves,
    COALESCE(l.nb::integer, 0) AS cephalopodes,
    COALESCE(m.nb::integer, 0) AS crustaces,
    COALESCE(n.nb::integer, 0) AS diatomees,
    COALESCE(p.nb::integer, 0) AS entognathes,
    COALESCE(q.nb::integer, 0) AS fougeres,
    COALESCE(r.nb::integer, 0) AS gasteropodes,
    COALESCE(s.nb::integer, 0) AS gymnospermes,
    COALESCE(t.nb::integer, 0) AS hepatiques_anthocerotes,
    COALESCE(u.nb::integer, 0) AS hydrozoaires,
    COALESCE(v.nb::integer, 0) AS insectes,
    COALESCE(w.nb::integer, 0) AS lichens,
    COALESCE(x.nb::integer, 0) AS mammiferes,
    COALESCE(y.nb::integer, 0) AS mousses,
    COALESCE(z.nb::integer, 0) AS myriapodes,
    COALESCE(ab.nb::integer, 0) AS nematodes,
    COALESCE(ac.nb::integer, 0) AS nemertes,
    COALESCE(ad.nb::integer, 0) AS octocoralliaires,
    COALESCE(ae.nb::integer, 0) AS oiseaux,
    COALESCE(af.nb::integer, 0) AS plathelminthes,
    COALESCE(ag.nb::integer, 0) AS poissons,
    COALESCE(ah.nb::integer, 0) AS pycnogonides,
    COALESCE(ai.nb::integer, 0) AS reptiles,
    COALESCE(aj.nb::integer, 0) AS scleractiniaires
   FROM atlas.vm_epci o
     LEFT JOIN acanthocephales a ON a.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN algues_brunes b ON b.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN algues_rouges c ON c.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN algues_vertes d ON d.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN amphibiens e ON e.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN angiospermes f ON f.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN annelides g ON g.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN arachnides h ON h.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN ascidies i ON i.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN autres j ON j.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN bivalves k ON k.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN cephalopodes l ON l.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN crustaces m ON m.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN diatomees n ON n.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN entognathes p ON p.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN fougeres q ON q.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN gasteropodes r ON r.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN gymnospermes s ON s.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN hepatiques_anthocerotes t ON t.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN hydrozoaires u ON u.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN insectes v ON v.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN lichens w ON w.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN mammiferes x ON x.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN mousses y ON y.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN myriapodes z ON z.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN nematodes ab ON ab.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN nemertes ac ON ac.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN octocoralliaires ad ON ad.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN oiseaux ae ON ae.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN plathelminthes af ON af.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN poissons ag ON ag.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN pycnogonides ah ON ah.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN reptiles ai ON ai.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN scleractiniaires aj ON aj.nom_epci_simple = o.nom_epci_simple
  WHERE o.nom_epci_simple IS NOT NULL
  ORDER BY o.nom_epci_simple
WITH DATA;

ALTER TABLE atlas.vm_stats_group2inpn_epci
  OWNER TO geonatuser;
GRANT ALL ON TABLE atlas.vm_stats_group2inpn_epci TO geonatuser;
GRANT SELECT ON TABLE atlas.vm_stats_group2inpn_epci TO geonatatlas;

-- Index: atlas.vm_stats_group2inpn_epci_nom_epci_simple_idx

-- DROP INDEX atlas.vm_stats_group2inpn_epci_nom_epci_simple_idx;

CREATE UNIQUE INDEX vm_stats_group2inpn_epci_nom_epci_simple_idx
  ON atlas.vm_stats_group2inpn_epci
  USING btree
  (nom_epci_simple COLLATE pg_catalog."default");



/* stats nb obs par group2_inpn pour chaque departement */

-- Materialized View: atlas.vm_stats_group2inpn_dpt
-- DROP MATERIALIZED VIEW atlas.vm_stats_group2inpn_dpt;

CREATE MATERIALIZED VIEW atlas.vm_stats_group2inpn_dpt AS 
 WITH cd_ref AS (
         SELECT vm_taxref.cd_ref, vm_taxref.group2_inpn
         FROM atlas.vm_taxref 
         WHERE vm_taxref.cd_ref = vm_taxref.cd_nom 
         ),
        Acanthocephales AS (
         SELECT left(s.insee,2) AS num_dpt, count(*) AS nb

         FROM atlas.vm_observations s
            LEFT JOIN cd_ref tx ON tx.cd_ref = s.cd_ref
         WHERE tx.group2_inpn = 'Acanthocéphales'
          GROUP BY num_dpt
        ), 
        Algues_brunes AS (
         SELECT left(s.insee,2) AS num_dpt, count(*) AS nb

         FROM atlas.vm_observations s
           LEFT JOIN cd_ref tx ON tx.cd_ref = s.cd_ref
         WHERE tx.group2_inpn = 'Algues brunes'
          GROUP BY num_dpt
        ), 
        Algues_rouges AS (
         SELECT left(s.insee,2) AS num_dpt, count(*) AS nb

         FROM atlas.vm_observations s
            LEFT JOIN cd_ref tx ON tx.cd_ref = s.cd_ref
         WHERE tx.group2_inpn = 'Algues rouges'
          GROUP BY num_dpt
        ), 
        Algues_vertes AS (
         SELECT left(s.insee,2) AS num_dpt, count(*) AS nb

         FROM atlas.vm_observations s
            LEFT JOIN cd_ref tx ON tx.cd_ref = s.cd_ref
         WHERE tx.group2_inpn = 'Algues vertes'
          GROUP BY num_dpt
        ), 
        Amphibiens AS (
         SELECT left(s.insee,2) AS num_dpt, count(*) AS nb

         FROM atlas.vm_observations s
            LEFT JOIN cd_ref tx ON tx.cd_ref = s.cd_ref
         WHERE tx.group2_inpn = 'Amphibiens'
          GROUP BY num_dpt
        ), 
        Angiospermes AS (
         SELECT left(s.insee,2) AS num_dpt, count(*) AS nb

         FROM atlas.vm_observations s
            LEFT JOIN cd_ref tx ON tx.cd_ref = s.cd_ref
         WHERE tx.group2_inpn = 'Angiospermes'
          GROUP BY num_dpt
        ), 
        Annelides AS (
         SELECT left(s.insee,2) AS num_dpt, count(*) AS nb

         FROM atlas.vm_observations s
            LEFT JOIN cd_ref tx ON tx.cd_ref = s.cd_ref
         WHERE tx.group2_inpn = 'Annélides'
          GROUP BY num_dpt
        ), 
        Arachnides AS (
         SELECT left(s.insee,2) AS num_dpt, count(*) AS nb

         FROM atlas.vm_observations s
            LEFT JOIN cd_ref tx ON tx.cd_ref = s.cd_ref
         WHERE tx.group2_inpn = 'Arachnides'
          GROUP BY num_dpt
        ), 
        Ascidies AS (
         SELECT left(s.insee,2) AS num_dpt, count(*) AS nb

         FROM atlas.vm_observations s
            LEFT JOIN cd_ref tx ON tx.cd_ref = s.cd_ref
         WHERE tx.group2_inpn = 'Ascidies'
          GROUP BY num_dpt
        ), 
        Autres AS (
         SELECT left(s.insee,2) AS num_dpt, count(*) AS nb

         FROM atlas.vm_observations s
            LEFT JOIN cd_ref tx ON tx.cd_ref = s.cd_ref
         WHERE tx.group2_inpn = 'Autres'
          GROUP BY num_dpt
        ), 
        Bivalves AS (
         SELECT left(s.insee,2) AS num_dpt, count(*) AS nb

         FROM atlas.vm_observations s
            LEFT JOIN cd_ref tx ON tx.cd_ref = s.cd_ref
         WHERE tx.group2_inpn = 'Bivalves'
          GROUP BY num_dpt
        ), 
        Cephalopodes AS (
         SELECT left(s.insee,2) AS num_dpt, count(*) AS nb

         FROM atlas.vm_observations s
            LEFT JOIN cd_ref tx ON tx.cd_ref = s.cd_ref
         WHERE tx.group2_inpn = 'Céphalopodes'
          GROUP BY num_dpt
        ), 
        Crustaces AS (
         SELECT left(s.insee,2) AS num_dpt, count(*) AS nb

         FROM atlas.vm_observations s
            LEFT JOIN cd_ref tx ON tx.cd_ref = s.cd_ref
         WHERE tx.group2_inpn = 'Crustacés'
          GROUP BY num_dpt
        ), 
        Diatomees AS (
         SELECT left(s.insee,2) AS num_dpt, count(*) AS nb

         FROM atlas.vm_observations s
            LEFT JOIN cd_ref tx ON tx.cd_ref = s.cd_ref
         WHERE tx.group2_inpn = 'Diatomées'
          GROUP BY num_dpt
        ), 
        Entognathes AS (
         SELECT left(s.insee,2) AS num_dpt, count(*) AS nb

         FROM atlas.vm_observations s
            LEFT JOIN cd_ref tx ON tx.cd_ref = s.cd_ref
         WHERE tx.group2_inpn = 'Entognathes'
          GROUP BY num_dpt
        ), 
        Fougeres AS (
         SELECT left(s.insee,2) AS num_dpt, count(*) AS nb

         FROM atlas.vm_observations s
            LEFT JOIN cd_ref tx ON tx.cd_ref = s.cd_ref
         WHERE tx.group2_inpn = 'Fougères'
          GROUP BY num_dpt
        ), 
        Gasteropodes AS (
         SELECT left(s.insee,2) AS num_dpt, count(*) AS nb

         FROM atlas.vm_observations s
            LEFT JOIN cd_ref tx ON tx.cd_ref = s.cd_ref
         WHERE tx.group2_inpn = 'Gastéropodes'
          GROUP BY num_dpt
        ), 
        Gymnospermes AS (
         SELECT left(s.insee,2) AS num_dpt, count(*) AS nb

         FROM atlas.vm_observations s
            LEFT JOIN cd_ref tx ON tx.cd_ref = s.cd_ref
         WHERE tx.group2_inpn = 'Gymnospermes'
          GROUP BY num_dpt
        ), 
        Hepatiques_Anthocerotes AS (
         SELECT left(s.insee,2) AS num_dpt, count(*) AS nb

         FROM atlas.vm_observations s
            LEFT JOIN cd_ref tx ON tx.cd_ref = s.cd_ref
         WHERE tx.group2_inpn = 'Hépatiques et Anthocérotes'
          GROUP BY num_dpt
        ), 
        Hydrozoaires AS (
         SELECT left(s.insee,2) AS num_dpt, count(*) AS nb

         FROM atlas.vm_observations s
            LEFT JOIN cd_ref tx ON tx.cd_ref = s.cd_ref
         WHERE tx.group2_inpn = 'Hydrozoaires'
          GROUP BY num_dpt
        ), 
        Insectes AS (
         SELECT left(s.insee,2) AS num_dpt, count(*) AS nb

         FROM atlas.vm_observations s
            LEFT JOIN cd_ref tx ON tx.cd_ref = s.cd_ref
         WHERE tx.group2_inpn = 'Insectes'
          GROUP BY num_dpt
        ), 
        Lichens AS (
         SELECT left(s.insee,2) AS num_dpt, count(*) AS nb

         FROM atlas.vm_observations s
            LEFT JOIN cd_ref tx ON tx.cd_ref = s.cd_ref
         WHERE tx.group2_inpn = 'Lichens'
          GROUP BY num_dpt
        ), 
        Mammiferes AS (
         SELECT left(s.insee,2) AS num_dpt, count(*) AS nb

         FROM atlas.vm_observations s
            LEFT JOIN cd_ref tx ON tx.cd_ref = s.cd_ref
         WHERE tx.group2_inpn = 'Mammifères'
          GROUP BY num_dpt
        ), 
        Mousses AS (
         SELECT left(s.insee,2) AS num_dpt, count(*) AS nb

         FROM atlas.vm_observations s
            LEFT JOIN cd_ref tx ON tx.cd_ref = s.cd_ref
         WHERE tx.group2_inpn = 'Mousses'
          GROUP BY num_dpt
        ), 
        Myriapodes AS (
         SELECT left(s.insee,2) AS num_dpt, count(*) AS nb

         FROM atlas.vm_observations s
            LEFT JOIN cd_ref tx ON tx.cd_ref = s.cd_ref
         WHERE tx.group2_inpn = 'Myriapodes'
          GROUP BY num_dpt
        ), 
        Nematodes AS (
         SELECT left(s.insee,2) AS num_dpt, count(*) AS nb

         FROM atlas.vm_observations s
            LEFT JOIN cd_ref tx ON tx.cd_ref = s.cd_ref
         WHERE tx.group2_inpn = 'Nématodes'
          GROUP BY num_dpt
        ), 
        Nemertes AS (
         SELECT left(s.insee,2) AS num_dpt, count(*) AS nb

         FROM atlas.vm_observations s
            LEFT JOIN cd_ref tx ON tx.cd_ref = s.cd_ref
         WHERE tx.group2_inpn = 'Némertes'
          GROUP BY num_dpt
        ), 
        Octocoralliaires AS (
         SELECT left(s.insee,2) AS num_dpt, count(*) AS nb

         FROM atlas.vm_observations s
            LEFT JOIN cd_ref tx ON tx.cd_ref = s.cd_ref
         WHERE tx.group2_inpn = 'Octocoralliaires'
          GROUP BY num_dpt
        ), 
        Oiseaux AS (
         SELECT left(s.insee,2) AS num_dpt, count(*) AS nb

         FROM atlas.vm_observations s
            LEFT JOIN cd_ref tx ON tx.cd_ref = s.cd_ref
         WHERE tx.group2_inpn = 'Oiseaux'
          GROUP BY num_dpt
        ), 
        Plathelminthes AS (
         SELECT left(s.insee,2) AS num_dpt, count(*) AS nb

         FROM atlas.vm_observations s
            LEFT JOIN cd_ref tx ON tx.cd_ref = s.cd_ref
         WHERE tx.group2_inpn = 'Plathelminthes'
          GROUP BY num_dpt
        ), 
        Poissons AS (
         SELECT left(s.insee,2) AS num_dpt, count(*) AS nb

         FROM atlas.vm_observations s
            LEFT JOIN cd_ref tx ON tx.cd_ref = s.cd_ref
         WHERE tx.group2_inpn = 'Poissons'
          GROUP BY num_dpt
        ), 
        Pycnogonides AS (
         SELECT left(s.insee,2) AS num_dpt, count(*) AS nb

         FROM atlas.vm_observations s
            LEFT JOIN cd_ref tx ON tx.cd_ref = s.cd_ref
         WHERE tx.group2_inpn = 'Pycnogonides'
          GROUP BY num_dpt
        ), 
        Reptiles AS (
         SELECT left(s.insee,2) AS num_dpt, count(*) AS nb

         FROM atlas.vm_observations s
            LEFT JOIN cd_ref tx ON tx.cd_ref = s.cd_ref
         WHERE tx.group2_inpn = 'Reptiles'
          GROUP BY num_dpt
        ), 
        Scleractiniaires AS (
         SELECT left(s.insee,2) AS num_dpt, count(*) AS nb

         FROM atlas.vm_observations s
            LEFT JOIN cd_ref tx ON tx.cd_ref = s.cd_ref
         WHERE tx.group2_inpn = 'Scléractiniaires'
          GROUP BY num_dpt
        )
 SELECT DISTINCT left(o.insee,2)::text AS num_dpt,
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

     LEFT JOIN Acanthocephales a ON a.num_dpt = left(o.insee,2)
     LEFT JOIN Algues_brunes b ON b.num_dpt = left(o.insee,2)
     LEFT JOIN Algues_rouges c ON c.num_dpt = left(o.insee,2)
     LEFT JOIN Algues_vertes d ON d.num_dpt = left(o.insee,2)
     LEFT JOIN Amphibiens e ON e.num_dpt = left(o.insee,2)
     LEFT JOIN Angiospermes f ON f.num_dpt = left(o.insee,2)
     LEFT JOIN Annelides g ON g.num_dpt = left(o.insee,2)
     LEFT JOIN Arachnides h ON h.num_dpt = left(o.insee,2)
     LEFT JOIN Ascidies i ON i.num_dpt = left(o.insee,2)
     LEFT JOIN Autres j ON j.num_dpt = left(o.insee,2)
     LEFT JOIN Bivalves k ON k.num_dpt = left(o.insee,2)
     LEFT JOIN Cephalopodes l ON l.num_dpt = left(o.insee,2)
     LEFT JOIN Crustaces m ON m.num_dpt = left(o.insee,2)
     LEFT JOIN Diatomees n ON n.num_dpt = left(o.insee,2)
     LEFT JOIN Entognathes p ON p.num_dpt = left(o.insee,2)
     LEFT JOIN Fougeres q ON q.num_dpt = left(o.insee,2)
     LEFT JOIN Gasteropodes r ON r.num_dpt = left(o.insee,2)
     LEFT JOIN Gymnospermes s ON s.num_dpt = left(o.insee,2)
     LEFT JOIN Hepatiques_Anthocerotes t ON t.num_dpt = left(o.insee,2)
     LEFT JOIN Hydrozoaires u ON u.num_dpt = left(o.insee,2)
     LEFT JOIN Insectes v ON v.num_dpt = left(o.insee,2)
     LEFT JOIN Lichens w ON w.num_dpt = left(o.insee,2)
     LEFT JOIN Mammiferes x ON x.num_dpt = left(o.insee,2)
     LEFT JOIN Mousses y ON y.num_dpt = left(o.insee,2)
     LEFT JOIN Myriapodes z ON z.num_dpt = left(o.insee,2)
     LEFT JOIN Nematodes ab ON ab.num_dpt = left(o.insee,2)
     LEFT JOIN Nemertes ac ON ac.num_dpt = left(o.insee,2)
     LEFT JOIN Octocoralliaires ad ON ad.num_dpt = left(o.insee,2)
     LEFT JOIN Oiseaux ae ON ae.num_dpt = left(o.insee,2)
     LEFT JOIN Plathelminthes af ON af.num_dpt = left(o.insee,2)
     LEFT JOIN Poissons ag ON ag.num_dpt = left(o.insee,2)
     LEFT JOIN Pycnogonides ah ON ah.num_dpt = left(o.insee,2)
     LEFT JOIN Reptiles ai ON ai.num_dpt = left(o.insee,2)
     LEFT JOIN Scleractiniaires aj ON aj.num_dpt = left(o.insee,2)

  WHERE o.insee IS NOT NULL
  ORDER BY num_dpt
  
WITH DATA;

ALTER TABLE atlas.vm_stats_group2inpn_dpt
  OWNER TO geonatuser;
GRANT ALL ON TABLE atlas.vm_stats_group2inpn_dpt TO geonatuser;
GRANT SELECT ON TABLE atlas.vm_stats_group2inpn_dpt TO geonatatlas;

-- Index: atlas.vm_stats_group2inpn_dpt_num_dpt_idx

-- DROP INDEX atlas.vm_stats_group2inpn_dpt_num_dpt_idx;

CREATE UNIQUE INDEX vm_stats_group2inpn_dpt_num_dpt_idx
  ON atlas.vm_stats_group2inpn_dpt
  USING btree (num_dpt);







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


/* stats nb obs par group2inpn pour chaque EPCI */



-- Materialized View: atlas.vm_stats_espece_group2inpn_epci

-- DROP MATERIALIZED VIEW atlas.vm_stats_espece_group2inpn_epci;

CREATE MATERIALIZED VIEW atlas.vm_stats_espece_group2inpn_epci AS 
 WITH cd_ref AS (
         SELECT vm_taxref.cd_ref,
            vm_taxref.group2_inpn
           FROM atlas.vm_taxref
          WHERE vm_taxref.cd_ref = vm_taxref.cd_nom
        ), somme_a AS (
         SELECT DISTINCT o_1.cd_ref,
            vm_epci.nom_epci_simple,
            count(o_1.cd_ref) AS nb,
            t_1.group2_inpn
           FROM atlas.vm_observations o_1
             JOIN atlas.vm_taxons t_1 ON t_1.cd_ref = o_1.cd_ref AND t_1.group2_inpn::text = 'Acanthocéphales'::text
             JOIN atlas.l_communes_epci ON l_communes_epci.insee = o_1.insee
             JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
          GROUP BY o_1.cd_ref, vm_epci.nom_epci_simple, t_1.group2_inpn
        ), acanthocephales AS (
         SELECT count(*) AS nb,
            somme_a.nom_epci_simple
           FROM somme_a
          GROUP BY somme_a.nom_epci_simple
        ), somme_b AS (
         SELECT DISTINCT o_1.cd_ref,
            vm_epci.nom_epci_simple,
            count(o_1.cd_ref) AS nb,
            t_1.group2_inpn
           FROM atlas.vm_observations o_1
             JOIN atlas.vm_taxons t_1 ON t_1.cd_ref = o_1.cd_ref AND t_1.group2_inpn::text = 'Algues brunes'::text
             JOIN atlas.l_communes_epci ON l_communes_epci.insee = o_1.insee
             JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
          GROUP BY o_1.cd_ref, vm_epci.nom_epci_simple, t_1.group2_inpn
        ), algues_brunes AS (
         SELECT count(*) AS nb,
            somme_b.nom_epci_simple
           FROM somme_b
          GROUP BY somme_b.nom_epci_simple
        ), somme_c AS (
         SELECT DISTINCT o_1.cd_ref,
            vm_epci.nom_epci_simple,
            count(o_1.cd_ref) AS nb,
            t_1.group2_inpn
           FROM atlas.vm_observations o_1
             JOIN atlas.vm_taxons t_1 ON t_1.cd_ref = o_1.cd_ref AND t_1.group2_inpn::text = 'Algues rouges'::text
             JOIN atlas.l_communes_epci ON l_communes_epci.insee = o_1.insee
             JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
          GROUP BY o_1.cd_ref, vm_epci.nom_epci_simple, t_1.group2_inpn
        ), algues_rouges AS (
         SELECT count(*) AS nb,
            somme_c.nom_epci_simple
           FROM somme_c
          GROUP BY somme_c.nom_epci_simple
        ), somme_d AS (
         SELECT DISTINCT o_1.cd_ref,
            vm_epci.nom_epci_simple,
            count(o_1.cd_ref) AS nb,
            t_1.group2_inpn
           FROM atlas.vm_observations o_1
             JOIN atlas.vm_taxons t_1 ON t_1.cd_ref = o_1.cd_ref AND t_1.group2_inpn::text = 'Algues vertes'::text
             JOIN atlas.l_communes_epci ON l_communes_epci.insee = o_1.insee
             JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
          GROUP BY o_1.cd_ref, vm_epci.nom_epci_simple, t_1.group2_inpn
        ), algues_vertes AS (
         SELECT count(*) AS nb,
            somme_d.nom_epci_simple
           FROM somme_d
          GROUP BY somme_d.nom_epci_simple
        ), somme_e AS (
         SELECT DISTINCT o_1.cd_ref,
            vm_epci.nom_epci_simple,
            count(o_1.cd_ref) AS nb,
            t_1.group2_inpn
           FROM atlas.vm_observations o_1
             JOIN atlas.vm_taxons t_1 ON t_1.cd_ref = o_1.cd_ref AND t_1.group2_inpn::text = 'Amphibiens'::text
             JOIN atlas.l_communes_epci ON l_communes_epci.insee = o_1.insee
             JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
          GROUP BY o_1.cd_ref, vm_epci.nom_epci_simple, t_1.group2_inpn
        ), amphibiens AS (
         SELECT count(*) AS nb,
            somme_e.nom_epci_simple
           FROM somme_e
          GROUP BY somme_e.nom_epci_simple
        ), somme_f AS (
         SELECT DISTINCT o_1.cd_ref,
            vm_epci.nom_epci_simple,
            count(o_1.cd_ref) AS nb,
            t_1.group2_inpn
           FROM atlas.vm_observations o_1
             JOIN atlas.vm_taxons t_1 ON t_1.cd_ref = o_1.cd_ref AND t_1.group2_inpn::text = 'Angiospermes'::text
             JOIN atlas.l_communes_epci ON l_communes_epci.insee = o_1.insee
             JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
          GROUP BY o_1.cd_ref, vm_epci.nom_epci_simple, t_1.group2_inpn
        ), angiospermes AS (
         SELECT count(*) AS nb,
            somme_f.nom_epci_simple
           FROM somme_f
          GROUP BY somme_f.nom_epci_simple
        ), somme_g AS (
         SELECT DISTINCT o_1.cd_ref,
            vm_epci.nom_epci_simple,
            count(o_1.cd_ref) AS nb,
            t_1.group2_inpn
           FROM atlas.vm_observations o_1
             JOIN atlas.vm_taxons t_1 ON t_1.cd_ref = o_1.cd_ref AND t_1.group2_inpn::text = 'Annélides'::text
             JOIN atlas.l_communes_epci ON l_communes_epci.insee = o_1.insee
             JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
          GROUP BY o_1.cd_ref, vm_epci.nom_epci_simple, t_1.group2_inpn
        ), annelides AS (
         SELECT count(*) AS nb,
            somme_g.nom_epci_simple
           FROM somme_g
          GROUP BY somme_g.nom_epci_simple
        ), somme_h AS (
         SELECT DISTINCT o_1.cd_ref,
            vm_epci.nom_epci_simple,
            count(o_1.cd_ref) AS nb,
            t_1.group2_inpn
           FROM atlas.vm_observations o_1
             JOIN atlas.vm_taxons t_1 ON t_1.cd_ref = o_1.cd_ref AND t_1.group2_inpn::text = 'Arachnides'::text
             JOIN atlas.l_communes_epci ON l_communes_epci.insee = o_1.insee
             JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
          GROUP BY o_1.cd_ref, vm_epci.nom_epci_simple, t_1.group2_inpn
        ), arachnides AS (
         SELECT count(*) AS nb,
            somme_h.nom_epci_simple
           FROM somme_h
          GROUP BY somme_h.nom_epci_simple
        ), somme_i AS (
         SELECT DISTINCT o_1.cd_ref,
            vm_epci.nom_epci_simple,
            count(o_1.cd_ref) AS nb,
            t_1.group2_inpn
           FROM atlas.vm_observations o_1
             JOIN atlas.vm_taxons t_1 ON t_1.cd_ref = o_1.cd_ref AND t_1.group2_inpn::text = 'Ascidies'::text
             JOIN atlas.l_communes_epci ON l_communes_epci.insee = o_1.insee
             JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
          GROUP BY o_1.cd_ref, vm_epci.nom_epci_simple, t_1.group2_inpn
        ), ascidies AS (
         SELECT count(*) AS nb,
            somme_i.nom_epci_simple
           FROM somme_i
          GROUP BY somme_i.nom_epci_simple
        ), somme_j AS (
         SELECT DISTINCT o_1.cd_ref,
            vm_epci.nom_epci_simple,
            count(o_1.cd_ref) AS nb,
            t_1.group2_inpn
           FROM atlas.vm_observations o_1
             JOIN atlas.vm_taxons t_1 ON t_1.cd_ref = o_1.cd_ref AND t_1.group2_inpn::text = 'Autres'::text
             JOIN atlas.l_communes_epci ON l_communes_epci.insee = o_1.insee
             JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
          GROUP BY o_1.cd_ref, vm_epci.nom_epci_simple, t_1.group2_inpn
        ), autres AS (
         SELECT count(*) AS nb,
            somme_j.nom_epci_simple
           FROM somme_j
          GROUP BY somme_j.nom_epci_simple
        ), somme_k AS (
         SELECT DISTINCT o_1.cd_ref,
            vm_epci.nom_epci_simple,
            count(o_1.cd_ref) AS nb,
            t_1.group2_inpn
           FROM atlas.vm_observations o_1
             JOIN atlas.vm_taxons t_1 ON t_1.cd_ref = o_1.cd_ref AND t_1.group2_inpn::text = 'Bivalves'::text
             JOIN atlas.l_communes_epci ON l_communes_epci.insee = o_1.insee
             JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
          GROUP BY o_1.cd_ref, vm_epci.nom_epci_simple, t_1.group2_inpn
        ), bivalves AS (
         SELECT count(*) AS nb,
            somme_k.nom_epci_simple
           FROM somme_k
          GROUP BY somme_k.nom_epci_simple
        ), somme_l AS (
         SELECT DISTINCT o_1.cd_ref,
            vm_epci.nom_epci_simple,
            count(o_1.cd_ref) AS nb,
            t_1.group2_inpn
           FROM atlas.vm_observations o_1
             JOIN atlas.vm_taxons t_1 ON t_1.cd_ref = o_1.cd_ref AND t_1.group2_inpn::text = 'Céphalopodes'::text
             JOIN atlas.l_communes_epci ON l_communes_epci.insee = o_1.insee
             JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
          GROUP BY o_1.cd_ref, vm_epci.nom_epci_simple, t_1.group2_inpn
        ), cephalopodes AS (
         SELECT count(*) AS nb,
            somme_l.nom_epci_simple
           FROM somme_l
          GROUP BY somme_l.nom_epci_simple
        ), somme_m AS (
         SELECT DISTINCT o_1.cd_ref,
            vm_epci.nom_epci_simple,
            count(o_1.cd_ref) AS nb,
            t_1.group2_inpn
           FROM atlas.vm_observations o_1
             JOIN atlas.vm_taxons t_1 ON t_1.cd_ref = o_1.cd_ref AND t_1.group2_inpn::text = 'Crustacés'::text
             JOIN atlas.l_communes_epci ON l_communes_epci.insee = o_1.insee
             JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
          GROUP BY o_1.cd_ref, vm_epci.nom_epci_simple, t_1.group2_inpn
        ), crustaces AS (
         SELECT count(*) AS nb,
            somme_m.nom_epci_simple
           FROM somme_m
          GROUP BY somme_m.nom_epci_simple
        ), somme_n AS (
         SELECT DISTINCT o_1.cd_ref,
            vm_epci.nom_epci_simple,
            count(o_1.cd_ref) AS nb,
            t_1.group2_inpn
           FROM atlas.vm_observations o_1
             JOIN atlas.vm_taxons t_1 ON t_1.cd_ref = o_1.cd_ref AND t_1.group2_inpn::text = 'Diatomées'::text
             JOIN atlas.l_communes_epci ON l_communes_epci.insee = o_1.insee
             JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
          GROUP BY o_1.cd_ref, vm_epci.nom_epci_simple, t_1.group2_inpn
        ), diatomees AS (
         SELECT count(*) AS nb,
            somme_n.nom_epci_simple
           FROM somme_n
          GROUP BY somme_n.nom_epci_simple
        ), somme_p AS (
         SELECT DISTINCT o_1.cd_ref,
            vm_epci.nom_epci_simple,
            count(o_1.cd_ref) AS nb,
            t_1.group2_inpn
           FROM atlas.vm_observations o_1
             JOIN atlas.vm_taxons t_1 ON t_1.cd_ref = o_1.cd_ref AND t_1.group2_inpn::text = 'Entognathes'::text
             JOIN atlas.l_communes_epci ON l_communes_epci.insee = o_1.insee
             JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
          GROUP BY o_1.cd_ref, vm_epci.nom_epci_simple, t_1.group2_inpn
        ), entognathes AS (
         SELECT count(*) AS nb,
            somme_p.nom_epci_simple
           FROM somme_p
          GROUP BY somme_p.nom_epci_simple
        ), somme_q AS (
         SELECT DISTINCT o_1.cd_ref,
            vm_epci.nom_epci_simple,
            count(o_1.cd_ref) AS nb,
            t_1.group2_inpn
           FROM atlas.vm_observations o_1
             JOIN atlas.vm_taxons t_1 ON t_1.cd_ref = o_1.cd_ref AND t_1.group2_inpn::text = 'Fougères'::text
             JOIN atlas.l_communes_epci ON l_communes_epci.insee = o_1.insee
             JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
          GROUP BY o_1.cd_ref, vm_epci.nom_epci_simple, t_1.group2_inpn
        ), fougeres AS (
         SELECT count(*) AS nb,
            somme_q.nom_epci_simple
           FROM somme_q
          GROUP BY somme_q.nom_epci_simple
        ), somme_r AS (
         SELECT DISTINCT o_1.cd_ref,
            vm_epci.nom_epci_simple,
            count(o_1.cd_ref) AS nb,
            t_1.group2_inpn
           FROM atlas.vm_observations o_1
             JOIN atlas.vm_taxons t_1 ON t_1.cd_ref = o_1.cd_ref AND t_1.group2_inpn::text = 'Gastéropodes'::text
             JOIN atlas.l_communes_epci ON l_communes_epci.insee = o_1.insee
             JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
          GROUP BY o_1.cd_ref, vm_epci.nom_epci_simple, t_1.group2_inpn
        ), gasteropodes AS (
         SELECT count(*) AS nb,
            somme_r.nom_epci_simple
           FROM somme_r
          GROUP BY somme_r.nom_epci_simple
        ), somme_s AS (
         SELECT DISTINCT o_1.cd_ref,
            vm_epci.nom_epci_simple,
            count(o_1.cd_ref) AS nb,
            t_1.group2_inpn
           FROM atlas.vm_observations o_1
             JOIN atlas.vm_taxons t_1 ON t_1.cd_ref = o_1.cd_ref AND t_1.group2_inpn::text = 'Gymnospermes'::text
             JOIN atlas.l_communes_epci ON l_communes_epci.insee = o_1.insee
             JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
          GROUP BY o_1.cd_ref, vm_epci.nom_epci_simple, t_1.group2_inpn
        ), gymnospermes AS (
         SELECT count(*) AS nb,
            somme_s.nom_epci_simple
           FROM somme_s
          GROUP BY somme_s.nom_epci_simple
        ), somme_t AS (
         SELECT DISTINCT o_1.cd_ref,
            vm_epci.nom_epci_simple,
            count(o_1.cd_ref) AS nb,
            t_1.group2_inpn
           FROM atlas.vm_observations o_1
             JOIN atlas.vm_taxons t_1 ON t_1.cd_ref = o_1.cd_ref AND t_1.group2_inpn::text = 'Hépatiques et Anthocérotes'::text
             JOIN atlas.l_communes_epci ON l_communes_epci.insee = o_1.insee
             JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
          GROUP BY o_1.cd_ref, vm_epci.nom_epci_simple, t_1.group2_inpn
        ), hepatiques_anthocerotes AS (
         SELECT count(*) AS nb,
            somme_t.nom_epci_simple
           FROM somme_t
          GROUP BY somme_t.nom_epci_simple
        ), somme_u AS (
         SELECT DISTINCT o_1.cd_ref,
            vm_epci.nom_epci_simple,
            count(o_1.cd_ref) AS nb,
            t_1.group2_inpn
           FROM atlas.vm_observations o_1
             JOIN atlas.vm_taxons t_1 ON t_1.cd_ref = o_1.cd_ref AND t_1.group2_inpn::text = 'Hydrozoaires'::text
             JOIN atlas.l_communes_epci ON l_communes_epci.insee = o_1.insee
             JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
          GROUP BY o_1.cd_ref, vm_epci.nom_epci_simple, t_1.group2_inpn
        ), hydrozoaires AS (
         SELECT count(*) AS nb,
            somme_u.nom_epci_simple
           FROM somme_u
          GROUP BY somme_u.nom_epci_simple
        ), somme_v AS (
         SELECT DISTINCT o_1.cd_ref,
            vm_epci.nom_epci_simple,
            count(o_1.cd_ref) AS nb,
            t_1.group2_inpn
           FROM atlas.vm_observations o_1
             JOIN atlas.vm_taxons t_1 ON t_1.cd_ref = o_1.cd_ref AND t_1.group2_inpn::text = 'Insectes'::text
             JOIN atlas.l_communes_epci ON l_communes_epci.insee = o_1.insee
             JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
          GROUP BY o_1.cd_ref, vm_epci.nom_epci_simple, t_1.group2_inpn
        ), insectes AS (
         SELECT count(*) AS nb,
            somme_v.nom_epci_simple
           FROM somme_v
          GROUP BY somme_v.nom_epci_simple
        ), somme_w AS (
         SELECT DISTINCT o_1.cd_ref,
            vm_epci.nom_epci_simple,
            count(o_1.cd_ref) AS nb,
            t_1.group2_inpn
           FROM atlas.vm_observations o_1
             JOIN atlas.vm_taxons t_1 ON t_1.cd_ref = o_1.cd_ref AND t_1.group2_inpn::text = 'Lichens'::text
             JOIN atlas.l_communes_epci ON l_communes_epci.insee = o_1.insee
             JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
          GROUP BY o_1.cd_ref, vm_epci.nom_epci_simple, t_1.group2_inpn
        ), lichens AS (
         SELECT count(*) AS nb,
            somme_w.nom_epci_simple
           FROM somme_w
          GROUP BY somme_w.nom_epci_simple
        ), somme_x AS (
         SELECT DISTINCT o_1.cd_ref,
            vm_epci.nom_epci_simple,
            count(o_1.cd_ref) AS nb,
            t_1.group2_inpn
           FROM atlas.vm_observations o_1
             JOIN atlas.vm_taxons t_1 ON t_1.cd_ref = o_1.cd_ref AND t_1.group2_inpn::text = 'Mammifères'::text
             JOIN atlas.l_communes_epci ON l_communes_epci.insee = o_1.insee
             JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
          GROUP BY o_1.cd_ref, vm_epci.nom_epci_simple, t_1.group2_inpn
        ), mammiferes AS (
         SELECT count(*) AS nb,
            somme_x.nom_epci_simple
           FROM somme_x
          GROUP BY somme_x.nom_epci_simple
        ), somme_y AS (
         SELECT DISTINCT o_1.cd_ref,
            vm_epci.nom_epci_simple,
            count(o_1.cd_ref) AS nb,
            t_1.group2_inpn
           FROM atlas.vm_observations o_1
             JOIN atlas.vm_taxons t_1 ON t_1.cd_ref = o_1.cd_ref AND t_1.group2_inpn::text = 'Mousses'::text
             JOIN atlas.l_communes_epci ON l_communes_epci.insee = o_1.insee
             JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
          GROUP BY o_1.cd_ref, vm_epci.nom_epci_simple, t_1.group2_inpn
        ), mousses AS (
         SELECT count(*) AS nb,
            somme_y.nom_epci_simple
           FROM somme_y
          GROUP BY somme_y.nom_epci_simple
        ), somme_z AS (
         SELECT DISTINCT o_1.cd_ref,
            vm_epci.nom_epci_simple,
            count(o_1.cd_ref) AS nb,
            t_1.group2_inpn
           FROM atlas.vm_observations o_1
             JOIN atlas.vm_taxons t_1 ON t_1.cd_ref = o_1.cd_ref AND t_1.group2_inpn::text = 'Myriapodes'::text
             JOIN atlas.l_communes_epci ON l_communes_epci.insee = o_1.insee
             JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
          GROUP BY o_1.cd_ref, vm_epci.nom_epci_simple, t_1.group2_inpn
        ), myriapodes AS (
         SELECT count(*) AS nb,
            somme_z.nom_epci_simple
           FROM somme_z
          GROUP BY somme_z.nom_epci_simple
        ), somme_ab AS (
         SELECT DISTINCT o_1.cd_ref,
            vm_epci.nom_epci_simple,
            count(o_1.cd_ref) AS nb,
            t_1.group2_inpn
           FROM atlas.vm_observations o_1
             JOIN atlas.vm_taxons t_1 ON t_1.cd_ref = o_1.cd_ref AND t_1.group2_inpn::text = 'Nématodes'::text
             JOIN atlas.l_communes_epci ON l_communes_epci.insee = o_1.insee
             JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
          GROUP BY o_1.cd_ref, vm_epci.nom_epci_simple, t_1.group2_inpn
        ), nematodes AS (
         SELECT count(*) AS nb,
            somme_ab.nom_epci_simple
           FROM somme_ab
          GROUP BY somme_ab.nom_epci_simple
        ), somme_ac AS (
         SELECT DISTINCT o_1.cd_ref,
            vm_epci.nom_epci_simple,
            count(o_1.cd_ref) AS nb,
            t_1.group2_inpn
           FROM atlas.vm_observations o_1
             JOIN atlas.vm_taxons t_1 ON t_1.cd_ref = o_1.cd_ref AND t_1.group2_inpn::text = 'Némertes'::text
             JOIN atlas.l_communes_epci ON l_communes_epci.insee = o_1.insee
             JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
          GROUP BY o_1.cd_ref, vm_epci.nom_epci_simple, t_1.group2_inpn
        ), nemertes AS (
         SELECT count(*) AS nb,
            somme_ac.nom_epci_simple
           FROM somme_ac
          GROUP BY somme_ac.nom_epci_simple
        ), somme_ad AS (
         SELECT DISTINCT o_1.cd_ref,
            vm_epci.nom_epci_simple,
            count(o_1.cd_ref) AS nb,
            t_1.group2_inpn
           FROM atlas.vm_observations o_1
             JOIN atlas.vm_taxons t_1 ON t_1.cd_ref = o_1.cd_ref AND t_1.group2_inpn::text = 'Octocoralliaires'::text
             JOIN atlas.l_communes_epci ON l_communes_epci.insee = o_1.insee
             JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
          GROUP BY o_1.cd_ref, vm_epci.nom_epci_simple, t_1.group2_inpn
        ), octocoralliaires AS (
         SELECT count(*) AS nb,
            somme_ad.nom_epci_simple
           FROM somme_ad
          GROUP BY somme_ad.nom_epci_simple
        ), somme_ae AS (
         SELECT DISTINCT o_1.cd_ref,
            vm_epci.nom_epci_simple,
            count(o_1.cd_ref) AS nb,
            t_1.group2_inpn
           FROM atlas.vm_observations o_1
             JOIN atlas.vm_taxons t_1 ON t_1.cd_ref = o_1.cd_ref AND t_1.group2_inpn::text = 'Oiseaux'::text
             JOIN atlas.l_communes_epci ON l_communes_epci.insee = o_1.insee
             JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
          GROUP BY o_1.cd_ref, vm_epci.nom_epci_simple, t_1.group2_inpn
        ), oiseaux AS (
         SELECT count(*) AS nb,
            somme_ae.nom_epci_simple
           FROM somme_ae
          GROUP BY somme_ae.nom_epci_simple
        ), somme_af AS (
         SELECT DISTINCT o_1.cd_ref,
            vm_epci.nom_epci_simple,
            count(o_1.cd_ref) AS nb,
            t_1.group2_inpn
           FROM atlas.vm_observations o_1
             JOIN atlas.vm_taxons t_1 ON t_1.cd_ref = o_1.cd_ref AND t_1.group2_inpn::text = 'Plathelminthes'::text
             JOIN atlas.l_communes_epci ON l_communes_epci.insee = o_1.insee
             JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
          GROUP BY o_1.cd_ref, vm_epci.nom_epci_simple, t_1.group2_inpn
        ), plathelminthes AS (
         SELECT count(*) AS nb,
            somme_af.nom_epci_simple
           FROM somme_af
          GROUP BY somme_af.nom_epci_simple
        ), somme_ag AS (
         SELECT DISTINCT o_1.cd_ref,
            vm_epci.nom_epci_simple,
            count(o_1.cd_ref) AS nb,
            t_1.group2_inpn
           FROM atlas.vm_observations o_1
             JOIN atlas.vm_taxons t_1 ON t_1.cd_ref = o_1.cd_ref AND t_1.group2_inpn::text = 'Poissons'::text
             JOIN atlas.l_communes_epci ON l_communes_epci.insee = o_1.insee
             JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
          GROUP BY o_1.cd_ref, vm_epci.nom_epci_simple, t_1.group2_inpn
        ), poissons AS (
         SELECT count(*) AS nb,
            somme_ag.nom_epci_simple
           FROM somme_ag
          GROUP BY somme_ag.nom_epci_simple
        ), somme_ah AS (
         SELECT DISTINCT o_1.cd_ref,
            vm_epci.nom_epci_simple,
            count(o_1.cd_ref) AS nb,
            t_1.group2_inpn
           FROM atlas.vm_observations o_1
             JOIN atlas.vm_taxons t_1 ON t_1.cd_ref = o_1.cd_ref AND t_1.group2_inpn::text = 'Pycnogonides'::text
             JOIN atlas.l_communes_epci ON l_communes_epci.insee = o_1.insee
             JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
          GROUP BY o_1.cd_ref, vm_epci.nom_epci_simple, t_1.group2_inpn
        ), pycnogonides AS (
         SELECT count(*) AS nb,
            somme_ah.nom_epci_simple
           FROM somme_ah
          GROUP BY somme_ah.nom_epci_simple
        ), somme_ai AS (
         SELECT DISTINCT o_1.cd_ref,
            vm_epci.nom_epci_simple,
            count(o_1.cd_ref) AS nb,
            t_1.group2_inpn
           FROM atlas.vm_observations o_1
             JOIN atlas.vm_taxons t_1 ON t_1.cd_ref = o_1.cd_ref AND t_1.group2_inpn::text = 'Reptiles'::text
             JOIN atlas.l_communes_epci ON l_communes_epci.insee = o_1.insee
             JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
          GROUP BY o_1.cd_ref, vm_epci.nom_epci_simple, t_1.group2_inpn
        ), reptiles AS (
         SELECT count(*) AS nb,
            somme_ai.nom_epci_simple
           FROM somme_ai
          GROUP BY somme_ai.nom_epci_simple
        ), somme_aj AS (
         SELECT DISTINCT o_1.cd_ref,
            vm_epci.nom_epci_simple,
            count(o_1.cd_ref) AS nb,
            t_1.group2_inpn
           FROM atlas.vm_observations o_1
             JOIN atlas.vm_taxons t_1 ON t_1.cd_ref = o_1.cd_ref AND t_1.group2_inpn::text = 'Scléractiniaires'::text
             JOIN atlas.l_communes_epci ON l_communes_epci.insee = o_1.insee
             JOIN atlas.vm_epci ON vm_epci.id = l_communes_epci.id
          GROUP BY o_1.cd_ref, vm_epci.nom_epci_simple, t_1.group2_inpn
        ), scleractiniaires AS (
         SELECT count(*) AS nb,
            somme_aj.nom_epci_simple
           FROM somme_aj
          GROUP BY somme_aj.nom_epci_simple
        )
 SELECT DISTINCT o.nom_epci_simple,
    COALESCE(a.nb::integer, 0) AS acanthocephales,
    COALESCE(b.nb::integer, 0) AS algues_brunes,
    COALESCE(c.nb::integer, 0) AS algues_rouges,
    COALESCE(d.nb::integer, 0) AS algues_vertes,
    COALESCE(e.nb::integer, 0) AS amphibiens,
    COALESCE(f.nb::integer, 0) AS angiospermes,
    COALESCE(g.nb::integer, 0) AS annelides,
    COALESCE(h.nb::integer, 0) AS arachnides,
    COALESCE(i.nb::integer, 0) AS ascidies,
    COALESCE(j.nb::integer, 0) AS autres,
    COALESCE(k.nb::integer, 0) AS bivalves,
    COALESCE(l.nb::integer, 0) AS cephalopodes,
    COALESCE(m.nb::integer, 0) AS crustaces,
    COALESCE(n.nb::integer, 0) AS diatomees,
    COALESCE(p.nb::integer, 0) AS entognathes,
    COALESCE(q.nb::integer, 0) AS fougeres,
    COALESCE(r.nb::integer, 0) AS gasteropodes,
    COALESCE(s.nb::integer, 0) AS gymnospermes,
    COALESCE(t.nb::integer, 0) AS hepatiques_anthocerotes,
    COALESCE(u.nb::integer, 0) AS hydrozoaires,
    COALESCE(v.nb::integer, 0) AS insectes,
    COALESCE(w.nb::integer, 0) AS lichens,
    COALESCE(x.nb::integer, 0) AS mammiferes,
    COALESCE(y.nb::integer, 0) AS mousses,
    COALESCE(z.nb::integer, 0) AS myriapodes,
    COALESCE(ab.nb::integer, 0) AS nematodes,
    COALESCE(ac.nb::integer, 0) AS nemertes,
    COALESCE(ad.nb::integer, 0) AS octocoralliaires,
    COALESCE(ae.nb::integer, 0) AS oiseaux,
    COALESCE(af.nb::integer, 0) AS plathelminthes,
    COALESCE(ag.nb::integer, 0) AS poissons,
    COALESCE(ah.nb::integer, 0) AS pycnogonides,
    COALESCE(ai.nb::integer, 0) AS reptiles,
    COALESCE(aj.nb::integer, 0) AS scleractiniaires
   FROM atlas.vm_epci o
     LEFT JOIN acanthocephales a ON a.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN algues_brunes b ON b.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN algues_rouges c ON c.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN algues_vertes d ON d.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN amphibiens e ON e.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN angiospermes f ON f.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN annelides g ON g.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN arachnides h ON h.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN ascidies i ON i.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN autres j ON j.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN bivalves k ON k.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN cephalopodes l ON l.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN crustaces m ON m.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN diatomees n ON n.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN entognathes p ON p.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN fougeres q ON q.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN gasteropodes r ON r.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN gymnospermes s ON s.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN hepatiques_anthocerotes t ON t.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN hydrozoaires u ON u.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN insectes v ON v.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN lichens w ON w.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN mammiferes x ON x.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN mousses y ON y.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN myriapodes z ON z.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN nematodes ab ON ab.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN nemertes ac ON ac.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN octocoralliaires ad ON ad.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN oiseaux ae ON ae.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN plathelminthes af ON af.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN poissons ag ON ag.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN pycnogonides ah ON ah.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN reptiles ai ON ai.nom_epci_simple = o.nom_epci_simple
     LEFT JOIN scleractiniaires aj ON aj.nom_epci_simple = o.nom_epci_simple
  WHERE o.nom_epci_simple IS NOT NULL
  ORDER BY o.nom_epci_simple
WITH DATA;

ALTER TABLE atlas.vm_stats_espece_group2inpn_epci
  OWNER TO geonatuser;
GRANT ALL ON TABLE atlas.vm_stats_espece_group2inpn_epci TO geonatuser;
GRANT SELECT ON TABLE atlas.vm_stats_espece_group2inpn_epci TO geonatatlas;

-- Index: atlas.vm_stats_espece_group2inpn_epci_nom_epci_simple_idx

-- DROP INDEX atlas.vm_stats_espece_group2inpn_epci_nom_epci_simple_idx;

CREATE UNIQUE INDEX vm_stats_espece_group2inpn_epci_nom_epci_simple_idx
  ON atlas.vm_stats_espece_group2inpn_epci
  USING btree
  (nom_epci_simple COLLATE pg_catalog."default");



/* stats nb obs par group2_inpn pour chaque departement */

-- Materialized View: atlas.vm_stats_espece_group2inpn_dpt
-- DROP MATERIALIZED VIEW atlas.vm_stats_espece_group2inpn_dpt;

-- Materialized View: atlas.vm_stats_espece_group2inpn_dpt
-- DROP MATERIALIZED VIEW atlas.vm_stats_espece_group2inpn_dpt;

CREATE MATERIALIZED VIEW atlas.vm_stats_espece_group2inpn_dpt AS 
 

 WITH cd_ref AS (
         SELECT vm_taxref.cd_ref, vm_taxref.group2_inpn
         FROM atlas.vm_taxref 
         WHERE vm_taxref.cd_ref = vm_taxref.cd_nom 
         ),
        somme_a AS (
         SELECT DISTINCT
            o.cd_ref,
            left(o.insee,2) AS num_dpt,
            COUNT(o.cd_ref) AS nb, 
            t.group2_inpn
        FROM atlas.vm_observations o
        JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
        AND t.group2_inpn = 'Acanthocéphales'
        GROUP BY o.cd_ref, num_dpt, t.group2_inpn
        ),
        Acanthocephales AS (
            select count(*) as nb,
            num_dpt
            from somme_a
            group by num_dpt
        ), 
     
        somme_b AS (
         SELECT DISTINCT
            o.cd_ref,
            left(o.insee,2) AS num_dpt,
            COUNT(o.cd_ref) AS nb, 
            t.group2_inpn
        FROM atlas.vm_observations o
        JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
        AND t.group2_inpn = 'Algues brunes'
        GROUP BY o.cd_ref, num_dpt, t.group2_inpn
        ),
        Algues_brunes AS (
            select count(*) as nb,
            num_dpt
            from somme_b
            group by num_dpt
        ), 

        somme_c AS (
         SELECT DISTINCT
            o.cd_ref,
            left(o.insee,2) AS num_dpt,
            COUNT(o.cd_ref) AS nb, 
            t.group2_inpn
        FROM atlas.vm_observations o
        JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
        AND t.group2_inpn = 'Algues rouges'
        GROUP BY o.cd_ref, num_dpt, t.group2_inpn
        ),
        Algues_rouges AS (
            select count(*) as nb,
            num_dpt
            from somme_c
            group by num_dpt
        ), 

        somme_d AS (
         SELECT DISTINCT
            o.cd_ref,
            left(o.insee,2) AS num_dpt,
            COUNT(o.cd_ref) AS nb, 
            t.group2_inpn
        FROM atlas.vm_observations o
        JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
        AND t.group2_inpn = 'Algues vertes'
        GROUP BY o.cd_ref, num_dpt, t.group2_inpn
        ),
        Algues_vertes AS (
            select count(*) as nb,
            num_dpt
            from somme_d
            group by num_dpt
        ), 

       somme_e AS (
         SELECT DISTINCT
            o.cd_ref,
            left(o.insee,2) AS num_dpt,
            COUNT(o.cd_ref) AS nb, 
            t.group2_inpn
        FROM atlas.vm_observations o
        JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
        AND t.group2_inpn = 'Amphibiens'
        GROUP BY o.cd_ref, num_dpt, t.group2_inpn
        ),
        Amphibiens AS (
            select count(*) as nb,
            num_dpt
            from somme_e
            group by num_dpt
        ), 

        somme_f AS (
         SELECT DISTINCT
            o.cd_ref,
            left(o.insee,2) AS num_dpt,
            COUNT(o.cd_ref) AS nb, 
            t.group2_inpn
        FROM atlas.vm_observations o
        JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
        AND t.group2_inpn = 'Angiospermes'
        GROUP BY o.cd_ref, num_dpt, t.group2_inpn
        ),
        Angiospermes AS (
            select count(*) as nb,
            num_dpt
            from somme_f
            group by num_dpt
        ), 

        somme_g AS (
         SELECT DISTINCT
            o.cd_ref,
            left(o.insee,2) AS num_dpt,
            COUNT(o.cd_ref) AS nb, 
            t.group2_inpn
        FROM atlas.vm_observations o
        JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
        AND t.group2_inpn = 'Annélides'        
        GROUP BY o.cd_ref, num_dpt, t.group2_inpn
        ),
        Annelides AS (
            select count(*) as nb,
            num_dpt
            from somme_g
            group by num_dpt
        ),

        somme_h AS (
         SELECT DISTINCT
            o.cd_ref,
            left(o.insee,2) AS num_dpt,
            COUNT(o.cd_ref) AS nb, 
            t.group2_inpn
        FROM atlas.vm_observations o
        JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
        AND t.group2_inpn = 'Arachnides'        
        GROUP BY o.cd_ref, num_dpt, t.group2_inpn
        ),
        Arachnides AS (
            select count(*) as nb,
            num_dpt
            from somme_h
            group by num_dpt
        ),

        somme_i AS (
         SELECT DISTINCT
            o.cd_ref,
            left(o.insee,2) AS num_dpt,
            COUNT(o.cd_ref) AS nb, 
            t.group2_inpn
        FROM atlas.vm_observations o
        JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
        AND t.group2_inpn = 'Ascidies'        
        GROUP BY o.cd_ref, num_dpt, t.group2_inpn
        ),
        Ascidies AS (
            select count(*) as nb,
            num_dpt
            from somme_i
            group by num_dpt
        ),

        somme_j AS (
         SELECT DISTINCT
            o.cd_ref,
            left(o.insee,2) AS num_dpt,
            COUNT(o.cd_ref) AS nb, 
            t.group2_inpn
        FROM atlas.vm_observations o
        JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
        AND t.group2_inpn = 'Autres'        
        GROUP BY o.cd_ref, num_dpt, t.group2_inpn
        ),
        Autres AS (
            select count(*) as nb,
            num_dpt
            from somme_j
            group by num_dpt
        ),

        somme_k AS (
         SELECT DISTINCT
            o.cd_ref,
            left(o.insee,2) AS num_dpt,
            COUNT(o.cd_ref) AS nb, 
            t.group2_inpn
        FROM atlas.vm_observations o
        JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
        AND t.group2_inpn = 'Bivalves'        
        GROUP BY o.cd_ref, num_dpt, t.group2_inpn
        ),
        Bivalves AS (
            select count(*) as nb,
            num_dpt
            from somme_k
            group by num_dpt
        ),

        somme_l AS (
         SELECT DISTINCT
            o.cd_ref,
            left(o.insee,2) AS num_dpt,
            COUNT(o.cd_ref) AS nb, 
            t.group2_inpn
        FROM atlas.vm_observations o
        JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
        AND t.group2_inpn = 'Céphalopodes'        
        GROUP BY o.cd_ref, num_dpt, t.group2_inpn
        ),
        Cephalopodes AS (
            select count(*) as nb,
            num_dpt
            from somme_l
            group by num_dpt
        ),

        somme_m AS (
         SELECT DISTINCT
            o.cd_ref,
            left(o.insee,2) AS num_dpt,
            COUNT(o.cd_ref) AS nb, 
            t.group2_inpn
        FROM atlas.vm_observations o
        JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
        AND t.group2_inpn = 'Crustacés'        
        GROUP BY o.cd_ref, num_dpt, t.group2_inpn
        ),
        Crustaces AS (
            select count(*) as nb,
            num_dpt
            from somme_m
            group by num_dpt
        ),

        somme_n AS (
         SELECT DISTINCT
            o.cd_ref,
            left(o.insee,2) AS num_dpt,
            COUNT(o.cd_ref) AS nb, 
            t.group2_inpn
        FROM atlas.vm_observations o
        JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
        AND t.group2_inpn = 'Diatomées'        
        GROUP BY o.cd_ref, num_dpt, t.group2_inpn
        ),
        Diatomees AS (
            select count(*) as nb,
            num_dpt
            from somme_n
            group by num_dpt
        ),

        somme_p AS (
         SELECT DISTINCT
            o.cd_ref,
            left(o.insee,2) AS num_dpt,
            COUNT(o.cd_ref) AS nb, 
            t.group2_inpn
        FROM atlas.vm_observations o
        JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
        AND t.group2_inpn = 'Entognathes'        
        GROUP BY o.cd_ref, num_dpt, t.group2_inpn
        ),
        Entognathes AS (
            select count(*) as nb,
            num_dpt
            from somme_p
            group by num_dpt
        ),

        somme_q AS (
         SELECT DISTINCT
            o.cd_ref,
            left(o.insee,2) AS num_dpt,
            COUNT(o.cd_ref) AS nb, 
            t.group2_inpn
        FROM atlas.vm_observations o
        JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
        AND t.group2_inpn = 'Fougères'        
        GROUP BY o.cd_ref, num_dpt, t.group2_inpn
        ),
        Fougeres AS (
            select count(*) as nb,
            num_dpt
            from somme_q
            group by num_dpt
        ),

        somme_r AS (
         SELECT DISTINCT
            o.cd_ref,
            left(o.insee,2) AS num_dpt,
            COUNT(o.cd_ref) AS nb, 
            t.group2_inpn
        FROM atlas.vm_observations o
        JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
        AND t.group2_inpn = 'Gastéropodes'        
        GROUP BY o.cd_ref, num_dpt, t.group2_inpn
        ),
        Gasteropodes AS (
            select count(*) as nb,
            num_dpt
            from somme_r
            group by num_dpt
        ),

        somme_s AS (
         SELECT DISTINCT
            o.cd_ref,
            left(o.insee,2) AS num_dpt,
            COUNT(o.cd_ref) AS nb, 
            t.group2_inpn
        FROM atlas.vm_observations o
        JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
        AND t.group2_inpn = 'Gymnospermes'        
        GROUP BY o.cd_ref, num_dpt, t.group2_inpn
        ),
        Gymnospermes AS (
            select count(*) as nb,
            num_dpt
            from somme_s
            group by num_dpt
        ),

        somme_t AS (
         SELECT DISTINCT
            o.cd_ref,
            left(o.insee,2) AS num_dpt,
            COUNT(o.cd_ref) AS nb, 
            t.group2_inpn
        FROM atlas.vm_observations o
        JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
        AND t.group2_inpn = 'Hépatiques et Anthocérotes'        
        GROUP BY o.cd_ref, num_dpt, t.group2_inpn
        ),
        Hepatiques_Anthocerotes AS (
            select count(*) as nb,
            num_dpt
            from somme_t
            group by num_dpt
        ),

        somme_u AS (
         SELECT DISTINCT
            o.cd_ref,
            left(o.insee,2) AS num_dpt,
            COUNT(o.cd_ref) AS nb, 
            t.group2_inpn
        FROM atlas.vm_observations o
        JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
        AND t.group2_inpn = 'Hydrozoaires'        
        GROUP BY o.cd_ref, num_dpt, t.group2_inpn
        ),
        Hydrozoaires AS (
            select count(*) as nb,
            num_dpt
            from somme_u
            group by num_dpt
        ),

        somme_v AS (
         SELECT DISTINCT
            o.cd_ref,
            left(o.insee,2) AS num_dpt,
            COUNT(o.cd_ref) AS nb, 
            t.group2_inpn
        FROM atlas.vm_observations o
        JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
        AND t.group2_inpn = 'Insectes'        
        GROUP BY o.cd_ref, num_dpt, t.group2_inpn
        ),
        Insectes AS (
            select count(*) as nb,
            num_dpt
            from somme_v
            group by num_dpt
        ),

        somme_w AS (
         SELECT DISTINCT
            o.cd_ref,
            left(o.insee,2) AS num_dpt,
            COUNT(o.cd_ref) AS nb, 
            t.group2_inpn
        FROM atlas.vm_observations o
        JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
        AND t.group2_inpn = 'Lichens'        
        GROUP BY o.cd_ref, num_dpt, t.group2_inpn
        ),
        Lichens AS (
            select count(*) as nb,
            num_dpt
            from somme_w
            group by num_dpt
        ),

        somme_x AS (
         SELECT DISTINCT
            o.cd_ref,
            left(o.insee,2) AS num_dpt,
            COUNT(o.cd_ref) AS nb, 
            t.group2_inpn
        FROM atlas.vm_observations o
        JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
        AND t.group2_inpn = 'Mammifères'        
        GROUP BY o.cd_ref, num_dpt, t.group2_inpn
        ),
        Mammiferes AS (
            select count(*) as nb,
            num_dpt
            from somme_x
            group by num_dpt
        ),

        somme_y AS (
         SELECT DISTINCT
            o.cd_ref,
            left(o.insee,2) AS num_dpt,
            COUNT(o.cd_ref) AS nb, 
            t.group2_inpn
        FROM atlas.vm_observations o
        JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
        AND t.group2_inpn = 'Mousses'        
        GROUP BY o.cd_ref, num_dpt, t.group2_inpn
        ),
        Mousses AS (
            select count(*) as nb,
            num_dpt
            from somme_y
            group by num_dpt
        ),

        somme_z AS (
         SELECT DISTINCT
            o.cd_ref,
            left(o.insee,2) AS num_dpt,
            COUNT(o.cd_ref) AS nb, 
            t.group2_inpn
        FROM atlas.vm_observations o
        JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
        AND t.group2_inpn = 'Myriapodes'        
        GROUP BY o.cd_ref, num_dpt, t.group2_inpn
        ),
        Myriapodes AS (
            select count(*) as nb,
            num_dpt
            from somme_z
            group by num_dpt
        ),

        somme_ab AS (
         SELECT DISTINCT
            o.cd_ref,
            left(o.insee,2) AS num_dpt,
            COUNT(o.cd_ref) AS nb, 
            t.group2_inpn
        FROM atlas.vm_observations o
        JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
        AND t.group2_inpn = 'Nématodes'        
        GROUP BY o.cd_ref, num_dpt, t.group2_inpn
        ),
        Nematodes AS (
            select count(*) as nb,
            num_dpt
            from somme_ab
            group by num_dpt
        ),

        somme_ac AS (
         SELECT DISTINCT
            o.cd_ref,
            left(o.insee,2) AS num_dpt,
            COUNT(o.cd_ref) AS nb, 
            t.group2_inpn
        FROM atlas.vm_observations o
        JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
        AND t.group2_inpn = 'Némertes'        
        GROUP BY o.cd_ref, num_dpt, t.group2_inpn
        ),
        Nemertes AS (
            select count(*) as nb,
            num_dpt
            from somme_ac
            group by num_dpt
        ),

        somme_ad AS (
         SELECT DISTINCT
            o.cd_ref,
            left(o.insee,2) AS num_dpt,
            COUNT(o.cd_ref) AS nb, 
            t.group2_inpn
        FROM atlas.vm_observations o
        JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
        AND t.group2_inpn = 'Octocoralliaires'        
        GROUP BY o.cd_ref, num_dpt, t.group2_inpn
        ),
        Octocoralliaires AS (
            select count(*) as nb,
            num_dpt
            from somme_ad
            group by num_dpt
        ),

        somme_ae AS (
         SELECT DISTINCT
            o.cd_ref,
            left(o.insee,2) AS num_dpt,
            COUNT(o.cd_ref) AS nb, 
            t.group2_inpn
        FROM atlas.vm_observations o
        JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
        AND t.group2_inpn = 'Oiseaux'        
        GROUP BY o.cd_ref, num_dpt, t.group2_inpn
        ),
        Oiseaux AS (
            select count(*) as nb,
            num_dpt
            from somme_ae
            group by num_dpt
        ),

        somme_af AS (
         SELECT DISTINCT
            o.cd_ref,
            left(o.insee,2) AS num_dpt,
            COUNT(o.cd_ref) AS nb, 
            t.group2_inpn
        FROM atlas.vm_observations o
        JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
        AND t.group2_inpn = 'Plathelminthes'        
        GROUP BY o.cd_ref, num_dpt, t.group2_inpn
        ),
        Plathelminthes AS (
            select count(*) as nb,
            num_dpt
            from somme_af
            group by num_dpt
        ),

        somme_ag AS (
         SELECT DISTINCT
            o.cd_ref,
            left(o.insee,2) AS num_dpt,
            COUNT(o.cd_ref) AS nb, 
            t.group2_inpn
        FROM atlas.vm_observations o
        JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
        AND t.group2_inpn = 'Poissons'        
        GROUP BY o.cd_ref, num_dpt, t.group2_inpn
        ),
        Poissons AS (
            select count(*) as nb,
            num_dpt
            from somme_ag
            group by num_dpt
        ),

        somme_ah AS (
         SELECT DISTINCT
            o.cd_ref,
            left(o.insee,2) AS num_dpt,
            COUNT(o.cd_ref) AS nb, 
            t.group2_inpn
        FROM atlas.vm_observations o
        JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
        AND t.group2_inpn = 'Pycnogonides'        
        GROUP BY o.cd_ref, num_dpt, t.group2_inpn
        ),
        Pycnogonides AS (
            select count(*) as nb,
            num_dpt
            from somme_ah
            group by num_dpt
        ),

        somme_ai AS (
         SELECT DISTINCT
            o.cd_ref,
            left(o.insee,2) AS num_dpt,
            COUNT(o.cd_ref) AS nb, 
            t.group2_inpn
        FROM atlas.vm_observations o
        JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
        AND t.group2_inpn = 'Reptiles'        
        GROUP BY o.cd_ref, num_dpt, t.group2_inpn
        ),
        Reptiles AS (
            select count(*) as nb,
            num_dpt
            from somme_ai
            group by num_dpt
        ),

        somme_aj AS (
         SELECT DISTINCT
            o.cd_ref,
            left(o.insee,2) AS num_dpt,
            COUNT(o.cd_ref) AS nb, 
            t.group2_inpn
        FROM atlas.vm_observations o
        JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
        AND t.group2_inpn = 'Scléractiniaires'        
        GROUP BY o.cd_ref, num_dpt, t.group2_inpn
        ),
        Scleractiniaires AS (
            select count(*) as nb,
            num_dpt
            from somme_aj
            group by num_dpt
        )



SELECT DISTINCT left(o.insee,2)::text AS num_dpt,
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

     LEFT JOIN Acanthocephales a ON a.num_dpt = left(o.insee,2)
     LEFT JOIN Algues_brunes b ON b.num_dpt = left(o.insee,2)
     LEFT JOIN Algues_rouges c ON c.num_dpt = left(o.insee,2)
     LEFT JOIN Algues_vertes d ON d.num_dpt = left(o.insee,2)
     LEFT JOIN Amphibiens e ON e.num_dpt = left(o.insee,2)
     LEFT JOIN Angiospermes f ON f.num_dpt = left(o.insee,2)
     LEFT JOIN Annelides g ON g.num_dpt = left(o.insee,2)
     LEFT JOIN Arachnides h ON h.num_dpt = left(o.insee,2)
     LEFT JOIN Ascidies i ON i.num_dpt = left(o.insee,2)
     LEFT JOIN Autres j ON j.num_dpt = left(o.insee,2)
     LEFT JOIN Bivalves k ON k.num_dpt = left(o.insee,2)
     LEFT JOIN Cephalopodes l ON l.num_dpt = left(o.insee,2)
     LEFT JOIN Crustaces m ON m.num_dpt = left(o.insee,2)
     LEFT JOIN Diatomees n ON n.num_dpt = left(o.insee,2)
     LEFT JOIN Entognathes p ON p.num_dpt = left(o.insee,2)
     LEFT JOIN Fougeres q ON q.num_dpt = left(o.insee,2)
     LEFT JOIN Gasteropodes r ON r.num_dpt = left(o.insee,2)
     LEFT JOIN Gymnospermes s ON s.num_dpt = left(o.insee,2)
     LEFT JOIN Hepatiques_Anthocerotes t ON t.num_dpt = left(o.insee,2)
     LEFT JOIN Hydrozoaires u ON u.num_dpt = left(o.insee,2)
     LEFT JOIN Insectes v ON v.num_dpt = left(o.insee,2)
     LEFT JOIN Lichens w ON w.num_dpt = left(o.insee,2)
     LEFT JOIN Mammiferes x ON x.num_dpt = left(o.insee,2)
     LEFT JOIN Mousses y ON y.num_dpt = left(o.insee,2)
     LEFT JOIN Myriapodes z ON z.num_dpt = left(o.insee,2)
     LEFT JOIN Nematodes ab ON ab.num_dpt = left(o.insee,2)
     LEFT JOIN Nemertes ac ON ac.num_dpt = left(o.insee,2)
     LEFT JOIN Octocoralliaires ad ON ad.num_dpt = left(o.insee,2)
     LEFT JOIN Oiseaux ae ON ae.num_dpt = left(o.insee,2)
     LEFT JOIN Plathelminthes af ON af.num_dpt = left(o.insee,2)
     LEFT JOIN Poissons ag ON ag.num_dpt = left(o.insee,2)
     LEFT JOIN Pycnogonides ah ON ah.num_dpt = left(o.insee,2)
     LEFT JOIN Reptiles ai ON ai.num_dpt = left(o.insee,2)
     LEFT JOIN Scleractiniaires aj ON aj.num_dpt = left(o.insee,2)


  WHERE o.insee IS NOT NULL
  ORDER BY num_dpt

WITH DATA;

ALTER TABLE atlas.vm_stats_espece_group2inpn_dpt
  OWNER TO geonatuser;
GRANT ALL ON TABLE atlas.vm_stats_espece_group2inpn_dpt TO geonatuser;
GRANT SELECT ON TABLE atlas.vm_stats_espece_group2inpn_dpt TO geonatatlas;

-- Index: atlas.vm_stats_espece_group2inpn_dpt_num_dpt_idx

-- DROP INDEX atlas.vm_stats_espece_group2inpn_dpt_num_dpt_idx;

CREATE UNIQUE INDEX vm_stats_espece_group2inpn_dpt_num_dpt_idx
  ON atlas.vm_stats_espece_group2inpn_dpt
  USING btree (num_dpt);