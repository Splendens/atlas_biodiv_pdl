
# -*- coding:utf-8 -*-

from sqlalchemy.sql import text



def getStatsOrgaTaxonChilds(connection, cd_ref):
    sql = """

        
    SELECT 
        SUM(_03) AS _03, 
        SUM(_05) AS _05, 
        SUM(_06) AS _06, 
        SUM(_70) AS _70, 
        SUM(_81) AS _81, 
        SUM(_82) AS _82, 
        SUM(_83) AS _83, 
        SUM(_84) AS _84

    FROM atlas.vm_stats_orga_taxon orgas
    
    WHERE orgas.cd_ref in (
            select * from atlas.find_all_taxons_childs(:thiscdref)
        )
        OR orgas.cd_ref = :thiscdref
        
    """.encode('UTF-8')

    mesOrgas = connection.execute(text(sql), thiscdref=cd_ref)
    for inter in mesOrgas:
        return [
            {'label': "Calluna (CBNB)", 'y': inter._06},
            {'label': "SICEN (CEN)", 'y': inter._03},
            {'label': "GRETIA", 'y': inter._05},
            {'label': "URCPIE", 'y': inter._70},
            {'label': "Faune Anjou (LPO49)", 'y': inter._81},
            {'label': "Faune Loire-Atlantique (LPO44, BV, GNLA)", 'y': inter._82},
            {'label': "Faune Vendée (LPO85)", 'y': inter._83},
            {'label': "Faune Maine (LPO72, MNE)", 'y': inter._84}
        ]

