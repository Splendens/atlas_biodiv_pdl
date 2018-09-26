var map = generateMap();

if (configuration.PRESSION_PROSPECTION){
	generateSliderOnMap();
}

var legend = L.control({position: 'bottomright'});


// Current observation Layer: leaflet layer type
var currentLayer; 

// Current observation geoJson:  type object
var myGeoJson;


// Diplay limit of the territory
var communeLayer = L.geoJson(communeGeoJson, {
	style : function(){
		return {
			fillColor: 'blue',
			opacity: 1,
			weight: 3,
			color: 'black',
			dashArray: '3',
			fillOpacity: 0
		}
	}
}).addTo(map);

var bounds = L.latLngBounds([]);
var layerBounds = communeLayer.getBounds();
bounds.extend(layerBounds);
map.fitBounds(bounds);




// Generate legends and check configuration to choose which to display (Maille ou Point)




if (configuration.PRESSION_PROSPECTION){
	htmlLegend = "<i style='border: solid 2px black; background-color: #dfd692;'> &nbsp; &nbsp; &nbsp;</i> Maille comportant au moins une observation <br> <br>" +
						"<i style='border-style: dotted;'> &nbsp; &nbsp; &nbsp;</i> Limite de la commune <br> <br>"+
						"<i style='border: solid "+configuration.MAP.BORDERS_WEIGHT+"px "+configuration.MAP.BORDERS_COLOR+";'> &nbsp; &nbsp; &nbsp;</i> Limite des "+configuration.STRUCTURE+"<br> <br>"+
						"<i style='border: solid "+configuration.MAP.BORDERS_DPT_WEIGHT+"px "+configuration.MAP.BORDERS_DPT_COLOR+";'> &nbsp; &nbsp; &nbsp;</i> Limites départementales";

	generateLegende(htmlLegend);

} else {

	htmlLegendMaille = "<i style='border: solid 1px red;'> &nbsp; &nbsp; &nbsp;</i> Maille comportant au moins une observation <br> <br>" +
						"<i style='border-style: dotted;'> &nbsp; &nbsp; &nbsp;</i> Limite de la commune <br> <br>"+
						"<i style='border: solid "+configuration.MAP.BORDERS_WEIGHT+"px "+configuration.MAP.BORDERS_COLOR+";'> &nbsp; &nbsp; &nbsp;</i> Limite des "+configuration.STRUCTURE+
						"<i style='border: solid "+configuration.MAP.BORDERS_DPT_WEIGHT+"px "+configuration.MAP.BORDERS_DPT_COLOR+";'> &nbsp; &nbsp; &nbsp;</i> Limites départementales";


	htmlLegendPoint = "<i style='border-style: dotted;'> &nbsp; &nbsp; &nbsp;</i> Limite de la commune <br> <br>"+
						"<i style='border: solid "+configuration.MAP.BORDERS_WEIGHT+"px "+configuration.MAP.BORDERS_COLOR+";'> &nbsp; &nbsp; &nbsp;</i> Limite des "+configuration.STRUCTURE+
						"<i style='border: solid "+configuration.MAP.BORDERS_DPT_WEIGHT+"px "+configuration.MAP.BORDERS_DPT_COLOR+";'> &nbsp; &nbsp; &nbsp;</i> Limites départementales";


	htmlLegend = configuration.AFFICHAGE_MAILLE ? htmlLegendMaille : htmlLegendPoint;

	generateLegende(htmlLegend);
}



if (configuration.PRESSION_PROSPECTION){
	var compteurLegend = 0; // compteur pour ne pas rajouter la légende à chaque fois

	$.ajax({
	  url: configuration.URL_APPLICATION+'/api/pressionProspectionCommune/'+insee, 
	  dataType: "json",
	  beforeSend: function(){
	    $('#loadingGif').attr('src', configuration.URL_APPLICATION+'/static/images/loading.svg')
	  }
	  }).done(function(observations) {
	    $('#loadingGif').hide();

	    // affichage des mailles
	    displayMaillePressionProspectionCommuneLayer(observations, taxonYearMin, YEARMAX);

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
	          displayMaillePressionProspectionCommuneLayer(observations, yearMin, yearMax)


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
	      var year = new Date('1500-01-01');


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

  	function openFicheEspece(cd_ref){
        $('#myTable tbody').on('click', '.taxonRow', function () {
			cdref=($(this).attr('cdRef'));
	    	window.open(configuration.URL_APPLICATION+'/espece/'+cdref,'_blank');
		});
	};
	$(document).ready(function(){
	    openFicheEspece();
	});

}else{
	// Display the 'x' last observations
		// MAILLE
	if (configuration.AFFICHAGE_MAILLE){
		displayMailleLayerLastObs(observations)
	}
		// POINT
	else{
		displayMarkerLayerPointLastObs(observations);

	}


	// display observation on click
	function displayObsTaxon(insee, cd_ref){
		$.ajax({
	      url: configuration.URL_APPLICATION+'/api/observations/'+insee+'/'+cd_ref, 
	      dataType: "json",
	        beforeSend: function(){
	            $('#loadingGif').show();
	            $('#loadingGif').attr("src", configuration.URL_APPLICATION+'/static/images/loading.svg');
	        }
		}).done(function(observations){
			$('#loadingGif').hide();
			map.removeLayer(currentLayer);
			if(configuration.AFFICHAGE_MAILLE){
				
			}else {
				displayMarkerLayerPointCommune(observations);
			}


		});
	};

	function displayObsTaxonMaille(insee, cd_ref){
		$.ajax({
		  url: configuration.URL_APPLICATION+'/api/observationsMaille/'+insee+'/'+cd_ref, 
		  dataType: "json",
		  beforeSend: function(){
		  	$('#loadingGif').show();
		    $('#loadingGif').attr("src", configuration.URL_APPLICATION+'/static/images/loading.svg');
	  	}
		}).done(function(observations){
			$('#loadingGif').hide();
			map.removeLayer(currentLayer);
			displayMailleLayerCommune(observations);
		});
	};

	function refreshObsCommune(){
	    if(configuration.MYTYPE == 1){
	        $('#myTable tbody').on('click', '.taxonRow', function () {
				$(this).siblings().removeClass('current');
			    $(this).addClass('current');
	            
				if(configuration.AFFICHAGE_MAILLE){
					displayObsTaxonMaille($(this).attr('insee'), $(this).attr('cdRef'));
				}else{
					displayObsTaxon($(this).attr('insee'), $(this).attr('cdRef'));
				}
				var name = ($(this).find('.name').html());
				$('#titleMap').fadeOut(500, function(){
					$(this).html("Observations du taxon:"+ name).fadeIn(500);
				})
			});
	    }
	};

	$('#myTable').on( 'page.dt', function (){
	    refreshObsCommune();
	});
	$(document).ready(function(){
		$('#loadingGif').hide();
	    refreshObsCommune();
	});

}