
# -*- coding:utf-8 -*-

from sqlalchemy.sql import text



def getStatsOrgaTaxonChilds(connection, cd_ref):
    sql = """
    SELECT
        SUM(_03) as _03, 
        SUM(_05) as _05,
        SUM(_06) as _06, 
        SUM(_70) as _70,
        SUM(_81) as _81, 
        SUM(_82) as _82,
        SUM(_83) as _83, 
        SUM(_84) as _84
    FROM atlas.vm_stats_orga_taxon orgas
    WHERE orgas.cd_ref in (
            select * from atlas.find_all_taxons_childs(:thiscdref)
        )
        OR orgas.cd_ref = :thiscdref
    """.encode('UTF-8')

    mesOrgas = connection.execute(text(sql), thiscdref=cd_ref)
    for inter in mesOrgas:
        return [
            {'orgas': "CBN de Brest", 'value': inter._06},
            {'orgas': "CEN Pays de la Loire", 'value': inter._03},
            {'orgas': "GRETIA", 'value': inter._05},
            {'orgas': "URCPIE", 'value': inter._70},
            {'orgas': "LPO Anjou", 'value': inter._81},
            {'orgas': "LPO Loire-Atlantique", 'value': inter._82},
            {'orgas': "LPO Vendée", 'value': inter._83},
            {'orgas': "LPO Sarthe", 'value': inter._84}
        ]

