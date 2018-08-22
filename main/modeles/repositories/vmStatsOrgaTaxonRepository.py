
# -*- coding:utf-8 -*-

from sqlalchemy.sql import text



def getStatsOrgaTaxonChilds(connection, cd_ref):
    sql = """

        
    SELECT _03, _05, _06, _70, _81, _82, _83, _84

    FROM atlas.vm_stats_orga_taxon orgas
    
    WHERE orgas.cd_ref in (
            select * from atlas.find_all_taxons_childs(:thiscdref)
        )
        OR orgas.cd_ref = :thiscdref
        
    """.encode('UTF-8')

    mesOrgas = connection.execute(text(sql), thiscdref=cd_ref)
    for inter in mesOrgas:
        return [
            {'label': "CBN de Brest", 'y': inter._06},
            {'label': "CEN Pays de la Loire", 'y': inter._03},
            {'label': "GRETIA", 'y': inter._05},
            {'label': "URCPIE", 'y': inter._70},
            {'label': "Faune Anjou", 'y': inter._81},
            {'label': "Faune Loire-Atlantique", 'y': inter._82},
            {'label': "Faune Vendée", 'y': inter._83},
            {'label': "Faune Maine", 'y': inter._84}
        ]

