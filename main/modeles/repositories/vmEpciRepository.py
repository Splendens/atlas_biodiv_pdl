
# -*- coding:utf-8 -*-

import ast
from ..entities.vmEpci import VmEpci
from sqlalchemy import distinct
from sqlalchemy.sql import text


def getAllEpci(session):
    req = session.query(distinct(VmEpci.nom_epci), VmEpci.nom_epci_simple).all()
    epciList = list()
    for r in req:
        temp = {'label': r[0], 'value': r[1]}
        epciList.append(temp)
    return epciList


def getEpciFromNomsimple(connection, nom_epci_simple):
    sql = "SELECT c.nom_epci, \
           c.nom_epci_simple, \
           c.epci_geojson \
           FROM atlas.vm_epci c \
           WHERE c.nom_epci_simple = :thisnomepcisimple"
    req = connection.execute(text(sql), thisnomepcisimple=nom_epci_simple)
    epciObj = dict()
    for r in req:
        epciObj = {
            'epciName': r.nom_epci,
            'nom_epci_simple': str(r.nom_epci_simple),
            'epciGeoJson': ast.literal_eval(r.epci_geojson)
        }
    return epciObj

    return req[0].nom_epci


def getDptFromEpci(connection, nom_epci_simple):
    sql = "SELECT distinct d.nom_dpt, \
           d.num_dpt \
           FROM atlas.vm_epci e \
           JOIN atlas.l_communes_epci ec ON e.id = ec.id \
           JOIN atlas.vm_departement d ON left(ec.insee,2)::int = d.num_dpt \
           WHERE e.nom_epci_simple = :thisnomepcisimple"
    req = connection.execute(text(sql), thisnomepcisimple=nom_epci_simple)
    epciObj = dict()
    for r in req:
        epciObj = {
            'dptName': r.nom_dpt,
            'num_dpt': r.num_dpt,
        }
    return epciObj



def getEpciObservationsChilds(connection, cd_ref):
    sql = """
    SELECT DISTINCT (e.nom_epci_simple) as nom_epci_simple,
     e.nom_epci,
     e.id
    FROM atlas.vm_epci e
    JOIN atlas.l_communes_epci ec ON ec.id = e.id
    JOIN atlas.vm_observations obs ON obs.insee = ec.insee

    WHERE obs.cd_ref in (
            SELECT * from atlas.find_all_taxons_childs(:thiscdref)
        )
        OR obs.cd_ref = :thiscdref
    ORDER BY e.nom_epci ASC
    """.encode('UTF-8')
    req = connection.execute(text(sql), thiscdref=cd_ref)
    listepci = list()
    for r in req:
        temp = {'id': r.id, 'nom_epci_simple': r.nom_epci_simple, 'nom_epci': r.nom_epci}
        listepci.append(temp)
    return listepci




def infosEpci(connection, nom_epci_simple):
    """
        recherche les infos sur l'epci
    """
    sql = """  
     WITH all_obs AS (
        SELECT
            extract(YEAR FROM o.dateobs) as annee
        FROM atlas.vm_observations o  
    JOIN atlas.l_communes_epci ec ON o.insee = ec.insee
        JOIN atlas.vm_epci e ON ec.id = e.id

    WHERE e.nom_epci_simple = :thisnomepcisimple
    )
    SELECT  
            min(annee) AS yearmin,
            max(annee) AS yearmax
    FROM all_obs
    """
    req = connection.execute(text(sql), thisnomepcisimple=nom_epci_simple)
    epciYearSearch = dict()
    for r in req:
        epciYearSearch = {
            'yearmin': r.yearmin,
            'yearmax': r.yearmax
        }
    return {
        'epciYearSearch': epciYearSearch
    }


def communesEpciChilds(connection, nom_epci_simple):
    """
        recherche les communes de l'epci
    """
    sql = """  
    SELECT c.commune_maj, c.insee, count(distinct o.cd_ref) AS nb_sp
    FROM atlas.vm_communes c  
        JOIN atlas.l_communes_epci ec ON c.insee = ec.insee
        JOIN atlas.vm_epci e ON ec.id = e.id
        LEFT JOIN atlas.vm_observations o ON o.insee = c.insee
    WHERE e.nom_epci_simple = :thisnomepcisimple
    GROUP BY c.commune_maj, c.insee
    ORDER BY c.commune_maj
    """
    req = connection.execute(text(sql), thisnomepcisimple=nom_epci_simple)
    communesEpciChilds = list()
    for r in req:
        temp = {
            'commune_maj': r.commune_maj,
            'insee': r.insee,
            'nb_sp': r.nb_sp
        }
        communesEpciChilds.append(temp)
    
    return {
        'communesEpciChilds': communesEpciChilds
    }

