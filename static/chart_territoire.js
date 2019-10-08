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



// Histogramme du nombre d'espèces par organismes/BD moissonnée
Highcharts.chart('statsorgataxonterriGraph', {
    chart: {
        type: 'column'
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
      text: "<b>Nombre d'espèces<br>sur le territoire</b><br>par source de données",
      style : { "color": "#333333", "fontSize": "22px" }
    },

    yAxis: {
        maxPadding:0.5,
        title: {
            text: "Nombre d'espèces"
        }
    },
    xAxis: {
       categories: [
        '<b>Calluna</b><br>(CBN de Brest)', 
        '<b>SICEN</b><br>(CEN Pays de la Loire)', 
        '<b>GRETIA</b>', 
        '<b>Kollect</b><br>URCPIE',
        '<b>Faune Loire-Atlantique</b><br>(LPO44, BV, GNLA)', 
        '<b>Faune Anjou</b><br>(LPO49)', 
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
        data: statsorgataxonterri,
        dataLabels: {
            enabled: true,
            //rotation: -90,
            color: "#333333",
            align: 'center',
            format: '{point.y:.0f}',
            y: -5, // 10 pixels down from the top
            style: {
                fontSize: '13px',
                fontFamily: 'Verdana, sans-serif'
            }
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
      filename: 'Nombre_espèces_sur_le_territoire_par_source_de_données',
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




// Histogramme du nombre d'espèces par organismes/BD moissonnée
Highcharts.chart('statsorgadataterriGraph', {
    chart: {
        type: 'column'
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
      text: "<b>Nombre d'observations<br>sur le territoire</b><br>par source de données",
      style : { "color": "#333333", "fontSize": "22px" }
    },

    yAxis: {
        maxPadding:0.5,
        title: {
            text: "Nombre d'observations"
        }
    },
    xAxis: {
       categories: [
        '<b>Calluna</b><br>(CBN de Brest)', 
        '<b>SICEN</b><br>(CEN Pays de la Loire)', 
        '<b>GRETIA</b>', 
        '<b>Kollect</b><br>URCPIE',
        '<b>Faune Loire-Atlantique</b><br>(LPO44, BV, GNLA)', 
        '<b>Faune Anjou</b><br>(LPO49)', 
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
        pointFormat: "<b>{point.y:.0f} observation(s)</b>"
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
        data: statsorgadataterri,
        dataLabels: {
            enabled: true,
            //rotation: -90,
            color: "#333333",
            align: 'center',
            format: '{point.y:.0f}',
            y: -5, // 10 pixels down from the top
            style: {
                fontSize: '13px',
                fontFamily: 'Verdana, sans-serif'
            }
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
      filename: 'Nombre_obervations_sur_le_territoire_par_source_de_données',
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
    text: "<b>Nombre d'observations</b>",
    style : { "color": "#333333", "fontSize": "22px" }
  },
  subtitle: {
    text: "par groupe taxonomique",
    style : { "color": "#333333", "fontSize": "18px" }
  },
  tooltip: {
    headerFormat: '',
    pointFormat: '<b>{point.label}</b> <br> <b>{point.y}</b>', 
    valueSuffix: ' observation(s) <br>({point.percentage:.2f}%)'
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
        format: '<b>{point.label}</b><br><b>{point.y} observation(s)</b><br>{point.percentage:.2f} %',
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
      filename: 'Nombre_de_données_par_groupes_taxonomique',
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





// PieChart du répartition du nombre d'espèces par groupe taxonomique
Highcharts.chart('taxongroup2inpnGraph', {
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
    text: "<b>Nombre d'espèces</b>",
    style : { "color": "#333333", "fontSize": "22px" }
  },
  subtitle: {
    text: "par groupe taxonomique",
    style : { "color": "#333333", "fontSize": "18px" }
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
      filename: 'Nombre_espèces_par_groupes_taxonomique',
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

