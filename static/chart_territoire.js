
Morris.Donut({
  element: 'statsorgacommChart',
  data: statsorgacomm,
  resize: true,
  formatter: function (value, data) { return value + ' %'; }
});

Morris.Donut({
  element: 'group2inpnChart',
  data: statsgroup2inpncomm,
  resize: true,
  formatter: function (value, data) { return value + ' %'; }
});


