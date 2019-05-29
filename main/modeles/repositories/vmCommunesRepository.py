
# -*- coding:utf-8 -*-

import ast
from ..entities.vmCommunes import VmCommunes
from sqlalchemy import distinct
from sqlalchemy.sql import text


def getAllCommunes(session):
    req = session.query(distinct(VmCommunes.commune_maj), VmCommunes.insee).all()
    communeList = list()
    for r in req:
        temp = {'label': r[0], 'value': r[1]}
        communeList.append(temp)
    return communeList


def getCommuneFromInsee(connection, insee):
    sql = "SELECT      \
                d.nom_dpt, \
                d.num_dpt, \
                c.commune_maj, \
                c.insee, \
                c.commune_geojson \
           FROM atlas.vm_communes c \
           JOIN atlas.vm_departement d ON d.num_dpt = left(c.insee,2)::int \
           WHERE c.insee = :thisInsee"
    req = connection.execute(text(sql), thisInsee=insee)
    communeObj = dict()
    for r in req:
        communeObj = {
            'dptName': r.nom_dpt,
            'num_dpt': r.num_dpt,
            'communeName': r.commune_maj,
            'insee': str(r.insee),
            'communeGeoJson': ast.literal_eval(r.commune_geojson)
        }
    return communeObj

    return req[0].commune_maj

def getCommunesObservationsChilds(connection, cd_ref):
    sql = """
    SELECT DISTINCT (com.insee) as insee, com.commune_maj
    FROM atlas.vm_communes com
    JOIN atlas.vm_observations obs
    ON obs.insee = com.insee
    WHERE obs.cd_ref in (
            SELECT * from atlas.find_all_taxons_childs(:thiscdref)
        )
        OR obs.cd_ref = :thiscdref
    ORDER BY com.commune_maj ASC
    """.encode('UTF-8')
    req = connection.execute(text(sql), thiscdref=cd_ref)
    listCommunes = list()
    for r in req:
        temp = {'insee': r.insee, 'commune_maj': r.commune_maj}
        listCommunes.append(temp)
    return listCommunes



#def infosCommune(connection, insee):
#    """
#        recherche les infos sur la commune
#    """
#    sql = """
#       WITH all_obs AS (
#        SELECT
#            extract(YEAR FROM o.dateobs) as annee, o.insee
#        FROM atlas.vm_observations o
#        WHERE o.insee = :thisInsee
#    )
#    SELECT  
#            min(annee) AS yearmin,
#            max(annee) AS yearmax,
#            e.nom_epci_simple, 
#            e.nom_epci
#    FROM all_obs ao 
#    JOIN atlas.l_communes_epci ec ON ao.insee = ec.insee
#    JOIN atlas.vm_epci e ON e.id = ec.id
#    GROUP BY  e.nom_epci_simple, e.nom_epci
#    """
#    req = connection.execute(text(sql), thisInsee=insee)
#    communeYearSearch = dict()
#    communeTerriSearch = dict()
#    for r in req:
#        communeYearSearch = {
#            'yearmin': r.yearmin,
#            'yearmax': r.yearmax
#        }
#        communeTerriSearch = {
#            'nom_epci_simple': r.nom_epci_simple,
#            'epciName': r.nom_epci
#        }
#    return {
#        'communeYearSearch': communeYearSearch,
#        'communeTerriSearch': communeTerriSearch
#    }


def infosCommune(connection, insee):
    """
        recherche les infos sur la commune
    """
    sql = """
    WITH all_obs AS (
        SELECT
            extract(YEAR FROM o.dateobs) as annee, o.insee
        FROM atlas.vm_observations o
        WHERE o.insee = :thisInsee
    )
    SELECT  
            min(annee) AS yearmin,
            max(annee) AS yearmax

    FROM all_obs ao 
    JOIN atlas.l_communes_epci ec ON ao.insee = ec.insee
    JOIN atlas.vm_epci e ON e.id = ec.id
    """
    req = connection.execute(text(sql), thisInsee=insee)
    communeYearSearch = dict()
    for r in req:
        communeYearSearch = {
            'yearmin': r.yearmin,
            'yearmax': r.yearmax
        }
    return {
        'communeYearSearch': communeYearSearch
    }



def epciCommune(connection, insee):
    """
        recherche l'epci de la commune
    """
    sql = """
        SELECT  
            e.nom_epci_simple, 
            e.nom_epci
        FROM atlas.vm_epci e
        JOIN atlas.l_communes_epci ec ON e.id = ec.id
        WHERE ec.insee =:thisInsee
    """
    req = connection.execute(text(sql), thisInsee=insee)

    for r in req:
        return {
            'nom_epci_simple': r.nom_epci_simple,
            'nom_epci': r.nom_epci
        }
