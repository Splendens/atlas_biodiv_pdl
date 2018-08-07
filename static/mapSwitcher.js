var map = generateMap();
generateSliderOnMap();
generateSwitcherOnMap();
var legend = L.control({position: 'bottomright'});

// Legende

htmlLegend = "<i style='border: solid "+configuration.MAP.BORDERS_WEIGHT+"px "+configuration.MAP.BORDERS_COLOR+";'> &nbsp; &nbsp; &nbsp;</i> Limite des "+ configuration.STRUCTURE;
generateLegende(htmlLegend);

// Layer display on window ready

/*GLOBAL VARIABLE*/

// Current observation Layer: leaflet layer type
var currentLayer; 

// Current observation geoJson:  type object
var myGeoJson;

var compteurLegend = 0; // counter to not put the legend each time

var $loader = $('#loadingGif').attr('src', configuration.URL_APPLICATION+'/static/images/loading.svg');



//display une première couche sur la carte avec switcher: mailles carrées pour 3 et 6, points pour 5 et 7
if(configuration.AFFICHAGE_ATLAS == 3 || configuration.AFFICHAGE_ATLAS == 6){

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
            if (observations.maille.length > 10) {
               displayMailleLayerFicheEspece(observations.maille, taxonYearMin, YEARMAX);
               mailleBoolean = true;
            }
            else {
              displayMarkerLayerFicheEspece(observations.point, taxonYearMin, YEARMAX);
            }
            
            if (mailleBoolean){
              // Slider event
                  mySlider.on("change",function(){
                      years = mySlider.getValue();
                      yearMin = years[0];
                      yearMax = years[1];


                      map.removeLayer(currentLayer);
                      if(map.getZoom() >= configuration.ZOOM_LEVEL_POINT){
                        displayMarkerLayerFicheEspece(observations.point, yearMin, yearMax);
                      }else{
                        displayMailleLayerFicheEspece(observations.maille, yearMin, yearMax)
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
                    if (activeMode != "Point" && map.getZoom() >= configuration.ZOOM_LEVEL_POINT ){
                      var legendblock = $("div.info");
                      map.removeLayer(currentLayer);
                      legendblock.attr("hidden", "true");


                        years = mySlider.getValue();
                        yearMin = years[0];
                        yearMax = years[1];

                      displayMarkerLayerFicheEspece(observations.point, yearMin, yearMax);
                      activeMode = "Point";
                    }
                    if (activeMode != "Maille" && map.getZoom() <= configuration.ZOOM_LEVEL_POINT -1 ){
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

        })



}




// ajout d'un contrôle pour changer le type d'analyse (mailles / communes / points)
var mySwitcher;
function generateSwitcherOnMap(){
//*******MAILLESCOMMUNALES********
    var SwitcherCommControl = L.Control.extend({

      options: {
        position: 'topright' 
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
        $(switcherCommContainer).attr("data-placement", "bottom");
        $(switcherCommContainer).attr("data-toggle", "tooltip");
        $(switcherCommContainer).attr("data-original-title", "Atlas par mailles communales");
        $(switcherCommContainer).css("margin-right", "50px"); 


        switcherCommContainer.onclick = function(){
              map.removeLayer(currentLayer);
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
        position: 'topright' 
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
        $(switcherMailleContainer).attr("data-placement", "bottom");
        $(switcherMailleContainer).attr("data-toggle", "tooltip");
        $(switcherMailleContainer).attr("data-original-title", "Atlas par mailles régulières 5x5km");
        $(switcherMailleContainer).css("margin-right", "50px"); 


        switcherMailleContainer.onclick = function(){
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
        position: 'topright' 
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
        $(switcherPointContainer).attr("data-placement", "bottom");
        $(switcherPointContainer).attr("data-toggle", "tooltip");
        $(switcherPointContainer).attr("data-original-title", "Localisation précise des observations");
        $(switcherPointContainer).css("margin-right", "50px"); 


        switcherPointContainer.onclick = function(){
              map.removeLayer(currentLayer);
              var legendblock = $("div.info");
              legendblock.attr("hidden", "true");

              $.ajax({
                url: configuration.URL_APPLICATION+'/api/observationsMailleAndPoint/'+cd_ref, 
                dataType: "json",
                beforeSend: function(){
                   $loader.show();        }
                }).done(function(observations) {
                    $loader.hide();
              
                    //display nb observations
                    if(map.getZoom() >= configuration.ZOOM_LEVEL_POINT && observations.maille.length > 10){
                          mailleBoolean = true;
                          displayMarkerLayerFicheEspece(observations.point, yearMin, yearMax);
                    }else{
                          displayMailleLayerFicheEspece(observations.maille, yearMin, yearMax)
                    }
              
                                  
                  if (mailleBoolean){
                    // Slider event
                        mySlider.on("change",function(){
                            years = mySlider.getValue();
                            yearMin = years[0];
                            yearMax = years[1];
              
              
                            map.removeLayer(currentLayer);
                            if(map.getZoom() >= configuration.ZOOM_LEVEL_POINT){
                              displayMarkerLayerFicheEspece(observations.point, yearMin, yearMax);
                            }else{
                              displayMailleLayerFicheEspece(observations.maille, yearMin, yearMax)
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
                          if (activeMode != "Point" && map.getZoom() >= configuration.ZOOM_LEVEL_POINT ){
                            var legendblock = $("div.info");
                            map.removeLayer(currentLayer);
                            legendblock.attr("hidden", "true");
              
              
                              years = mySlider.getValue();
                              yearMin = years[0];
                              yearMax = years[1];
              
                            displayMarkerLayerFicheEspece(observations.point, yearMin, yearMax);
                            activeMode = "Point";
                          }
                          if (activeMode != "Maille" && map.getZoom() <= configuration.ZOOM_LEVEL_POINT -1 ){
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
              
              });




        }

        return switcherPointContainer;
      }


  });


  if(configuration.AFFICHAGE_ATLAS == 3 || configuration.AFFICHAGE_ATLAS == 5 || configuration.AFFICHAGE_ATLAS == 6){
          if(configuration.AFFICHAGE_ATLAS == 3){
               map.addControl(new SwitcherMailleControl());
               map.addControl(new SwitcherPointControl());
          }else{
               if(configuration.AFFICHAGE_ATLAS == 5){
                  map.addControl(new SwitcherCommControl());
                  map.addControl(new SwitcherPointControl());
                  
                }else{
                  map.addControl(new SwitcherCommControl());
                  map.addControl(new SwitcherMailleControl());
                }
          }
  }else{
          map.addControl(new SwitcherCommControl());
          map.addControl(new SwitcherMailleControl());
          map.addControl(new SwitcherPointControl());
  }


}