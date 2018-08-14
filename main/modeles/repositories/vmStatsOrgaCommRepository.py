
# -*- coding:utf-8 -*-

from sqlalchemy.sql import text


def getStatsOrgaCommChilds(connection, insee):
    sql = """
    WITH somme AS ( 
        
    SELECT _03, _05, _06, _70, _81, _82, _83, _84,
    (_03 + _05 + _06 + _70 + _81 + _82 + _83 + _84)::integer AS total 

    FROM atlas.vm_stats_orga_comm orgas
    WHERE orgas.insee = :thisinsee
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

    mesOrgas = connection.execute(text(sql), thisinsee=insee)
    for inter in mesOrgas:
        return [
            {'label': "CBN de Brest", 'value': inter._06},
            {'label': "CEN Pays de la Loire", 'value': inter._03},
            {'label': "GRETIA", 'value': inter._05},
            {'label': "URCPIE", 'value': inter._70},
            {'label': "LPO Anjou", 'value': inter._81},
            {'label': "LPO Loire-Atlantique", 'value': inter._82},
            {'label': "LPO Vendée", 'value': inter._83},
            {'label': "LPO Sarthe", 'value': inter._84}
        ]

