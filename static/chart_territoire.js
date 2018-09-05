
// Radialize the colors
Highcharts.setOptions({
  colors: Highcharts.map(Highcharts.getOptions().colors, function (color) {
    return {
      radialGradient: {
        cx: 0.5,
        cy: 0.3,
        r: 0.7
      },
      stops: [
        [0, color],
        [1, Highcharts.Color(color).brighten(-0.3).get('rgb')] // darken
      ]
    };
  })
});


var pieColors = (function () {
    var colors = [],
        base = Highcharts.getOptions().colors[0],
        i;

    for (i = 0; i < 10; i += 1) {
        // Start out with a darkened base color (negative brighten), and end
        // up with a much brighter color
        colors.push(Highcharts.Color(base).brighten((i - 3) / 7).get());
    }
    return colors;
}());



// Histogramme du nombre d'espèces par organismes/BD moissonnée
Highcharts.chart('statsorgacommGraph', {
    chart: {
        type: 'column'
    },

    credits: {
      enabled: false
    },

    title: {
      text: "Pourcentage d'espèces sur le territoire<br>par base de données",
      style : { "color": "#333333", "fontSize": "22px" }
    },
    yAxis: {
        title: {
            text: "Nombre d'espèces"
        }
    },
    xAxis: {
        categories: [
        '<b>Calluna</b><br>(CBN de Brest)', 
        '<b>SICEN</b><br>(CEN Pays de la Loire)', 
        '<b>GRETIA</b>', 
        '<b>URCPIE</b>', 
        '<b>Faune Anjou</b><br>(LPO49)', 
        '<b>Faune Loire-Atlantique</b><br>(LPO44, BV, GNLA)', 
        '<b>Faune Vendée</b><br>(LPO85)', 
        '<b>Faune Maine</b><br>(LPO72, MNE)'
        ],

        labels: {
          rotation: -45,
          style: {
              fontSize: '13px',
              fontFamily: 'Verdana, sans-serif'
          }
        }
    },

    legend: {
        enabled: false
    },

    tooltip: {
        pointFormat: "<b>{point.y:.0f} espèce(s)</b>"
    },

    plotOptions: {
      column: {
        color: "#8ac3e5",
        borderColor: "#7094db"
      },
      series: {
        minPointLength: 5
      }
    },

    series: [{
        name: 'label',
        data: statsorgacomm,
        dataLabels: {
            enabled: true,
            rotation: -90,
            color: "#333333",
            align: 'right',
            format: '{point.y:.0f}',
            y: 20, // 10 pixels down from the top
            style: {
                fontSize: '13px',
                fontFamily: 'Verdana, sans-serif'
            }
        }
    }]
});


// PieChart Répartition du nombre d'espèces par organismes/BD moissonnée
/*Highcharts.chart('statsorgacommGraph', {
  chart: {
    plotBackgroundColor: null,
    plotBorderWidth: null,
    plotShadow: false,
    type: 'pie'
  },
  credits: {
    enabled: false
  },
  title: {
    text: "Répartition du nombre d'espèces <br>selon la base de données de provenance",
    style : { "color": "#333333", "fontSize": "22px" }
  },

  tooltip: {
    headerFormat: '',
    pointFormat: '<b>{point.label}</b> <br> <b>{point.y}</b>', 
    valueSuffix: ' espèce(s) <br>({point.percentage:.1f}%)'
  },

  plotOptions: {
    pie: {
      allowPointSelect: true,
      cursor: 'pointer',
      colors: pieColors,
      borderColor: "#7094db",
      
      // style: { color: (Highcharts.theme && Highcharts.theme.contrastTextColor) || 'black' },
        
      showInLegend: false,
      
      dataLabels: {
        allowOverlap: true,
        connectorColor: "#7094db",
        enabled: true,
        format: '<b>{point.label}</b><br><b>{point.y} espèce(s)</b><br>{point.percentage:.1f} %',
        //distance: 10,
        filter: {
          property: 'percentage',
          operator: '>',
          value: 0
        },
        style : { "color": "#333333", "fontSize": "11px" }
      }

    }
  },

  series: [{
   data : statsorgacomm,
   innerSize: '30%',                
   //showInLegend:true,
   dataLabels: {
       enabled: true,
       padding: 0
   }
  }]
});
*/





// PieChart répartition du nombre de données par groupe taxonomique
Highcharts.chart('group2inpnGraph', {
  chart: {
    plotBackgroundColor: null,
    plotBorderWidth: null,
    plotShadow: false,
    type: 'pie'
    },
  credits: {
    enabled: false
  },
  title: {
    text: "Répartition du nombre de données<br> par groupe taxonomique",
    style : { "color": "#333333", "fontSize": "22px" }
  },

  tooltip: {
    headerFormat: '',
    pointFormat: '<b>{point.label}</b> <br> <b>{point.y}</b>', 
    valueSuffix: ' donnée(s) <br>({point.percentage:.2f}%)'
  },

  plotOptions: {
    pie: {
      allowPointSelect: true,
      cursor: 'pointer',
      colors: pieColors,
      borderColor: "#7094db",
      /*
       style: {
          color: (Highcharts.theme && Highcharts.theme.contrastTextColor) || 'black'
        },
        */
      showInLegend: false,
      
      dataLabels: {
        allowOverlap: true,
        connectorColor: "#7094db",
        enabled: true,
        format: '<b>{point.label}</b><br><b>{point.y} donnée(s)</b><br>{point.percentage:.2f} %',
        style : { "color": "#333333", "fontSize": "11px" },
        /*distance: 10,*/
        filter: {
          property: 'percentage',
          operator: '>',
          value: 0
        }
      }

    }
  },

  series: [{
   data : statsgroup2inpncomm,
   innerSize: '30%',                
  // showInLegend:true,
   dataLabels: {
       enabled: true,
       padding: 0
   }
  }]
});





// PieChart du répartition du nombre d'espèces par groupe taxonomique
Highcharts.chart('taxongroup2inpnGraph', {
  chart: {
    plotBackgroundColor: null,
    plotBorderWidth: null,
    plotShadow: false,
    type: 'pie'
  },
  credits: {
    enabled: false
  },
  title: {
    text: "Répartition du nombre d'espèces<br> par groupe taxonomique",
    style : { "color": "#333333", "fontSize": "22px" }
  },

  tooltip: {
    headerFormat: '',
    pointFormat: '<b>{point.label}</b> <br> <b>{point.y}</b>', 
    valueSuffix: ' espèce(s) <br>({point.percentage:.2f}%)'
  },

  plotOptions: {
    pie: {
      allowPointSelect: true,
      cursor: 'pointer',
      colors: pieColors,
      borderColor: "#7094db",
      /*
       style: {
          color: (Highcharts.theme && Highcharts.theme.contrastTextColor) || 'black'
        },
        */
      showInLegend: false,
      
      dataLabels: {
        allowOverlap: true,
        connectorColor: "#7094db",
        enabled: true,
        format: '<b>{point.label}</b><br><b>{point.y} espèce(s)</b><br>{point.percentage:.2f} %',
        style : { "color": "#333333", "fontSize": "11px" },
        /*distance: 10,*/
        filter: {
          property: 'percentage',
          operator: '>',
          value: 0
        }
      }

    }
  },

  series: [{

   //name: 'Asia',
   data: statstaxongroup2inpncomm,
   innerSize: '30%',                
  // showInLegend:true,
   dataLabels: {
       enabled: true,
       padding: 0
   }

  }]
});

