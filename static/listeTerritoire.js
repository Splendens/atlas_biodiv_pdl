/*
$(document).ready(function(){
    $('#myTableCommune').show();
    $('#myTableCommune').DataTable({
    	"responsive": true
        ,"order":[defaultSortedColumn, 'desc']
        ,"aoColumnDefs" : [
            {
                'bSortable' : false,
                'aTargets' : noSordedColumns
            }
        ]
      ,"fnDrawCallback": function( oSettings ) {
            //restore tooltips when page change
            $('[data-toggle="tooltip"]').tooltip(); 
        }  
    });
});

// change de glyphicon
$('th').click( function(){
    $(this).find('span').toggleClass('glyphicon glyphicon-menu-down').toggleClass('glyphicon glyphicon-menu-up');
});
*/

// Basic example
$(document).ready(function () {
  $('#ordercommepci').DataTable({
    "responsive": true
    ,"columnDefs": [
        { "orderable": false, "targets": 3 }
      ]
    ,"ordering": true // false to disable sorting (or any other option)
    ,"lengthChange": false
    ,"paging": false
    ,"searching": false
    ,"info": false
  });
});

$(document).ready(function () {
  $('#ordercommdpt').DataTable({
    "responsive": true
    ,"columnDefs": [
        { "orderable": false, "targets": 3 }
      ]
    ,"ordering": true // false to disable sorting (or any other option)
    ,"lengthChange": false
    ,"paging": false
    ,"searching": false
    ,"info": false
  });
});

$(document).ready(function () {
  $('#orderepcidpt').DataTable({
    "responsive": true
    ,"columnDefs": [
        { "orderable": false, "targets": 3 }
      ]
    ,"ordering": true // false to disable sorting (or any other option)
    ,"lengthChange": false
    ,"paging": false
    ,"searching": false
    ,"info": false
  });
});