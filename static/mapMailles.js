var map = generateMap();
if (configuration.GROS_JEU_DONNEES == false){
    generateSliderOnMap()
};
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

var compteurLegend = 0; // compteur pour ne pas rajouter la légende à chaque fois

$.ajax({
  url: configuration.URL_APPLICATION+'/api/observationsMaille/'+cd_ref, 
  dataType: "json",
  beforeSend: function(){
    $('#loadingGif').attr('src', configuration.URL_APPLICATION+'/static/images/loading.svg')
  }
  }).done(function(observations) {
    $('#loadingGif').hide();

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
   

      if (configuration.GROS_JEU_DONNEES == false){
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
    }


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

