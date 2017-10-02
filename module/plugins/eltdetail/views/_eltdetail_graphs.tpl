%if app.graphs_module.is_available():
<script>
  var html_graphes = [];
  var current_graph = '';
  var graphstart={{graphstart}};
var graphend={{graphend}};
</script>
<div class="tab-pane fade" id="graphs">
  <div class="panel panel-default" style="border-top:none; border-radius:0;">
    <div class="panel-body">
      %# Set source as '' or module ui-graphite will try to fetch templates from default 'detail'
      %uris = app.graphs_module.get_graph_uris(elt, graphstart=graphstart, graphend=graphend)
      %if uris:
      <div class='well'>
        <!-- 5 standard time ranges to display ...  -->
        <ul id="graph_periods" class="nav nav-pills nav-justified">
          <li><a data-type="graph" data-period="4h" > 4 hours</a></li>
          <li><a data-type="graph" data-period="1d" > 1 day</a></li>
          <li><a data-type="graph" data-period="1w" > 1 week</a></li>
          <li><a data-type="graph" data-period="1m" > 1 month</a></li>
          <li><a data-type="graph" data-period="1y" > 1 year</a></li>
        </ul>
      </div>

      <div class='well'>
        <div id='real_graphs'>
        </div>
      </div>

      <script>
        $('a[href="#graphs"]').on('shown.bs.tab', function (e) {
          %uris = dict()
            %uris['4h'] = app.graphs_module.get_graph_uris(elt, duration=     4*3600)
            %uris['1d'] = app.graphs_module.get_graph_uris(elt, duration=    24*3600)
            %uris['1w'] = app.graphs_module.get_graph_uris(elt, duration=  7*24*3600)
            %uris['1m'] = app.graphs_module.get_graph_uris(elt, duration= 31*24*3600)
            %uris['1y'] = app.graphs_module.get_graph_uris(elt, duration=365*24*3600)

            // let's create the html content for each time range
            var element='/{{elt_type}}/{{elt.get_full_name()}}';
          %for period in ['4h', '1d', '1w', '1m', '1y']:

            html_graphes['{{period}}'] = '<p>';
          %for g in uris[period]:
            html_graphes['{{period}}'] +=  '<img src="{{g['img_src']}}" class="jcropelt"/> <p></p>';
          %end
            html_graphes['{{period}}'] += '</p>';

          %end

            // Set first graph
            current_graph = '4h';
          $('a[data-type="graph"][data-period="'+current_graph+'"]').trigger('click');
        });
      </script>
      %else:
      <div class="alert alert-info">
        <div class="font-blue"><strong>No graphs available for this {{elt_type}}!</strong></div>
      </div>
      %end
    </div>
  </div>
</div>
%end
