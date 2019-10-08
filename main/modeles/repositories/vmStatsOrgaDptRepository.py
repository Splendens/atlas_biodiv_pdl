
# -*- coding:utf-8 -*-

from sqlalchemy.sql import text


def getStatsOrgaTaxonDptChilds(connection, num_dpt):
    sql = """
       
    SELECT 
    _03nbtaxon, 
    _05nbtaxon, 
    _06nbtaxon, 
    _70nbtaxon, 
    _81nbtaxon, 
    _82nbtaxon, 
    _83nbtaxon, 
    _84nbtaxon 

    FROM atlas.vm_stats_orga_dpt orgas

    WHERE orgas.num_dpt::int = :thisNumdpt

    """.encode('UTF-8')

    mesOrgas = connection.execute(text(sql), thisNumdpt=num_dpt)
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


def getStatsOrgaDataDptChilds(connection, num_dpt):
    sql = """
       
    SELECT 
    _03nbobs, 
    _05nbobs, 
    _06nbobs, 
    _70nbobs, 
    _81nbobs, 
    _82nbobs, 
    _83nbobs, 
    _84nbobs 

    FROM atlas.vm_stats_orga_dpt orgas

    WHERE orgas.num_dpt::int = :thisNumdpt

    """.encode('UTF-8')

    mesOrgas = connection.execute(text(sql), thisNumdpt=num_dpt)
    for inter in mesOrgas:
        return [
            {'label': "Calluna (CBNB)", 'y': inter._06nbobs},
            {'label': "SICEN (CEN)", 'y': inter._03nbobs},
            {'label': "GRETIA", 'y': inter._05nbobs},
            {'label': "Kollect (URCPIE)", 'y': inter._70nbobs},
            {'label': "Faune Loire-Atlantique (LPO44, BV, GNLA)", 'y': inter._81nbobs},
            {'label': "Faune Anjou (LPO49)", 'y': inter._82nbobs},
            {'label': "Faune Vendée (LPO85)", 'y': inter._83nbobs},
            {'label': "Faune Maine (LPO72, MNE)", 'y': inter._84nbobs}
        ]

