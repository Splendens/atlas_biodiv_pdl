
# -*- coding:utf-8 -*-

from sqlalchemy.sql import text



def getStatsOrgaTaxonChilds(connection, cd_ref):
    sql = """

    WITH somme AS ( 
        
    SELECT _03, _05, _06, _70, _81, _82, _83, _84,
    (_03 + _05 + _06 + _70 + _81 + _82 + _83 + _84)::integer AS total 

    FROM atlas.vm_stats_orga_taxon orgas
    WHERE orgas.cd_ref in (
            select * from atlas.find_all_taxons_childs(:thiscdref)
        )
        OR orgas.cd_ref = :thiscdref
    )

   SELECT   
        (_03*100/total) AS _03,
        (_05*100/total) AS _05,
        (_06*100/total) AS _06,
        (_70*100/total) AS _70,
        (_81*100/total) AS _81,
        (_82*100/total) AS _82,
        (_83*100/total) AS _83,
        (_84*100/total) AS _84
        from somme
        
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

