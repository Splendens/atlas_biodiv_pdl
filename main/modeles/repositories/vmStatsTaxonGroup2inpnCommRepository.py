
# -*- coding:utf-8 -*-

from sqlalchemy.sql import text


def getStatsTaxonGroup2inpnCommChilds(connection, insee):
      sql = """
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
            scleractiniaires

            FROM atlas.vm_stats_espece_group2inpn_comm group2inpn
            WHERE group2inpn.insee = :thisinsee
        """.encode('UTF-8')

      mesGroup = connection.execute(text(sql), thisinsee=insee)
      grouplist = []
      for inter in mesGroup:
            if inter.acanthocephales != 0:
                  grouplist.append({'label': "Acanthocéphales", 'y': inter.acanthocephales},)

            if inter.algues_brunes != 0:
                  grouplist.append({'label': "Algues brunes", 'y': inter.algues_brunes},)

            if inter.algues_rouges != 0:
                  grouplist.append({'label': "Algues rouges", 'y': inter.algues_rouges},)
                  
            if inter.algues_vertes != 0:
                  grouplist.append({'label': "Algues vertes", 'y': inter.algues_vertes},)

            if inter.amphibiens != 0:
                  grouplist.append({'label': "Amphibiens", 'y': inter.amphibiens},)
                  
            if inter.angiospermes != 0:
                  grouplist.append({'label': "Angiospermes", 'y': inter.angiospermes},)    
                  
            if inter.annelides != 0:
                  grouplist.append({'label': "Annélides", 'y': inter.annelides},)
                  
            if inter.arachnides != 0:
                  grouplist.append({'label': "Arachnides", 'y': inter.arachnides},)
                  
            if inter.ascidies != 0:
                  grouplist.append({'label': "Ascidies", 'y': inter.ascidies},)
                  
            if inter.autres != 0:
                  grouplist.append({'label': "Autres", 'y': inter.autres},)
                  
            if inter.bivalves != 0:
                  grouplist.append({'label': "Bivalves", 'y': inter.bivalves},)
                  
            if inter.cephalopodes != 0:
                  grouplist.append({'label': "Céphalopodes", 'y': inter.cephalopodes},)
                  
            if inter.crustaces != 0:
                  grouplist.append({'label': "Crustacés", 'y': inter.crustaces},)
                  
            if inter.diatomees != 0:
                  grouplist.append({'label': "Diatomées", 'y': inter.diatomees},)
                  
            if inter.entognathes != 0:
                  grouplist.append({'label': "Entognathes", 'y': inter.entognathes},)
                  
            if inter.fougeres != 0:
                  grouplist.append({'label': "Fougères", 'y': inter.fougeres},)
                  
            if inter.gasteropodes != 0:
                  grouplist.append({'label': "Gastéropodes", 'y': inter.gasteropodes},)
                  
            if inter.gymnospermes != 0:
                  grouplist.append({'label': "Gymnospermes", 'y': inter.gymnospermes},)
                  
            if inter.hepatiques_anthocerotes != 0:
                  grouplist.append({'label': "Hépatiques et Anthocérotes", 'y': inter.hepatiques_anthocerotes},)
                  
            if inter.hydrozoaires != 0:
                  grouplist.append({'label': "Hydrozoaires", 'y': inter.hydrozoaires},)
                  
            if inter.insectes != 0:
                  grouplist.append({'label': "Insectes", 'y': inter.insectes},)
                  
            if inter.lichens != 0:
                  grouplist.append({'label': "Lichens", 'y': inter.lichens},)
                  
            if inter.mammiferes != 0:
                  grouplist.append({'label': "Mammifères", 'y': inter.mammiferes},)
                  
            if inter.mousses != 0:
                  grouplist.append({'label': "Mousses", 'y': inter.mousses},)
                  
            if inter.myriapodes != 0:
                  grouplist.append({'label': "Myriapodes", 'y': inter.myriapodes},)
                  
            if inter.nematodes != 0:
                  grouplist.append({'label': "Nématodes", 'y': inter.nematodes},)
                  
            if inter.nemertes != 0:
                  grouplist.append({'label': "Némertes", 'y': inter.nemertes},)
                  
            if inter.octocoralliaires != 0:
                  grouplist.append({'label': "Octocoralliaires", 'y': inter.octocoralliaires},)
                  
            if inter.oiseaux != 0:
                  grouplist.append({'label': "Oiseaux", 'y': inter.oiseaux},)
                  
            if inter.plathelminthes != 0:
                  grouplist.append({'label': "Plathelminthes", 'y': inter.plathelminthes},)
                  
            if inter.poissons != 0:
                  grouplist.append({'label': "Poissons", 'y': inter.poissons},)
                  
            if inter.pycnogonides != 0:
                  grouplist.append({'label': "Pycnogonides", 'y': inter.pycnogonides},)
                  
            if inter.reptiles != 0:
                  grouplist.append({'label': "Reptiles", 'y': inter.reptiles},)
                  
            if inter.scleractiniaires != 0:
                  grouplist.append({'label': "Scléractiniaires", 'y': inter.scleractiniaires},)     

      return grouplist





def getStatsTaxonGroup2inpnEpciChilds(connection, nom_epci_simple):
      sql = """
         SELECT   
            SUM(acanthocephales) AS acanthocephales, 
            SUM(algues_brunes) AS algues_brunes, 
            SUM(algues_rouges) AS algues_rouges,
            SUM(algues_vertes) AS algues_vertes,
            SUM(amphibiens) AS amphibiens,
            SUM(angiospermes) AS angiospermes,
            SUM(annelides) AS annelides, 
            SUM(arachnides) AS arachnides,
            SUM(ascidies) AS ascidies,
            SUM(autres) AS autres, 
            SUM(bivalves) AS bivalves,
            SUM(cephalopodes) AS cephalopodes, 
            SUM(crustaces) AS crustaces,
            SUM(diatomees) AS diatomees,
            SUM(entognathes) AS entognathes, 
            SUM(fougeres) AS fougeres,
            SUM(gasteropodes) AS gasteropodes, 
            SUM(gymnospermes) AS gymnospermes,
            SUM(hepatiques_anthocerotes) AS hepatiques_anthocerotes,
            SUM(hydrozoaires) AS hydrozoaires,
            SUM(insectes) AS insectes,
            SUM(lichens) AS lichens,
            SUM(mammiferes) AS mammiferes,
            SUM(mousses) AS mousses,
            SUM(myriapodes) AS myriapodes, 
            SUM(nematodes) AS nematodes,
            SUM(nemertes) AS nemertes,
            SUM(octocoralliaires) AS octocoralliaires,
            SUM(oiseaux) AS oiseaux, 
            SUM(plathelminthes) AS plathelminthes, 
            SUM(poissons) AS poissons,
            SUM(pycnogonides) AS pycnogonides,
            SUM(reptiles) AS reptiles, 
            SUM(scleractiniaires) AS scleractiniaires

            FROM atlas.vm_stats_espece_group2inpn_comm group2inpn
      
            JOIN atlas.l_communes_epci ec ON ec.insee = group2inpn.insee
            JOIN atlas.vm_epci e ON ec.id = e.id

            WHERE e.nom_epci_simple = :thisnomepcisimple

            """.encode('UTF-8')

      mesGroup = connection.execute(text(sql), thisnomepcisimple=nom_epci_simple)
      grouplist = []
      for inter in mesGroup:
            if inter.acanthocephales != 0:
                  grouplist.append({'label': "Acanthocéphales", 'y': inter.acanthocephales},)

            if inter.algues_brunes != 0:
                  grouplist.append({'label': "Algues brunes", 'y': inter.algues_brunes},)

            if inter.algues_rouges != 0:
                  grouplist.append({'label': "Algues rouges", 'y': inter.algues_rouges},)
                  
            if inter.algues_vertes != 0:
                  grouplist.append({'label': "Algues vertes", 'y': inter.algues_vertes},)

            if inter.amphibiens != 0:
                  grouplist.append({'label': "Amphibiens", 'y': inter.amphibiens},)
                  
            if inter.angiospermes != 0:
                  grouplist.append({'label': "Angiospermes", 'y': inter.angiospermes},)    
                  
            if inter.annelides != 0:
                  grouplist.append({'label': "Annélides", 'y': inter.annelides},)
                  
            if inter.arachnides != 0:
                  grouplist.append({'label': "Arachnides", 'y': inter.arachnides},)
                  
            if inter.ascidies != 0:
                  grouplist.append({'label': "Ascidies", 'y': inter.ascidies},)
                  
            if inter.autres != 0:
                  grouplist.append({'label': "Autres", 'y': inter.autres},)
                  
            if inter.bivalves != 0:
                  grouplist.append({'label': "Bivalves", 'y': inter.bivalves},)
                  
            if inter.cephalopodes != 0:
                  grouplist.append({'label': "Céphalopodes", 'y': inter.cephalopodes},)
                  
            if inter.crustaces != 0:
                  grouplist.append({'label': "Crustacés", 'y': inter.crustaces},)
                  
            if inter.diatomees != 0:
                  grouplist.append({'label': "Diatomées", 'y': inter.diatomees},)
                  
            if inter.entognathes != 0:
                  grouplist.append({'label': "Entognathes", 'y': inter.entognathes},)
                  
            if inter.fougeres != 0:
                  grouplist.append({'label': "Fougères", 'y': inter.fougeres},)
                  
            if inter.gasteropodes != 0:
                  grouplist.append({'label': "Gastéropodes", 'y': inter.gasteropodes},)
                  
            if inter.gymnospermes != 0:
                  grouplist.append({'label': "Gymnospermes", 'y': inter.gymnospermes},)
                  
            if inter.hepatiques_anthocerotes != 0:
                  grouplist.append({'label': "Hépatiques et Anthocérotes", 'y': inter.hepatiques_anthocerotes},)
                  
            if inter.hydrozoaires != 0:
                  grouplist.append({'label': "Hydrozoaires", 'y': inter.hydrozoaires},)
                  
            if inter.insectes != 0:
                  grouplist.append({'label': "Insectes", 'y': inter.insectes},)
                  
            if inter.lichens != 0:
                  grouplist.append({'label': "Lichens", 'y': inter.lichens},)
                  
            if inter.mammiferes != 0:
                  grouplist.append({'label': "Mammifères", 'y': inter.mammiferes},)
                  
            if inter.mousses != 0:
                  grouplist.append({'label': "Mousses", 'y': inter.mousses},)
                  
            if inter.myriapodes != 0:
                  grouplist.append({'label': "Myriapodes", 'y': inter.myriapodes},)
                  
            if inter.nematodes != 0:
                  grouplist.append({'label': "Nématodes", 'y': inter.nematodes},)
                  
            if inter.nemertes != 0:
                  grouplist.append({'label': "Némertes", 'y': inter.nemertes},)
                  
            if inter.octocoralliaires != 0:
                  grouplist.append({'label': "Octocoralliaires", 'y': inter.octocoralliaires},)
                  
            if inter.oiseaux != 0:
                  grouplist.append({'label': "Oiseaux", 'y': inter.oiseaux},)
                  
            if inter.plathelminthes != 0:
                  grouplist.append({'label': "Plathelminthes", 'y': inter.plathelminthes},)
                  
            if inter.poissons != 0:
                  grouplist.append({'label': "Poissons", 'y': inter.poissons},)
                  
            if inter.pycnogonides != 0:
                  grouplist.append({'label': "Pycnogonides", 'y': inter.pycnogonides},)
                  
            if inter.reptiles != 0:
                  grouplist.append({'label': "Reptiles", 'y': inter.reptiles},)
                  
            if inter.scleractiniaires != 0:
                  grouplist.append({'label': "Scléractiniaires", 'y': inter.scleractiniaires},)     

      return grouplist



