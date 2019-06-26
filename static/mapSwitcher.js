var map = generateMap();
generateSliderOnMap();
generateSwitcherOnMap();
var legend = L.control({position: 'bottomright'});

// Legende

htmlLegend = "<i style='border: solid "+configuration.MAP.BORDERS_WEIGHT+"px "+configuration.MAP.BORDERS_COLOR+";'> &nbsp; &nbsp; &nbsp;</i> Limite des "+ configuration.STRUCTURE+"<br> <br>"+
            "<i style='border: solid "+configuration.MAP.BORDERS_DPT_WEIGHT+"px "+configuration.MAP.BORDERS_DPT_COLOR+";'> &nbsp; &nbsp; &nbsp;</i> Limites départementales";

generateLegende(htmlLegend);

// Layer display on window ready

/*GLOBAL VARIABLE*/

// Current observation Layer: leaflet layer type
var currentLayer; 

// Current observation geoJson:  type object
var myGeoJson;

var compteurLegend = 0; // counter to not put the legend each time

var $loader = $('#loadingGif').attr('src', configuration.URL_APPLICATION+'/static/images/loading.svg');


//display une première couche sur la carte avec switcher
if(configuration.AFFICHAGE_ATLAS_MAILLE_CARREE){
      $.ajax({
        url: configuration.URL_APPLICATION+'/api/observationsMaille/'+cd_ref, 
        dataType: "json",
        beforeSend: function(){
            $loader.show();        }
        }).done(function(observations) {
             $loader.hide();
      
          // affichage des mailles
          displayMailleLayerFicheEspece(observations, taxonYearMin, YEARMAX);
      
            //display nb observations
        $("#nbObsLateral").html("<b>"+observations.length+" </b> </br> Observations" );

          // pointer on first and last obs
          $('.pointer').css('cursor', 'pointer');
          //display nb observations
              nbObs=0;
              myGeoJson.features.forEach(function(l){
                nbObs += l.properties.nb_observations
                })
              $("#nbObs").html("Nombre d'observation(s): "+ nbObs);
         
      
      
           // Slider event
          mySlider.on("change",function(){
                years = mySlider.getValue();
                yearMin = years[0];
                yearMax = years[1];
                map.removeLayer(currentLayer);
                displayMailleLayerFicheEspece(observations, yearMin, yearMax)
      
      
              nbObs=0;
              myGeoJson.features.forEach(function(l){
                nbObs += l.properties.nb_observations
              })
      
              $("#nbObs").html("Nombre d'observation(s): "+ nbObs);
      
             });
      
      
          // Stat - map interaction
          $('#firstObs').click(function(){
            var firstObsLayer;
            var year = new Date('2400-01-01');
      
      
                var layer = (currentLayer._layers);
                for (var key in layer) {
                  layer[key].feature.properties.tabDateobs.forEach(function(thisYear){
                    if (thisYear <= year){
                      year = thisYear;
                      firstObsLayer = layer[key];
                    }
                  });
                }
      
                
                var bounds = L.latLngBounds([]);
                var layerBounds = firstObsLayer.getBounds();
                bounds.extend(layerBounds);
                map.fitBounds(bounds, {
                  maxZoom : 12
                });
      
                firstObsLayer.openPopup();
          })
      
          $('#lastObs').click(function(){
            var firstObsLayer;
            var year = new Date('1800-01-01');
      
      
                var layer = (currentLayer._layers);
                for (var key in layer) {
                  layer[key].feature.properties.tabDateobs.forEach(function(thisYear){
                    if (thisYear >= year){
                      year = thisYear;
                      firstObsLayer = layer[key];
                    }
                  });
                }
      
                
                var bounds = L.latLngBounds([]);
                var layerBounds = firstObsLayer.getBounds();
                bounds.extend(layerBounds);
                map.fitBounds(bounds, {
                  maxZoom : 12
                });
      
                firstObsLayer.openPopup();
          })
      });

}else{
     



}




// ajout d'un contrôle pour changer le type d'analyse (mailles / communes / points)
var mySwitcher;
function generateSwitcherOnMap(){
//*******MAILLESCOMMUNALES********
    var SwitcherCommControl = L.Control.extend({

      options: {
        position: 'topleft' 
        //control position - allowed: 'topleft', 'topright', 'bottomleft', 'bottomright'
      },

      onAdd: function (map) {

        var switcherCommContainer =L.DomUtil.create('div', 'leaflet-bar leaflet-control leaflet-control-custom');
        switcherCommContainer.style.backgroundColor = 'white';
        switcherCommContainer.style.width = '35px';
        switcherCommContainer.style.height = '35px';
        switcherCommContainer.style.border = 'solid white 1px';
        switcherCommContainer.style.cursor = 'pointer';
        switcherCommContainer.style.backgroundImage = "url("+configuration.URL_APPLICATION+"/static/images/icons8-carte-26.png)";
        switcherCommContainer.style.backgroundRepeat = 'no-repeat';
        switcherCommContainer.style.backgroundPosition = 'center';
        $(switcherCommContainer).attr("data-placement", "right");
        $(switcherCommContainer).attr("data-toggle", "tooltip");
        $(switcherCommContainer).attr("data-original-title", "Atlas par mailles communales");
        $(switcherCommContainer).attr("id", "AtlasComm");
        $(switcherCommContainer).css("margin-right", "50px"); 


        switcherCommContainer.onclick = function(){
              map.removeLayer(currentLayer);
              if (!$(switcherCommContainer).hasClass('active')) {
                $('#AtlasComm').addClass('active');
                $('#AtlasMaille').removeClass('active');
                $('#AtlasPoint').removeClass('active');
              }

              $.ajax({
                url: configuration.URL_APPLICATION+'/api/observationsMailleCommunale/'+cd_ref, 
                dataType: "json",
                beforeSend: function(){
                   $loader.show();        }
                }).done(function(observations) {
                    $loader.hide();
              
                  // affichage des mailles
                  displayMailleCommunaleLayerFicheEspece(observations, taxonYearMin, YEARMAX);
              
                  //display nb observations
                  $("#nbObsLateral").html("<b>"+observations.length+" </b> </br> Observations" );
              
                  // pointer on first and last obs
                  $('.pointer').css('cursor', 'pointer');
                  //display nb observations
                      nbObs=0;
                      myGeoJson.features.forEach(function(l){
                        nbObs += l.properties.nb_observations
                        })
                      $("#nbObs").html("Nombre d'observation(s): "+ nbObs);
                 
              
              
                   // Slider event
                  mySlider.on("change",function(){
                        years = mySlider.getValue();
                        yearMin = years[0];
                        yearMax = years[1];
                        map.removeLayer(currentLayer);
                        displayMailleCommunaleLayerFicheEspece(observations, yearMin, yearMax)
              
              
                      nbObs=0;
                      myGeoJson.features.forEach(function(l){
                        nbObs += l.properties.nb_observations
                      })
              
                      $("#nbObs").html("Nombre d'observation(s): "+ nbObs);
              
                     });
              
              
                  // Stat - map interaction
                  $('#firstObs').click(function(){
                    var firstObsLayer;
                    var year = new Date('2400-01-01');
              
              
                        var layer = (currentLayer._layers);
                        for (var key in layer) {
                          layer[key].feature.properties.tabDateobs.forEach(function(thisYear){
                            if (thisYear <= year){
                              year = thisYear;
                              firstObsLayer = layer[key];
                            }
                          });
                        }
              
                        
                        var bounds = L.latLngBounds([]);
                        var layerBounds = firstObsLayer.getBounds();
                        bounds.extend(layerBounds);
                        map.fitBounds(bounds, {
                          maxZoom : 12
                        });
              
                        firstObsLayer.openPopup();
                  })
              
                  $('#lastObs').click(function(){
                    var firstObsLayer;
                    var year = new Date('1800-01-01');
              
              
                        var layer = (currentLayer._layers);
                        for (var key in layer) {
                          layer[key].feature.properties.tabDateobs.forEach(function(thisYear){
                            if (thisYear >= year){
                              year = thisYear;
                              firstObsLayer = layer[key];
                            }
                          });
                        }
              
                        
                        var bounds = L.latLngBounds([]);
                        var layerBounds = firstObsLayer.getBounds();
                        bounds.extend(layerBounds);
                        map.fitBounds(bounds, {
                          maxZoom : 12
                        });
              
                        firstObsLayer.openPopup();
                  })
              });

        }

        return switcherCommContainer;
      }


    });

//*******MAILLESCARREES********
    var SwitcherMailleControl = L.Control.extend({

      options: {
        position: 'topleft' 
        //control position - allowed: 'topleft', 'topright', 'bottomleft', 'bottomright'
      },

      onAdd: function (map) {

        var switcherMailleContainer =L.DomUtil.create('div', 'leaflet-bar leaflet-control leaflet-control-custom');
        switcherMailleContainer.style.backgroundColor = 'white';
        switcherMailleContainer.style.width = '35px';
        switcherMailleContainer.style.height = '35px';
        switcherMailleContainer.style.border = 'solid white 1px';
        switcherMailleContainer.style.cursor = 'pointer';
        switcherMailleContainer.style.backgroundImage = "url("+configuration.URL_APPLICATION+"/static/images/icons8-grille-26.png)";
        switcherMailleContainer.style.backgroundRepeat = 'no-repeat';
        switcherMailleContainer.style.backgroundPosition = 'center';
        $(switcherMailleContainer).attr("data-placement", "right");
        $(switcherMailleContainer).attr("data-toggle", "tooltip");
        $(switcherMailleContainer).attr("data-original-title", "Atlas par mailles régulières 5x5km");
        $(switcherMailleContainer).attr("id", "AtlasMaille");
        $(switcherMailleContainer).css("margin-right", "50px"); 


        switcherMailleContainer.onclick = function(){

              if (!$(switcherMailleContainer).hasClass('active')) {
                $('#AtlasMaille').addClass('active');
                $('#AtlasComm').removeClass('active');
                $('#AtlasPoint').removeClass('active');
              }
              map.removeLayer(currentLayer);
              $.ajax({
                url: configuration.URL_APPLICATION+'/api/observationsMaille/'+cd_ref, 
                dataType: "json",
                beforeSend: function(){
                    $loader.show();        }
                }).done(function(observations) {
                     $loader.hide();
              
                  // affichage des mailles
                  displayMailleLayerFicheEspece(observations, taxonYearMin, YEARMAX);
              
                  //display nb observations
                  $("#nbObsLateral").html("<b>"+observations.length+" </b> </br> Observations" );
                            
                  // pointer on first and last obs
                  $('.pointer').css('cursor', 'pointer');
                  //display nb observations
                      nbObs=0;
                      myGeoJson.features.forEach(function(l){
                        nbObs += l.properties.nb_observations
                        })
                      $("#nbObs").html("Nombre d'observation(s): "+ nbObs);
                 
              
              
                   // Slider event
                  mySlider.on("change",function(){
                        years = mySlider.getValue();
                        yearMin = years[0];
                        yearMax = years[1];
                        map.removeLayer(currentLayer);
                        displayMailleLayerFicheEspece(observations, yearMin, yearMax)
              
              
                      nbObs=0;
                      myGeoJson.features.forEach(function(l){
                        nbObs += l.properties.nb_observations
                      })
              
                      $("#nbObs").html("Nombre d'observation(s): "+ nbObs);
              
                     });
              
              
                  // Stat - map interaction
                  $('#firstObs').click(function(){
                    var firstObsLayer;
                    var year = new Date('2400-01-01');
              
              
                        var layer = (currentLayer._layers);
                        for (var key in layer) {
                          layer[key].feature.properties.tabDateobs.forEach(function(thisYear){
                            if (thisYear <= year){
                              year = thisYear;
                              firstObsLayer = layer[key];
                            }
                          });
                        }
              
                        
                        var bounds = L.latLngBounds([]);
                        var layerBounds = firstObsLayer.getBounds();
                        bounds.extend(layerBounds);
                        map.fitBounds(bounds, {
                          maxZoom : 12
                        });
              
                        firstObsLayer.openPopup();
                  })
              
                  $('#lastObs').click(function(){
                    var firstObsLayer;
                    var year = new Date('1800-01-01');
              
              
                        var layer = (currentLayer._layers);
                        for (var key in layer) {
                          layer[key].feature.properties.tabDateobs.forEach(function(thisYear){
                            if (thisYear >= year){
                              year = thisYear;
                              firstObsLayer = layer[key];
                            }
                          });
                        }
              
                        
                        var bounds = L.latLngBounds([]);
                        var layerBounds = firstObsLayer.getBounds();
                        bounds.extend(layerBounds);
                        map.fitBounds(bounds, {
                          maxZoom : 12
                        });
              
                        firstObsLayer.openPopup();
                  })
              });
              
              
              
              
        }

        return switcherMailleContainer;
      }


    });


//*******POINTS********
   var SwitcherPointControl = L.Control.extend({

      options: {
        position: 'topleft' 
        //control position - allowed: 'topleft', 'topright', 'bottomleft', 'bottomright'
      },

      onAdd: function (map) {
        var switcherPointContainer =L.DomUtil.create('div', 'leaflet-bar leaflet-control leaflet-control-custom');
        switcherPointContainer.style.backgroundColor = 'white';
        switcherPointContainer.style.width = '35px';
        switcherPointContainer.style.height = '35px';
        switcherPointContainer.style.border = 'solid white 1px';
        switcherPointContainer.style.cursor = 'pointer';
        switcherPointContainer.style.backgroundImage = "url("+configuration.URL_APPLICATION+"/static/images/icons8-marqueur-26.png)";
        switcherPointContainer.style.backgroundRepeat = 'no-repeat';
        switcherPointContainer.style.backgroundPosition = 'center';
        $(switcherPointContainer).attr("data-placement", "right");
        $(switcherPointContainer).attr("data-toggle", "tooltip");
        $(switcherPointContainer).attr("data-original-title", "Localisation précise des observations");
        $(switcherPointContainer).attr("id", "AtlasPoint");
        $(switcherPointContainer).css("margin-right", "50px"); 


        switcherPointContainer.onclick = function(){
              map.removeLayer(currentLayer);
              var legendblock = $("div.info");
              legendblock.attr("hidden", "true");

              if (!$(switcherPointContainer).hasClass('active')) {
                $('#AtlasPoint').addClass('active');  
                $('#AtlasMaille').removeClass('active');
                $('#AtlasComm').removeClass('active');
              }

         $.ajax({
          url: configuration.URL_APPLICATION+'/api/observationsMailleAndPoint/'+cd_ref, 
          dataType: "json",
          beforeSend: function(){
            $('#loadingGif').attr("src", configuration.URL_APPLICATION+'/static/images/loading.svg')
          }

          }).done(function(observations) {
            $('#loadingGif').hide();

            //display nb observations
            var mailleBoolean = false;
            if (map.getZoom() < configuration.ZOOM_LEVEL_POINT && observations.maille.length > 1 && $('#AtlasPoint').hasClass('active')) {
               displayMailleLayerFicheEspece(observations.maille, taxonYearMin, YEARMAX);
               mailleBoolean = true;
            }
            else {
                  if($('#AtlasPoint').hasClass('active')){
                        displayMarkerLayerFicheEspece(observations.point, taxonYearMin, YEARMAX);
                  }
            }

           
              if (mailleBoolean){
                // Slider event
                    mySlider.on("change",function(){
                        years = mySlider.getValue();
                        yearMin = years[0];
                        yearMax = years[1];


                        map.removeLayer(currentLayer);
                        if(map.getZoom() >= configuration.ZOOM_LEVEL_POINT && $('#AtlasPoint').hasClass('active')){
                          displayMarkerLayerFicheEspece(observations.point, yearMin, yearMax);
                        }else{
                          if($('#AtlasPoint').hasClass('active')){
                              displayMailleLayerFicheEspece(observations.maille, yearMin, yearMax)
                          }
                        }

                        nbObs=0;
                        myGeoJson.features.forEach(function(l){
                          nbObs += l.properties.nb_observations
                        })

                        $("#nbObs").html("Nombre d'observation(s): "+ nbObs);

                       });


                      // ZoomEvent: change maille to point

                      var activeMode = "Maille";                

                      map.on("zoomend", function(){
                      if (activeMode != "Point" && map.getZoom() >= configuration.ZOOM_LEVEL_POINT && $('#AtlasPoint').hasClass('active')){

                        var legendblock = $("div.info");
                        map.removeLayer(currentLayer);
                        legendblock.attr("hidden", "true");


                          years = mySlider.getValue();
                          yearMin = years[0];
                          yearMax = years[1];

                        displayMarkerLayerFicheEspece(observations.point, yearMin, yearMax);
                        activeMode = "Point";
                      }

                      if (activeMode != "Maille" && map.getZoom() <= configuration.ZOOM_LEVEL_POINT -1  && $('#AtlasPoint').hasClass('active')){
                        // display legend
                        var legendblock = $("div.info");
                        map.removeLayer(currentLayer);

                        legendblock.removeAttr( "hidden" );

                          years = mySlider.getValue();
                          yearMin = years[0];
                          yearMax = years[1];
                        displayMailleLayerFicheEspece(observations.maille, yearMin, yearMax);
                        activeMode = "Maille"
                      }

                      });


              // if not display Maille
              }else {
                  if($('#AtlasPoint').hasClass('active')){
                      // Slider event
                      mySlider.on("change",function(){
                          years = mySlider.getValue();
                          yearMin = years[0];
                          yearMax = years[1];


                          map.removeLayer(currentLayer);
                          displayMarkerLayerFicheEspece(observations.point, yearMin, yearMax);
                          nbObs=0;
                          myGeoJson.features.forEach(function(l){
                            nbObs += l.properties.nb_observations
                          })

                          $("#nbObs").html("Nombre d'observation(s): "+ nbObs);
                         });
                  }

              }

        })//ajax done



        }
        return switcherPointContainer;
      }


  });




  if(configuration.AFFICHAGE_ATLAS_MAILLE_COMMUNALE){
    map.addControl(new SwitcherCommControl());
  }
  if(configuration.AFFICHAGE_ATLAS_MAILLE_CARREE){
    map.addControl(new SwitcherMailleControl());
  }
  if(configuration.AFFICHAGE_ATLAS_POINT){
    map.addControl(new SwitcherPointControl());
  }


}