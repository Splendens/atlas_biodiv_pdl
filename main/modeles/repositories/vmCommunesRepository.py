
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
    sql = "SELECT c.commune_maj, \
           c.insee, \
           c.commune_geojson \
           FROM atlas.vm_communes c \
           WHERE c.insee = :thisInsee"
    req = connection.execute(text(sql), thisInsee=insee)
    communeObj = dict()
    for r in req:
        communeObj = {
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



def getNbTaxonsCommunes(connection, insee):
    sql = """
        SELECT COUNT(o.id_observation) AS nb_obs
        FROM atlas.vm_observations o
        WHERE o.insee = :thisInsee
    """
    req = connection.execute(text(sql), thisInsee=insee)
    nbTaxonCommunesList = list()
    for r in req:
        temp = {
            'nb_obs': r.nb_obs
        }
        nbTaxonCommunesList.append(temp)
        nb_obs = r.nb_obs
    return nb_obs    



def infosCommune(connection, insee):
    """
        recherche les infos sur la commune
    """
    sql = """
       WITH all_obs AS (
        SELECT
            extract(YEAR FROM o.dateobs) as annee
        FROM atlas.vm_observations o
        WHERE o.insee = :thisInsee
    )
    SELECT  
            min(annee) AS yearmin,
            max(annee) AS yearmax
    FROM all_obs
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

