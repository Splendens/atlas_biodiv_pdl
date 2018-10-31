// Download symbol
Highcharts.SVGRenderer.prototype.symbols.download = function (x, y, w, h) {
    var path = [
        // Arrow stem
        'M', x + w * 0.5, y,
        'L', x + w * 0.5, y + h * 0.7,
        // Arrow head
        'M', x + w * 0.3, y + h * 0.5,
        'L', x + w * 0.5, y + h * 0.7,
        'L', x + w * 0.7, y + h * 0.5,
        // Box
        'M', x, y + h * 0.9,
        'L', x, y + h,
        'L', x + w, y + h,
        'L', x + w, y + h * 0.9
    ];
    return path;
};


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



// Build the chart
Highcharts.chart('statsorgataxonChart', {
  chart: {
    plotBackgroundColor: null,
    plotBorderWidth: null,
    plotShadow: false,
    type: 'pie'
  },
  lang: {
    //printChart: 'Print chart',
    downloadPNG: 'Export PNG',
    downloadJPEG: 'Export JPEG',
    //downloadPDF: 'Download PDF',
    //downloadSVG: 'Download SVG',
    //contextButtonTitle: 'Context menu'
  },
  credits: {
    enabled: false
  },
  title: {
    text: "Origine des données",
    style : { "color": "#333333", "fontSize": "22px" }
  },
  subtitle: {
    text: "Bases de données moissonnées",
    style : { "color": "#333333", "fontSize": "15px" }
  },
  tooltip: {
    headerFormat: '',
    pointFormat: '<b>{point.label}</b> <br> <b>{point.y}</b>', 
    valueSuffix: ' donnée(s) <br>({point.percentage:.1f}%)'
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
        format: '<b>{point.label}</b><br><b>{point.y} donnée(s)</b><br>{point.percentage:.1f} %',
        /*distance: 10,*/
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
   data : statsorgataxon,
   innerSize: '30%',                
   //showInLegend:true,
   dataLabels: {
       enabled: true,
       padding: 0
   }
  }],

  navigation: {
        buttonOptions: {

            theme: {
                'stroke-width': 1,
                stroke: 'silver',
                r: 0,
                states: {
                    hover: {
                        fill: '#a4edba'
                    },
                    select: {
                        stroke: '#039',
                        fill: '#a4edba'
                    }
                },
                style: {
                    color: '#3c763d',
                    textDecoration: 'bold'
                }
            }

        }
    },
    exporting: {
      filename: 'Origine_des_données',
      buttons: {
        contextButton: {
          symbol: 'download',
          text: 'Enregistrer',
          menuItems: [
            'downloadPNG',
            'downloadJPEG'
           ]
        }
      }
    }

});





/* PHENOLOGIE */

Highcharts.chart('phenologyChart', {
    chart: {
        type: 'line'
    },
    lang: {
      //printChart: 'Print chart',
      downloadPNG: 'Export PNG',
      downloadJPEG: 'Export JPEG',
      //downloadPDF: 'Download PDF',
      //downloadSVG: 'Download SVG',
      //contextButtonTitle: 'Context menu'
    },
    credits: {
      enabled: false
    },
    title: {
      text: "Observations mensuelles",
      style : { "color": "#333333", "fontSize": "22px" }
    },
    subtitle: {
      text: "Phénologie de l'espèce",
      style : { "color": "#333333", "fontSize": "15px" }
    },
    legend: {
      enabled: false
    },
    xAxis: {
      labels: {
        rotation: -45,
        style: {
          fontSize: '13px',
          fontFamily: 'Verdana, sans-serif'
        }
      },
        categories: ['Janv.', 'Fév.', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet', 'Août', 'Sept.', 'Oct.', 'Nov.', 'Déc.']
    },
    yAxis: {
        title: {
            text: 'Nombre de données'
        }
    },

    plotOptions: {
        spline: {
            dataLabels: {
                enabled: true
            },
            lineWidth: 4,
            states: {
                hover: {
                    lineWidth: 5
                }
            },
            marker: {
                enabled: false
            }
        }
    },

    series: [{
        name: 'donnée(s)',
        data: months,
        type: 'spline',

    }],

  navigation: {
        buttonOptions: {

            theme: {
                'stroke-width': 1,
                stroke: 'silver',
                r: 0,
                states: {
                    hover: {
                        fill: '#a4edba'
                    },
                    select: {
                        stroke: '#039',
                        fill: '#a4edba'
                    }
                },
                style: {
                    color: '#3c763d',
                    textDecoration: 'bold'
                }
            }

        }
    },
    exporting: {
      filename: 'Phénologie',
      buttons: {
        contextButton: {
          symbol: 'download',
          text: 'Enregistrer',
          menuItems: [
            'downloadPNG',
            'downloadJPEG'
           ]
        }
      }
    }

});

