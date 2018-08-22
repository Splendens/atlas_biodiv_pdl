
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
Highcharts.chart('statsorgacommGraph', {
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
    text: "Répartition des données selon <br>la base de données de provenance",
    style : { "color": "#333333", "fontSize": "22px" }
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
      /*
       style: {
          color: (Highcharts.theme && Highcharts.theme.contrastTextColor) || 'black'
        },
        */
      showInLegend: false,
      
      dataLabels: {
        enabled: true,
        format: '<b>{point.label}</b><br>{point.percentage:.1f} %',
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
   data : statsorgacomm,
   innerSize: '30%',                
   //showInLegend:true,
   dataLabels: {
       enabled: true,
       padding: 0
   }
  }]
});






// Build the chart
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
    text: "Répartition des données d'observations<br> par groupe taxonomique",
    style : { "color": "#333333", "fontSize": "22px" }
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
      /*
       style: {
          color: (Highcharts.theme && Highcharts.theme.contrastTextColor) || 'black'
        },
        */
      showInLegend: false,
      
      dataLabels: {
        enabled: true,
        format: '<b>{point.label}</b><br>{point.percentage:.1f} %',
        /*distance: 10,*/
        /*filter: {
          property: 'percentage',
          operator: '>',
          value: 0
        }*/
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





// Build the chart
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
    valueSuffix: ' espèce(s) <br>({point.percentage:.1f}%)'
  },

  plotOptions: {
    pie: {
      allowPointSelect: true,
      cursor: 'pointer',
      colors: pieColors,
      /*
       style: {
          color: (Highcharts.theme && Highcharts.theme.contrastTextColor) || 'black'
        },
        */
      showInLegend: false,
      
      dataLabels: {
        enabled: true,
        format: '<b>{point.label}</b><br>{point.percentage:.1f} %',
        /*distance: 10,*/
        /*filter: {
          property: 'percentage',
          operator: '>',
          value: 0
        }*/
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

