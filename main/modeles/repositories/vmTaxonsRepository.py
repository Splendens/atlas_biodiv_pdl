
# -*- coding:utf-8 -*-

import unicodedata

from ...configuration import config
from sqlalchemy.sql import text
from .. import utils


def deleteAccent(string):
    return unicodedata.normalize('NFD', string).encode('ascii', 'ignore')


# With distinct the result in a array not an object, 0: lb_nom, 1: nom_vern
def getTaxonsCommunes(connection, insee):
    sql = """
        SELECT DISTINCT
            o.cd_ref, max(date_part('year'::text, o.dateobs)) as last_obs,
            COUNT(o.id_observation) AS nb_obs, t.nom_complet_html, t.nom_vern,
            t.group2_inpn, t.patrimonial, t.protection_stricte,
            m.url, m.chemin, m.id_media
        FROM atlas.vm_observations o
        JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
        LEFT JOIN atlas.vm_medias m ON m.cd_ref=o.cd_ref AND m.id_type={}
        WHERE o.insee = :thisInsee
        GROUP BY o.cd_ref, t.nom_vern, t.nom_complet_html, t.group2_inpn,
            t.patrimonial, t.protection_stricte, m.url, m.chemin, m.id_media
        ORDER BY group2_inpn, nom_complet_html ASC
    """.format(config.ATTR_MAIN_PHOTO)
    req = connection.execute(text(sql), thisInsee=insee)
    taxonCommunesList = list()
    nbObsTotal = 0
    for r in req:
        temp = {
            'nom_complet_html': r.nom_complet_html,
            'nb_obs': r.nb_obs,
            'nom_vern': r.nom_vern,
            'cd_ref': r.cd_ref,
            'last_obs': r.last_obs,
            'group2_inpn': deleteAccent(r.group2_inpn),
            'patrimonial': r.patrimonial,
            'protection_stricte': r.protection_stricte,
            'path': utils.findPath(r),
            'id_media': r.id_media
        }
        taxonCommunesList.append(temp)
        nbObsTotal = nbObsTotal + r.nb_obs
    return {'taxons': taxonCommunesList, 'nbObsTotal': nbObsTotal}



# With distinct the result in a array not an object, 0: lb_nom, 1: nom_vern
def getTaxonsEpci(connection, nom_epci_simple):
    sql = """
        with taxonepci AS (
            SELECT DISTINCT
                        o.cd_ref, max(date_part('year'::text, o.dateobs)) as last_obs,
                        COUNT(o.id_observation) AS nb_obs, t.nom_complet_html, t.nom_vern,
                        t.group2_inpn, t.patrimonial, t.protection_stricte, o.insee,
                        m.url, m.chemin, m.id_media
                    FROM atlas.vm_observations o
                    JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
                    JOIN atlas.l_communes_epci ec ON ec.insee = o.insee
                    JOIN atlas.vm_epci e ON ec.id = e.id
                    LEFT JOIN atlas.vm_medias m ON m.cd_ref=o.cd_ref AND id_type={}
                    WHERE e.nom_epci_simple = :thisNomEpciSimple
                    GROUP BY o.cd_ref, t.nom_vern, t.nom_complet_html, t.group2_inpn,
                        t.patrimonial, t.protection_stricte, o.insee, m.url, m.chemin, m.id_media
                    ORDER BY o.cd_ref DESC
            )
        select DISTINCT
                    cd_ref, max(last_obs) as last_obs,
                    SUM(nb_obs) AS nb_obs, nom_complet_html, nom_vern,
                    group2_inpn, patrimonial, protection_stricte,
                    url, chemin, id_media
                     from taxonepci
           GROUP BY cd_ref, nom_vern, nom_complet_html, group2_inpn,
                    patrimonial, protection_stricte, url, chemin, id_media
        ORDER BY group2_inpn, nom_complet_html ASC
    """.format(config.ATTR_MAIN_PHOTO)
    req = connection.execute(text(sql), thisNomEpciSimple=nom_epci_simple)
    taxonEpciList = list()
    nbObsTotal = 0
    for r in req:
        temp = {
            'nom_complet_html': r.nom_complet_html,
            'nb_obs': r.nb_obs,
            'nom_vern': r.nom_vern,
            'cd_ref': r.cd_ref,
            'last_obs': r.last_obs,
            'group2_inpn': deleteAccent(r.group2_inpn),
            'patrimonial': r.patrimonial,
            'protection_stricte': r.protection_stricte,
            'path': utils.findPath(r),
            'id_media': r.id_media
        }
        taxonEpciList.append(temp)
        nbObsTotal = nbObsTotal + r.nb_obs
    return {'taxons': taxonEpciList, 'nbObsTotal': nbObsTotal}



# With distinct the result in a array not an object, 0: lb_nom, 1: nom_vern
def getTaxonsDpt(connection, num_dpt):
    sql = """
        SELECT *
        FROM  atlas.vm_synthese_obs_taxons_dpt
        WHERE num_dpt = :thisNumdpt
        ORDER BY group2_inpn, nom_complet_html ASC
    """.format(config.ATTR_MAIN_PHOTO)
    req = connection.execute(text(sql), thisNumdpt=num_dpt)
    taxonDptList = list()
    nbObsTotal = 0
    for r in req:
        temp = {
            'nom_complet_html': r.nom_complet_html,
            'nb_obs': r.nb_obs,
            'nom_vern': r.nom_vern,
            'cd_ref': r.cd_ref,
            'last_obs': r.last_obs,
            'group2_inpn': deleteAccent(r.group2_inpn),
            'patrimonial': r.patrimonial,
            'protection_stricte': r.protection_stricte,
            'path': utils.findPath(r),
            'id_media': r.id_media
        }
        taxonDptList.append(temp)
        nbObsTotal = nbObsTotal + r.nb_obs
    return {'taxons': taxonDptList, 'nbObsTotal': nbObsTotal}





# With distinct the result in a array not an object, 0: lb_nom, 1: nom_vern
def getListeTaxonsCommunes(connection, insee):
    sql = """
        SELECT DISTINCT
            o.cd_ref, max(date_part('year'::text, o.dateobs)) as last_obs,
            COUNT(o.id_observation) AS nb_obs, replace(replace(t.nom_complet_html, '<i>', ''), '</i>', '') as nom_complet, t.nom_vern,
            t.group2_inpn, t.patrimonial, t.protection_stricte
        FROM atlas.vm_observations o
        JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
        WHERE o.insee = :thisInsee
        GROUP BY o.cd_ref, t.nom_vern, t.nom_complet_html, t.group2_inpn,
            t.patrimonial, t.protection_stricte
        ORDER BY group2_inpn, nom_complet ASC
    """
    req = connection.execute(text(sql), thisInsee=insee)
    taxonCommunesList = list()
    nbObsTotal = 0
    for r in req:
        temp = {
            'nom_complet': r.nom_complet,
            'nb_obs': r.nb_obs,
            'nom_vern': r.nom_vern,
            'cd_ref': r.cd_ref,
            'last_obs': r.last_obs,
            'group2_inpn': r.group2_inpn,
            'patrimonial': r.patrimonial,
            'protection_stricte': r.protection_stricte,
        }
        taxonCommunesList.append(temp)
        nbObsTotal = nbObsTotal + r.nb_obs
    return {'taxons': taxonCommunesList, 'nbObsTotal': nbObsTotal}



# With distinct the result in a array not an object, 0: lb_nom, 1: nom_vern
def getListeTaxonsEpci(connection, nom_epci_simple):
    sql = """
        with taxonepci AS (
            SELECT DISTINCT
                        o.cd_ref, max(date_part('year'::text, o.dateobs)) as last_obs,
                        COUNT(o.id_observation) AS nb_obs, t.nom_complet_html, t.nom_vern,
                        t.group2_inpn, t.patrimonial, t.protection_stricte, o.insee
                    FROM atlas.vm_observations o
                    JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
                    JOIN atlas.l_communes_epci ec ON ec.insee = o.insee
                    JOIN atlas.vm_epci e ON ec.id = e.id
                    WHERE e.nom_epci_simple = :thisNomEpciSimple
                    GROUP BY o.cd_ref, t.nom_vern, t.nom_complet_html, t.group2_inpn,
                        t.patrimonial, t.protection_stricte, o.insee
                    ORDER BY o.cd_ref DESC
            )
        select DISTINCT
                    cd_ref, max(last_obs) as last_obs,
                    SUM(nb_obs)::int AS nb_obs, replace(replace(nom_complet_html, '<i>', ''), '</i>', '') as nom_complet, nom_vern,
                    group2_inpn, patrimonial, protection_stricte
                    from taxonepci
           GROUP BY cd_ref, nom_vern, nom_complet, group2_inpn,
                    patrimonial, protection_stricte
        ORDER BY group2_inpn, nom_complet ASC
    """
    req = connection.execute(text(sql), thisNomEpciSimple=nom_epci_simple)
    taxonEpciList = list()
    nbObsTotal = 0
    for r in req:
        temp = {
            'nom_complet': r.nom_complet,
            'nb_obs': r.nb_obs,
            'nom_vern': r.nom_vern,
            'cd_ref': r.cd_ref,
            'last_obs': r.last_obs,
            'group2_inpn': r.group2_inpn,
            'patrimonial': r.patrimonial,
            'protection_stricte': r.protection_stricte
        }
        taxonEpciList.append(temp)
        nbObsTotal = nbObsTotal + r.nb_obs
    return {'taxons': taxonEpciList, 'nbObsTotal': nbObsTotal}


# With distinct the result in a array not an object, 0: lb_nom, 1: nom_vern
def getListeTaxonsDpt(connection, num_dpt):
    sql = """
        with taxondpt AS (
            SELECT DISTINCT
                        o.cd_ref, max(date_part('year'::text, o.dateobs)) as last_obs,
                        COUNT(o.id_observation) AS nb_obs, t.nom_complet_html, t.nom_vern,
                        t.group2_inpn, t.patrimonial, t.protection_stricte, o.insee
                    FROM atlas.vm_observations o
                    JOIN atlas.vm_taxons t ON t.cd_ref=o.cd_ref
                    WHERE left(o.insee,2)::int = :thisNumdpt
                    GROUP BY o.cd_ref, t.nom_vern, t.nom_complet_html, t.group2_inpn,
                        t.patrimonial, t.protection_stricte, o.insee
                    ORDER BY o.cd_ref DESC
            )
        select DISTINCT
                    cd_ref, max(last_obs) as last_obs,
                    SUM(nb_obs)::int AS nb_obs, replace(replace(nom_complet_html, '<i>', ''), '</i>', '') as nom_complet, nom_vern,
                    group2_inpn, patrimonial, protection_stricte
                     from taxondpt
           GROUP BY cd_ref, nom_vern, nom_complet, group2_inpn,
                    patrimonial, protection_stricte
        ORDER BY group2_inpn, nom_complet ASC
    """
    req = connection.execute(text(sql), thisNumdpt=num_dpt)
    taxonDptList = list()
    nbObsTotal = 0
    for r in req:
        temp = {
            'nom_complet': r.nom_complet,
            'nb_obs': r.nb_obs,
            'nom_vern': r.nom_vern,
            'cd_ref': r.cd_ref,
            'last_obs': r.last_obs,
            'group2_inpn': r.group2_inpn,
            'patrimonial': r.patrimonial,
            'protection_stricte': r.protection_stricte
        }
        taxonDptList.append(temp)
        nbObsTotal = nbObsTotal + r.nb_obs
    return {'taxons': taxonDptList, 'nbObsTotal': nbObsTotal}



def getTaxonsChildsList(connection, cd_ref):
    sql = """
        SELECT DISTINCT nom_complet_html, nb_obs, nom_vern, tax.cd_ref,
            yearmax, group2_inpn, patrimonial, protection_stricte,
            chemin, url, m.id_media
        FROM atlas.vm_taxons tax
        JOIN atlas.bib_taxref_rangs bib_rang
        ON trim(tax.id_rang)= trim(bib_rang.id_rang)
        LEFT JOIN atlas.vm_medias m
        ON m.cd_ref = tax.cd_ref AND m.id_type={}
        WHERE tax.cd_ref IN (
            SELECT * FROM atlas.find_all_taxons_childs(:thiscdref)
        ) """.format(str(config.ATTR_MAIN_PHOTO)).encode('UTF-8')
    req = connection.execute(text(sql), thiscdref=cd_ref)
    taxonRankList = list()
    nbObsTotal = 0
    for r in req:
        temp = {
            'nom_complet_html': r.nom_complet_html,
            'nb_obs': r.nb_obs,
            'nom_vern': r.nom_vern,
            'cd_ref': r.cd_ref,
            'last_obs': r.yearmax,
            'group2_inpn': deleteAccent(r.group2_inpn),
            'patrimonial': r.patrimonial,
            'protection_stricte': r.protection_stricte,
            'path': utils.findPath(r),
            'id_media': r.id_media
        }
        taxonRankList.append(temp)
        nbObsTotal = nbObsTotal + r.nb_obs
    return {'taxons': taxonRankList, 'nbObsTotal': nbObsTotal}


def getINPNgroupPhotos(connection):
    """
        Get list of INPN groups with at least one photo
    """

    sql = """
        SELECT DISTINCT count(*) AS nb_photos, group2_inpn
        FROM atlas.vm_taxons T
        JOIN atlas.vm_medias M on M.cd_ref = T.cd_ref
        GROUP BY group2_inpn
        ORDER BY nb_photos DESC
    """
    req = connection.execute(text(sql))
    groupList = list()
    for r in req:
        temp = {
            'group': utils.deleteAccent(r.group2_inpn),
            'groupAccent': r.group2_inpn
        }
        groupList.append(temp)
    return groupList


def getTaxonsGroup(connection, groupe):
    sql = """
        SELECT t.cd_ref, t.nom_complet_html, t.nom_vern, t.nb_obs,
            t.group2_inpn, t.protection_stricte, t.patrimonial, t.yearmax,
            m.chemin, m.url, m.id_media,
            t.nb_obs
        FROM atlas.vm_taxons t
        LEFT JOIN atlas.vm_medias m
        ON m.cd_ref = t.cd_ref AND m.id_type={}
        WHERE t.group2_inpn = :thisGroupe
        GROUP BY t.cd_ref, t.nom_complet_html, t.nom_vern, t.nb_obs,
            t.group2_inpn, t.protection_stricte, t.patrimonial, t.yearmax,
            m.chemin, m.url, m.id_media
        """.format(config.ATTR_MAIN_PHOTO)
    req = connection.execute(text(sql), thisGroupe=groupe)
    tabTaxons = list()
    nbObsTotal = 0
    for r in req:
        nbObsTotal = nbObsTotal+r.nb_obs
        temp = {
            'nom_complet_html': r.nom_complet_html,
            'nb_obs': r.nb_obs,
            'nom_vern': r.nom_vern,
            'cd_ref': r.cd_ref,
            'last_obs': r.yearmax,
            'group2_inpn': deleteAccent(r.group2_inpn),
            'patrimonial': r.patrimonial,
            'protection_stricte': r.protection_stricte,
            'id_media': r.id_media,
            'path': utils.findPath(r)
        }
        tabTaxons.append(temp)
    return {'taxons': tabTaxons, 'nbObsTotal': nbObsTotal}


# get all groupINPN
def getAllINPNgroup(connection):
    sql = """
        SELECT SUM(nb_obs) AS som_obs, group2_inpn
        FROM atlas.vm_taxons
        GROUP BY group2_inpn
        ORDER by som_obs DESC
    """
    req = connection.execute(text(sql))
    groupList = list()
    for r in req:
        temp = {
            'group': utils.deleteAccent(r.group2_inpn),
            'groupAccent': r.group2_inpn
        }
        groupList.append(temp)
    return groupList

