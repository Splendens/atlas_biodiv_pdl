
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


def getDepartementFromNumdpt(connection, thisnumdpt):
    sql = "SELECT d.num_dpt, \
           d.nom_dpt, \
           d.dpt_geojson \
           FROM atlas.vm_departement d \
           WHERE d.num_dpt = :thisnumdpt"
    req = connection.execute(text(sql), thisnumdpt=num_dpt)
    dptObj = dict()
    for r in req:
        dptObj = {
            'dptName': r.nom_dpt,
            'num_dpt': str(r.num_dpt),
            'dptGeoJson': ast.literal_eval(r.dpt_geojson)
        }
    return dptObj

    return req[0].nom_dpt


#def getDepartementObservationsChilds(connection, cd_ref):
#    sql = """
#    SELECT DISTINCT (e.num_dpt) as num_dpt,
#     e.nom_,
#     e.id
#    FROM atlas.vm_epci e
#    JOIN atlas.l_communes_epci ec ON ec.id = e.id
#    JOIN atlas.vm_observations obs ON obs.insee = ec.insee
#
#    WHERE obs.cd_ref in (
#            SELECT * from atlas.find_all_taxons_childs(:thiscdref)
#        )
#        OR obs.cd_ref = :thiscdref
#    ORDER BY e.nom_epci ASC
#    """.encode('UTF-8')
#    req = connection.execute(text(sql), thiscdref=cd_ref)
#    listepci = list()
#    for r in req:
#        temp = {'id': r.id, 'nom_epci_simple': r.nom_epci_simple, 'nom_epci': r.nom_epci}
#        listepci.append(temp)
#    return listepci
#
#
#def infosDepartement(connection, insee):
#    """
#        recherche les infos sur l'epci
#    """
#    sql = """  
#     WITH all_obs AS (
#        SELECT
#            extract(YEAR FROM o.dateobs) as annee
#        FROM atlas.vm_observations o  
#    JOIN atlas.l_communes_epci ec ON o.insee = ec.insee
#        JOIN atlas.vm_epci e ON ec.id = e.id
#
#    WHERE e.nom_epci_simple = :thisnomepcisimple
#    )
#    SELECT  
#            min(annee) AS yearmin,
#            max(annee) AS yearmax
#    FROM all_obs
#    """
#    req = connection.execute(text(sql), thisnomepcisimple=nom_epci_simple)
#    epciYearSearch = dict()
#    for r in req:
#        epciYearSearch = {
#            'yearmin': r.yearmin,
#            'yearmax': r.yearmax
#        }
#    return {
#        'epciYearSearch': epciYearSearch
#    }
#