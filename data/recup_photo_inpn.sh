#!/bin/bash

# Make sure only root can run our script
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

#echo "MaJ et installation de jq..."
#sudo apt-get update
#sudo apt-get -y upgrade
#sudo apt-get -y install jq

#. ../main/configuration/settings.ini

db_name1=db_test


cdnom=(`psql -h localhost -p 5432 -t -U postgres -d $db_name1 -c "select cd_nom from taxonomie.bib_noms"`)


query="select cd_nom from taxonomie.bib_noms;" 
QUERY_RESULTS=(`psql -h localhost -p 5432 -t -U postgres -d db_test -c "$query"`)
QUERY_RESULTS_STR=$(printf "%s," "${QUERY_RESULTS[@]}")
			   echo ${QUERY_RESULTS_STR}


query="select cd_nom from taxonomie.bib_noms;" 
QUERY_RESULTS=($(psql -h localhost -p 5432 -t -U postgres -d db_test -c "$query"))

echo ${QUERY_RESULTS[1]}

cpt=0
for ligne in $(echo $QUERY_RESULTS); do 
	_cdnom() {
		echo ${ligne} | base64 --decode 
	}
	echo "${cpt}"
	echo $(_cdnom)
	((cpt+=1))
	echo "${cpt}"
done




jsondata=$(curl -X GET "https://taxref.mnhn.fr/api/media/cdNom/85740" -H "accept: application/json" | jq -r '.media.media') 

echo "${jsond}"

i=0
for row in $(echo "${jsondata}" | jq -r '.[] | @base64'); do
    _jq() {
     echo ${row} | base64 --decode | jq -r ${1}
    }
	echo "${i}"
	url=$(_jq '.url')
	echo $url
	licence=$(_jq '.licence')
	echo $licence
	copyright=$(_jq '.copyright')
	echo $copyright
	legende=$(_jq '.legende')
	echo $legende
	((i+=1))
done

