
# -*- coding:utf-8 -*-

import ast
from ..entities.vmDepartement import VmDepartement
from sqlalchemy import distinct
from sqlalchemy.sql import text


def getAllDepartement(session):
    req = session.query(distinct(VmDepartement.nom_dpt), VmDepartement.num_dpt).all()
    dptList = list()
    for r in req:
        temp = {'label': r[0], 'value': r[1]}
        dptList.append(temp)
    return dptList


def getDepartementFromNumdpt(connection, num_dpt):
    sql = "SELECT d.num_dpt, \
           d.nom_dpt, \
           d.dpt_geojson \
           FROM atlas.vm_departement d \
           WHERE d.num_dpt = :thisNumdpt"
    req = connection.execute(text(sql), thisNumdpt=num_dpt)
    dptObj = dict()
    for r in req:
        dptObj = {
            'dptName': r.nom_dpt,
            'num_dpt': str(r.num_dpt),
            'dptGeoJson': ast.literal_eval(r.dpt_geojson)
        }
    return dptObj

    return req[0].nom_dpt


def getDptObservationsChilds(connection, cd_ref):
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
        temp = {'id': r.id, 'num_dpt': r.num_dpt, 'nom_dpt': r.nom_dpt}
        listepci.append(temp)
    return listepci




def infosDpt(connection, num_dpt):
    """
        recherche les infos sur l'epci
    """
    sql = """  
     WITH all_obs AS (
        SELECT
            extract(YEAR FROM o.dateobs) as annee
        FROM atlas.vm_observations o  
        WHERE left(o.insee,2)::int = :thisNumdpt

    )
    SELECT  
            min(annee) AS yearmin,
            max(annee) AS yearmax
    FROM all_obs
    """
    req = connection.execute(text(sql), thisNumdpt=num_dpt)
    dptYearSearch = dict()
    for r in req:
        dptYearSearch = {
            'yearmin': r.yearmin,
            'yearmax': r.yearmax
        }
    return {
        'dptYearSearch': dptYearSearch
    }


def communesDptChilds(connection, num_dpt):
    """
        recherche les communes de l'epci
    """
    sql = """  
    SELECT c.commune_maj, c.insee, count(distinct o.cd_ref) AS nb_sp
    FROM atlas.vm_communes c  
        JOIN atlas.vm_departement e ON e.num_dpt = left(c.insee,2)::int
        LEFT JOIN atlas.vm_observations o ON o.insee = c.insee
    WHERE e.num_dpt = :thisNumdpt
    GROUP BY c.commune_maj, c.insee
    ORDER BY c.commune_maj
    """
    req = connection.execute(text(sql), thisNumdpt=num_dpt)
    communesDptChilds = list()
    for r in req:
        temp = {
            'commune_maj': r.commune_maj,
            'insee': r.insee,
            'nb_sp': r.nb_sp
        }
        communesDptChilds.append(temp)
    
    return {
        'communesDptChilds': communesDptChilds
    }


def epciDptChilds(connection, num_dpt):
    """
        recherche les communes du departement
    """
    sql = """  
    SELECT  
        e.nom_epci_simple, 
        e.nom_epci, 
        count(distinct ec.insee) AS nb_comm,
        count(distinct o.cd_ref) AS nb_sp
    FROM atlas.vm_epci e
        JOIN atlas.l_communes_epci ec ON e.id = ec.id
        JOIN atlas.vm_communes c ON c.insee = ec.insee
        LEFT JOIN atlas.vm_observations o ON o.insee = c.insee
    WHERE left(ec.insee,2)::int = :thisNumdpt
    GROUP BY e.nom_epci_simple, e.nom_epci, left(ec.insee,2)
    ORDER BY e.nom_epci

    """
    req = connection.execute(text(sql), thisNumdpt=num_dpt)
    epciDptChilds = list()
    for r in req:
        temp = {
            'nom_epci_simple': r.nom_epci_simple,
            'nom_epci': r.nom_epci,
            'nb_sp': r.nb_sp,
            'nb_comm': r.nb_comm
        }
        epciDptChilds.append(temp)
    
    return {
        'epciDptChilds': epciDptChilds
    }

