$(document).ready(function(){

  /*** Export PDF liste communale ***/
  $('#exportcom').click(function () {

      var datenow = $.datepicker.formatDate('dd/mm/yy', new Date());


      var doc = new jsPDF();

      //texte avant le tableau
      doc.setFontSize(16);
      doc.text("Liste des espèces de la commune : "+referenciel.communeName+' ('+referenciel.num_dpt+')', 12, 20);

      doc.setFontSize(12);
      doc.text("Nombre d'espèces : "+listespeces.taxons.length, 12, 30);

      doc.setFontSize(12);
      doc.text("Liste téléchargée sur Biodiv'Pays de la Loire le "+datenow, 12, 40);

      //var pageWidth = doc.internal.pageSize.width || doc.internal.pageSize.getWidth();
      //var text = doc.splitTextToSize('blablabling.', pageWidth - 35, {});
      //doc.text(text, 14, 30);

   
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
      doc.save(datenow+'_liste_especes_commune_'+insee+'.pdf');

  });




  /*** Export PDF liste intercommunale ***/
  $('#exportepci').click(function () {

      var datenow = $.datepicker.formatDate('dd/mm/yy', new Date());


      var doc = new jsPDF();

      //texte avant le tableau
      doc.setFontSize(18);
      doc.text("Liste des espèces de l'EPCI : "+referenciel.epciName+' ('+referenciel.num_dpt+')', 14, 20);

      doc.setFontSize(14);
      doc.text("Nombre de taxons : "+listespeces.taxons.length, 14, 30);

      doc.setFontSize(12);
      doc.text("Liste téléchargée sur Biodiv'Pays de la Loire le "+datenow, 14, 40);

      //var pageWidth = doc.internal.pageSize.width || doc.internal.pageSize.getWidth();
      //var text = doc.splitTextToSize('blablabling.', pageWidth - 35, {});
      //doc.text(text, 14, 30);

   
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

  });



  /*** Export PDF liste departementale ***/
  $('#exportdpt').click(function () {

      var datenow = $.datepicker.formatDate('dd/mm/yy', new Date());


      var doc = new jsPDF();

      //texte avant le tableau
      doc.setFontSize(18);
      doc.text("Liste des espèces du département : "+referenciel.dptName+' ('+referenciel.num_dpt+')', 14, 20);

      doc.setFontSize(14);
      doc.text("Nombre de taxons : "+listespeces.taxons.length, 14, 30);

      doc.setFontSize(12);
      doc.text("Liste téléchargée sur Biodiv'Pays de la Loire le "+datenow, 14, 40);

      //var pageWidth = doc.internal.pageSize.width || doc.internal.pageSize.getWidth();
      //var text = doc.splitTextToSize('blablabling.', pageWidth - 35, {});
      //doc.text(text, 14, 30);

   
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
      doc.save(datenow+'_liste_especes_commune_'+num_dpt+'.pdf');

  });



});



