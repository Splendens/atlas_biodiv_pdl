
# -*- coding:utf-8 -*-

from .. import utils
from sqlalchemy.sql import text
import ast


def getObservationsMaillesCommunalesChilds(connection, cd_ref):
    sql = """WITH obstax AS (
                select *
                from atlas.vm_observations
                where cd_ref in (
                        SELECT * FROM atlas.find_all_taxons_childs(:thiscdref)
                    )
                or obs.cd_ref = :thiscdref
        )
        SELECT
            obs.insee,
            c.commune_maj AS nom_com,
            obs.geojson_commune,
            a.nom_organisme AS orgaobs, 
            o.dateobs,
            extract(YEAR FROM o.dateobs) as annee
        FROM atlas.vm_observations_communes obs
        JOIN obstax o ON o.id_observation = obs.id_observation
        LEFT JOIN atlas.vm_organismes a ON a.id_organisme = o.id_organisme 
        LEFT JOIN atlas.vm_communes c ON c.insee = obs.insee
        ORDER BY insee"""
    observations = connection.execute(text(sql), thiscdref=cd_ref)
    tabObs = list()
    for o in observations:
        temp = {
            'id_maille': o.insee,
            'nom_com': o.nom_com,
            'nb_observations': 1,
            'annee': o.annee,
            'dateobs': str(o.dateobs),
            'orga_obs': o.orgaobs,
            'geojson_maille':  ast.literal_eval(o.geojson_commune)
        }
        tabObs.append(temp)
    return tabObs


def getpressionProspectionEpciMaillesCommunalesChilds(connection, nom_epci_simple):
    sql = """SELECT
            obs.insee,
            c.commune_maj AS nom_com,
            obs.geojson_commune,
            a.nom_organisme AS orgaobs, 
            o.dateobs,
            extract(YEAR FROM o.dateobs) as annee
        FROM atlas.vm_observations_communes obs
        JOIN atlas.vm_observations o ON o.id_observation = obs.id_observation
        JOIN atlas.l_communes_epci ec ON ec.insee = obs.insee
        JOIN atlas.vm_epci e ON ec.id = e.id
        LEFT JOIN atlas.vm_organismes a ON a.id_organisme = o.id_organisme 
        LEFT JOIN atlas.vm_communes c ON c.insee = obs.insee
        WHERE e.nom_epci_simple = :thisNomepcisimple
        ORDER BY insee"""
    observations = connection.execute(text(sql), thisNomepcisimple=nom_epci_simple)
    tabObs = list()
    for o in observations:
        temp = {
            'id_maille': o.insee,
            'nom_com': o.nom_com,
            'nb_observations': 1,
            'annee': o.annee,
            'dateobs': str(o.dateobs),
            'orga_obs': o.orgaobs,
            'geojson_maille':  ast.literal_eval(o.geojson_commune)
        }
        tabObs.append(temp)
    return tabObs



def getpressionProspectionDptMaillesCommunalesChilds(connection, num_dpt):
    sql = """SELECT
            obs.insee,
            c.commune_maj AS nom_com,
            obs.geojson_commune,
            a.nom_organisme AS orgaobs, 
            o.dateobs,
            extract(YEAR FROM o.dateobs) as annee
        FROM atlas.vm_observations_communes obs
        JOIN atlas.vm_observations o ON o.id_observation = obs.id_observation
        LEFT JOIN atlas.vm_organismes a ON a.id_organisme = o.id_organisme 
        LEFT JOIN atlas.vm_communes c ON c.insee = obs.insee
        WHERE left(obs.insee,2)::int = :thisNumdpt
        ORDER BY insee"""
    observations = connection.execute(text(sql), thisNumdpt=num_dpt)
    tabObs = list()
    for o in observations:
        temp = {
            'id_maille': o.insee,
            'nom_com': o.nom_com,
            'nb_observations': 1,
            'annee': o.annee,
            'dateobs': str(o.dateobs),
            'orga_obs': o.orgaobs,
            'geojson_maille':  ast.literal_eval(o.geojson_commune)
        }
        tabObs.append(temp)
    return tabObs








# last observation for index.html
#def lastObservationsCommunes(connection, mylimit, idPhoto):
#    sql = """
#        SELECT obs.*,
#        tax.lb_nom, tax.nom_vern, tax.group2_inpn,
#        o.dateobs, o.altitude_retenue,
#        medias.url, medias.chemin, medias.id_media
#        FROM atlas.vm_observations_mailles obs
#        JOIN atlas.vm_taxons tax ON tax.cd_ref = obs.cd_ref
#        JOIN atlas.vm_observations o ON o.id_observation=obs.id_observation
#        LEFT JOIN atlas.vm_medias medias
#            ON medias.cd_ref = obs.cd_ref AND medias.id_type = :thisID
#        WHERE  o.dateobs >= (CURRENT_TIMESTAMP - INTERVAL :thislimit)
#        ORDER BY o.dateobs DESC
#    """
#
#    observations = connection.execute(
#        text(sql),
#        thislimit=mylimit,
#        thisID=idPhoto
#    )
#    obsList = list()
#    for o in observations:
#        if o.nom_vern:
#            inter = o.nom_vern.split(',')
#            taxon = inter[0] + ' | ' + o.lb_nom
#        else:
#            taxon = o.lb_nom
#        temp = {
#            'id_observation': o.id_observation,
#            'id_maille': o.id_maille,
#            'cd_ref': o.cd_ref,
#            'dateobs': str(o.dateobs),
#            'altitude_retenue': o.altitude_retenue,
#            'taxon': taxon,
#            'geojson_maille': ast.literal_eval(o.geojson_maille),
#            'group2_inpn': utils.deleteAccent(o.group2_inpn),
#            'pathImg': utils.findPath(o),
#            'id_media': o.id_media
#        }
#        obsList.append(temp)
#    return obsList
