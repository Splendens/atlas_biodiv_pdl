
# -*- coding:utf-8 -*-

from sqlalchemy.sql import text


def getStatsGroup2inpnCommChilds(connection, insee):
    sql = """
        WITH somme AS ( 
            
        SELECT          
             acanthocephales, 
             algues_brunes, 
             algues_rouges,
             algues_vertes,
             amphibiens,
             angiospermes,
             annelides, 
             arachnides,
             ascidies,
             autres, 
             bivalves,
             cephalopodes, 
             crustaces,
             diatomees,
             entognathes, 
             fougeres,
             gasteropodes, 
             gymnospermes,
             hepatiques_anthocerotes,
             hydrozoaires, 
             insectes,
             lichens, 
             mammiferes,
             mousses,
             myriapodes, 
             nematodes, 
             nemertes,
             octocoralliaires,
             oiseaux, 
             plathelminthes, 
             poissons,
             pycnogonides,
             reptiles, 
             scleractiniaires,
             (acanthocephales+ 
             algues_brunes+ 
             algues_rouges+
             algues_vertes+
             amphibiens+
             angiospermes+
             annelides+ 
             arachnides+
             ascidies+
             autres+ 
             bivalves+
             cephalopodes+ 
             crustaces+
             diatomees+
             entognathes+ 
             fougeres+
             gasteropodes+ 
             gymnospermes+
             hepatiques_anthocerotes+
             hydrozoaires+ 
             insectes+
             lichens+ 
             mammiferes+
             mousses+
             myriapodes+ 
             nematodes+ 
             nemertes+
             octocoralliaires+
             oiseaux+ 
             plathelminthes+ 
             poissons+
             pycnogonides+
             reptiles+ 
             scleractiniaires)::integer AS total

        FROM atlas.vm_stats_group2inpn_comm group2inpn
        WHERE group2inpn.insee = :thisinsee

        )

         SELECT   
            (acanthocephales*100/total) AS acanthocephales, 
            (algues_brunes*100/total) AS algues_brunes, 
            (algues_rouges*100/total) AS algues_rouges,
            (algues_vertes*100/total) AS algues_vertes,
            (amphibiens*100/total) AS amphibiens,
            (angiospermes*100/total) AS angiospermes,
            (annelides*100/total) AS annelides, 
            (arachnides*100/total) AS arachnides,
            (ascidies*100/total) AS ascidies,
            (autres*100/total) AS autres, 
            (bivalves*100/total) AS bivalves,
            (cephalopodes*100/total) AS cephalopodes, 
            (crustaces*100/total) AS crustaces,
            (diatomees*100/total) AS diatomees,
            (entognathes*100/total) AS entognathes, 
            (fougeres*100/total) AS fougeres,
            (gasteropodes*100/total) AS gasteropodes, 
            (gymnospermes*100/total) AS gymnospermes,
            (hepatiques_anthocerotes*100/total) AS hepatiques_anthocerotes,
            (hydrozoaires*100/total) AS hydrozoaires, 
            (insectes*100/total) AS insectes,
            (lichens*100/total) AS lichens, 
            (mammiferes*100/total) AS mammiferes,
            (mousses*100/total) AS mousses,
            (myriapodes*100/total) AS myriapodes, 
            (nematodes*100/total) AS nematodes, 
            (nemertes*100/total) AS nemertes,
            (octocoralliaires*100/total) AS octocoralliaires,
            (oiseaux*100/total) AS oiseaux, 
            (plathelminthes*100/total) AS plathelminthes, 
            (poissons*100/total) AS poissons,
            (pycnogonides*100/total) AS pycnogonides,
            (reptiles*100/total) AS reptiles, 
            (scleractiniaires*100/total) AS scleractiniaires

            FROM somme
        """.encode('UTF-8')

    mesGroup = connection.execute(text(sql), thisinsee=insee)
    for inter in mesGroup:
        return [
            {'label': "Acanthocéphales", 'value': inter.acanthocephales},
            {'label': "Algues brunes", 'value': inter.algues_brunes},
            {'label': "Algues rouges", 'value': inter.algues_rouges},
            {'label': "Algues vertes", 'value': inter.algues_vertes},
            {'label': "Amphibiens", 'value': inter.amphibiens},
            {'label': "Angiospermes", 'value': inter.angiospermes},
            {'label': "Annélides", 'value': inter.annelides},
            {'label': "Arachnides", 'value': inter.arachnides},
            {'label': "Ascidies", 'value': inter.ascidies},
            {'label': "Autres", 'value': inter.autres},
            {'label': "Bivalves", 'value': inter.bivalves},
            {'label': "Céphalopodes", 'value': inter.cephalopodes},
            {'label': "Crustacés", 'value': inter.crustaces},
            {'label': "Diatomées", 'value': inter.diatomees},
            {'label': "Entognathes", 'value': inter.entognathes},
            {'label': "Fougères", 'value': inter.fougeres},
            {'label': "Gastéropodes", 'value': inter.gasteropodes},
            {'label': "Gymnospermes", 'value': inter.gymnospermes},
            {'label': "Hépatiques et Anthocérotes", 'value': inter.hepatiques_anthocerotes},
            {'label': "Hydrozoaires", 'value': inter.hydrozoaires},
            {'label': "Insectes", 'value': inter.insectes},
            {'label': "Lichens", 'value': inter.lichens},
            {'label': "Mammifères", 'value': inter.mammiferes},
            {'label': "Mousses", 'value': inter.mousses},
            {'label': "Myriapodes", 'value': inter.myriapodes},
            {'label': "Nématodes", 'value': inter.nematodes},
            {'label': "Némertes", 'value': inter.nemertes},
            {'label': "Octocoralliaires", 'value': inter.octocoralliaires},
            {'label': "Oiseaux", 'value': inter.oiseaux},
            {'label': "Plathelminthes", 'value': inter.plathelminthes},
            {'label': "Poissons", 'value': inter.poissons},
            {'label': "Pycnogonides", 'value': inter.pycnogonides},
            {'label': "Reptiles", 'value': inter.reptiles},
            {'label': "Scléractiniaires", 'value': inter.scleractiniaires}
        ]

