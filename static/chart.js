
Highcharts.chart('monthsGraph', {
  chart: {
    zoomType: 'x'
  },
  title: {
    text: 'USD to EUR exchange rate over time'
  },
  subtitle: {
    text: document.ontouchstart === undefined ?
        'Click and drag in the plot area to zoom in' : 'Pinch the chart to zoom in'
  },
  xAxis: {
    type: 'datetime'
  },
  yAxis: {
    title: {
      text: 'Exchange rate'
    }
  },
  legend: {
    enabled: false
  },
  plotOptions: {
    area: {
      fillColor: {
        linearGradient: {
          x1: 0,
          y1: 0,
          x2: 0,
          y2: 1
        },
        stops: [
          [0, Highcharts.getOptions().colors[0]],
          [1, Highcharts.Color(Highcharts.getOptions().colors[0]).setOpacity(0).get('rgba')]
        ]
      },
      marker: {
        radius: 2
      },
      lineWidth: 1,
      states: {
        hover: {
          lineWidth: 1
        }
      },
      threshold: null
    }
  },

  series: [{
    type: 'area',
    name: 'USD to EUR',
    data: data
  }]
});






/*
// statsorgataxon graph
Morris.Bar({
            element:"statsorgataxonChart",
            data : dataset,
            xkey: "orgas",
            ykeys : ["value"],
            labels: ['Observation(s) '],
            yLabelFormat: function (y) {
                return y + " %";
            },
            xLabelAngle: 45,
            hideHover: 'auto',
            resize: true,
            axes: true,
            gridIntegers: true
       });



svgbis=d3.selectAll("svg");

        svgbis.append("g")
        .append("text")
            .attr("y", "90%")
            .attr("x", "100%")
            .attr("dy", ".71em")
            .attr("fill", "#888888")
            .attr("font-size", "10px")
            .style("text-anchor", "end")
            .text("");


var phenologyChart =  Morris.Bar({
                        element:"phenologyChart",
                        data : months,
                        xkey: "mois",
                        ykeys : ["value"],
                        labels: ['Observation(s)'],
                        xLabelAngle: 60,
                        hideHover: 'auto',
                        resize: true,
                        axes: true,
                    });
svgContainer = d3.selectAll("svg");
    svgContainer.append("g")
        .append("text")
            .attr("transform", "rotate(-90)")
            .attr("y", '0%')
            .attr('x', '-15%')
            .attr("dy", ".71em")
            .attr("fill", "#888888")
            .attr("font-size", "10px")
            .style("text-anchor", "end")
            .text("Observations");



rect = d3.selectAll("rect");

            rect.on("mouseover", function(d) {
             d3.select(this).classed("highlight", true);
             d3.select(this).select("text").style("visibility", "visible");

});

            rect.on("mouseout", function() {
    d3.select(this).classed("highlight", false);

});

svgContainer = d3.selectAll("svg");
    svgContainer.append("g")
        .append("text")
            .attr("transform", "rotate(-90)")
            .attr("y", '0%')
            .attr('x', '-15%')
            .attr("dy", ".71em")
            .attr("fill", "#888888")
            .attr("font-size", "10px")
            .style("text-anchor", "end")
            .text("Observations");

*/