#!/bin/bash

################################
# Décommenter pour instalr jq #
################################
#sudo apt-get update
#sudo apt-get -y upgrade
#sudo apt-get -y install jq

################################################################################
# REMARQUE#
#il faut une table pg pour le suivi des ajout de média
#Exemple :
#CREATE TABLE taxonomie.t_medias_api_suivi
#(
#  cd_nom integer NOT NULL,
#  nom_photo character varying(100) NOT NULL,
#  source text,
#  CONSTRAINT pk_suivi_dl_media PRIMARY KEY (cd_nom, nom_photo)
#);
################################################################################



#SETTINGS
DBTAXHUB=mydbtaxo
DBATLAS=mydbatlas
SOURCE="INPN"
IDTYPE=2
MYUSER="mon user"
CHEMIN_MEDIA_TAXHUB="/home/${MYUSER}/taxhub/static/medias/"
DBPGPASSWORD="lemotdepasse"

 
#On recupère tous les cd_nom de toxonomie.bib_noms (geonature2db) pour télécharger les medias de nos taxons (#et pas de tout TAXREF)
  QUERYGETCDNOM="select cd_nom from taxonomie.bib_noms where cd_nom = cd_ref;" 
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
                    concat(
                        regexp_replace(
                            regexp_replace(
                                regexp_replace(
                                    regexp_replace(
                                        nom_francais, '''|,|\s', '_', 'g'
                                    )
                                    ,'\)', ''
                                )
                                ,'\(', ''
                            )
                            ,'''', ''
                        )
                        ,'.jpg'
                    )
                    FROM taxonomie.bib_noms 
                    WHERE cd_nom=$CDNOM;"
    TITREMEDIA=($(PGPASSWORD=$DBPGPASSWORD psql -h localhost -p 5432 -t -U postgres -d $DBTAXHUB -c "$QUERYTITREMEDIA"))


   #On recupère le fichier JSON associe au cd_nom
    JSONDATA=$(curl -X GET "https://taxref.mnhn.fr/api/taxa/$CDNOM/media" -H "accept: application/hal+json;version=1" | jq -r '._embedded.media') 

        #On boucle dans le fichier JSON
        for ROW in $(echo "${JSONDATA}" | jq -r '.[] | @base64'); do
            _jq() {
                echo ${ROW} | base64 --decode | jq -r ${1}
            }

        #On recupère l'url pour télécharger le média
        URL=$(_jq '._links.file.href')
        #On recupère le numero du media         
        NUMBERMEDIA=$(echo $URL | tr -cd '[[:digit:]]')

        #On récupère les numéros de média déjà téléchargés dans la table t_media_api_suivi
        QUERYMESEDIA="select nom_photo::integer FROM taxonomie.t_medias_api_suivi WHERE cd_nom=$CDNOM AND source ilike 'inpn';"
        QUERY_RESULTS_MESMEDIA=($(PGPASSWORD=$DBPGPASSWORD psql -h localhost -p 5432 -t -U postgres -d $DBTAXHUB -c "$QUERYMESEDIA"))
    
        #on verifie qu'on a pas déjà ajouter le media
        for val in $NUMBERMEDIA; do
            ix=$( printf "%s\n" "${QUERY_RESULTS_MESMEDIA[@]}" | grep -n -m 1 "^${val}$" | cut -d ":" -f1 )
            #si on a pas le média on l'ajoute
            if [[ -z $ix ]]
              then
               #On recupère l'url pour télécharger le média
                URL=$(_jq '._links.file.href')
                echo $URL
            
                #On recupère la licence d'utilisation du média
                LICENCE=$(_jq '.licence')
                echo $LICENCE
            
                #On recupère le nom de l'auteur du média
                COPYRIGHT=$(_jq '.copyright')
                COPYRIGHT=`echo $COPYRIGHT | sed -e s/\'/\'\'/ `
                echo $COPYRIGHT
            
                #On recupère la legende associee au média
                LEGENDE=$(_jq '.title')
                LEGENDE=`echo $LEGENDE | sed -e s/\'/\'\'/ `
                echo $LEGENDE

            #On insère les données dans taxonomie.t_medias
                #On récupère le prochain id_media
                QUERYIDMEDIA="select nextval('taxonomie.t_medias_id_media_seq'::regclass);"
                IDMEDIA=($(PGPASSWORD=$DBPGPASSWORD psql -h localhost -p 5432 -t -U postgres -d $DBTAXHUB -c "$QUERYIDMEDIA"))

                #On crée le chemin avec le nom du fichier media
                CHEMIN="static/medias/${CDREF}_${IDMEDIA}_${TITREMEDIA}"

                #On lance le insert dans taxonomie.t_medias
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

                #On met à jour la table de suivi taxonomie.t_medias_api_suivi
                QUERYMAJSUIVIMEDIA="insert into taxonomie.t_medias_api_suivi (cd_nom, nom_photo, source) values (${CDNOM}, '${NUMBERMEDIA}', 'inpn');" 
                RESULTS_QUERYMAJSUIVIMEDIA=($(PGPASSWORD=$DBPGPASSWORD psql -h localhost -p 5432 -t -U postgres -d $DBTAXHUB -c "$QUERYMAJSUIVIMEDIA"))
                #On enregistre le média dans /home/MYUSER/taxhub/static/medias/ avec le même nom que celui renseigné dans taxonomie.t_medias
                cd "${CHEMIN_MEDIA_TAXHUB}"
                wget -O "${CHEMIN_MEDIA_TAXHUB}${CDREF}_${IDMEDIA}_${TITREMEDIA}" "${URL}"
            
            else
                  echo $val déjà présent en position $(( ix-1 ))

            fi
        done
      
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


#On rafraichit les vm de l'atlas

QUERYREFRESH="REFRESH MATERIALIZED VIEW atlas.vm_medias; REFRESH MATERIALIZED VIEW atlas.vm_taxons_plus_observes;" 
RESULTS_QUERYREFRESH=($(PGPASSWORD=$DBPGPASSWORD psql -h localhost -p 5432 -t -U postgres -d $DBATLAS -c "$QUERYREFRESH"))

cd "/home/${MYUSER}/"
