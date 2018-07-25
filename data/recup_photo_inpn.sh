#!/bin/bash

#echo "MaJ et installation de jq..."
#sudo apt-get update
#sudo apt-get -y upgrade
#sudo apt-get -y install jq

#SETIINGS
DBTAXHUB=geonaturedb
DBATLAS=geonatureatlas
TABLESYNTHESE=syntheseff_atlas
SOURCE="INPN service TaxRef MNHN"
IDTYPE=2
MYUSER="cen-pdl"
CHEMIN_MEDIA_TAXHUB="/home/${MYUSER}/taxhub/static/medias/"



#On récupère tous les taxons présents dans la synthese

QUERYMESTAXON="WITH observations AS (SELECT DISTINCT cd_nom FROM synthese.$TABLESYNTHESE)
SELECT json_build_object('cd_nom', o.cd_nom, 'cd_ref', tx.cd_ref, 'nom_tax', COALESCE(tx.nom_vern,tx.lb_nom))   
FROM observations o JOIN atlas.vm_taxref tx ON o.cd_nom = tx.cd_nom limit 50"

QUERY_RESULTS_MESTAXON=($(psql -h localhost -p 5432 -t -U postgres -d $DBATLAS -c "$QUERYMESTAXON"))


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
        QUERY_RESULTS_INSERTBIBNOM=($(psql -h localhost -p 5432 -t -U postgres -d $DBTAXHUB -c "$QUERYINSERTBIBNOM"))

    done


#On recupère tous les cd_nom de toxonomie.bib_noms (geonaturedb) pour télécharger les medias de nos taxons (et pas de tout TAXREF)
QUERYGETCDNOM="select cd_nom from taxonomie.bib_noms;" 
QUERY_RESULTS_CDNOM=($(psql -h localhost -p 5432 -t -U postgres -d $DBTAXHUB -c "$QUERYGETCDNOM"))


#On boucle pour chaque cd_nom présent dans bib_noms
cnt=${#QUERY_RESULTS_CDNOM[@]}

for (( i=0 ; i<${cnt} ; i++ )); do
    _cdnom() {
        echo "${QUERY_RESULTS_CDNOM[$i]}"
    }

    CDNOM=$(_cdnom)

#On récupère le cd_ref associé au cd_nom (dans la table taxonomie.bib_noms)
    QUERYGETCDREF="select cd_ref from taxonomie.bib_noms where cd_ref=$CDNOM;" 
    CDREF=($(psql -h localhost -p 5432 -t -U postgres -d $DBTAXHUB -c "$QUERYGETCDREF"))

#On récupère le nom français associé au cd_nom (dans la table taxonomie.bib_noms)

     QUERYGETNOMFR="SELECT CASE 
                      WHEN nom_francais ilike '%,%' THEN  regexp_replace(split_part(nom_francais,',',1),'\s','_') 
                      WHEN nom_francais ilike '%(%' THEN  regexp_replace(split_part(nom_francais,'(',1),'\s','_') 
                      ELSE nom_francais
                    END
                    FROM taxonomie.bib_noms 
                    WHERE cd_nom=$CDNOM;"

    TITRE=($(psql -h localhost -p 5432 -t -U postgres -d $DBTAXHUB -c "$QUERYGETNOMFR"))
#echo "Le cdref du taxon ${CDNOM} est le ${CDREF} et son nom est ${TITRE}"
#done

#On recupère le fichier JSON associe au cd_nom
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
                echo $COPYRIGHT
            
#On recupère la legende associee au média
                LEGENDE=$(_jq '.legende')
                echo $LEGENDE

#On insère les données dans taxonomie.t_medias
  #On récupère le prochain id_media
                QUERYIDMEDIA="select nextval('taxonomie.t_medias_id_media_seq'::regclass);"
                IDMEDIA=($(psql -h localhost -p 5432 -t -U postgres -d $DBTAXHUB -c "$QUERYIDMEDIA"))

  #On crée le chemin avec le nom du fichier media
                CHEMIN="/static/medias/${CDREF}_${IDMEDIA}_${TITRE}"
  
  #On lance le insert dans taxonomie.t_medias
                QUERYINSERTTMEDIA="insert into taxonomie.t_medias (cd_ref, titre, chemin, auteur, desc_media, date_media, id_type, source, licence) values (${CDREF}, '${TITRE}', '${CHEMIN}', '${COPYRIGHT}', '${LEGENDE}', now(), ${IDTYPE}, '${SOURCE}', '${LICENCE}');" 
                RESULTS_QUERYINSERTTMEDIA=($(psql -h localhost -p 5432 -t -U postgres -d $DBTAXHUB -c "$QUERYINSERTTMEDIA")) 


#On enregistre le média dans /home/MYUSER/taxhub/static/medias/ avec le même nom que celui renseigné dans taxonomie.t_medias
                cd "${CHEMIN_MEDIA_TAXHUB}"
                wget -O "${CHEMIN_MEDIA_TAXHUB}${CDREF}_${IDMEDIA}_${TITRE}" "${URL}"

            done
done

#Arrivé ici, on a téléchargé toutes les photos associées à nos cd_noms, tous en photos secondaires (id tpe 2)

#On change le type d'une des photos de 2 à 1 pour avoir une photo principale

QUERYPHOTO1="UPDATE taxonomie.t_medias SET id_type = 1
            WHERE id_media IN (
                SELECT max(id_media)
                FROM taxonomie.t_medias t
                LEFT OUTER JOIN (SELECT cd_ref FROM taxonomie.t_medias WHERE id_type = 1) e
                ON t.cd_ref = e.cd_ref
                WHERE e.cd_ref IS NULL
                GROUP BY t.cd_ref
            );"

RESULTS_QUERYPHOTO1=($(psql -h localhost -p 5432 -t -U postgres -d $DBTAXHUB -c "$QUERYPHOTO1")) 


#On rafraichit la vm_medias de l'atlas

QUERYREFRESH="REFRESH MATERIALIZED VIEW atlas.vm_medias;" 
RESULTS_QUERYREFRESH=($(psql -h localhost -p 5432 -t -U postgres -d $DBATLAS -c "$QUERYREFRESH"))



##########################################
##########################################
##########################################
##########################################


#JSONDATA=$(curl -X GET "https://taxref.mnhn.fr/api/media/cdNom/85740" -H "accept: application/json" | jq -r '.media.media') 
#
#echo "${JSONDATA}"
#
#a=0
#for ROW in $(echo "${JSONDATA}" | jq -r '.[] | @base64'); do
#    _jq() {
#        echo ${ROW} | base64 --decode | jq -r ${1}
#    }
#echo $a
#    URL=$(_jq '.url')
#    echo $URL
#
#    LICENCE=$(_jq '.licence')
#    echo $LICENCE
#
#    COPYRIGHT=$(_jq '.copyright')
#    echo $COPYRIGHT
#
#    LEGENDE=$(_jq '.legende')
#    echo $LEGENDE
#
#    ((a+=1))
#echo $a
#
#done


#CDNOM=(`psql -h localhost -p 5432 -t -U postgres -d $DBTAXHUB -c "select cd_nom from taxonomie.bib_noms"`)
#QUERY="select cd_nom from taxonomie.bib_noms;" 
#QUERY_RESULTS=(`psql -h localhost -p 5432 -t -U postgres -d db_test -c "$QUERY"`)
#QUERY_RESULTS_STR=$(printf "%s," "${QUERY_RESULTS[@]}")
#echo ${QUERY_RESULTS_STR}


#QUERY="select cd_nom from taxonomie.bib_noms;" 
#QUERY_RESULTS=($(psql -h localhost -p 5432 -t -U postgres -d $DBTAXHUB -c "$QUERY"))
#
#
#
#cnt=${#QUERY_RESULTS[@]}
#
#for (( i=0 ; i<${cnt} ; i++ ))
#do
#    echo "Espece No. $i: ${QUERY_RESULTS[$i]}"
#done
#
#
#
#JSONDATA=$(curl -X GET "https://taxref.mnhn.fr/api/media/cdNom/85740" -H "accept: application/json" | jq -r '.media.media') 
#
#echo "${JSONDATA}"
#
#i=0
#for ROW in $(echo "${JSONDATA}" | jq -r '.[] | @base64'); do
#    _jq() {
#     echo ${ROW} | base64 --decode | jq -r ${1}
#    }
#    echo "${i}"
#    URL=$(_jq '.url')
#    echo $URL
#    LICENCE=$(_jq '.licence')
#    echo $LICENCE
#    COPYRIGHT=$(_jq '.copyright')
#    echo $COPYRIGHT
#    LEGENDE=$(_jq '.legende')
#    echo $LEGENDE
#    ((i+=1))
#done

