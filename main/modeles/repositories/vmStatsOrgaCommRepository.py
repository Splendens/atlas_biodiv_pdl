
# -*- coding:utf-8 -*-

from sqlalchemy.sql import text


def getStatsOrgaCommChilds(connection, insee):
    sql = """
       
    SELECT _03, _05, _06, _70, _81, _82, _83, _84

    FROM atlas.vm_stats_orga_comm orgas

    WHERE orgas.insee = :thisinsee

    """.encode('UTF-8')

    mesOrgas = connection.execute(text(sql), thisinsee=insee)
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

