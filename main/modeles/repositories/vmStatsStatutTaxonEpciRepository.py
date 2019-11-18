
# -*- coding:utf-8 -*-

from sqlalchemy.sql import text


# get nombre taxons protégés et nombre taxons patrimoniaux par epci
def getNbTaxonsProPatriEpci(connection, nom_epci_simple):
    sql = """
    SELECT 
        nb_taxon_pro, 
        nb_taxon_patri
    FROM atlas.vm_stats_statut_taxon_epci a
    WHERE a.nom_epci_simple = :thisNomEpciSimple
    """.encode('UTF-8')
    req = connection.execute(text(sql), thisNomEpciSimple=nom_epci_simple)
    taxonProPatri = dict()
    for r in req:
        taxonProPatri = {
            'nbTaxonPro': r.nb_taxon_pro,
            'nbTaxonPatri' :r.nb_taxon_patri
            }
    return taxonProPatri
    




# get stats sur les statuts des taxons par epci
def getStatsStatutsTaxonsEpci(connection, nom_epci_simple):
    sql = """
        SELECT 
        nb_taxon_que_pro, 
        nb_taxon_que_patri, 
        nb_taxon_pro_et_patri, 
        nb_taxon_sans_statut
        FROM atlas.vm_stats_statut_taxon_epci a
        WHERE a.nom_epci_simple = :thisNomEpciSimple
    """.encode('UTF-8')

    mesStatutsTaxons = connection.execute(text(sql), thisNomEpciSimple=nom_epci_simple)
    for inter in mesStatutsTaxons:
        return [
            {'label': "Taxons protégés", 'y': inter.nb_taxon_que_pro},
            {'label': "Taxons patrimoniaux", 'y': inter.nb_taxon_que_patri},
            {'label': "Taxons protégés et patrimoniaux", 'y': inter.nb_taxon_pro_et_patri},
            {'label': "Autres taxons", 'y': inter.nb_taxon_sans_statut},
       ]

