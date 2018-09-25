
# -*- coding:utf-8 -*-

from sqlalchemy.sql import text


def getStatsOrgaCommChilds(connection, insee):
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

    FROM atlas.vm_stats_orga_comm orgas

    WHERE orgas.insee = :thisinsee

    """.encode('UTF-8')

    mesOrgas = connection.execute(text(sql), thisinsee=insee)
    for inter in mesOrgas:
        return [
            {'label': "Calluna (CBNB)", 'y': inter._06nbtaxon},
            {'label': "SICEN (CEN)", 'y': inter._03nbtaxon},
            {'label': "GRETIA", 'y': inter._05nbtaxon},
            {'label': "URCPIE", 'y': inter._70nbtaxon},
            {'label': "Faune Anjou (LPO49)", 'y': inter._81nbtaxon},
            {'label': "Faune Loire-Atlantique (LPO44, BV, GNLA)", 'y': inter._82nbtaxon},
            {'label': "Faune Vendée (LPO85)", 'y': inter._83nbtaxon},
            {'label': "Faune Maine (LPO72, MNE)", 'y': inter._84nbtaxon}
        ]



def getStatsOrgaEpciChilds(connection, nom_epci_simple):
    sql = """
       
    SELECT 
        sum(_03nbobs) AS _03nbobs,  sum(_03nbtaxon) AS _03nbtaxon, 
        sum(_05nbobs) AS _05nbobs,  sum(_05nbtaxon) AS _05nbtaxon, 
        sum(_06nbobs) AS _06nbobs,  sum(_06nbtaxon) AS _06nbtaxon, 
        sum(_70nbobs) aS _70nbobs,  sum(_70nbtaxon) AS _70nbtaxon, 
        sum(_81nbobs) AS _81nbobs,  sum(_81nbtaxon) AS _81nbtaxon, 
        sum(_82nbobs) AS _82nbobs,  sum(_82nbtaxon) AS _82nbtaxon, 
        sum(_83nbobs) AS _83nbobs,  sum(_83nbtaxon) AS _83nbtaxon, 
        sum(_84nbobs) AS _84nbobs,  sum(_84nbtaxon) AS _84nbtaxon 

    FROM atlas.vm_stats_orga_comm o
    JOIN atlas.l_communes_epci ec ON ec.insee = o.insee
    JOIN atlas.vm_epci e ON ec.id = e.id

    WHERE e.nom_epci_simple = :thisnomepcisimple

    """.encode('UTF-8')

    mesOrgas = connection.execute(text(sql), thisnomepcisimple=nom_epci_simple)
    for inter in mesOrgas:
        return [
            {'label': "Calluna (CBNB)", 'y': inter._06nbtaxon},
            {'label': "SICEN (CEN)", 'y': inter._03nbtaxon},
            {'label': "GRETIA", 'y': inter._05nbtaxon},
            {'label': "URCPIE", 'y': inter._70nbtaxon},
            {'label': "Faune Anjou (LPO49)", 'y': inter._81nbtaxon},
            {'label': "Faune Loire-Atlantique (LPO44, BV, GNLA)", 'y': inter._82nbtaxon},
            {'label': "Faune Vendée (LPO85)", 'y': inter._83nbtaxon},
            {'label': "Faune Maine (LPO72, MNE)", 'y': inter._84nbtaxon}
        ]
