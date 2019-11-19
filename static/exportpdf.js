$(document).ready(function(){

  /*** Export PDF liste communale ***/
  $('#exportcom').click(function () {

      var datenow = $.datepicker.formatDate('dd/mm/yy', new Date());

      var doc = new jsPDF();

      //texte avant le tableau
      doc.setFontSize(16);
      doc.setFontType("bold");
      doc.setTextColor(27, 86, 126);
      doc.text("Liste des espèces de la commune : "+referenciel.communeName+' ('+referenciel.num_dpt+')', 12, 20);

      doc.setFontSize(12);
      doc.setFontType("normal");
      doc.setTextColor(13, 43, 63);
      doc.text("Nombre d'espèces : "+listespeces.taxons.length, 12, 30);

      doc.setFontSize(11);
      doc.setTextColor(13, 43, 63);

      if ( (configuration.AFFICHE_PATRIMONIALITE == false) && (configuration.PROTECTION == false) ) {
        doc.text("----------", 12, 40);
      }  
      if ( (configuration.AFFICHE_PATRIMONIALITE) && (configuration.PROTECTION == false) ) {
        doc.text("Nombre d'espèces patrimoniales : "+taxonProPatri.nbTaxonPatri, 12, 40);
      }    
      if ( (configuration.AFFICHE_PATRIMONIALITE == false) && (configuration.PROTECTION) ) {
        doc.text("Nombre d'espèces protégées : "+taxonProPatri.nbTaxonPro, 12, 40);
      }    
      if ( (configuration.AFFICHE_PATRIMONIALITE) && (configuration.PROTECTION) ) {
        doc.text("Nombre d'espèces protégées : "+taxonProPatri.nbTaxonPro+" - Nombre d'espèces patrimoniales : "+taxonProPatri.nbTaxonPatri, 12, 40);
      }    
      
      doc.text("Liste téléchargée sur Biodiv'Pays de la Loire le "+datenow, 12, 50);
      doc.text("Référentiel : TAXREF v12", 12, 60);

      doc.setLineWidth(0.2);
      doc.setDrawColor(27, 86, 126);
      doc.line(12, 75, 200, 75);

      doc.setFontSize(11);
      doc.setFontType("bold");
      doc.setTextColor(13, 43, 63);
      doc.text("Avertissement", 12, 80);

      doc.setFontSize(11);

      doc.setFontType("normal");
      doc.setTextColor(13, 43, 63);
      doc.text("Les données visualisables reflètent l'état d'avancement des connaissances et/ou la disponibilité des données", 12, 90);

      doc.setFontType("normal");
      doc.setTextColor(13, 43, 63);
      doc.text("existantes : elles ne peuvent en aucun cas être considérées comme exhaustives. De plus, le moissonnage", 12, 95);

      doc.setFontType("normal");
      doc.setTextColor(13, 43, 63);
      doc.text("des bases de données partenaires est toujours en cours, le nombre de données visualisables est amené à", 12, 100);

      doc.setFontType("normal");
      doc.setTextColor(13, 43, 63);
      doc.text("augmenter au fil du temps. Il est à noter que certaines données visualisables sont validées au niveau régional, ", 12, 105);

      doc.setFontType("normal");
      doc.setTextColor(13, 43, 63);
      doc.text("et que d'autres sont encore dans un processus de validation. Ces dernières sont donc visualisables sans", 12, 110);  

      doc.setFontType("normal");
      doc.setTextColor(13, 43, 63);
      doc.text("être formellement validées.", 12, 115); 
    
      doc.setLineWidth(0.2);
      doc.setDrawColor(27, 86, 126);
      doc.line(12, 120, 200, 120); 


      //récupère les classes taxo observée sur le territoire
      var classetaxon = [];
      for(i = 0; i< listespeces.taxons.length; i++){    
          if(classetaxon.indexOf(listespeces.taxons[i].group2_inpn) === -1){
              classetaxon.push(listespeces.taxons[i].group2_inpn);        
          }        
      }


      var first = true; 
      
      for(i = 0; i< classetaxon.length; i++){   

          //Variables pour la boucle dans les classes taxo
          var col = 'col' + i ;
          window[col] = col[i];
         
          var rows = 'rows' + i ;
          window[rows] = rows[i];


          //Initialisation du tableau
          if ( (configuration.AFFICHE_PATRIMONIALITE == false) && (configuration.PROTECTION == false) ) {
            window[col] = ["Nom complet", "Nom vernaculaire", "Dernière\nobservation"];
            window[rows]  = [];
          }    
          if ( (configuration.AFFICHE_PATRIMONIALITE) && (configuration.PROTECTION == false) ) {
            window[col] = ["Nom complet", "Nom vernaculaire", "Patrimonial", "Dernière\nobservation"];
            window[rows]  = [];
          }    
          if ( (configuration.AFFICHE_PATRIMONIALITE == false) && (configuration.PROTECTION) ) {
            window[col] = ["Nom complet", "Nom vernaculaire", "Protégé", "Dernière\nobservation"];
            window[rows]  = [];
          }    
          if ( (configuration.AFFICHE_PATRIMONIALITE) && (configuration.PROTECTION) ) {
            window[col] = ["Nom complet", "Nom vernaculaire", "Protégé", "Patrimonial", "Dernière\nobservation"];
            window[rows]  = [];
          } 

          //On récupère les données du JSON listespece.taxons
          listespeces.taxons.forEach(element => {      

              if ( element.nom_vern != null ) {
                var nom_vern = element.nom_vern;
              } else {var nom_vern = '';}

              if ( element.protection_stricte != null ) {
                var protection_stricte = 'protégé';
              } else {var protection_stricte = '';}

              if ( element.patrimonial != null ) {
                var patrimonial = 'patrimonial';
              } else {var patrimonial = '';}




          if ( (configuration.AFFICHE_PATRIMONIALITE == false) && (configuration.PROTECTION == false) ) {
              if ( element.group2_inpn == classetaxon[i] ) {
                  var temp = [
                              element.nom_complet,
                              nom_vern,
                              element.last_obs
                              ];
                  window[rows].push(temp);
                }
          } 

          if ( (configuration.AFFICHE_PATRIMONIALITE) && (configuration.PROTECTION == false) ) {
              if ( element.group2_inpn == classetaxon[i] ) {
                  var temp = [
                              element.nom_complet,
                              nom_vern,
                              patrimonial,
                              element.last_obs
                              ];
                  window[rows].push(temp);
                }
          } 

          if ( (configuration.AFFICHE_PATRIMONIALITE == false) && (configuration.PROTECTION) ) {
              if ( element.group2_inpn == classetaxon[i] ) {
                  var temp = [
                              element.nom_complet,
                              nom_vern,
                              protection_stricte,
                              element.last_obs
                              ];
                  window[rows].push(temp);
                }
          } 

          if ( (configuration.AFFICHE_PATRIMONIALITE) && (configuration.PROTECTION) ) {
              if ( element.group2_inpn == classetaxon[i] ) {
                  var temp = [
                              element.nom_complet,
                              nom_vern,
                              protection_stricte,
                              patrimonial,
                              element.last_obs
                              ];
                  window[rows].push(temp);
                }
          } 



          }); 



          //paramétrage du rendu du tableau

          if (first == true ) { 
              startytable = 140; 
              startytitretable = 135; 
          } else { 
              startytable = doc.autoTable.previous.finalY + 20; 
              startytitretable = doc.autoTable.previous.finalY + 15; 
          }


          //Nom du tableau (=la classe taxo)
          doc.setFontSize(13);
          doc.setFontType("bold");
          doc.setTextColor(40, 128, 186);
          doc.text(classetaxon[i], 14, startytitretable);
          //corps du tableau

          doc.autoTable(window[col], window[rows], {
              startY: startytable,
               showHeader: 'firstPage',
              //pageBreak: 'wrap',
              margin: {horizontal: 7},
              // bodyStyles: {valign: 'top'},
              styles: {overflow: 'linebreak', columnWidth: 'wrap'},
              columnStyles: {0: {columnWidth: 85},1: {columnWidth: 'auto'},2: {columnWidth: 25}}
          });
          first = false;       

      }


      //Enregistrement du PDF
      doc.save(datenow+'_liste_especes_commune_'+insee+'.pdf');



  });




  /*** Export PDF liste intercommunale ***/
  $('#exportepci').click(function () {

    var datenow = $.datepicker.formatDate('dd/mm/yy', new Date());

      var doc = new jsPDF();

      //texte avant le tableau
      doc.setFontSize(16);
      doc.setFontType("bold");
      doc.setTextColor(27, 86, 126);
      doc.text("Liste des espèces de l'EPCI : "+referenciel.epciName+' ('+epciDpt.num_dpt+')', 12, 20);
doc.setFontSize(12);
      doc.setFontType("normal");
      doc.setTextColor(13, 43, 63);
      doc.text("Nombre d'espèces : "+listespeces.taxons.length, 12, 30);

      doc.setFontSize(11);
      doc.setTextColor(13, 43, 63);

      if ( (configuration.AFFICHE_PATRIMONIALITE == false) && (configuration.PROTECTION == false) ) {
        doc.text("----------", 12, 40);
      }  
      if ( (configuration.AFFICHE_PATRIMONIALITE) && (configuration.PROTECTION == false) ) {
        doc.text("Nombre d'espèces patrimoniales : "+taxonProPatri.nbTaxonPatri, 12, 40);
      }    
      if ( (configuration.AFFICHE_PATRIMONIALITE == false) && (configuration.PROTECTION) ) {
        doc.text("Nombre d'espèces protégées : "+taxonProPatri.nbTaxonPro, 12, 40);
      }    
      if ( (configuration.AFFICHE_PATRIMONIALITE) && (configuration.PROTECTION) ) {
        doc.text("Nombre d'espèces protégées : "+taxonProPatri.nbTaxonPro+" - Nombre d'espèces patrimoniales : "+taxonProPatri.nbTaxonPatri, 12, 40);
      }    
      
      doc.text("Liste téléchargée sur Biodiv'Pays de la Loire le "+datenow, 12, 50);
      doc.text("Référentiel : TAXREF v12", 12, 60);

      doc.setLineWidth(0.2);
      doc.setDrawColor(27, 86, 126);
      doc.line(12, 75, 200, 75);

      doc.setFontSize(11);
      doc.setFontType("bold");
      doc.setTextColor(13, 43, 63);
      doc.text("Avertissement", 12, 80);

      doc.setFontSize(11);

      doc.setFontType("normal");
      doc.setTextColor(13, 43, 63);
      doc.text("Les données visualisables reflètent l'état d'avancement des connaissances et/ou la disponibilité des données", 12, 90);

      doc.setFontType("normal");
      doc.setTextColor(13, 43, 63);
      doc.text("existantes : elles ne peuvent en aucun cas être considérées comme exhaustives. De plus, le moissonnage", 12, 95);

      doc.setFontType("normal");
      doc.setTextColor(13, 43, 63);
      doc.text("des bases de données partenaires est toujours en cours, le nombre de données visualisables est amené à", 12, 100);

      doc.setFontType("normal");
      doc.setTextColor(13, 43, 63);
      doc.text("augmenter au fil du temps. Il est à noter que certaines données visualisables sont validées au niveau régional, ", 12, 105);

      doc.setFontType("normal");
      doc.setTextColor(13, 43, 63);
      doc.text("et que d'autres sont encore dans un processus de validation. Ces dernières sont donc visualisables sans", 12, 110);  

      doc.setFontType("normal");
      doc.setTextColor(13, 43, 63);
      doc.text("être formellement validées.", 12, 115); 
    
      doc.setLineWidth(0.2);
      doc.setDrawColor(27, 86, 126);
      doc.line(12, 120, 200, 120);  

      //récupère les classes taxo observée sur le territoire
      var classetaxon = [];
      for(i = 0; i< listespeces.taxons.length; i++){    
          if(classetaxon.indexOf(listespeces.taxons[i].group2_inpn) === -1){
              classetaxon.push(listespeces.taxons[i].group2_inpn);        
          }        
      }


      var first = true; 
      
      for(i = 0; i< classetaxon.length; i++){   

          //Variables pour la boucle dans les classes taxo
          var col = 'col' + i ;
          window[col] = col[i];
         
          var rows = 'rows' + i ;
          window[rows] = rows[i];


          //Initialisation du tableau
          if ( (configuration.AFFICHE_PATRIMONIALITE == false) && (configuration.PROTECTION == false) ) {
            window[col] = ["Nom complet", "Nom vernaculaire", "Dernière\nobservation"];
            window[rows]  = [];
          } 
          if ( (configuration.AFFICHE_PATRIMONIALITE) && (configuration.PROTECTION == false) ) {
            window[col] = ["Nom complet", "Nom vernaculaire", "Patrimonial", "Dernière\nobservation"];
            window[rows]  = [];
          }    
          if ( (configuration.AFFICHE_PATRIMONIALITE == false) && (configuration.PROTECTION) ) {
            window[col] = ["Nom complet", "Nom vernaculaire", "Protégé", "Dernière\nobservation"];
            window[rows]  = [];
          }    
          if ( (configuration.AFFICHE_PATRIMONIALITE) && (configuration.PROTECTION) ) {
            window[col] = ["Nom complet", "Nom vernaculaire", "Protégé", "Patrimonial", "Dernière\nobservation"];
            window[rows]  = [];
          } 

          //On récupère les données du JSON listespece.taxons
          listespeces.taxons.forEach(element => {      

              if ( element.nom_vern != null ) {
                var nom_vern = element.nom_vern;
              } else {var nom_vern = '';}

              if ( element.protection_stricte != null ) {
                var protection_stricte = 'protégé';
              } else {var protection_stricte = '';}

              if ( element.patrimonial != null ) {
                var patrimonial = 'patrimonial';
              } else {var patrimonial = '';}

          if ( (configuration.AFFICHE_PATRIMONIALITE == false) && (configuration.PROTECTION == false) ) {
              if ( element.group2_inpn == classetaxon[i] ) {
                  var temp = [
                              element.nom_complet,
                              nom_vern,
                              element.last_obs
                              ];
                  window[rows].push(temp);
                }
          } 

          if ( (configuration.AFFICHE_PATRIMONIALITE) && (configuration.PROTECTION == false) ) {
              if ( element.group2_inpn == classetaxon[i] ) {
                  var temp = [
                              element.nom_complet,
                              nom_vern,
                              patrimonial,
                              element.last_obs
                              ];
                  window[rows].push(temp);
                }
          } 

          if ( (configuration.AFFICHE_PATRIMONIALITE == false) && (configuration.PROTECTION) ) {
              if ( element.group2_inpn == classetaxon[i] ) {
                  var temp = [
                              element.nom_complet,
                              nom_vern,
                              protection_stricte,
                              element.last_obs
                              ];
                  window[rows].push(temp);
                }
          } 

          if ( (configuration.AFFICHE_PATRIMONIALITE) && (configuration.PROTECTION) ) {
              if ( element.group2_inpn == classetaxon[i] ) {
                  var temp = [
                              element.nom_complet,
                              nom_vern,
                              protection_stricte,
                              patrimonial,
                              element.last_obs
                              ];
                  window[rows].push(temp);
                }
          } 


          }); 



          //paramétrage du rendu du tableau

          if (first == true ) { 
              startytable = 140; 
              startytitretable = 135; 
          } else { 
              startytable = doc.autoTable.previous.finalY + 20; 
              startytitretable = doc.autoTable.previous.finalY + 15; 
          }


          //Nom du tableau (=la classe taxo)
          doc.setFontSize(13);
          doc.setFontType("bold");
          doc.setTextColor(40, 128, 186);
          doc.text(classetaxon[i], 14, startytitretable);
          //corps du tableau

          doc.autoTable(window[col], window[rows], {
              startY: startytable,
               showHeader: 'firstPage',
              //pageBreak: 'wrap',
              margin: {horizontal: 7},
              // bodyStyles: {valign: 'top'},
              styles: {overflow: 'linebreak', columnWidth: 'wrap'},
              columnStyles: {0: {columnWidth: 85},1: {columnWidth: 'auto'},2: {columnWidth: 25}}
          });
          first = false;       

      }


      //Enregistrement du PDF
      doc.save(datenow+'_liste_especes_epci_'+nom_epci_simple+'.pdf');




/*

      var datenow = $.datepicker.formatDate('dd/mm/yy', new Date());


      var doc = new jsPDF();

      //texte avant le tableau
      doc.setFontSize(18);
      doc.text("Liste des espèces de l'EPCI : "+referenciel.epciName+' ('+epciDpt.num_dpt+')', 14, 20);

      doc.setFontSize(14);
      doc.text("Nombre de taxons : "+listespeces.taxons.length, 14, 30);

      doc.setFontSize(12);
      doc.text("Liste téléchargée sur Biodiv'Pays de la Loire le "+datenow, 14, 40);

   
      //Initialisation du tableau
      var col = ["Classe","Nom complet", "Nom vernaculaire", "Dernière\nobservation"];
      var rows = [];

      //On récupère les données du JSON listespece.taxons
      listespeces.taxons.forEach(element => {      

          if ( element.nom_vern != null ) {
            var nom_vern = element.nom_vern;
          } else {var nom_vern = '';}

          var temp = [
                      element.group2_inpn,
                      element.nom_complet,
                      nom_vern,
                      element.last_obs
                      ];
          rows.push(temp);
      });        

      //paramétrage du rendu du tableau
      doc.autoTable(col, rows, {
          startY: 50,
          margin: {horizontal: 7},
         // bodyStyles: {valign: 'top'},
          styles: {overflow: 'linebreak', columnWidth: 'wrap'},
          columnStyles: {1: {columnWidth: 80},2: {columnWidth: 'auto'},3: {columnWidth: 25}}
      });

      //Enregistrement du PDF
      doc.save(datenow+'_liste_especes_epci_'+nom_epci_simple+'.pdf');
*/
  });



  /*** Export PDF liste departementale ***/
  $('#exportdpt').click(function () {

      var datenow = $.datepicker.formatDate('dd/mm/yy', new Date());

      var doc = new jsPDF();

      //texte avant le tableau
      doc.setFontSize(16);
      doc.setFontType("bold");
      doc.setTextColor(27, 86, 126);
      doc.text("Liste des espèces du département : "+referenciel.dptName+' ('+referenciel.num_dpt+')', 12, 20);

     doc.setFontSize(12);
      doc.setFontType("normal");
      doc.setTextColor(13, 43, 63);
      doc.text("Nombre d'espèces : "+listespeces.taxons.length, 12, 30);
      
      doc.setFontSize(11);
      doc.setTextColor(13, 43, 63);


      if ( (configuration.AFFICHE_PATRIMONIALITE == false) && (configuration.PROTECTION == false) ) {
        doc.text("----------", 12, 40);
      }  
      if ( (configuration.AFFICHE_PATRIMONIALITE) && (configuration.PROTECTION == false) ) {
        doc.text("Nombre d'espèces patrimoniales : "+taxonProPatri.nbTaxonPatri, 12, 40);
      }    
      if ( (configuration.AFFICHE_PATRIMONIALITE == false) && (configuration.PROTECTION) ) {
        doc.text("Nombre d'espèces protégées : "+taxonProPatri.nbTaxonPro, 12, 40);
      }    
      if ( (configuration.AFFICHE_PATRIMONIALITE) && (configuration.PROTECTION) ) {
        doc.text("Nombre d'espèces protégées : "+taxonProPatri.nbTaxonPro+" - Nombre d'espèces patrimoniales : "+taxonProPatri.nbTaxonPatri, 12, 40);
      }    
      
      doc.text("Liste téléchargée sur Biodiv'Pays de la Loire le "+datenow, 12, 50);

      doc.text("Référentiel : TAXREF v12", 12, 60);

      doc.setLineWidth(0.2);
      doc.setDrawColor(27, 86, 126);
      doc.line(12, 75, 200, 75);

      doc.setFontSize(11);
      doc.setFontType("bold");
      doc.setTextColor(13, 43, 63);
      doc.text("Avertissement", 12, 80);

      doc.setFontSize(11);

      doc.setFontType("normal");
      doc.setTextColor(13, 43, 63);
      doc.text("Les données visualisables reflètent l'état d'avancement des connaissances et/ou la disponibilité des données", 12, 90);

      doc.setFontType("normal");
      doc.setTextColor(13, 43, 63);
      doc.text("existantes : elles ne peuvent en aucun cas être considérées comme exhaustives. De plus, le moissonnage", 12, 95);

      doc.setFontType("normal");
      doc.setTextColor(13, 43, 63);
      doc.text("des bases de données partenaires est toujours en cours, le nombre de données visualisables est amené à", 12, 100);

      doc.setFontType("normal");
      doc.setTextColor(13, 43, 63);
      doc.text("augmenter au fil du temps. Il est à noter que certaines données visualisables sont validées au niveau régional, ", 12, 105);

      doc.setFontType("normal");
      doc.setTextColor(13, 43, 63);
      doc.text("et que d'autres sont encore dans un processus de validation. Ces dernières sont donc visualisables sans", 12, 110);  

      doc.setFontType("normal");
      doc.setTextColor(13, 43, 63);
      doc.text("être formellement validées.", 12, 115); 
    
      doc.setLineWidth(0.2);
      doc.setDrawColor(27, 86, 126);
      doc.line(12, 120, 200, 120); 


      //récupère les classes taxo observée sur le territoire
      var classetaxon = [];
      for(i = 0; i< listespeces.taxons.length; i++){    
          if(classetaxon.indexOf(listespeces.taxons[i].group2_inpn) === -1){
              classetaxon.push(listespeces.taxons[i].group2_inpn);        
          }        
      }


      var first = true; 
      
      for(i = 0; i< classetaxon.length; i++){   

          //Variables pour la boucle dans les classes taxo
          var col = 'col' + i ;
          window[col] = col[i];
         
          var rows = 'rows' + i ;
          window[rows] = rows[i];


          //Initialisation du tableau
          if ( (configuration.AFFICHE_PATRIMONIALITE == false) && (configuration.PROTECTION == false) ) {
            window[col] = ["Nom complet", "Nom vernaculaire", "Dernière\nobservation"];
            window[rows]  = [];
          } 
          if ( (configuration.AFFICHE_PATRIMONIALITE) && (configuration.PROTECTION == false) ) {
            window[col] = ["Nom complet", "Nom vernaculaire", "Patrimonial", "Dernière\nobservation"];
            window[rows]  = [];
          }    
          if ( (configuration.AFFICHE_PATRIMONIALITE == false) && (configuration.PROTECTION) ) {
            window[col] = ["Nom complet", "Nom vernaculaire", "Protégé", "Dernière\nobservation"];
            window[rows]  = [];
          }    
          if ( (configuration.AFFICHE_PATRIMONIALITE) && (configuration.PROTECTION) ) {
            window[col] = ["Nom complet", "Nom vernaculaire", "Protégé", "Patrimonial", "Dernière\nobservation"];
            window[rows]  = [];
          } 

          //On récupère les données du JSON listespece.taxons
          listespeces.taxons.forEach(element => {      

              if ( element.nom_vern != null ) {
                var nom_vern = element.nom_vern;
              } else {var nom_vern = '';}

              if ( element.protection_stricte != null ) {
                var protection_stricte = 'protégé';
              } else {var protection_stricte = '';}

              if ( element.patrimonial != null ) {
                var patrimonial = 'patrimonial';
              } else {var patrimonial = '';}


          if ( (configuration.AFFICHE_PATRIMONIALITE == false) && (configuration.PROTECTION == false) ) {
              if ( element.group2_inpn == classetaxon[i] ) {
                  var temp = [
                              element.nom_complet,
                              nom_vern,
                              element.last_obs
                              ];
                  window[rows].push(temp);
                }
          } 

          if ( (configuration.AFFICHE_PATRIMONIALITE) && (configuration.PROTECTION == false) ) {
              if ( element.group2_inpn == classetaxon[i] ) {
                  var temp = [
                              element.nom_complet,
                              nom_vern,
                              patrimonial,
                              element.last_obs
                              ];
                  window[rows].push(temp);
                }
          } 

          if ( (configuration.AFFICHE_PATRIMONIALITE == false) && (configuration.PROTECTION) ) {
              if ( element.group2_inpn == classetaxon[i] ) {
                  var temp = [
                              element.nom_complet,
                              nom_vern,
                              protection_stricte,
                              element.last_obs
                              ];
                  window[rows].push(temp);
                }
          } 

          if ( (configuration.AFFICHE_PATRIMONIALITE) && (configuration.PROTECTION) ) {
              if ( element.group2_inpn == classetaxon[i] ) {
                  var temp = [
                              element.nom_complet,
                              nom_vern,
                              protection_stricte,
                              patrimonial,
                              element.last_obs
                              ];
                  window[rows].push(temp);
                }
          } 


          }); 



          //paramétrage du rendu du tableau

          if (first == true ) { 
              startytable = 140; 
              startytitretable = 135; 
          } else { 
              startytable = doc.autoTable.previous.finalY + 20; 
              startytitretable = doc.autoTable.previous.finalY + 15; 
          }


          //Nom du tableau (=la classe taxo)
          doc.setFontSize(13);
          doc.setFontType("bold");
          doc.setTextColor(40, 128, 186);
          doc.text(classetaxon[i], 14, startytitretable);
          //corps du tableau

          doc.autoTable(window[col], window[rows], {
              startY: startytable,
               showHeader: 'firstPage',
              //pageBreak: 'wrap',
              margin: {horizontal: 7},
              // bodyStyles: {valign: 'top'},
              styles: {overflow: 'linebreak', columnWidth: 'wrap'},
              columnStyles: {0: {columnWidth: 85},1: {columnWidth: 'auto'},2: {columnWidth: 25}}
          });
          first = false;       

      }


      //Enregistrement du PDF
      doc.save(datenow+'_liste_especes_dpt_'+num_dpt+'.pdf');

   });
      

});



