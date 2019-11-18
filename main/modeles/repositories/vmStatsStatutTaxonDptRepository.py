
# -*- coding:utf-8 -*-

from sqlalchemy.sql import text


# get nombre taxons protégés et nombre taxons patrimoniaux par departement
def getNbTaxonsProPatriDpt(connection, num_dpt):
    sql = """
    SELECT 
        nb_taxon_pro, 
        nb_taxon_patri
    FROM atlas.vm_stats_statut_taxon_dpt a
    WHERE a.num_dpt = :thisNumdpt
    """.encode('UTF-8')
    req = connection.execute(text(sql), thisNumdpt=num_dpt)
    taxonProPatri = dict()
    for r in req:
        taxonProPatri = {
            'nbTaxonPro': r.nb_taxon_pro,
            'nbTaxonPatri' :r.nb_taxon_patri
            }
    return taxonProPatri





# get stats sur les statuts des taxons par departement
def getStatsStatutsTaxonsDpt(connection, num_dpt):
    sql = """
        SELECT 
        nb_taxon_que_pro, 
        nb_taxon_que_patri, 
        nb_taxon_pro_et_patri, 
        nb_taxon_sans_statut
        FROM atlas.vm_stats_statut_taxon_dpt a
        WHERE a.num_dpt = :thisNumdpt
    """.encode('UTF-8')

    mesStatutsTaxons = connection.execute(text(sql), thisNumdpt=num_dpt)
    for inter in mesStatutsTaxons:
        return [
            {'label': "Taxons protégés", 'y': inter.nb_taxon_que_pro},
            {'label': "Taxons patrimoniaux", 'y': inter.nb_taxon_que_patri},
            {'label': "Taxons protégés et patrimoniaux", 'y': inter.nb_taxon_pro_et_patri},
            {'label': "Autres taxons", 'y': inter.nb_taxon_sans_statut},
       ]


