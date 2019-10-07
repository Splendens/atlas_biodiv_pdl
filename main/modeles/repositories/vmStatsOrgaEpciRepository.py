
# -*- coding:utf-8 -*-

from sqlalchemy.sql import text


def getStatsOrgaEpciChilds(connection, nom_epci_simple):
    sql = """
       
    SELECT 
    _03nbobs, _03nbtaxon, 
    _05nbobs, _05nbtaxon, 
    _06nbobs, _06nbtaxon, 
    _70nbobs, _70nbtaxon, 
    _81nbobs, _81nbtaxon, 
    _82nbobs, _82nbtaxon, 
    _83nbobs, _83nbtaxon, 
    _84nbobs, _84nbtaxon 

    FROM atlas.vm_stats_orga_epci orgas

    WHERE orgas.nom_epci_simple = :thisNomEpciSimple

    """.encode('UTF-8')

    mesOrgas = connection.execute(text(sql), thisNomEpciSimple=nom_epci_simple)
    for inter in mesOrgas:
        return [
            {'label': "Calluna (CBNB)", 'y': inter._06nbtaxon},
            {'label': "SICEN (CEN)", 'y': inter._03nbtaxon},
            {'label': "GRETIA", 'y': inter._05nbtaxon},
            {'label': "Kollect (URCPIE)", 'y': inter._70nbtaxon},
            {'label': "Faune Loire-Atlantique (LPO44, BV, GNLA)", 'y': inter._81nbtaxon},
            {'label': "Faune Anjou (LPO49)", 'y': inter._82nbtaxon},
            {'label': "Faune Vendée (LPO85)", 'y': inter._83nbtaxon},
            {'label': "Faune Maine (LPO72, MNE)", 'y': inter._84nbtaxon}
        ]

