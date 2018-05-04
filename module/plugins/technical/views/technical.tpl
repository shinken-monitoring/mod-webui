%from shinken.misc.perfdata import PerfDatas

%groupname = 'all'
%groupalias = 'All hosts'
%title = 'Technical for all hosts'

%helper = app.helper

%search_string = app.get_search_string()

%rebase("layout", title='Technical for hosts/services', css=['technical/css/technical.css'], js=['technical/js/technical.js'], breadcrumb=[ ['All hosts', '/technical'] ])

<link rel="stylesheet" type="text/css" href="https://cdn.datatables.net/v/bs/dt-1.10.16/datatables.min.css"/>

<script type="text/javascript" charset="utf8" src="https://cdn.datatables.net/1.10.16/js/jquery.dataTables.js"></script>
<script type="text/javascript" charset="utf8" src="https://cdn.datatables.net/buttons/1.5.1/js/dataTables.buttons.min.js"></script>
<script type="text/javascript" charset="utf8" src="https://cdn.datatables.net/buttons/1.5.1/js/buttons.flash.min.js"></script>
<script type="text/javascript" charset="utf8" src="https://cdnjs.cloudflare.com/ajax/libs/jszip/3.1.3/jszip.min.js"></script>
<script type="text/javascript" charset="utf8" src="https://cdnjs.cloudflare.com/ajax/libs/pdfmake/0.1.32/pdfmake.min.js"></script>
<script type="text/javascript" charset="utf8" src="https://cdnjs.cloudflare.com/ajax/libs/pdfmake/0.1.32/vfs_fonts.js"></script>
<script type="text/javascript" charset="utf8" src="https://cdn.datatables.net/buttons/1.5.1/js/buttons.html5.min.js"></script>
<script type="text/javascript" charset="utf8" src="https://cdn.datatables.net/buttons/1.5.1/js/buttons.print.min.js"></script>

<div id="technical">

<!--<input type="text" id="search" value="{{ search }}" />-->

<table id="myTable" class="table table-bordered table-condensed" style="text-align: right;">

</table>


<script>
var _cache = {}

function humanBytes(fileSizeInBytes) {

    var i = -1;
    var byteUnits = ['kb', 'Mb', 'Gb', 'Tb', 'Pb', 'Eb', 'Zb', 'Yb'];
    do {
        fileSizeInBytes = fileSizeInBytes / 1024;
        i++;
    } while (fileSizeInBytes > 1024);

    return Math.max(fileSizeInBytes, 0.1).toFixed(1) + byteUnits[i];
};

function humanHertz(frequency) {

    var i = 0;
    var byteUnits = ['Hz', 'kHz', 'MHz', 'GHz'];
    do {
        frequency = frequency / 1000;
        i++;
    } while (frequency > 1000);

    return Math.max(frequency, 0).toFixed(0) + byteUnits[i];
};

function getServiceFromMetric(metric) {
  for (var i in _cache.groups) {
    if( $.inArray(metric, _cache.groups[i]) >= 0 ) {
       return i;
    }
  }
  return '';
}

function g(host,metric) {
  var ser = getServiceFromMetric(metric)
  if (ser == 'host') ser = '__HOST__';
  var val = "" + host + "." + ser + "." + metric;
  var src = "http://"+window.location.hostname+":4288/render/?width=640&height=200&lineMode=connected&target="+val+"&fontSize=12&from=-7days"
  $('#g').attr('src',src);
}

function processMetric(m) {
    str = "";

    if (false) { null }
    else if (m.name == 'upbw' || m.name == 'dnbw') str = str + humanBytes(m.value);
    else if (m.name.includes('freq')) str = str + humanHertz(m.value);
    else str = str + m.value;

    //if ( m.uom ) str = str +  " " + m.uom;


    if (false) { null }
    else if ( m.critical && m.critical > m.warning && m.value > m.critical ) str = '<span class="font-critical">' + str + '<span>';
    else if ( m.critical && m.critical < m.warning && m.value < m.critical ) str = '<span class="font-critical">' + str + '<span>';
    else if ( m.warning && m.critical > m.warning && m.value > m.warning )   str = '<span class="font-warning">' + str + '<span>';
    else if ( m.warning && m.critical < m.warning && m.value < m.warning )   str = '<span class="font-warning">' + str + '<span>';
    else if ( m.warning == null && m.critical == null) str = '<span>' + str + '<span>'
    else  str = '<span class="font-ok">' + str + '<span>';

    return str

}

$(document).ready( function (){

  var table;
  var _headers = [];


  $("#g").hide();
  $("#g").on('click',function(){
    $(this).hide();
  });

  $('body').keypress(function(e) {
    if ( e.key == 'g' ) {
      $('#g').toggle();
    }
  });


  $.getJSON( "/technical/json?search=" + $('#search').val(), function( data ) {
        _cache = data;

        row = '<thead><tr><th></th>';
        _headers.push('host');
        $.each(data.groups, function(k,v){
           if (v.length > 0) {
             row = row + '<th colspan="'+v.length+'">' + k + "</th>";
           }
        });
        row = row + '</tr><tr>';
        row = row + '<th>Host</th>';

        $.each(data.groups, function(k,v){
           $.each(v, function(kk,vv){
             _headers.push(vv)
             row = row + '<th style="width: 40px; override: hidden">' + vv + "</th>";
           });
        });
        row = row + "</tr></thead>";
        $('#myTable').append(row);

        row = "<tbody>";
        $('#myTable').append(row);
        var host = null;
        $.each(data.data, function(k,v){
            row = "<tr>";
            $.each(_headers, function(kk,i){
              cell = v[i]
              if ( i == "host" ) {
                row = row + '<td ><a href="/cpe/' + cell +'">' + cell + '</a></td>';
                host = cell;
              } else if ( cell instanceof Object ) {
                row = row + '<td onmouseover="g(\''+host+'\',\''+cell.name+'\')">' + processMetric(cell) + '</td>';
              } else if ( typeof cell === "undefined"){
                 row = row + '<td>-</td>';
              } else {
                 row = row + "<td>" + cell + "</td>";
              }
            });

           row = row + "</tr>";
           $('#myTable').append(row);
        });

        row = "</tbody>";
        $('#myTable').append(row);

        var table = $('#myTable').DataTable( {
          lengthMenu: [[25, 50, 100, -1], [25, 50, 100, "All"]],
          searching: false,
          pageLength: 25,
          dom: 'Blfrtip',
          buttons: [
              'copy', 'csv', 'excel', 'pdf', 'print'
          ]
        });

        $('#myTable tbody').on( 'click', 'tr', function () {
               if ( $(this).hasClass('selected') ) {
                   $(this).removeClass('selected');
               } else {
                   table.$('tr.selected').removeClass('selected');
                   $(this).addClass('selected');
               }
           } );




  } );

} );

</script>
<style>
td.highlight {
    background-color: whitesmoke !important;
}
</style>


<img id="g" src="about:blank" style="position: fixed; bottom: 0px; right: 0px;">
