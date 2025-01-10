%if app.graphs_module.is_available():
<script>
  var html_graphes = [];
  var current_graph = '';
  var hostname='{{elt.host_name}}';
  var graphstart={{graphstart}};
  var graphend={{graphend}};
  function graphmax() {
    return Math.floor(Date.now()/1000);
  }
  if (graphend > graphmax) {
    graphend = graphmax;
  }
</script>
<div class="tab-pane fade" id="graphs">
  <div class="panel panel-default" style="border-top:none; border-radius:0;">
    <div class="panel-body">
      %if graph_uris:
      <div class="row">
        <div class="col-md-6">
          <div class="text-center">
            <div class="form-inline" style="display: inline-block;">
              <div class="input-group" style="width: 400px; margin-bottom: 8px;">
                <div class="input-group-addon" id="daterange-duration" style="width: 1%;">3d</div>
                <input id="daterange" class="form-control btn-shinken" type="text" value="…">
                <div class="input-group-btn" style="width: 1%;">
                  <button type="button" class="btn btn-default btn-shinken dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
                    <span class="caret"></span>
                  </button>
                  <ul class="dropdown-menu dropdown-menu-right">
                    <li><a class="js-graph-shortcut" data-delta=14400>4 hours</a></li>
                    <li><a class="js-graph-shortcut" data-delta=86400>1 day</a></li>
                    <li><a class="js-graph-shortcut" data-delta=172800>2 days</a></li>
                    <li><a class="js-graph-shortcut" data-delta=608800>1 week</a></li>
                    <li><a class="js-graph-shortcut" data-delta=2592000>1 month</a></li>
                    <li><a class="js-graph-shortcut" data-delta=7776000>3 month</a></li>
                    <li><a class="js-graph-shortcut" data-delta=15552000>6 month</a></li>
                    <li><a class="js-graph-shortcut" data-delta=31536000>1 year</a></li>
                  </ul>
                </div>
              </div>
              <div class="btn-group" role="group" aria-label="..." style="margin-bottom: 8px;">
                <button type="button" class="btn btn-default btn-shinken js-graph-left" title="Pan Left"><i class="fa fa-backward"></i></button>
                <button type="button" class="btn btn-default btn-shinken js-graph-right" title="Pan Right"><i class="fa fa-forward"></i></button>
                <button type="button" class="btn btn-default btn-shinken js-graph-zoom-in" title="Zoom In"><i class="fa fa-plus"></i></button>
                <button type="button" class="btn btn-default btn-shinken js-graph-zoom-out" title="Zoom Out"><i class="fa fa-minus"></i></button>
              </div>
            </div>
          </div>

          <div class="text-center" id='graph_images' style='margin-top: 16px'>
            %include("_eltdetail_service_graphs.tpl")
            %if elt_type == 'host':
            %include("_eltdetail_host_graphs.tpl")
            %end

            %if elt_type == 'service':
            %twin_elts=app.datamgr.get_twin_elts(elt, user)
            %if twin_elts:
            <div class="text-center">
              %for twin_elt in twin_elts:
              %if twin_elt != elt:
              <h4 class="page-subheader"><a class="js-open-elt" href="{{ helper.get_link_dest(twin_elt) }}">{{! helper.get_fa_icon_state(twin_elt) }}{{ twin_elt.get_full_name() }}</a></h4>
              %include("_eltdetail_service_graphs.tpl", elt=twin_elt)
              %end
              %end
            </div>
            %end
            %end
            
            %related_hosts=app.datamgr.get_related_hosts(elt, user)
            <div class="text-center">
              <hr>
              %for related_host in related_hosts:
              <h4 class="page-subheader"><a class="js-open-elt" href="{{ helper.get_link_dest(related_host) }}">Related host {{ related_host.get_full_name() }}</a></h4>
              %include("_eltdetail_host_graphs.tpl", elt=related_host)
              %end
            </div>
          </div>
        </div>

        <div class="col-md-6">
          <div class="text-center">
            <div class="form-inline" style="display: inline-block;">
              <div class="input-group" role="group" aria-label="...">
                <div class="input-group-addon">Event level >=</div>
                <select class="form-control btn-shinken" id="level-select" style="width: auto;">
                  <option>Auto</option>
                  <option>0</option>
                  <option>1</option>
                  <option>2</option>
                  <option>3</option>
                  <option>4</option>
                  <option>5</option>
                </select>
              </div>
            </div>
          </div>
          <div id='main_events' style='margin-top: 16px'>
          </div>
        </div>
      </div>

      <script>
        function refreshURL() {
          // URL = /host/xxx-www01?graphstart=…&graphend=…#graphs
          var queryParams = new URLSearchParams(window.location.search);
          queryParams.set("graphstart", graphstart);
          queryParams.set("graphend", graphend);
          var hash = window.location.hash
          history.pushState(null, null, "?"+queryParams.toString()+hash);
        }

        function refreshDateRange() {
          duration = moment.duration(moment(graphend, 'X').diff(moment(graphstart, 'X')));
          if (duration.as('y') > 2) {
            duration_str = Math.floor(duration.as('years')) + 'Y';
          } else if (duration.as('s') > 60*60*24*60) {
            duration_str = Math.floor(duration.as('months')) + 'M';
          } else if (duration.as('s') > 60*60*24) {
            duration_str = Math.floor(duration.as('days')) + 'd';
          } else if (duration.as('s') > 60*60) {
            duration_str = Math.floor(duration.as('h')) + 'h';
          } else {
            duration_str = Math.floor(duration.as('minutes')) + 'm';
          }
          $('#daterange-duration').text(duration_str);
          $('#daterange').val(moment(graphstart, 'X').calendar({sameElse: 'YYYY-MM-DD'}) + ' -- ' + moment(graphend, 'X').calendar({sameElse: 'YYYY-MM-DD'}));
        }

        function refreshEvents() {
          level = $('#level-select').val();
          if (level == 'Auto') {
            if (graphend - graphstart > 60*60*24*180) {
              var level = 3
            } else if (graphend - graphstart > 60*60*24*35) {
              var level = 2
            } else if (graphend - graphstart > 60*60*24*14) {
              var level = 1
            } else {
              var level = 0
            }
          }
          $('#main_events').html('<i class="fas fa-spinner fa-spin"></i> Loading events…')
          $('#main_events').load('/events/host/'+hostname+'?range_start='+graphstart+'&range_end='+graphend+'&level='+level);
          //$('#main_events_level').text(level);

        }

        function refreshGraphs() {
          $('#graph_images img').each(function () {
            graphurl = $(this).attr('src');
            graphurl = graphurl.replace(/start%3D[0-9]+/, 'start%3D'+graphstart);
            graphurl = graphurl.replace(/end%3D[0-9]+/, 'end%3D'+graphend);
            $(this).prop('src', graphurl);
          });
        };

        function updateDateRange() {
          refreshURL();
          refreshDateRange();
          refreshGraphs();
          refreshEvents();
        }

        $("body").on("click", ".js-graph-left", function () {
          delta = Math.floor((graphend - graphstart)/4);
          graphstart = graphstart - delta;
          graphend = graphend - delta;

          updateDateRange();
        });

        $("body").on("click", ".js-graph-right", function () {
          delta = Math.floor((graphend - graphstart)/4);
          diff = graphend - graphstart;
          graphend = Math.min(graphend + delta, graphmax());
          graphstart = Math.min(graphend - diff, graphstart + delta);

          updateDateRange();
        });

        $("body").on("click", ".js-graph-zoom-out", function () {
          if ((graphmax() - graphend) < (60*60*12)) {
            delta = Math.floor((graphend - graphstart)/2);
            graphstart = graphstart - delta;
          } else {
            delta = Math.floor((graphend - graphstart)/4);
            graphend = Math.min(graphend + delta, graphmax());
            graphstart = graphstart - delta;
          }

          updateDateRange();
        });

        $("body").on("click", ".js-graph-zoom-in", function () {
          if ((graphmax() - graphend) < (60*60*12)) {
            delta = Math.floor((graphend - graphstart)/3);
            graphstart = graphstart + delta;
          } else {
            delta = Math.floor((graphend - graphstart)/6);
            graphend = graphend - delta;
            graphstart = graphstart + delta;
          }

          updateDateRange();
        });

        $("body").on("click", ".js-graph-shortcut", function () {
          graphend = graphmax();
          graphstart = graphend - $(this).data('delta');

          updateDateRange();
        });

        $("#daterange").on("click", function () {
          daterange=$('#daterange').val(moment(graphstart, 'X').format('YYYY-MM-DD hh:mm') + ' -- ' + moment(graphend, 'X').format('YYYY-MM-DD hh:mm'));
        });

        $("body").on("change", '#daterange', function () {
          daterange=daterange.val();
          [dr_start, dr_end] = daterange.split(' -- ');
          console.log('date change : ' + moment(dr_start).format() + ' to ' + moment(dr_end).format());
          graphend = moment(dr_end).format('X');
          graphstart = moment(dr_start).format('X');

          updateDateRange();
        });

        $("body").on("change", "#level-select", function () {
          refreshEvents();
        });

        // :TODO:maethor:240925: updateDateRange ?
        $(document).ready(refreshEvents());
        $(document).ready(refreshDateRange());

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
