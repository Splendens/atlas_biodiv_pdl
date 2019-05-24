
# -*- coding:utf-8 -*-

from .. import utils
from ...configuration import config

from sqlalchemy.sql import text
import ast
from datetime import datetime

currentYear = datetime.now().year


def searchObservationsChilds(connection, cd_ref):
    sql = """SELECT obs.*,
            a.nom_organisme AS orgaobs
            FROM atlas.vm_observations obs
            LEFT JOIN atlas.vm_organismes a ON a.id_organisme = obs.id_organisme
            WHERE obs.cd_ref in (
                SELECT * FROM atlas.find_all_taxons_childs(:thiscdref)
                )
                OR obs.cd_ref = :thiscdref""".encode('UTF-8')

    observations = connection.execute(text(sql), thiscdref=cd_ref)
    obsList = list()
    for o in observations:
        temp = dict(o)
        temp.pop('the_geom_point', None)
        temp['geojson_point'] = ast.literal_eval(o.geojson_point)
        temp['dateobs'] = str(o.dateobs)
        temp['year'] = o.dateobs.year
        temp ['orga_obs'] = o.orgaobs
        obsList.append(temp)
    return obsList


def firstObservationChild(connection, cd_ref):
    sql = "SELECT min(taxons.yearmin) as yearmin \
    FROM atlas.vm_taxons taxons \
    JOIN atlas.vm_taxref taxref ON taxref.cd_ref=taxons.cd_ref \
    WHERE taxons.cd_ref in ( \
    SELECT * FROM atlas.find_all_taxons_childs(:thiscdref) \
    )OR taxons.cd_ref = :thiscdref".encode('UTF-8')
    req = connection.execute(text(sql), thiscdref=cd_ref)
    for r in req:
        return r.yearmin


def lastObservations(connection, mylimit, idPhoto):
    sql = """
    SELECT obs.*,
        COALESCE(split_part(tax.nom_vern, ',', 1) || ' | ', '')
            || tax.lb_nom as taxon,
        tax.group2_inpn,
        medias.url, medias.chemin, medias.id_media
    FROM atlas.vm_observations obs
    JOIN atlas.vm_taxons tax
        ON tax.cd_ref = obs.cd_ref
    LEFT JOIN atlas.vm_medias medias
        ON medias.cd_ref = obs.cd_ref AND medias.id_type = :thisidphoto
    WHERE  obs.dateobs >= (CURRENT_TIMESTAMP - INTERVAL :thislimit)
    ORDER BY obs.dateobs DESC """

    observations = connection.execute(
        text(sql),
        thislimit=mylimit,
        thisidphoto=idPhoto
    )

    obsList = list()
    for o in observations:
        temp = dict(o)
        temp.pop('the_geom_point', None)
        temp['geojson_point'] = ast.literal_eval(o.geojson_point)
        temp['dateobs'] = str(o.dateobs)
        temp['group2_inpn'] = utils.deleteAccent(o.group2_inpn)
        temp['pathImg'] = utils.findPath(o)
        obsList.append(temp)
    return obsList


def lastObservationsCommune(connection, mylimit, insee):
    sql = """SELECT o.*,
            a.nom_organisme AS orgaobs,
            COALESCE(split_part(tax.nom_vern, ',', 1) || ' | ', '')
                || tax.lb_nom as taxon
    FROM atlas.vm_observations o
    /*JOIN atlas.vm_communes c ON ST_Intersects(o.the_geom_point, c.the_geom)*/
    JOIN atlas.vm_communes c ON o.insee = c.insee
    JOIN atlas.vm_taxons tax ON  o.cd_ref = tax.cd_ref
    LEFT JOIN atlas.vm_organismes a ON a.id_organisme = o.id_organisme
    WHERE c.insee = :thisInsee
    ORDER BY o.dateobs DESC """
    observations = connection.execute(text(sql), thisInsee=insee)
    obsList = list()
    for o in observations:
        temp = dict(o)
        temp.pop('the_geom_point', None)
        temp['geojson_point'] = ast.literal_eval(o.geojson_point)
        temp['dateobs'] = str(o.dateobs)
        temp ['orga_obs'] = o.orgaobs
        obsList.append(temp)
    return obsList


def getObservationTaxonCommune(connection, insee, cd_ref):
    sql = """
        SELECT o.*,
            COALESCE(split_part(tax.nom_vern, ',', 1) || ' | ', '')
                || tax.lb_nom as taxon,
        o.observateurs
        FROM (
            SELECT * FROM atlas.vm_observations o
            WHERE o.insee = :thisInsee AND o.cd_ref = :thiscdref
        )  o
        JOIN (
            SELECT nom_vern, lb_nom, cd_ref
            FROM atlas.vm_taxons
            WHERE cd_ref = :thiscdref
        ) tax ON tax.cd_ref = tax.cd_ref
    """

    observations = connection.execute(
        text(sql),
        thiscdref=cd_ref,
        thisInsee=insee
    )
    obsList = list()
    for o in observations:
        temp = dict(o)
        temp.pop('the_geom_point', None)
        temp['geojson_point'] = ast.literal_eval(o.geojson_point)
        temp['dateobs'] = str(o.dateobs)
        obsList.append(temp)
    return obsList


def observersParser(req):
    setObs = set()
    tabObs = list()
    for r in req:
        if r.observateurs != None:
            tabObs = r.observateurs.replace(' & ',', ').split(', ')
        for o in tabObs:
            o = o.lower()
            setObs.add(o)
    finalList = list()
    for s in setObs:
        tabInter = s.split(' ')
        fullName = str()
        i = 0
        while i < len(tabInter):
            if i == len(tabInter)-1:
                fullName += tabInter[i].capitalize()
            else:
                fullName += tabInter[i].capitalize() + " "
            i = i+1
        finalList.append(fullName)
    return sorted(finalList)


def getObservers(connection, cd_ref):
    sql = """
    SELECT distinct observateurs
    FROM atlas.vm_observations
    WHERE cd_ref in (
            SELECT * FROM atlas.find_all_taxons_childs(:thiscdref)
        )
        OR cd_ref = :thiscdref
    """
    req = connection.execute(text(sql), thiscdref=cd_ref)
    return observersParser(req)


def getGroupeObservers(connection, groupe):
    sql = """
        SELECT distinct observateurs
        FROM atlas.vm_observations
        WHERE cd_ref in (
            SELECT cd_ref from atlas.vm_taxons WHERE group2_inpn = :thisgroupe
        )
    """
    req = connection.execute(text(sql), thisgroupe=groupe)
    return observersParser(req)


def getGroupeOrgas(connection, groupe):
    sql = """
        SELECT distinct a.nom_organisme AS orgaobs
        FROM atlas.vm_observations o
        LEFT JOIN atlas.vm_organismes a ON a.id_organisme = o.id_organisme
        WHERE cd_ref in (
            SELECT cd_ref from atlas.vm_taxons WHERE group2_inpn = :thisgroupe
        )
    """
    req = connection.execute(text(sql), thisgroupe=groupe)
    listOrgasGroupe = list()
    for r in req:
        temp = {'orga_obs': r.orgaobs}
        listOrgasGroupe.append(temp)
    return listOrgasGroupe


def getObserversCommunes(connection, insee):
    sql = """
        SELECT distinct observateurs
        FROM atlas.vm_observations
        WHERE insee = :thisInsee
    """
    req = connection.execute(text(sql), thisInsee=insee)
    return observersParser(req)


def statIndex(connection):
    result = {'nbTotalObs': None, 'nbTotalTaxons': None, 'town': None, 'epci': None, 'departement': None, 'photo': None}

    sql = "SELECT COUNT(*) AS count \
    FROM atlas.vm_observations "
    req = connection.execute(text(sql))
    for r in req:
        result['nbTotalObs'] = r.count

    sql = "SELECT COUNT(*) AS count\
    FROM atlas.vm_communes"
    req = connection.execute(text(sql))
    for r in req:
        result['town'] = r.count

    sql = "SELECT COUNT(*) AS count\
    FROM atlas.vm_epci"
    req = connection.execute(text(sql))
    for r in req:
        result['epci'] = r.count

    sql = "SELECT COUNT(*) AS count\
    FROM atlas.vm_departement"
    req = connection.execute(text(sql))
    for r in req:
        result['departement'] = r.count

    sql = "SELECT COUNT(DISTINCT cd_ref) AS count \
    FROM atlas.vm_taxons"
    connection.execute(text(sql))
    req = connection.execute(text(sql))
    for r in req:
        result['nbTotalTaxons'] = r.count

    sql = "SELECT COUNT (DISTINCT id_media) AS count \
    FROM atlas.vm_medias m \
    JOIN atlas.vm_taxons t ON t.cd_ref = m.cd_ref \
    WHERE id_type IN (:idType1, :id_type2)"
    req = connection.execute(
        text(sql),
        idType1=config.ATTR_MAIN_PHOTO,
        id_type2=config.ATTR_OTHER_PHOTO
    )
    for r in req:
        result['photo'] = r.count
    return result


def genericStat(connection, tab):
    tabStat = list()
    for pair in tab:
        rang, nomTaxon = pair.items()[0]
        sql = """
            SELECT COUNT (o.id_observation) AS nb_obs,
            COUNT (DISTINCT t.cd_ref) AS nb_taxons
            FROM atlas.vm_taxons t
            JOIN atlas.vm_observations o ON o.cd_ref = t.cd_ref
            WHERE t.{rang} IN :nomTaxon
        """.format(rang=rang)
        req = connection.execute(text(sql), nomTaxon=tuple(nomTaxon))
        for r in req:
            temp = {'nb_obs': r.nb_obs, 'nb_taxons': r.nb_taxons}
            tabStat.append(temp)
    return tabStat


def genericStatMedias(connection, tab):
    tabStat = list()
    for i in range(len(tab)):
        rang, nomTaxon = tab[i].items()[0]
        sql = """
            SELECT t.nb_obs, t.cd_ref, t.lb_nom, t.nom_vern, t.group2_inpn,
                m.url, m.chemin, m.auteur, m.id_media
            FROM atlas.vm_taxons t
            JOIN atlas.vm_medias m ON m.cd_ref = t.cd_ref AND m.id_type = 1
            WHERE t.{} IN :nomTaxon
            ORDER BY RANDOM()
            LIMIT 10
        """.format(rang)
        req = connection.execute(text(sql), nomTaxon=tuple(nomTaxon))
        tabStat.insert(i, list())
        for r in req:
            shorterName = None
            if r.nom_vern != None:
                shorterName = r.nom_vern.split(",")
                shorterName = shorterName[0]
            temp = {
                'cd_ref': r.cd_ref,
                'lb_nom': r.lb_nom,
                'nom_vern': shorterName,
                'path': utils.findPath(r),
                'author': r.auteur,
                'group2_inpn': utils.deleteAccent(r.group2_inpn),
                'nb_obs': r.nb_obs,
                'id_media': r.id_media
            }
            tabStat[i].append(temp)
    if len(tabStat[0]) == 0:
        return None
    else:
        return tabStat


def getOrgasObservations(connection, cd_ref):
    sql = "select distinct(a.nom_organisme) AS orgaobs \
        FROM  atlas.vm_observations o \
        JOIN atlas.vm_organismes a ON a.id_organisme = o.id_organisme \
        WHERE cd_ref in ( \
        SELECT * from atlas.find_all_taxons_childs(:thiscdref) \
        )OR cd_ref = :thiscdref \
        GROUP BY nom_organisme".encode('UTF-8')
    req = connection.execute(text(sql), thiscdref = cd_ref)
    listOrgas = list()
    for r in req:
        temp = {'orga_obs': r.orgaobs}
        listOrgas.append(temp)
    return listOrgas


def getOrgasCommunes(connection, insee):
    sql = "select distinct(a.nom_organisme) AS orgaobs \
        FROM  atlas.vm_observations o \
        JOIN atlas.vm_organismes a ON a.id_organisme = o.id_organisme \
        WHERE insee = :thisInsee  \
        GROUP BY nom_organisme".encode('UTF-8')
    req = connection.execute(text(sql), thisInsee = insee)
    listOrgasCom = list()
    for r in req:
        temp = {'orga_obs': r.orgaobs}
        listOrgasCom.append(temp)
    return listOrgasCom




def lastObservationsEpci(connection, mylimit, nom_epci_simple):
    sql = """SELECT o.*,
            a.nom_organisme AS orgaobs,
            COALESCE(split_part(tax.nom_vern, ',', 1) || ' | ', '')
                || tax.lb_nom as taxon
        FROM atlas.vm_observations o
        /*JOIN atlas.vm_communes c ON ST_Intersects(o.the_geom_point, c.the_geom)*/
        JOIN atlas.vm_communes c ON o.insee = c.insee
        JOIN atlas.vm_taxons tax ON  o.cd_ref = tax.cd_ref
        LEFT JOIN atlas.vm_organismes a ON a.id_organisme = o.id_organisme
        JOIN atlas.l_communes_epci ec ON ec.insee = o.insee
        JOIN atlas.vm_epci e ON ec.id = e.id
        WHERE e.nom_epci_simple = :thisNomEpciSimple
        ORDER BY o.dateobs DESC """
    observations = connection.execute(text(sql), thisNomEpciSimple=nom_epci_simple)
    obsList = list()
    for o in observations:
        temp = dict(o)
        temp.pop('the_geom_point', None)
        temp['geojson_point'] = ast.literal_eval(o.geojson_point)
        temp['dateobs'] = str(o.dateobs)
        temp ['orga_obs'] = o.orgaobs
        obsList.append(temp)
    return obsList


def getOrgasEpci(connection, nom_epci_simple):
    sql = "select distinct(a.nom_organisme) AS orgaobs \
        FROM  atlas.vm_observations o \
        JOIN atlas.vm_organismes a ON a.id_organisme = o.id_organisme \
        JOIN atlas.l_communes_epci ec ON ec.insee = o.insee \
        JOIN atlas.vm_epci e ON ec.id = e.id \
        WHERE e.nom_epci_simple = :thisNomEpciSimple  \
        GROUP BY nom_organisme".encode('UTF-8')
    req = connection.execute(text(sql), thisNomEpciSimple = nom_epci_simple)
    listOrgasCom = list()
    for r in req:
        temp = {'orga_obs': r.orgaobs}
        listOrgasCom.append(temp)
    return listOrgasCom



def getObserversEpci(connection, nom_epci_simple):
    sql = """
        SELECT distinct observateurs
        FROM atlas.vm_observations o
        JOIN atlas.l_communes_epci ec ON ec.insee = o.insee 
        JOIN atlas.vm_epci e ON ec.id = e.id 
        WHERE e.nom_epci_simple =  :thisNomEpciSimple
    """
    req = connection.execute(text(sql), thisNomEpciSimple=nom_epci_simple)
    return observersParser(req)






def lastObservationsDpt(connection, mylimit, num_dpt):
    sql = """SELECT o.*,
            a.nom_organisme AS orgaobs,
            COALESCE(split_part(tax.nom_vern, ',', 1) || ' | ', '')
                || tax.lb_nom as taxon
        FROM atlas.vm_observations o
        /*JOIN atlas.vm_communes c ON ST_Intersects(o.the_geom_point, c.the_geom)*/
        JOIN atlas.vm_communes c ON o.insee = c.insee
        JOIN atlas.vm_taxons tax ON  o.cd_ref = tax.cd_ref
        LEFT JOIN atlas.vm_organismes a ON a.id_organisme = o.id_organisme
        WHERE left(o.insee,2)::int = :thisNumdpt
        ORDER BY o.dateobs DESC """
    observations = connection.execute(text(sql), thisNumdpt=num_dpt)
    obsList = list()
    for o in observations:
        temp = dict(o)
        temp.pop('the_geom_point', None)
        temp['geojson_point'] = ast.literal_eval(o.geojson_point)
        temp['dateobs'] = str(o.dateobs)
        temp ['orga_obs'] = o.orgaobs
        obsList.append(temp)
    return obsList


def getOrgasDpt(connection, num_dpt):
    sql = "select distinct(a.nom_organisme) AS orgaobs \
        FROM  atlas.vm_observations o \
        JOIN atlas.vm_organismes a ON a.id_organisme = o.id_organisme \
        WHERE left(o.insee,2)::int = :thisNumdpt  \
        GROUP BY nom_organisme".encode('UTF-8')
    req = connection.execute(text(sql), thisNumdpt = num_dpt)
    listOrgasCom = list()
    for r in req:
        temp = {'orga_obs': r.orgaobs}
        listOrgasCom.append(temp)
    return listOrgasCom



def getObserversDpt(connection, num_dpt):
    sql = """
        SELECT distinct observateurs
        FROM atlas.vm_observations o 
        WHERE left(o.insee,2)::int = :thisNumdpt
    """
    req = connection.execute(text(sql), thisNumdpt=num_dpt)
    return observersParser(req)