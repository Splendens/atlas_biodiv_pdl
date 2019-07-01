function generateMap() {

    // Map initialization
    firstMapTile = L.tileLayer(configuration.MAP.FIRST_MAP.url, {attribution : configuration.MAP.FIRST_MAP.attribution} );
    orthoMap =  L.tileLayer(configuration.MAP.SECOND_MAP.url, {attribution: configuration.MAP.SECOND_MAP.attribution});

    baseMap = {};
    baseMap[configuration.MAP.FIRST_MAP.tileName]=firstMapTile;


    var map = L.map('map',{
      crs: L.CRS.EPSG3857,
      center: configuration.MAP.LAT_LONG, 
      geosearch: true,
      zoom: configuration.MAP.ZOOM,
      layers : [firstMapTile],
      fullscreenControl: true,
      });

    // Style of territory on map
    territoryStyle = {
      fill: false,
      color: configuration.MAP.BORDERS_COLOR,
      weight: configuration.MAP.BORDERS_WEIGHT
    }

    // Style of territory departement on map
    territoryDptStyle = {
      fill: false,
      color: configuration.MAP.BORDERS_DPT_COLOR,
      weight: configuration.MAP.BORDERS_DPT_WEIGHT
    }

     // Add limits of the territory to the map
     $(document).ready(function()
          {
              $.getJSON(url_limit_territory, function(json) {
                  L.geoJson(json, {
                  	style: territoryStyle
                  }).addTo(map);
              });
          });

     // Add limits of the territory departement to the map
     $(document).ready(function()
          {
              $.getJSON(url_limit_dpt_territory, function(json) {
                  L.geoJson(json, {
                    style: territoryDptStyle
                  }).addTo(map);
              });
          });

     // 'Google-like' baseLayer controler

    var LayerControl = L.Control.extend({

      options: {
        position: 'bottomleft' 
      },

      onAdd: function (map) { 
        currentTileMap = "earth"; 
        var container = L.DomUtil.create('div', 'leaflet-bar leaflet-control leaflet-control-custom');
     
        container.style.backgroundColor = 'white';
        container.style.backgroundImage = "url("+configuration.URL_APPLICATION+"/static/images/logo_topo_map.PNG)";
        container.style.width = '50px';
        container.style.height = '50px';
        container.style.border = 'solid white 1px';
        container.style.cursor = 'pointer';
        $(container).attr("data-placement", "right");
        $(container).attr("data-toggle", "tooltip");
        $(container).attr("data-original-title", "Plan");


        container.onclick = function(){
          if(currentTileMap == "earth"){ 
          container.style.backgroundImage = "url("+configuration.URL_APPLICATION+"/static/images/logo_earth_map.PNG)"; 
          $(container).attr("data-original-title", "Photos aérienne");
          map.removeLayer(firstMapTile);
          orthoMap.addTo(map);
          currentTileMap = "topo";
          }
          else{
          container.style.backgroundImage = "url("+configuration.URL_APPLICATION+"/static/images/logo_topo_map.PNG)";
          $(container).attr("data-original-title", "Plan");
          map.removeLayer(orthoMap);
          firstMapTile.addTo(map);
          currentTileMap = "earth"; 
          }
        }
        return container;
      }
    });

    map.addControl(new LayerControl());

    // add tooltip on fullScreen button

    fullScreenButton = $(".leaflet-control-fullscreen");
    fullScreenButton.attr("data-placement", "right");
    fullScreenButton.attr("data-toggle", "tooltip");
    fullScreenButton.attr("data-original-title", "Plein écran");
    $('.leaflet-control-fullscreen-button').removeAttr('title');

    

    return map
}



//****** Fonction fiche espèce ***********

// Popup Point
function onEachFeaturePoint(feature, layer){
    popupContent = "<b>Date: </b>"+ feature.properties.dateobsPopup+"</br><b>Altitude: </b>"+ feature.properties.altitude_retenue+
                "</br><b>Observateur(s): </b>"+ feature.properties.observateurs;

    // verifie si on doit afficher les organismes ou non
    if(configuration.AFFICHAGE_ORGAS_OBS_FICHEESP){      
      popupContent=popupContent+"</br> <b> Provenance: </b>" + feature.properties.orga_obs + " ";
    }

   // verifie si le champs effectif est rempli
    if(feature.properties.effectif_total != undefined){
      popupContent=popupContent+"</br><b>Effectif: </b>"+ feature.properties.effectif_total;
    }        

    layer.bindPopup(popupContent)
}

// Popup Maille
function onEachFeatureMaille(feature, layer){

   popupContent = "<b>Nombre d'observation(s): </b>" + feature.properties.nb_observations;

    // verifie si on doit afficher les organismes ou non
    if(configuration.AFFICHAGE_ORGAS_OBS_FICHEESP){      
      popupContent=popupContent+"</br> <b> Provenance: </b>" + feature.properties.orga_obs + " ";
    }

    popupContent=popupContent+"</br> <b> Dernière observation: </b>" + feature.properties.last_observation + " ";

    layer.bindPopup(popupContent)
}


// Popup Maille Communale
function onEachFeatureMailleCommunale(feature, layer){

   popupContent="<b>Commune: </b><a href = '" + configuration.URL_APPLICATION + "/commune/" + feature.properties.id_maille +"'>"  + feature.properties.nom_com + "</a> ";
     
   popupContent =popupContent+"</br><b>Nombre d'observation(s): </b>" + feature.properties.nb_observations;

    // verifie si on doit afficher les organismes ou non
    if(configuration.AFFICHAGE_ORGAS_OBS_FICHEESP){      
      popupContent=popupContent+"</br> <b> Provenance: </b>" + feature.properties.orga_obs + " ";
    }

    popupContent=popupContent+"</br> <b> Dernière observation: </b>" + feature.properties.last_observation + " ";

    layer.bindPopup(popupContent)
}



// Style maille
function getColor(d) {
    return d > 10000 ? '#800026' :
           d > 5000  ? '#BD0026' :
           d > 1000  ? '#E31A1C' :
           d > 500   ? '#FC4E2A' :
           d > 100   ? '#FD8D3C' :
           d > 50    ? '#FEB24C' :
           d > 10    ? '#FED976' :
                      '#FFEDA0';
}

function styleMaille(feature) {
    return {
        fillColor: getColor(feature.properties.nb_observations),
        weight: 2,
        color: 'black',
        fillOpacity: 0.8
    };
}


function generateLegendMaille(){
    legend.onAdd = function (map) {

        var div = L.DomUtil.create('div', 'info legend'),
            grades = [1, 10, 50, 100, 500, 1000, 5000, 10000],
            labels = ["<strong> Nombre <br> d'observations </strong> <br>"];

        // loop through our density intervals and generate a label with a colored square for each interval
        for (var i = 0; i < grades.length; i++) {
            labels.push(
                '<i style="background:' + getColor(grades[i] + 1) + '"></i> ' +
                grades[i] + (grades[i + 1] ? '&ndash;' + grades[i + 1] + '<br>' : '+'));
        }
        div.innerHTML = labels.join('<br>');

        return div;
    };

    legend.addTo(map);
}





// Geojson Maille
function generateGeojsonMaille(observations, yearMin, yearMax) {

  var i=0;
  myGeoJson = {'type': 'FeatureCollection',
             'features' : []
          }
  tabProperties =[]
  while (i<observations.length){
    if(observations[i].annee >= yearMin && observations[i].annee <= yearMax ) {
      geometry = observations[i].geojson_maille;
      idMaille = observations[i].id_maille;
      properties = {
        id_maille : idMaille, 
        nb_observations : observations[i].nb_observations, 
        orga_obs: observations[i].orga_obs, 
        last_observation: observations[i].annee, 
        tabDateobs: [new Date(observations[i].dateobs)]
      };
      var j = i+1;
      while (j<observations.length && observations[j].id_maille <= idMaille){
        if(observations[j].annee >= yearMin && observations[j].annee <= yearMax ){
          properties.nb_observations +=  observations[j].nb_observations;
          properties.tabDateobs.push(new Date(observations[i].dateobs));
        }
        if (observations[j].annee >=  properties.last_observation){
          properties.last_observation = observations[j].annee
        }
        if (!properties.orga_obs.includes(observations[j].orga_obs)) {
          properties.orga_obs += (' <br/> ' + observations[j].orga_obs)
        }
        j = j+1
      }
      myGeoJson.features.push({
          'type' : 'Feature',
          'properties' : properties,
          'geometry' : geometry   
      })
      // on avance jusqu' à j 
      i = j  ;
    }
    else {
      i = i+1;
    }
  }

  return myGeoJson
}

// Geojson Maille Communale
function generateGeojsonMailleCommunale(observations, yearMin, yearMax) {

  var i=0;
  myGeoJson = {'type': 'FeatureCollection',
             'features' : []
          }
  tabProperties =[]
  while (i<observations.length){
    if(observations[i].annee >= yearMin && observations[i].annee <= yearMax ) {
      geometry = observations[i].geojson_maille;
      idMaille = observations[i].id_maille;
      properties = {
        id_maille : idMaille, 
        nom_com : observations[i].nom_com, 
        nb_observations : observations[i].nb_observations, 
        orga_obs: observations[i].orga_obs, 
        last_observation: observations[i].annee, 
        tabDateobs: [new Date(observations[i].dateobs)]
      };
      var j = i+1;
      while (j<observations.length && observations[j].id_maille <= idMaille){
        if(observations[j].annee >= yearMin && observations[j].annee <= yearMax ){
          properties.nb_observations +=  observations[j].nb_observations;
          properties.tabDateobs.push(new Date(observations[i].dateobs));
        }
        if (observations[j].annee >=  properties.last_observation){
          properties.last_observation = observations[j].annee
        }
        if (!properties.orga_obs.includes(observations[j].orga_obs)) {
          properties.orga_obs += (' <br/> ' + observations[j].orga_obs)
        }
        j = j+1
      }
      myGeoJson.features.push({
          'type' : 'Feature',
          'properties' : properties,
          'geometry' : geometry   
      })
      // on avance jusqu' à j 
      i = j  ;
    }
    else {
      i = i+1;
    }
  }

  return myGeoJson
}



// Display Maille layer

function displayMailleLayerFicheEspece(observationsMaille, yearMin, yearMax){
  myGeoJson = generateGeojsonMaille(observationsMaille, yearMin, yearMax);
  currentLayer = L.geoJson(myGeoJson, {
      onEachFeature : onEachFeatureMaille,
      style: styleMaille,
  });
  currentLayer.addTo(map);

  // ajout de la légende
  generateLegendMaille();
}



// Display Maille Communale layer

function displayMailleCommunaleLayerFicheEspece(observationsMaille, yearMin, yearMax){
  myGeoJson = generateGeojsonMailleCommunale(observationsMaille, yearMin, yearMax);
  currentLayer = L.geoJson(myGeoJson, {
      onEachFeature : onEachFeatureMailleCommunale,
      style: styleMaille,
  });
  currentLayer.addTo(map);

  // ajout de la légende
  generateLegendMaille();
}





function generateGeojsonMailleCommune(observations){
   var i=0;
  myGeoJson = {'type': 'FeatureCollection',
             'features' : []
          }
  tabProperties =[]
  while (i<observations.length){
      geometry = observations[i].geojson_maille;
      idMaille = observations[i].id_maille;
      properties = {
        id_maille : idMaille, 
        nb_observations: observations[i].nb_observations, 
        last_observation: observations[i].annee
      };
      var j = i+1;
      while (j<observations.length && observations[j].id_maille <= idMaille){
          properties.nb_observations +=  observations[j].nb_observations;
        
        if (observations[j].annee >=  properties.last_observation){
          properties.last_observation = observations[j].annee
        }
        j = j+1
      }
      myGeoJson.features.push({
          'type' : 'Feature',
          'properties' : properties,
          'geometry' : geometry   
      })
      // on avance jusqu' à j 
      i = j  ;
    }

  return myGeoJson
}

function displayMailleLayerCommune(observations){
  myGeoJson = generateGeojsonMailleCommune(observations);
  currentLayer = L.geoJson(myGeoJson, {
      onEachFeature : onEachFeatureMaille,
      style: styleMaille,
  });
  currentLayer.addTo(map);

  // ajout de la légende
  generateLegendMaille();

}


// GeoJson Point
function generateGeojsonPointFicheEspece(observationsPoint, yearMin, yearMax){
    myGeoJson = {'type': 'FeatureCollection','features' : []}
    observationsPoint.forEach(function(obs){
        if(obs.year >= yearMin && obs.year <= yearMax ) {
            properties = obs;
            properties['dateobsCompare'] = new Date(obs.dateobs);
            properties['dateobsPopup'] = obs.dateobs;
            properties['nb_observations'] =1;
            myGeoJson.features.push({
              'type' : 'Feature',
              'properties' : properties,
              'geometry' : obs.geojson_point   
            });
        } 
    });
    return myGeoJson
}

// Display marker Layer (cluster or not)
function displayMarkerLayerFicheEspece(observationsPoint, yearMin, yearMax){

  myGeojson = generateGeojsonPointFicheEspece(observationsPoint, yearMin, yearMax);

  if (typeof pointDisplayOptionsFicheEspece == 'undefined') {
    pointDisplayOptionsFicheEspece = function(feature) {
      return {};
    }
  }
  currentLayer = L.geoJson(myGeojson, {
          onEachFeature : onEachFeaturePoint,
          
          pointToLayer: function (feature, latlng) {
            return L.circleMarker(latlng, pointDisplayOptionsFicheEspece(feature));
          }
  });
  if (myGeojson.features.length > configuration.LIMIT_CLUSTER_POINT) {
      newLayer = currentLayer;
      currentLayer = L.markerClusterGroup();
      currentLayer.addLayer(newLayer);
      map.addLayer(currentLayer)

  }
  else {
    currentLayer.addTo(map);
  }
  
  if (typeof divLegendeFicheEspece !== 'undefined') {
    legend.onAdd = function (map) {
        var div =  L.DomUtil.create('div', 'info legend');
        div.innerHTML = divLegendeFicheEspece;
        return div;
    };
    legend.addTo(map);
  }
}



// ***************Fonction lastObservations de mapCommune*****************


/* *** Maille pression de prospection *** */
function generateGeojsonMaillePressionProspectionCommune(observations, yearMin, yearMax) {

  var i=0;
  myGeoJson = {'type': 'FeatureCollection',
             'features' : []
          }
  tabProperties =[]
  while (i<observations.length){
    if(observations[i].annee >= yearMin && observations[i].annee <= yearMax ) {
      geometry = observations[i].geojson_maille;
      idMaille = observations[i].id_maille;
      properties = {
        id_maille : idMaille, 
        nom_com : observations[i].nom_com, 
        nb_observations: observations[i].nb_observations, 
        orga_obs: observations[i].orga_obs, 
        last_observation: observations[i].annee, 
        tabDateobs: [new Date(observations[i].dateobs)]
      };
      var j = i+1;
      while (j<observations.length && observations[j].id_maille <= idMaille){
        if(observations[j].annee >= yearMin && observations[j].annee <= yearMax ){
          properties.nb_observations += observations[j].nb_observations;
          properties.tabDateobs.push(new Date(observations[i].dateobs));
        }
        if (observations[j].annee >= properties.last_observation){
          properties.last_observation = observations[j].annee
        }
        if (!properties.orga_obs.includes(observations[j].orga_obs)) {
          properties.orga_obs += (' <br/> ' + observations[j].orga_obs)
        }
        j = j+1
      }
      myGeoJson.features.push({
          'type' : 'Feature',
          'properties' : properties,
          'geometry' : geometry   
      })
      // on avance jusqu' à j 
      i = j  ;
    }
    else {
      i = i+1;
    }
  }

  return myGeoJson
}



function generateGeojsonMaillePressionProspectionMailleCommunale(observations, yearMin, yearMax) {

  var i=0;
  myGeoJson = {'type': 'FeatureCollection',
             'features' : []
          }
  tabProperties =[]
  while (i<observations.length){
    if(observations[i].annee >= yearMin && observations[i].annee <= yearMax ) {
      geometry = observations[i].geojson_maille;
      idMaille = observations[i].id_maille;
      properties = {
        id_maille : idMaille, 
        nom_com : observations[i].nom_com, 
        nb_observations : observations[i].nb_observations,
        orga_obs: observations[i].orga_obs, 
        last_observation: observations[i].annee, 
        tabDateobs: [new Date(observations[i].dateobs)]
      };
      var j = i+1;
      while (j<observations.length && observations[j].id_maille <= idMaille){
        if(observations[j].annee >= yearMin && observations[j].annee <= yearMax ){
          properties.nb_observations +=  observations[j].nb_observations;
          properties.tabDateobs.push(new Date(observations[i].dateobs));
        }
        if (observations[j].annee >=  properties.last_observation){
          properties.last_observation = observations[j].annee
        }
        if (!properties.orga_obs.includes(observations[j].orga_obs)) {
          properties.orga_obs += (' <br/> ' + observations[j].orga_obs)
        }
        j = j+1
      }
      myGeoJson.features.push({
          'type' : 'Feature',
          'properties' : properties,
          'geometry' : geometry   
      })
      // on avance jusqu' à j 
      i = j  ;
    }
    else {
      i = i+1;
    }
  }

  return myGeoJson
}

// Popup pression prospection 
function onEachFeatureMaillePressionProspectionCommune(feature, layer){

   popupContent ="<b>Nombre d'observation(s): </b>" + feature.properties.nb_observations;

    // verifie si on doit afficher les organismes ou non
    if(configuration.AFFICHAGE_ORGAS_OBS_FICHECOMM){      
      popupContent=popupContent+"</br> <b> Provenance: </b>" + feature.properties.orga_obs + " ";
    }

    popupContent=popupContent+"</br> <b> Dernière observation: </b>" + feature.properties.last_observation + " ";

    layer.bindPopup(popupContent)
}

// Popup pression prospection  Maille Communale
function onEachFeaturePressionProspectionMailleCommunale(feature, layer){

   popupContent="<b>Commune: </b><a href = '" + configuration.URL_APPLICATION + "/commune/" + feature.properties.id_maille +"'>"  + feature.properties.nom_com + "</a> ";
     
   popupContent =popupContent+"</br><b>Nombre d'observation(s): </b>" + feature.properties.nb_observations;

    // verifie si on doit afficher les organismes ou non
    if(configuration.AFFICHAGE_ORGAS_OBS_FICHECOMM){      
      popupContent=popupContent+"</br> <b> Provenance: </b>" + feature.properties.orga_obs + " ";
    }

    popupContent=popupContent+"</br> <b> Dernière observation: </b>" + feature.properties.last_observation + " ";

    layer.bindPopup(popupContent)
}

function displayMaillePressionProspectionCommuneLayer(observationsMaille, yearMin, yearMax){
  myGeoJson = generateGeojsonMaillePressionProspectionCommune(observationsMaille, yearMin, yearMax);
  currentLayer = L.geoJson(myGeoJson, {
      onEachFeature : onEachFeatureMaillePressionProspectionCommune,
      style: styleMaille,
  });
  currentLayer.addTo(map);

  // ajout de la légende
  generateLegendMaille();
}

function displayMaillePressionProspectionMailleCommunaleLayer(observationsMaille, yearMin, yearMax){
  myGeoJson = generateGeojsonMaillePressionProspectionMailleCommunale(observationsMaille, yearMin, yearMax);
  currentLayer = L.geoJson(myGeoJson, {
      onEachFeature : onEachFeaturePressionProspectionMailleCommunale,
      style: styleMaille,
  });
  currentLayer.addTo(map);

  // ajout de la légende
  generateLegendMaille();
}




  /* *** Point ****/

function onEachFeaturePointLastObs(feature, layer){
    popupContent = "<b>Espèce: </b>"+ feature.properties.taxon+
                "</br><b>Date: </b>"+ feature.properties.dateobs;

    // verifie s'il y a une altitude renseignée
    if(feature.properties.altitude_retenue != undefined){
      popupContent=popupContent+"</br><b>Altitude: </b>"+ feature.properties.altitude_retenue;
    }else{
      popupContent=popupContent+"</br><b>Altitude: </b>non renseignée";
    }        

    // verifie si on doit afficher les organismes ou non
    if(configuration.AFFICHAGE_ORGAS_OBS_FICHECOMM){      
      popupContent = popupContent + "</br> <b> Provenance: </b>" + feature.properties.orga_obs + " ";
    }
 
    layer.bindPopup(popupContent + "</br> <a href='"+ configuration.URL_APPLICATION+"/espece/"+feature.properties.cd_ref+"'> Fiche espèce </a>")
}

function onEachFeaturePointCommune(feature, layer){
    popupContent = "<b>Espèce: </b>"+ feature.properties.taxon+
                "</br><b>Date: </b>"+ feature.properties.dateobs+"</br><b>Altitude: </b>"+ 
                feature.properties.altitude_retenue+
                "</br><b> Observateurs(s): </b>"+ feature.properties.observateurs;

    layer.bindPopup(popupContent + "</br> <a href='"+ configuration.URL_APPLICATION+"/espece/"+feature.properties.cd_ref+"'> Fiche espèce </a>")
}

function generateGeojsonPointLastObs(observationsPoint){
    myGeoJson = {'type': 'FeatureCollection','features' : []}

      observationsPoint.forEach(function(obs){
          properties = obs;
          properties['dateobsCompare'] = new Date(obs.dateobs);
          properties['dateobsPopup'] = obs.dateobs;
          properties['nb_observations'] =1;
          myGeoJson.features.push({
            'type' : 'Feature',
            'properties' : properties,
            'geometry' : obs.geojson_point   
          });
          myGeoJson.features.push({
            'type' : 'Feature',
            'properties' : properties,
            'geometry' :  obs.geojson_point   
          })
      });
  return myGeoJson
}


function displayMarkerLayerPointLastObs(observationsPoint){
  myGeojson = generateGeojsonPointLastObs(observationsPoint);
  if (typeof pointDisplayOptionsFicheCommuneHome == 'undefined') {
    pointDisplayOptionsFicheCommuneHome = function(feature) {
      return {};
    }
  }

  currentLayer = L.geoJson(myGeojson, {
      onEachFeature : onEachFeaturePointLastObs,
      pointToLayer: function (feature, latlng) {
          return L.circleMarker(latlng, pointDisplayOptionsFicheCommuneHome(feature));
      }
  });

  map.addLayer(currentLayer);
  if (typeof divLegendeFicheCommuneHome !== 'undefined') {
    legend.onAdd = function (map) {
        var div =  L.DomUtil.create('div', 'info legend');
        div.innerHTML = divLegendeFicheCommuneHome;
        return div;
    };
    legend.addTo(map);
  }
}


function displayMarkerLayerPointCommune(observationsPoint){
    myGeojson = generateGeojsonPointLastObs(observationsPoint);
    if (typeof pointDisplayOptionsFicheCommuneHome == 'undefined') {
      pointDisplayOptionsFicheCommuneHome = function(feature) {
        return {};
      }
    }

    currentLayer = L.geoJson(myGeojson, {
        onEachFeature : onEachFeaturePointCommune,
        pointToLayer: function (feature, latlng) {
          return L.circleMarker(latlng, pointDisplayOptionsFicheCommuneHome(feature));
        }
    });

    newLayer = currentLayer;
    currentLayer = L.markerClusterGroup();
    currentLayer.addLayer(newLayer);
    map.addLayer(currentLayer);
}







//  ** MAILLE ***

function compare(a,b) {
  if (a.id_maille < b.id_maille)
    return -1;
  if (a.id_maille > b.id_maille)
    return 1;
  return 0;
}

function printEspece(tabEspece, tabCdRef){
  stringEspece = "";
  if (configuration.HOMEMAP){
  i = 0;
  while(i<tabEspece.length){
    
    stringEspece += "<li> <a href='./espece/"+tabCdRef[i]+"'>"+tabEspece[i]+"</li>";
    i=i+1;
    }
  }
    else{
      i = 0;
      while(i<tabEspece.length){
      stringEspece += "<li> <a href='../espece/"+tabCdRef[i]+"'>"+tabEspece[i]+"</li>";
      i=i+1;
    }  
  }
  return stringEspece
}



function onEachFeatureMailleLastObs(feature, layer){
    popupContent = "<b>Espèces observées dans la maille: </b> <ul> "+printEspece(feature.properties.list_taxon, feature.properties.list_cdref) + "</ul>";

        layer.bindPopup(popupContent)
      }

function styleMailleLastObs(){
    return {
        opacity: 1,
        weight: 2,
        color: 'red',
        fillOpacity: 0
    }
}


function generateGeoJsonMailleLastObs(observations) {

  var i=0;
   myGeoJson = {'type': 'FeatureCollection',
             'features' : []
          }
  while (i<observations.length){
      geometry = observations[i].geojson_maille;
      idMaille = observations[i].id_maille;
      properties = {id_maille : idMaille, list_taxon : [observations[i].taxon], list_cdref:[observations[i].cd_ref], list_id_observation: [observations[i].id_observation] };
      var j = i+1;
      while (j<observations.length && observations[j].id_maille == idMaille){
           properties.list_taxon.push(observations[j].taxon);
           properties.list_cdref.push(observations[j].cd_ref);
           properties.list_id_observation.push(observations[j].id_observation);
        j = j+1
      }
      myGeoJson.features.push({
          'type' : 'Feature',
          'properties' : properties,
          'geometry' : geometry
      })
      // on avance jusqu' à j 
      i = j ;
  }

  return myGeoJson
}


function find_id_observation_in_array(tab_id, id_observation){
  i = 0 ;
  while (i < tab_id.length && tab_id[i] != id_observation){
    i = i+1
  }
  return i != tab_id.length
}

function displayMailleLayerLastObs(observations){

      observations.sort(compare);
      var geojsonMaille = generateGeoJsonMailleLastObs(observations);
      currentLayer = L.geoJson(geojsonMaille,{onEachFeature: onEachFeatureMailleLastObs, style:styleMailleLastObs });
      currentLayer.addTo(map);

    }



// Legend 

  var legend;
  var legendActiv = false;
  var div;

function generateLegende(htmlLegend){

    // Legende

    var legendControl = L.Control.extend({

      options: {
        position: 'topleft' 
        //control position - allowed: 'topleft', 'topright', 'bottomleft', 'bottomright'
      },

    onAdd: function (map) {
        var container = L.DomUtil.create('div', 'leaflet-bar leaflet-control leaflet-control-custom');
     
        container.style.backgroundColor = 'white';
        container.style.width = '25px';
        container.style.height = '25px';
        container.style.border = 'solid white 1px';
        container.style.cursor = 'pointer';
        $(container).html("<img src='"+configuration.URL_APPLICATION+"/static/images/info.png' alt='Légende'>")
        $(container).attr("data-placement", "right");
        $(container).attr("data-toggle", "tooltip");
        $(container).attr("data-original-title", "Légende");
        
        
        container.onclick = function(){
          if (legendActiv == false){

             legend = L.control({position: 'topleft'});

              legend.onAdd = function (map) {
                  div = L.DomUtil.create('div', 'info legend'),
                  $(div).addClass("generalLegend");


                  div.innerHTML = htmlLegend;

                  return div;
              };
          legend.addTo(map);
          legendActiv = true;
        

          }else {
            legend.remove(map)
            legendActiv = false;
          }

      }
        return container;
      }
    

    });

    map.addControl(new legendControl());

  }

var mySlider;
function generateSliderOnMap(){
        var SliderControl = L.Control.extend({

      options: {
        position: 'bottomleft' 
        //control position - allowed: 'topleft', 'topright', 'bottomleft', 'bottomright'
      },

    onAdd: function (map) {
        var sliderContainer = L.DomUtil.create('div', 'leaflet-bar leaflet-control leaflet-slider-control');
     
        sliderContainer.style.backgroundColor = 'white';
        sliderContainer.style.width = '300px';
        sliderContainer.style.height = '50px';
        sliderContainer.style.border = 'solid white 1px';
        sliderContainer.style.cursor = 'pointer';
        $(sliderContainer).css("margin-bottom", "-300px");
        $(sliderContainer).css("margin-left", "200px");
        $(sliderContainer).css("text-align", "center");
        $(sliderContainer).append("<p> <span id='yearMin'> </span> <input id='sliderControl' type='text'/> <span id='yearMax'>  </span>  </p>"
                            +"<p id='nbObs'> Nombre d'observation(s): "+nb_obs+" </p>");
        L.DomEvent.disableClickPropagation(sliderContainer);
        return sliderContainer;
      }


    });

  if(typeof taxonYearMin  !== 'undefined' && typeof YEARMAX !== 'undefined'){

      map.addControl(new SliderControl());
          
          mySlider = new Slider('#sliderControl', {
          value: [taxonYearMin, YEARMAX],
          min : taxonYearMin,
          max : YEARMAX,
          step: configuration.MAP.STEP,
        });

      $("#yearMax").html("&nbsp;&nbsp;&nbsp;&nbsp;"+ YEARMAX);
      $("#yearMin").html(taxonYearMin + "&nbsp;&nbsp;&nbsp;&nbsp");
  }



}


