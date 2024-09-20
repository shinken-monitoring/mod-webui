%if app.graphs_module.is_available():
<script>
  var html_graphes = [];
  var current_graph = '';
  var graphstart={{graphstart}};
  var graphend={{graphend}};
  var graphmax={{graphend}};
</script>
<div class="tab-pane fade" id="graphs">
  <div class="panel panel-default" style="border-top:none; border-radius:0;">
    <div class="panel-body">
      %if graph_uris:
      <div class="text-center" style="margin-bottom: 10px;">
        <div class="btn-group" role="group" aria-label="...">
          <button type="button" class="btn btn-default js-graph-left" title="Pan Left"><i class="fa fa-backward"></i></button>
          <button type="button" class="btn btn-default js-graph-right" title="Pan Right"><i class="fa fa-forward"></i></button>
          <button type="button" class="btn btn-default js-graph-zoom-in" title="Zoom In"><i class="fa fa-plus"></i></button>
          <button type="button" class="btn btn-default js-graph-zoom-out" title="Zoom Out"><i class="fa fa-minus"></i></button>
          <div class="btn-group" role="group">
            <button type="button" class="btn btn-default dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
              <span class="caret"></span>
            </button>
            <ul class="dropdown-menu">
              <li><a class="js-graph-shortcut" data-delta=14400>4 hours</a></li>
              <li><a class="js-graph-shortcut" data-delta=86400>1 day</a></li>
              <li><a class="js-graph-shortcut" data-delta=608800>1 week</a></li>
              <li><a class="js-graph-shortcut" data-delta=2592000>1 month</a></li>
              <li><a class="js-graph-shortcut" data-delta=31536000>1 year</a></li>
            </ul>
          </div>
        </div>
      </div>

      <div id='graph_images'>
        %include("_eltdetail_service_graphs.tpl")
        %if elt_type == 'host':
        %include("_eltdetail_host_graphs.tpl")
        %end

        %if elt_type == 'service':
        %twin_elts=app.datamgr.get_twin_elts(elt, user)
        %if twin_elts:
        <hr>
        <h4 class="page-subheader">Twin graphs</h4>
        %for twin_elt in twin_elts:
        %include("_eltdetail_service_graphs.tpl", elt=twin_elt)
        %end
        %end
        %end

        %for related_host in app.datamgr.get_related_hosts(elt, user):
        <hr>
        <h4 class="page-subheader">Related graphs for {{ related_host.get_full_name() }}</h4>
        %include("_eltdetail_host_graphs.tpl", elt=related_host)
        %end
      </div>

      <script>
        function refreshGraphs() {
          $('#graph_images img').each(function () {
            graphurl = $(this).attr('src');
            graphurl = graphurl.replace(/start%3D[0-9]+/, 'start%3D'+graphstart);
            graphurl = graphurl.replace(/end%3D[0-9]+/, 'end%3D'+graphend);
            $(this).prop('src', graphurl);
          });
        };

        $("body").on("click", ".js-graph-left", function () {
          delta = Math.floor((graphend - graphstart)/4);
          graphstart = graphstart - delta;
          graphend = graphend - delta;

          refreshGraphs();
        });

        $("body").on("click", ".js-graph-right", function () {
          delta = Math.floor((graphend - graphstart)/4);
          diff = graphend - graphstart;
          graphend = Math.min(graphend + delta, graphmax);
          graphstart = Math.min(graphend - diff, graphstart + delta);

          refreshGraphs();
        });

        $("body").on("click", ".js-graph-zoom-out", function () {
          delta = Math.floor((graphend - graphstart)/4);
          graphend = Math.min(graphend + delta, graphmax);
          graphstart = graphstart - delta;

          refreshGraphs();
        });

        $("body").on("click", ".js-graph-zoom-in", function () {
          delta = Math.floor((graphend - graphstart)/6);
          if (graphend != graphmax) {
            graphend = graphend - delta;
          }
          graphstart = graphstart + delta;

          refreshGraphs();
        });

        $("body").on("click", ".js-graph-shortcut", function () {
          graphend = graphmax;
          graphstart = graphend - $(this).data('delta');

          refreshGraphs();
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
