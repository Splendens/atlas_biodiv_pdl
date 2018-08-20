
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
      grouplist = []
      for inter in mesGroup:
            if inter.acanthocephales != 0:
                  grouplist.append({'label': "Acanthocéphales", 'value': inter.acanthocephales},)

            if inter.algues_brunes != 0:
                  grouplist.append({'label': "Algues brunes", 'value': inter.algues_brunes},)

            if inter.algues_rouges != 0:
                  grouplist.append({'label': "Algues rouges", 'value': inter.algues_rouges},)
                  
            if inter.algues_vertes != 0:
                  grouplist.append({'label': "Algues vertes", 'value': inter.algues_vertes},)

            if inter.amphibiens != 0:
                  grouplist.append({'label': "Amphibiens", 'value': inter.amphibiens},)
                  
            if inter.angiospermes != 0:
                  grouplist.append({'label': "Angiospermes", 'value': inter.angiospermes},)    
                  
            if inter.annelides != 0:
                  grouplist.append({'label': "Annélides", 'value': inter.annelides},)
                  
            if inter.arachnides != 0:
                  grouplist.append({'label': "Arachnides", 'value': inter.arachnides},)
                  
            if inter.ascidies != 0:
                  grouplist.append({'label': "Ascidies", 'value': inter.ascidies},)
                  
            if inter.autres != 0:
                  grouplist.append({'label': "Autres", 'value': inter.autres},)
                  
            if inter.bivalves != 0:
                  grouplist.append({'label': "Bivalves", 'value': inter.bivalves},)
                  
            if inter.cephalopodes != 0:
                  grouplist.append({'label': "Céphalopodes", 'value': inter.cephalopodes},)
                  
            if inter.crustaces != 0:
                  grouplist.append({'label': "Crustacés", 'value': inter.crustaces},)
                  
            if inter.diatomees != 0:
                  grouplist.append({'label': "Diatomées", 'value': inter.diatomees},)
                  
            if inter.entognathes != 0:
                  grouplist.append({'label': "Entognathes", 'value': inter.entognathes},)
                  
            if inter.fougeres != 0:
                  grouplist.append({'label': "Fougères", 'value': inter.fougeres},)
                  
            if inter.gasteropodes != 0:
                  grouplist.append({'label': "Gastéropodes", 'value': inter.gasteropodes},)
                  
            if inter.gymnospermes != 0:
                  grouplist.append({'label': "Gymnospermes", 'value': inter.gymnospermes},)
                  
            if inter.hepatiques_anthocerotes != 0:
                  grouplist.append({'label': "Hépatiques et Anthocérotes", 'value': inter.hepatiques_anthocerotes},)
                  
            if inter.hydrozoaires != 0:
                  grouplist.append({'label': "Hydrozoaires", 'value': inter.hydrozoaires},)
                  
            if inter.insectes != 0:
                  grouplist.append({'label': "Insectes", 'value': inter.insectes},)
                  
            if inter.lichens != 0:
                  grouplist.append({'label': "Lichens", 'value': inter.lichens},)
                  
            if inter.mammiferes != 0:
                  grouplist.append({'label': "Mammifères", 'value': inter.mammiferes},)
                  
            if inter.mousses != 0:
                  grouplist.append({'label': "Mousses", 'value': inter.mousses},)
                  
            if inter.myriapodes != 0:
                  grouplist.append({'label': "Myriapodes", 'value': inter.myriapodes},)
                  
            if inter.nematodes != 0:
                  grouplist.append({'label': "Nématodes", 'value': inter.nematodes},)
                  
            if inter.nemertes != 0:
                  grouplist.append({'label': "Némertes", 'value': inter.nemertes},)
                  
            if inter.octocoralliaires != 0:
                  grouplist.append({'label': "Octocoralliaires", 'value': inter.octocoralliaires},)
                  
            if inter.oiseaux != 0:
                  grouplist.append({'label': "Oiseaux", 'value': inter.oiseaux},)
                  
            if inter.plathelminthes != 0:
                  grouplist.append({'label': "Plathelminthes", 'value': inter.plathelminthes},)
                  
            if inter.poissons != 0:
                  grouplist.append({'label': "Poissons", 'value': inter.poissons},)
                  
            if inter.pycnogonides != 0:
                  grouplist.append({'label': "Pycnogonides", 'value': inter.pycnogonides},)
                  
            if inter.reptiles != 0:
                  grouplist.append({'label': "Reptiles", 'value': inter.reptiles},)
                  
            if inter.scleractiniaires != 0:
                  grouplist.append({'label': "Scléractiniaires", 'value': inter.scleractiniaires},)     

      return grouplist



