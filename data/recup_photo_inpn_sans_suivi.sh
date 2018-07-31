#!/bin/bash

################################
# Décommenter pour instalr jq #
################################
#sudo apt-get update
#sudo apt-get -y upgrade
#sudo apt-get -y install jq




#SETTINGS
DBTAXHUB=mydbtaxo
DBATLAS=mydbatlas
TABLESYNTHESE=syntheseff
SOURCE="INPN service TaxRef MNHN"
IDTYPE=2
MYUSER="mon user"
CHEMIN_MEDIA_TAXHUB="/home/${MYUSER}/taxhub/static/medias/"
DBPGPASSWORD="lemotdepasse"


#On récupère tous les taxons présents dans la synthese

QUERYMESTAXON="WITH observations AS (SELECT DISTINCT cd_nom FROM synthese.$TABLESYNTHESE)
SELECT json_build_object('cd_nom', o.cd_nom, 'cd_ref', tx.cd_ref, 'nom_tax', tx.lb_nom)   
FROM observations o JOIN atlas.vm_taxref tx ON o.cd_nom = tx.cd_nom"

QUERY_RESULTS_MESTAXON=($(PGPASSWORD=$DBPGPASSWORD psql -h localhost -p 5432 -t -U postgres -d $DBATLAS -c "$QUERYMESTAXON"))


    for ROW in $(echo "${QUERY_RESULTS_MESTAXON[@]}" | jq -r '. | @base64'); do
        _taxon() {
            echo ${ROW} | base64 --decode | jq -r ${1}
        }

        TAXCDNOM=$(_taxon '.cd_nom')
        echo ${TAXCDNOM}
      
        TAXCDREF=$(_taxon '.cd_ref')
        echo ${TAXCDREF}

        NOMTAX=$(_taxon '.nom_tax')
        echo ${NOMTAX}

#On fait un insert dans taxonomie.bib_nom pour chaque cdNom
        QUERYINSERTBIBNOM="insert into taxonomie.bib_noms (cd_nom, cd_ref, nom_francais) values (${TAXCDNOM}, ${TAXCDREF}, '${NOMTAX}') ON CONFLICT (cd_nom) DO NOTHING;" 
        QUERY_RESULTS_INSERTBIBNOM=($(PGPASSWORD=$DBPGPASSWORD psql -h localhost -p 5432 -t -U postgres -d $DBTAXHUB -c "$QUERYINSERTBIBNOM"))

    done


 
 #On recupère tous les cd_nom de toxonomie.bib_noms (geonaturedb) pour télécharger les medias de nos taxons (#et pas de tout TAXREF)
  QUERYGETCDNOM="select cd_nom from taxonomie.bib_noms;" 
  QUERY_RESULTS_CDNOM=($(PGPASSWORD=$DBPGPASSWORD psql -h localhost -p 5432 -t -U postgres -d $DBTAXHUB -c "$QUERYGETCDNOM"))

 
 #On boucle pour chaque cd_nom présent dans bib_noms
 cnt=${#QUERY_RESULTS_CDNOM[@]}
 
 for (( i=0 ; i<${cnt} ; i++ )); do
     _cdnom() {
         echo "${QUERY_RESULTS_CDNOM[$i]}"
     }
     CDNOM=$(_cdnom)
 
   #On récupère le cd_ref associé au cd_nom (dans la table taxonomie.bib_noms)
    QUERYGETCDREF="select cd_ref from taxonomie.bib_noms where cd_nom=$CDNOM;" 
    CDREF=($(PGPASSWORD=$DBPGPASSWORD psql -h localhost -p 5432 -t -U postgres -d $DBTAXHUB -c "$QUERYGETCDREF"))
 
   #On récupère le nom français associé au cd_nom (dans la table taxonomie.bib_noms)
    QUERYGETNOMFR="SELECT nom_francais FROM taxonomie.bib_noms WHERE cd_nom=$CDNOM;"
    TITRE="$(PGPASSWORD=$DBPGPASSWORD psql -h localhost -p 5432 -t -U postgres -d $DBTAXHUB -c "$QUERYGETNOMFR")"
    TITRE=`echo $TITRE | sed -e s/\'/\'\'/ `

    QUERYTITREMEDIA="SELECT
                    regexp_replace(nom_francais, '''|,|\s', '_', 'g')
                    FROM taxonomie.bib_noms 
                    WHERE cd_nom=$CDNOM;"
    TITREMEDIA=($(PGPASSWORD=$DBPGPASSWORD psql -h localhost -p 5432 -t -U postgres -d $DBTAXHUB -c "$QUERYTITREMEDIA"))

 
 #On recupère le fichier JSON associe au cd_nom#
  JSONDATA=$(curl -X GET "https://taxref.mnhn.fr/api/media/cdNom/$CDNOM" -H "accept: application/json" | jq -r '.media.media')  
 #On boucle dans le fichier JSON
             for ROW in $(echo "${JSONDATA}" | jq -r '.[] | @base64'); do
                 _jq() {
                     echo ${ROW} | base64 --decode | jq -r ${1}
                 }
 
               #On recupère l'url pour télécharger le média
                URL=$(_jq '.url')
                echo $URL
            
                #On recupère la licence d'utilisation du média
                LICENCE=$(_jq '.licence')
                echo $LICENCE
            
                #On recupère le nom de l'auteur du média
                COPYRIGHT=$(_jq '.copyright')
                COPYRIGHT=`echo $COPYRIGHT | sed -e s/\'/\'\'/ `
                echo $COPYRIGHT
            
                #On recupère la legende associee au média
                LEGENDE=$(_jq '.legende')
                LEGENDE=`echo $LEGENDE | sed -e s/\'/\'\'/ `
                echo $LEGENDE
 
 #On insère les données dans taxonomie.t_medias
   #On récupère le prochain id_media
                QUERYIDMEDIA="select nextval('taxonomie.t_medias_id_media_seq'::regclass);"
                IDMEDIA=($(PGPASSWORD=$DBPGPASSWORD psql -h localhost -p 5432 -t -U postgres -d $DBTAXHUB -c "$QUERYIDMEDIA"))
 
   #On crée le chemin avec le nom du fichier media
                 CHEMIN="static/medias/${CDREF}_${IDMEDIA}_${TITREMEDIA}"
 
   #On lance le insert dans taxonomie.t_medias#
                QUERYINSERTTMEDIA="insert into taxonomie.t_medias (
                    cd_ref, 
                    titre, 
                    chemin, 
                    auteur, 
                    desc_media, 
                    date_media, 
                    id_type, 
                    source, 
                    licence) 
                values (
                    '${CDREF}',
                    '${TITRE}',
                    '${CHEMIN}', 
                    '${COPYRIGHT}',
                    COALESCE('${LEGENDE}', null), 
                    now(), 
                    ${IDTYPE}, 
                    '${SOURCE}', 
                    '${LICENCE}'
                    );" 

                 RESULTS_QUERYINSERTTMEDIA=($(PGPASSWORD=$DBPGPASSWORD psql -h localhost -p 5432 -t -U postgres -d $DBTAXHUB -c "$QUERYINSERTTMEDIA")) 
 
 
 #On enregistre le média dans /home/MYUSER/taxhub/static/medias/ avec le même nom que celui renseigné dans #taxonomie.t_medias
                 cd "${CHEMIN_MEDIA_TAXHUB}"
                 wget -O "${CHEMIN_MEDIA_TAXHUB}${CDREF}_${IDMEDIA}_${TITREMEDIA}" "${URL}"
 
             done
 done
 
 #Arrivé ici, on a téléchargé toutes les photos associées à nos cd_noms, toutes en photos type 2
 #On change le type d'une des photos de 2 à 1 pour avoir une photo principale
 
QUERYPHOTO1="UPDATE taxonomie.t_medias SET id_type = 1
            WHERE id_media IN (
                SELECT min(id_media)
                FROM taxonomie.t_medias t
                  LEFT OUTER JOIN (SELECT cd_ref FROM taxonomie.t_medias WHERE id_type = 1) e
                  ON t.cd_ref = e.cd_ref
                WHERE e.cd_ref IS NULL
                GROUP BY t.cd_ref
            );"

RESULTS_QUERYPHOTO1=($(PGPASSWORD=$DBPGPASSWORD psql -h localhost -p 5432 -t -U postgres -d $DBTAXHUB -c "$QUERYPHOTO1")) 


#On rafraichit la vm_medias de l'atlas

QUERYREFRESH="REFRESH MATERIALIZED VIEW atlas.vm_medias; REFRESH MATERIALIZED VIEW atlas.vm_taxons_plus_observes;" 
RESULTS_QUERYREFRESH=($(PGPASSWORD=$DBPGPASSWORD psql -h localhost -p 5432 -t -U postgres -d $DBATLAS -c "$QUERYREFRESH"))

