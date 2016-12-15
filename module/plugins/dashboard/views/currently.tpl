%setdefault('refresh', True)
%rebase("fullscreen", css=['dashboard/css/currently.css'], js=['dashboard/js/Chart.js'], title='Shinken currently')

%import json

%setdefault('panels', None)
%create_panels_preferences = False
%if not 'panel_counters_hosts' in panels:
%panels['panel_counters_hosts'] = {'collapsed': False}
%panels['panel_counters_services'] = {'collapsed': False}
%panels['panel_percentage_hosts'] = {'collapsed': False}
%panels['panel_percentage_services'] = {'collapsed': False}
%panels['panel_pie_graph_hosts'] = {'collapsed': False}
%panels['panel_pie_graph_services'] = {'collapsed': False}
%panels['panel_line_graph_hosts'] = {'collapsed': False}
%panels['panel_line_graph_services'] = {'collapsed': False}
%create_panels_preferences = True
%end

%setdefault('graphs', None)
%setdefault('hosts_states', ['up','down','unreachable','unknown'])
%setdefault('services_states', ['ok','warning','critical','unknown'])

%create_graphs_preferences = False
%if not 'pie_graph_hosts' in graphs:
%graphs['pie_graph_hosts'] = {'legend': True, 'title': True, 'states': hosts_states}
%graphs['pie_graph_services'] = {'legend': True, 'title': True, 'states': services_states}
%graphs['line_graph_hosts'] = {'legend': True, 'title': True, 'states': hosts_states}
%graphs['line_graph_services'] = {'legend': True, 'title': True, 'states': services_states}
%create_graphs_preferences = True
%end

%create_graphs_preferences = False
%if not 'display_states' in graphs['pie_graph_hosts']:
%graphs['pie_graph_hosts']['display_states'] = {}
%graphs['line_graph_hosts']['display_states'] = {}
%for state in hosts_states:
%graphs['pie_graph_hosts']['display_states'][state] = False if state in ['unknown'] else True
%graphs['line_graph_hosts']['display_states'][state] = False if state in ['unknown','up'] else True
%end
%graphs['pie_graph_services']['display_states'] = {}
%graphs['line_graph_services']['display_states'] = {}
%for state in services_states:
%graphs['pie_graph_services']['display_states'][state] = False if state in ['unknown'] else True
%graphs['line_graph_services']['display_states'][state] = False if state in ['unknown','ok'] else True
%end
%create_graphs_preferences = True
%end

%setdefault('hosts_states_queue_length', 30)
%setdefault('services_states_queue_length', 30)


%helper = app.helper

<script type="text/javascript">
    var dashboard_logs = false;

    // Shinken globals
    dashboard_currently = true;

    panels = {{ ! json.dumps(panels) }};
    graphs = {{ ! json.dumps(graphs) }};

    %if create_panels_preferences:
    save_user_preference('panels', JSON.stringify(panels));
    %end
    %if create_graphs_preferences:
    save_user_preference('graphs', JSON.stringify(graphs));
    %end

    // Function called on each page refresh ... update graphs!
    function on_page_refresh(forced) {
        // Hosts data
        var hosts_count = parseInt($('#one-eye-overall .hosts-all').data("count"));
        var hosts_problems = parseInt($('#one-eye-overall .hosts-all').data("problems"));
        if (! sessionStorage.getItem("hosts_problems")) {
           sessionStorage.setItem("hosts_problems", hosts_problems);
        }
        var old_hosts_problems = Number(sessionStorage.getItem("hosts_problems"));
        if (dashboard_logs) console.debug("Hosts: ", hosts_count, hosts_problems, old_hosts_problems);

        // Services data
        var services_count = parseInt($('#one-eye-overall .services-all').data("count"));
        var services_problems = parseInt($('#one-eye-overall .services-all').data("problems"));
        if (! sessionStorage.getItem("services_problems")) {
           sessionStorage.setItem("services_problems", services_problems);
        }
        var old_services_problems = Number(sessionStorage.getItem("services_problems"));
        if (dashboard_logs) console.debug("services: ", services_count, services_problems, old_services_problems);

        // Refresh user's preferences
        get_user_preference('panels', function(data) {
            panels=data;
            get_user_preference('graphs', function(data) {
                graphs=data;

                // Sound alerting
                if (sessionStorage.getItem("sound_play") == '1') {
                    if ((old_hosts_problems < hosts_problems) || (old_services_problems < services_problems)) {
                       playAlertSound();
                    }
                }
                if (old_hosts_problems < hosts_problems) {
                    var message = (hosts_problems - old_hosts_problems) + " more " + ((hosts_problems - old_hosts_problems)==1 ? "host problem" : "host problems") + " in the last "+app_refresh_period+" seconds."
                    alertify.log(message, "error", 5000);
                    if (dashboard_logs) console.debug(message);
                }
                if (hosts_problems < old_hosts_problems) {
                    var message = (old_hosts_problems - hosts_problems) + " fewer " + ((old_hosts_problems - hosts_problems)==1 ? "host problem" : "host problems") + " in the last "+app_refresh_period+" seconds."
                    alertify.log(message, "success", 5000);
                    if (dashboard_logs) console.debug(message);
                }
                sessionStorage.setItem("hosts_problems", hosts_problems);
                if (old_services_problems < services_problems) {
                    var message = (services_problems - old_services_problems) + " more " + ((services_problems - old_services_problems)==1 ? "service problem" : "service problems") + " in the last "+app_refresh_period+" seconds."
                    alertify.log(message, "error", 5000);
                    if (dashboard_logs) console.debug(message);
                }
                if (services_problems < old_services_problems) {
                    var message = (old_services_problems - services_problems) + " fewer " + ((old_services_problems - services_problems)==1 ? "service problem" : "service problems") + " in the last "+app_refresh_period+" seconds."
                    alertify.log(message, "success", 5000);
                    if (dashboard_logs) console.debug(message);
                }
                sessionStorage.setItem("services_problems", services_problems);

                // Hosts pie chart
                if ($("#panel_pie_graph_hosts").is(":visible") && ! panels["panel_pie_graph_hosts"].collapsed) {
                    if (dashboard_logs) console.debug('Refresh: panel_pie_graph_hosts');
                    var data = [];
                    $.each(graphs['pie_graph_hosts']['display_states'], function(state, active) {
                        if (! active) return;
                        var counter_value = parseInt($('#one-eye-overall span.hosts-count[data-state="'+state+'"]').data("count"));

                        // Update table rows
                        row = pie_graph_hosts_parameters[state];
                        row['value'] = counter_value;
                        data.push(row)
                    });

                    // Update graph
                    var ctx = $("#pie-graph-hosts canvas").get(0).getContext("2d");
                    var myPieChart = new Chart(ctx).Doughnut(data, pie_graph_hosts_options);
                    if (graphs['pie_graph_hosts'].title) {
                        $("#pie-graph-hosts .title").show();
                        $("#pie-graph-hosts .title span").html(hosts_count + " hosts").show();
                    } else {
                        $("#pie-graph-hosts .title").hide();
                    }
                    if (graphs['pie_graph_hosts']['legend']) {
                        if (line_graph_hosts_options) {
                            $("#pie-graph-hosts .legend").show();
                            if ($("#pie-graph-hosts span.legend").length) {
                                if (! $("#pie_graph_hosts_legend").length) {
                                    $("#pie-graph-hosts .legend span").append(myPieChart.generateLegend());
                                }
                                // TODO: Update ...
                            }
                        }
                    } else {
                        $("#pie-graph-hosts .legend").hide();
                    }
                }

                // Hosts line chart
                if ($("#panel_line_graph_hosts").is(":visible") && ! panels["panel_line_graph_hosts"].collapsed) {
                    if (dashboard_logs) console.debug('Refresh: panel_line_graph_hosts');
                    var data = [];
                    data['labels'] = line_graph_hosts_data['labels'];
                    data['datasets'] = [];
                    $.each(graphs['line_graph_hosts']['display_states'], function(state, active) {
                        if (! active) return;
                        var counter_value = parseInt($('#one-eye-overall span.hosts-count[data-state="'+state+'"]').data("count"));

                        // Update table rows
                        row = line_graph_hosts_data['datasets'][state];
                        row['data'] = states_queue["nb_hosts_"+state];
                        data['datasets'].push(row);

                        if (! forced) {
                            if (states_queue["nb_hosts_"+state].length > hosts_states_queue_length) {
                                states_queue["nb_hosts_"+state].shift();
                            }
                            states_queue["nb_hosts_"+state].push( counter_value );
                        }
                    });

                    // Get the context of the canvas element we want to select
                    var ctx = $("#line-graph-hosts canvas").get(0).getContext("2d");
                    var myLineChart = new Chart(ctx).Line(data, line_graph_hosts_options);
                    if (graphs['line_graph_hosts']['title']) {
                        $("#line-graph-hosts .title").show();
                        $("#line-graph-hosts .title span").html(hosts_count + " hosts");
                    } else {
                        $("#line-graph-hosts .title").hide();
                    }
                    if (graphs['line_graph_hosts']['legend']) {
                        if (line_graph_hosts_options) {
                            $("#line-graph-hosts .legend").show();
                            if ($("#line-graph-hosts span.legend").length) {
                                if (! $("#line_graph_hosts_legend").length) {
                                    $("#line-graph-hosts span.legend").append(myLineChart.generateLegend());
                                }
                            }
                        }
                    } else {
                        $("#line-graph-hosts .legend").hide();
                    }
                }

                // Services pie chart
                if ($("#panel_pie_graph_services").is(":visible") && ! panels["panel_pie_graph_services"].collapsed) {
                    if (dashboard_logs) console.debug('Refresh: panel_pie_graph_services');
                    var data = [];
                    $.each(graphs['pie_graph_services']['display_states'], function(state, active) {
                        if (! active) return;
                        var counter_value = parseInt($('#one-eye-overall span.services-count[data-state="'+state+'"]').data("count"));

                        // Update table rows
                        row = pie_graph_services_parameters[state];
                        row['value'] = counter_value;
                        data.push(row)
                    });

                    // Get the context of the canvas element we want to select
                    var ctx = $("#pie-graph-services canvas").get(0).getContext("2d");
                    var myPieChart = new Chart(ctx).Doughnut(data, pie_graph_services_options);
                    if (graphs['pie_graph_services']['title']) {
                        $("#pie-graph-services .title").show();
                        $("#pie-graph-services .title span").html(services_count + " services");
                    } else {
                        $("#pie-graph-services .title").hide();
                    }
                    if (graphs['pie_graph_services']['legend']) {
                        if (pie_graph_services_options) {
                            $("#pie-graph-services .legend").show();
                            if ($("#pie-graph-services span.legend").length) {
                                if (! $("#pie_graph_services_legend").length) {
                                    $("#pie-graph-services span.legend").append(myPieChart.generateLegend());
                                }
                            }
                        }
                    } else {
                        $("#pie-graph-services .legend").hide();
                    }
                }

                // Services line chart
                if ($("#panel_line_graph_services").is(":visible") && ! panels["panel_line_graph_services"].collapsed) {
                    if (dashboard_logs) console.debug('Refresh: panel_line_graph_services');
                    var data = [];
                    data['labels'] = line_graph_services_data['labels'];
                    data['datasets'] = [];

                    $.each(graphs['line_graph_services']['display_states'], function(state, active) {
                        if (! active) return;
                        var counter_value = parseInt($('#one-eye-overall span.services-count[data-state="'+state+'"]').data("count"));

                        // Update table rows
                        row = line_graph_services_data['datasets'][state];
                        row['data'] = states_queue["nb_services_"+state];
                        data['datasets'].push(row);

                        if (! forced) {
                            if (states_queue["nb_services_"+state].length > services_states_queue_length) {
                                states_queue["nb_services_"+state].shift();
                            }
                            states_queue["nb_services_"+state].push(counter_value);
                        }
                    });

                    // Get the context of the canvas element we want to select
                    var ctx = $("#line-graph-services canvas").get(0).getContext("2d");
                    var myLineChart = new Chart(ctx).Line(data, line_graph_services_options);
                    if (graphs['line_graph_services']['title']) {
                        $("#line-graph-services .title").show();
                        $("#line-graph-services .title span").html(services_count + " services");
                    } else {
                        $("#line-graph-services .title").hide();
                    }
                    if (graphs['line_graph_services']['legend']) {
                        if (line_graph_services_options) {
                            $("#line-graph-services .legend").show();
                            if ($("#line-graph-services span.legend").length) {
                                if (! $("#line_graph_services_legend").length) {
                                    $("#line-graph-services span.legend").append(myLineChart.generateLegend());
                                }
                            }
                        }
                    } else {
                        $("#line-graph-services .legend").hide();
                    }
                }
            });
        });
    }

    $(document).ready(function(){
        // Date / time
        $('#clock').jclock({ format: '%H:%M:%S' });
        $('#date').jclock({ format: '%A, %B %d' });

        on_page_refresh();

        // Fullscreen management
        if (screenfull.enabled) {
            $('a[action="fullscreen-request"]').on('click', function() {
                screenfull.request();
            });

            // Fullscreen changed event
            document.addEventListener(screenfull.raw.fullscreenchange, function () {
                if (screenfull.isFullscreen) {
                    $('a[action="fullscreen-request"]').hide();
                } else {
                    $('a[action="fullscreen-request"]').show();
                }
            });
        }

        // Toggle sound ...
        if (sessionStorage.getItem("sound_play") == '1') {
            $('#sound_alerting i.fa-ban').addClass('hidden');
        } else {
            $('#sound_alerting i.fa-ban').removeClass('hidden');
        }

        // Panels collapse state
        $('body').on('hidden.bs.collapse', '.panel', function () {
            stop_refresh();
            panels[$(this).parent().attr('id')].collapsed = true;
            $(this).find('.fa-minus-square').removeClass('fa-minus-square').addClass('fa-plus-square');
            save_user_preference('panels', JSON.stringify(panels), function() {
                start_refresh();
                do_refresh(true);
            });
        });
        $('body').on('shown.bs.collapse', '.panel', function () {
            stop_refresh();
            panels[$(this).parent().attr('id')].collapsed = false;
            $(this).find('.fa-plus-square').removeClass('fa-plus-square').addClass('fa-minus-square');
            save_user_preference('panels', JSON.stringify(panels), function() {
                start_refresh();
                do_refresh();
            });
        });

        // Graphs options
        $('body').on('click', '[data-action="toggle-title"]', function () {
            stop_refresh();
            graphs[$(this).data('graph')].title = ! graphs[$(this).data('graph')].title;
            save_user_preference('graphs', JSON.stringify(graphs), function() {
                start_refresh();
                do_refresh(true);
            });
        });
        $('body').on('click', '[data-action="toggle-legend"]', function () {
            stop_refresh();
            graphs[$(this).data('graph')].legend = ! graphs[$(this).data('graph')].legend;
            save_user_preference('graphs', JSON.stringify(graphs), function() {
                start_refresh();
                do_refresh(true);
            });
        });
        $('body').on('click', '[data-action="toggle-state"]', function () {
            stop_refresh();
            graphs[$(this).data('graph')]['display_states'][$(this).data('state')] = ! graphs[$(this).data('graph')]['display_states'][$(this).data('state')];
            save_user_preference('graphs', JSON.stringify(graphs), function() {
                start_refresh();
                do_refresh(true);
            });
        });
    });
</script>

%setdefault('user', None)
%username = 'anonymous'
%if user is not None:
%if hasattr(user, 'alias'):
%  username = user.alias
%else:
%  username = user.get_name()
%end
%end

%if app.play_sound:
<audio id="alert-sound" volume="1.0">
   <source src="/static/sound/alert.wav" type="audio/wav">
   Your browser does not support the <code>HTML5 Audio</code> element.
   <EMBED src="/static/sound/alert.wav" autostart=true loop=false volume=100 >
</audio>

<script type="text/javascript">
   // Set alerting sound icon ...
   if (! sessionStorage.getItem("sound_play")) {
      // Default is to play ...
      sessionStorage.setItem("sound_play", {{'1' if app.play_sound else '0'}});
   }

   // Toggle sound ...
   if (sessionStorage.getItem("sound_play") == '1') {
      $('#sound_alerting i.fa-ban').addClass('hidden');
   } else {
      $('#sound_alerting i.fa-ban').removeClass('hidden');
   }
   $('body').on('click', '[action="toggle-sound-alert"]', function (e, data) {
      if (sessionStorage.getItem("sound_play") == '1') {
         sessionStorage.setItem("sound_play", "0");
         $('#sound_alerting i.fa-ban').removeClass('hidden');
      } else {
         playAlertSound();
         $('#sound_alerting i.fa-ban').addClass('hidden');
      }
   });
</script>
%end

%s = app.datamgr.get_services_synthesis(None, user)
%h = app.datamgr.get_hosts_synthesis(None, user)

%if username != 'anonymous':
<div class="container-fluid">
<div class="row">
    <div id="one-eye-toolbar" class="col-xs-12">
        <div class="col-md-12 col-lg-12">
            <ul class="nav navbar-nav navbar-left">
                <li>
                    <a tabindex="0" class="font-darkgrey" role="button" title="Close" href="/dashboard">
                        <span id="back-dashboard" class="fa-stack">
                            <i class="fa fa-home fa-stack-1x"></i>
                            <i class="fa fa-ban fa-stack-2x hidden"></i>
                        </span>
                    </a>
                </li>
                <li>
                    <a tabindex="0" class="font-darkgrey" role="button" title="Got to fullscreen" href="#" action="fullscreen-request">
                        <span id="go-fullscreen" class="fa-stack">
                            <i class="fa fa-desktop fa-stack-1x"></i>
                            <i class="fa fa-ban fa-stack-2x hidden"></i>
                        </span>
                    </a>
                </li>
                %if app.play_sound:
                <li>
                    <a tabindex="0" class="font-darkgrey" role="button" title="Sound alerting" href="#" action="toggle-sound-alert">
                        <span id="sound_alerting" class="fa-stack">
                            <i class="fa fa-music fa-stack-1x"></i>
                            <i class="fa fa-ban fa-stack-2x text-danger hidden"></i>
                        </span>
                    </a>
                </li>
                %end
            </ul>

            <ul class="nav navbar-nav navbar-right">
                <li>
                    <p class="navbar-text font-darkgrey">
                       <span id="date"></span>&nbsp;&hyphen;&nbsp;<span id="clock"></span>
                    </p>
                </li>
            </ul>
        </div>
    </div>
</div>
</div>
%end

<div class="container-fluid">
<div class="row" style="top:60px; ">
    <div id="one-eye-overall" class="col-xs-12">
        <div class="col-md-6" id="panel_counters_hosts">
            <div class="panel panel-default">
                <div class="panel-heading">
                    <i class="fa fa-server"></i>
                    <span class="hosts-all" data-count="{{ h['nb_elts'] }}" data-problems="{{ h['nb_problems'] }}">
                        {{h['nb_elts']}} hosts{{! "<em class='font-down'> (%d problems).</em>" % (h['nb_problems']) if h['nb_problems'] else '.'}}
                    </span>
                    <div class="pull-right">
                        <a href="#p_panel_counters_hosts" data-toggle="collapse" type="button" class="btn btn-xs"><i class="fa {{'fa-minus-square' if not panels['panel_counters_hosts']['collapsed'] else 'fa-plus-square'}} fa-fw"></i></a>
                    </div>
                </div>
                <div id="p_panel_counters_hosts" class="panel-collapse collapse {{'in' if not panels['panel_counters_hosts']['collapsed'] else ''}}">
                    <div class="panel-body">
                        %for state in 'up', 'unreachable', 'down', 'unknown':
                        <div class="col-xs-6 col-md-3 text-center">
                            %label = "%d<br/><em>(%s)</em>" % (h['nb_' + state], state)
                            <a role="button" href="/all?search=type:host is:{{state}} isnot:ack isnot:downtime" class="font-{{state.lower()}}">
                                <span class="hosts-count" data-count="{{ h['nb_' + state] }}" data-state="{{ state }}" style="font-size: 3em;">{{ h['nb_' + state] }}</span>
                                <br/>
                                <span style="font-size: 1.5em;">{{ state }}</span>
                            </a>
                        </div>
                        %end
                    </div>
                </div>
            </div>
        </div>
        <div class="col-md-6" id="panel_counters_services">
            <div class="panel panel-default">
                <div class="panel-heading">
                    <i class="fa fa-cubes"></i>
                    <span class="services-all" data-count="{{ s['nb_elts'] }}" data-problems="{{ s['nb_problems'] }}">
                        {{s['nb_elts']}} services{{! "<em class='font-down'> (%d problems).</em>" % (s['nb_problems']) if s['nb_problems'] else '.'}}
                    </span>
                    <div class="pull-right">
                        <a href="#p_panel_counters_services" data-toggle="collapse" type="button" class="btn btn-xs"><i class="fa {{'fa-minus-square' if not panels['panel_counters_services']['collapsed'] else 'fa-plus-square'}} fa-fw"></i></a>
                    </div>
                </div>
                <div id="p_panel_counters_services" class="panel-collapse collapse {{'in' if not panels['panel_counters_services']['collapsed'] else ''}}">
                    <div class="panel-body">
                        %for state in 'ok', 'warning', 'critical', 'unknown':
                        <div class="col-xs-6 col-md-3 text-center">
                            %label = "%d<br/><em>(%s)</em>" % (s['nb_' + state], state)
                            <a role="button" href="/all?search=type:service is:{{state}} isnot:ack isnot:downtime" class="font-{{state.lower()}}">
                                <span class="services-count" data-count="{{ s['nb_' + state] }}" data-state="{{ state }}" style="font-size: 3em;">{{ s['nb_' + state] }}</span>
                                <br/>
                                <span style="font-size: 1.5em;">{{ state }}</span>
                            </a>
                        </div>
                        %end
                    </div>
                </div>
            </div>
        </div>
    </div>

    <div id="one-eye-icons" class="col-xs-12">
        <div class="col-md-6" id="panel_percentage_hosts">
            <div class="panel panel-default">
                <div class="panel-heading">
                    <i class="fa fa-server"></i>
                    <span class="hosts-all" data-count="{{ h['nb_elts'] }}" data-problems="{{ h['nb_problems'] }}">
                        {{h['nb_elts']}} hosts{{! "<em class='font-down'> (%d problems).</em>" % (h['nb_problems']) if h['nb_problems'] else '.'}}
                    </span>
                    <div class="pull-right">
                        <a href="#p_panel_percentage_hosts" data-toggle="collapse" type="button" class="btn btn-xs"><i class="fa {{'fa-minus-square' if not panels['panel_percentage_hosts']['collapsed'] else 'fa-plus-square'}} fa-fw"></i></a>
                    </div>
                </div>
                <div id="p_panel_percentage_hosts" class="panel-collapse collapse {{'in' if not panels['panel_percentage_hosts']['collapsed'] else ''}}">
                    <div class="panel-body">
                        <!-- Hosts SLA icons -->
                        <div class="col-xs-4 col-sm-4 text-center">
                            %if username != 'anonymous':
                            <a href="/all?search=type:host" class="btn">
                            %end
                               <div>
                                  %state = (100 - h['pct_up'])
                                  %font='ok' if state >= app.hosts_states_warning else 'warning' if state >= app.hosts_states_critical else 'critical'
                                  <span class="badger-big badger-right font-{{font}}">{{state}}%</span>
                               </div>

                               <i class="fa fa-4x fa-server font-{{font}}"></i>
                               <p class="badger-title font-{{font}}">&nbsp;SLA</p>

                            %if username != 'anonymous':
                            </a>
                            %end
                        </div>

                        %for state in 'up', 'unreachable', 'down':
                        <div class="col-xs-4 col-sm-4 text-center">
                            <a role="button" href="/all?search=type:host is:{{state}} isnot:ack isnot:downtime" class="font-{{state.lower()}}">
                                <span class="hosts-count" data-count="{{ h['nb_' + state] }}" data-state="{{ state }}" style="font-size: 1.8em;">{{ h['pct_' + state] }}%</span>
                                <br/>
                                <span style="font-size: 1em;">{{ state }}</span>
                            </a>
                        </div>
                        %end
                        %known_problems=h['nb_ack']+h['nb_downtime']+h['nb_unknown']
                        %pct_known_problems=round(100.0 * known_problems / h['nb_elts'], 2)
                        <div class="col-xs-4 col-sm-4 text-center">
                            <a role="button" href="/all?search=type:host is:ack" class="font-unknown">
                                <span class="hosts-count" data-count="{{ h['nb_' + state] }}" data-state="{{ state }}" style="font-size: 1.8em;">{{ pct_known_problems }}%</span>
                                <br/>
                                <span style="font-size: 1em;">Known problems</span>
                            </a>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        <div class="col-md-6" id="panel_percentage_services">
            <div class="panel panel-default">
                <div class="panel-heading">
                    <i class="fa fa-cubes"></i>
                    <span class="services-all" data-count="{{ s['nb_elts'] }}" data-problems="{{ s['nb_problems'] }}">
                        {{s['nb_elts']}} services{{! "<em class='font-down'> (%d problems).</em>" % (s['nb_problems']) if s['nb_problems'] else '.'}}
                    </span>
                    <div class="pull-right">
                        <a href="#p_panel_percentage_services" data-toggle="collapse" type="button" class="btn btn-xs"><i class="fa {{'fa-minus-square' if not panels['panel_percentage_services']['collapsed'] else 'fa-plus-square'}} fa-fw"></i></a>
                    </div>
                </div>
                <div id="p_panel_percentage_services" class="panel-collapse collapse {{'in' if not panels['panel_percentage_services']['collapsed'] else ''}}">
                    <div class="panel-body">
                        <!-- Services SLA icons -->
                        <div class="col-xs-4 col-sm-4 text-center">
                            %if username != 'anonymous':
                            <a href="/all?search=type:service" class="btn">
                            %end
                               <div>
                                  %state = (100 - s['pct_ok'])
                                  %font='ok' if state >= app.services_states_warning else 'warning' if state >= app.services_states_critical else 'critical'
                                  <span class="badger-big badger-right font-{{font}}">{{state}}%</span>
                               </div>

                               <i class="fa fa-4x fa-server font-{{font}}"></i>
                               <p class="badger-title font-{{font}}">&nbsp;SLA</p>

                            %if username != 'anonymous':
                            </a>
                            %end
                        </div>

                        %for state in 'ok', 'warning', 'critical':
                        <div class="col-xs-4 col-sm-4 text-center">
                            <a role="button" href="/all?search=type:service is:{{state}} isnot:ack isnot:downtime" class="font-{{state.lower()}}">
                                <span class="services-count" data-count="{{ s['nb_' + state] }}" data-state="{{ state }}" style="font-size: 1.8em;">{{ s['pct_' + state] }}%</span>
                                <br/>
                                <span style="font-size: 1em;">{{ state }}</span>
                            </a>
                        </div>
                        %end
                        %known_problems=s['nb_ack']+s['nb_downtime']+s['nb_unknown']
                        %pct_known_problems=round(100.0 * known_problems / s['nb_elts'], 2)
                        <div class="col-xs-4 col-sm-4 text-center">
                            <a role="button" href="/all?search=type:service is:ack" class="font-unknown">
                                <span class="services-count" data-count="{{ s['nb_' + state] }}" data-state="{{ state }}" style="font-size: 1.8em;">{{ pct_known_problems }}%</span>
                                <br/>
                                <span style="font-size: 1em;">Known problems</span>
                            </a>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <div id="livestate-graphs" class="col-xs-12">
        <div class="col-md-6" id="panel_pie_graph_hosts">
            <div class="panel panel-default">
                <div class="panel-heading">
                    <i class="fa fa-pie-chart"></i>
                    <span class="hosts-all" data-count="{{ h['nb_elts'] }}" data-problems="{{ h['nb_problems'] }}">
                        {{h['nb_elts']}} hosts{{! "<em class='font-down'> (%d problems).</em>" % (h['nb_problems']) if h['nb_problems'] else '.'}}
                    </span>
                    <div class="pull-right">
                        <div class="btn-group">
                            <button type="button" class="btn btn-default btn-xs dropdown-toggle" data-toggle="dropdown">
                                <i class="fa fa-gear fa-fw"></i>
                                <span class="caret"></span>
                            </button>
                            <ul class="dropdown-menu pull-right" role="menu">
                                <li>
                                    <a href="#" data-action="toggle-legend" data-graph="pie_graph_hosts" class="{{'active' if graphs['pie_graph_hosts']['legend'] else ''}}">
                                        {{! helper.get_on_off(graphs['pie_graph_hosts']['legend'], 'Display graph legend?')}}&nbsp;legend
                                    </a>
                                </li>
                                <li>
                                    <a href="#" data-action="toggle-title" data-graph="pie_graph_hosts" class="{{'active' if graphs['pie_graph_hosts']['title'] else ''}}">
                                        {{! helper.get_on_off(graphs['pie_graph_hosts']['title'], 'Display graph title?')}}&nbsp;title
                                    </a>
                                </li>
                                <li class="divider"></li>
                                %for state in graphs['pie_graph_hosts']['states']:
                                <li>
                                    <a href="#" data-action="toggle-state" data-graph="pie_graph_hosts" data-state="{{state}}" class="{{'active' if graphs['pie_graph_hosts']['display_states'][state] else ''}}">
                                        {{! helper.get_on_off(graphs['pie_graph_hosts']['display_states'][state], 'Display state {{state?')}}&nbsp;state {{state}}
                                    </a>
                                </li>
                                %end
                            </ul>
                        </div>
                        <a href="#p_panel_pie_graph_hosts" data-toggle="collapse" type="button" class="btn btn-xs"><i class="fa {{'fa-minus-square' if not panels['panel_pie_graph_hosts']['collapsed'] else 'fa-plus-square'}} fa-fw"></i></a>
                    </div>
                </div>
                <div id="p_panel_pie_graph_hosts" class="panel-collapse collapse {{'in' if not panels['panel_pie_graph_hosts']['collapsed'] else ''}}">
                    <div class="panel-body">
                        <!-- Chart -->
                        <div id="pie-graph-hosts">
                            <div class="well">
                                <canvas></canvas>
                                <div class="row title" style="display:none">
                                    <div class="text-center">
                                        <h4>Hosts states</h4>
                                        <span class="text-muted">-/-</span>
                                    </div>
                                </div>
                                <div class="row legend" style="display-none">
                                    <div class="pull-left well well-sm" style="margin-bottom: 0px">
                                        <span class="legend hidden-sm hidden-xs"></span>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        <div class="col-md-6" id="panel_pie_graph_services">
            <div class="panel panel-default">
                <div class="panel-heading">
                    <i class="fa fa-pie-chart"></i>
                    <span class="services-all" data-count="{{ s['nb_elts'] }}" data-problems="{{ s['nb_problems'] }}">
                        {{s['nb_elts']}} services{{! "<em class='font-down'> (%d problems).</em>" % (s['nb_problems']) if s['nb_problems'] else '.'}}
                    </span>
                    <div class="pull-right">
                        <div class="btn-group">
                            <button type="button" class="btn btn-default btn-xs dropdown-toggle" data-toggle="dropdown">
                                <i class="fa fa-gear fa-fw"></i>
                                <span class="caret"></span>
                            </button>
                            <ul class="dropdown-menu pull-right" role="menu">
                                <li>
                                    <a href="#" data-action="toggle-legend" data-graph="pie_graph_services" class="{{'active' if graphs['pie_graph_services']['legend'] else ''}}">
                                        {{! helper.get_on_off(graphs['pie_graph_services']['legend'], 'Display graph legend?')}}&nbsp;legend
                                    </a>
                                </li>
                                <li>
                                    <a href="#" data-action="toggle-title" data-graph="pie_graph_services" class="{{'active' if graphs['pie_graph_services']['title'] else ''}}">
                                        {{! helper.get_on_off(graphs['pie_graph_services']['title'], 'Display graph title?')}}&nbsp;title
                                    </a>
                                </li>
                                <li class="divider"></li>
                                %for state in graphs['pie_graph_services']['states']:
                                <li>
                                    <a href="#" data-action="toggle-state" data-graph="pie_graph_services" data-state="{{state}}" class="{{'active' if graphs['pie_graph_services']['display_states'][state] else ''}}">
                                        {{! helper.get_on_off(graphs['pie_graph_services']['display_states'][state], 'Display state {{state?')}}&nbsp;state {{state}}
                                    </a>
                                </li>
                                %end
                            </ul>
                        </div>
                        <a href="#p_panel_pie_graph_services" data-toggle="collapse" type="button" class="btn btn-xs"><i class="fa {{'fa-minus-square' if not panels['panel_pie_graph_services']['collapsed'] else 'fa-plus-square'}} fa-fw"></i></a>
                    </div>
                </div>
                <div id="p_panel_pie_graph_services" class="panel-collapse collapse {{'in' if not panels['panel_pie_graph_services']['collapsed'] else ''}}">
                    <div class="panel-body">
                        <!-- Chart -->
                        <div id="pie-graph-services">
                            <div class="well">
                                <canvas></canvas>
                                <div class="row title" style="display:none">
                                    <div class="text-center">
                                        <h4 class="title">Services states</h4>
                                        <span class="subtitle text-muted">-/-</span>
                                    </div>
                                </div>
                                <div class="row legend" style="display:none">
                                    <div class="pull-left well well-sm" style="margin-bottom: 0px">
                                        <span class="legend hidden-sm hidden-xs"></span>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        <div class="col-md-6" id="panel_line_graph_hosts">
            <div class="panel panel-default">
                <div class="panel-heading">
                    <i class="fa fa-bar-chart"></i>
                    <span class="hosts-all" data-count="{{ h['nb_elts'] }}" data-problems="{{ h['nb_problems'] }}">
                        {{h['nb_elts']}} hosts{{! "<em class='font-down'> (%d problems).</em>" % (h['nb_problems']) if h['nb_problems'] else '.'}}
                    </span>
                    <div class="pull-right">
                        <div class="btn-group">
                            <button type="button" class="btn btn-default btn-xs dropdown-toggle" data-toggle="dropdown">
                                <i class="fa fa-gear fa-fw"></i>
                                <span class="caret"></span>
                            </button>
                            <ul class="dropdown-menu pull-right" role="menu">
                                <li>
                                    <a href="#" data-action="toggle-legend" data-graph="line_graph_hosts" class="{{'active' if graphs['line_graph_hosts']['legend'] else ''}}">
                                        {{! helper.get_on_off(graphs['line_graph_hosts']['legend'], 'Display graph legend?')}}&nbsp;legend
                                    </a>
                                </li>
                                <li>
                                    <a href="#" data-action="toggle-title" data-graph="line_graph_hosts" class="{{'active' if graphs['line_graph_hosts']['title'] else ''}}">
                                        {{! helper.get_on_off(graphs['line_graph_hosts']['title'], 'Display graph title?')}}&nbsp;title
                                    </a>
                                </li>
                                <li class="divider"></li>
                                %for state in graphs['line_graph_hosts']['states']:
                                <li>
                                    <a href="#" data-action="toggle-state" data-graph="line_graph_hosts" data-state="{{state}}" class="{{'active' if graphs['line_graph_hosts']['display_states'][state] else ''}}">
                                        {{! helper.get_on_off(graphs['line_graph_hosts']['display_states'][state], 'Display state {{state?')}}&nbsp;state {{state}}
                                    </a>
                                </li>
                                %end
                            </ul>
                        </div>
                        <a href="#p_panel_line_graph_hosts" data-toggle="collapse" type="button" class="btn btn-xs"><i class="fa {{'fa-minus-square' if not panels['panel_line_graph_hosts']['collapsed'] else 'fa-plus-square'}} fa-fw"></i></a>
                    </div>
                </div>
                <div id="p_panel_line_graph_hosts" class="panel-collapse collapse {{'in' if not panels['panel_line_graph_hosts']['collapsed'] else ''}}">
                    <div class="panel-body">
                        <!-- Chart -->
                        <div id="line-graph-hosts">
                            <div class="well">
                                <canvas></canvas>
                                <div class="row title" style="display:none">
                                    <div class="text-center">
                                        <h4 class="title">Hosts states monitoring</h4>
                                        <span class="subtitle text-muted">-/-</span>
                                    </div>
                                </div>
                                <div class="row legend" style="display:none">
                                    <div class="pull-left well well-sm" style="margin-bottom: 0px">
                                        <span class="legend hidden-sm hidden-xs"></span>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        <div class="col-md-6" id="panel_line_graph_services">
            <div class="panel panel-default">
                <div class="panel-heading">
                    <i class="fa fa-bar-chart"></i>
                    <span class="services-all" data-count="{{ s['nb_elts'] }}" data-problems="{{ s['nb_problems'] }}">
                        {{s['nb_elts']}} services{{! "<em class='font-down'> (%d problems).</em>" % (s['nb_problems']) if s['nb_problems'] else '.'}}
                    </span>
                    <div class="pull-right">
                        <div class="btn-group">
                            <button type="button" class="btn btn-default btn-xs dropdown-toggle" data-toggle="dropdown">
                                <i class="fa fa-gear fa-fw"></i>
                                <span class="caret"></span>
                            </button>
                            <ul class="dropdown-menu pull-right" role="menu">
                                <li>
                                    <a href="#" data-action="toggle-legend" data-graph="line_graph_services" class="{{'active' if graphs['line_graph_services']['legend'] else ''}}">
                                        {{! helper.get_on_off(graphs['line_graph_services']['legend'], 'Display graph legend?')}}&nbsp;legend
                                    </a>
                                </li>
                                <li>
                                    <a href="#" data-action="toggle-title" data-graph="line_graph_services" class="{{'active' if graphs['line_graph_services']['title'] else ''}}">
                                        {{! helper.get_on_off(graphs['line_graph_services']['title'], 'Display graph title?')}}&nbsp;title
                                    </a>
                                </li>
                                <li class="divider"></li>
                                %for state in graphs['line_graph_services']['states']:
                                <li>
                                    <a href="#" data-action="toggle-state" data-graph="line_graph_services" data-state="{{state}}" class="{{'active' if graphs['line_graph_services']['display_states'][state] else ''}}">
                                        {{! helper.get_on_off(graphs['line_graph_services']['display_states'][state], 'Display state {{state?')}}&nbsp;state {{state}}
                                    </a>
                                </li>
                                %end
                            </ul>
                        </div>
                        <a href="#p_panel_line_graph_services" data-toggle="collapse" type="button" class="btn btn-xs"><i class="fa {{'fa-minus-square' if not panels['panel_line_graph_services']['collapsed'] else 'fa-plus-square'}} fa-fw"></i></a>
                    </div>
                </div>
                <div id="p_panel_line_graph_services" class="panel-collapse collapse {{'in' if not panels['panel_line_graph_services']['collapsed'] else ''}}">
                    <div class="panel-body">
                        <!-- Chart -->
                        <div id="line-graph-services">
                            <div class="well">
                                <canvas></canvas>
                                <div class="row title" style="display:none">
                                    <div class="text-center">
                                        <h4 class="title">Services states monitoring</h4>
                                        <span class="subtitle text-muted">-/-</span>
                                    </div>
                                </div>
                                <div class="row legend" style="display:none">
                                    <div class="pull-left well well-sm" style="margin-bottom: 0px">
                                        <span class="legend hidden-sm hidden-xs"></span>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
</div>
<script>
/*
 * Expert configuration for page graphs.
 * ------------------------------------------
 * Based on: http://www.chartjs.org/docs/
 */

    Chart.defaults.global = {
        // Boolean - Whether to animate the chart
        animation: false,

        // Number - Number of animation steps
        animationSteps: 60,

        // String - Animation easing effect
        // Possible effects are:
        // [easeInOutQuart, linear, easeOutBounce, easeInBack, easeInOutQuad,
        //  easeOutQuart, easeOutQuad, easeInOutBounce, easeOutSine, easeInOutCubic,
        //  easeInExpo, easeInOutBack, easeInCirc, easeInOutElastic, easeOutBack,
        //  easeInQuad, easeInOutExpo, easeInQuart, easeOutQuint, easeInOutCirc,
        //  easeInSine, easeOutExpo, easeOutCirc, easeOutCubic, easeInQuint,
        //  easeInElastic, easeInOutSine, easeInOutQuint, easeInBounce,
        //  easeOutElastic, easeInCubic]
        animationEasing: "easeOutQuart",

        // Boolean - If we should show the scale at all
        showScale: true,

        // Boolean - If we want to override with a hard coded scale
        scaleOverride: false,

        // ** Required if scaleOverride is true **
        // Number - The number of steps in a hard coded scale
        scaleSteps: null,
        // Number - The value jump in the hard coded scale
        scaleStepWidth: null,
        // Number - The scale starting value
        scaleStartValue: null,

        // String - Colour of the scale line
        scaleLineColor: "rgba(0,0,0,.1)",

        // Number - Pixel width of the scale line
        scaleLineWidth: 1,

        // Boolean - Whether to show labels on the scale
        scaleShowLabels: true,

        // Interpolated JS string - can access value
        scaleLabel: "<%=value%>",

        // Boolean - Whether the scale should stick to integers, not floats even if drawing space is there
        scaleIntegersOnly: true,

        // Boolean - Whether the scale should start at zero, or an order of magnitude down from the lowest value
        scaleBeginAtZero: false,

        // String - Scale label font declaration for the scale label
        scaleFontFamily: "'Helvetica Neue', 'Helvetica', 'Arial', sans-serif",

        // Number - Scale label font size in pixels
        scaleFontSize: 12,

        // String - Scale label font weight style
        scaleFontStyle: "normal",

        // String - Scale label font colour
        scaleFontColor: "#666",

        // Boolean - whether or not the chart should be responsive and resize when the browser does.
        responsive: true,

        // Boolean - whether to maintain the starting aspect ratio or not when responsive, if set to false, will take up entire container
        maintainAspectRatio: true,

        // Boolean - Determines whether to draw tooltips on the canvas or not
        showTooltips: true,

        // Function - Determines whether to execute the customTooltips function instead of drawing the built in tooltips (See [Advanced - External Tooltips](#advanced-usage-custom-tooltips))
        customTooltips: function(tooltip) {
            if (! tooltip) return;
            //console.log(tooltip)
        },

        // Array - Array of string names to attach tooltip events
        tooltipEvents: ["mousemove", "touchstart", "touchmove"],

        // String - Tooltip background colour
        tooltipFillColor: "rgba(0,0,0,0.8)",

        // String - Tooltip label font declaration for the scale label
        tooltipFontFamily: "'Helvetica Neue', 'Helvetica', 'Arial', sans-serif",

        // Number - Tooltip label font size in pixels
        tooltipFontSize: 14,

        // String - Tooltip font weight style
        tooltipFontStyle: "normal",

        // String - Tooltip label font colour
        tooltipFontColor: "#fff",

        // String - Tooltip title font declaration for the scale label
        tooltipTitleFontFamily: "'Helvetica Neue', 'Helvetica', 'Arial', sans-serif",

        // Number - Tooltip title font size in pixels
        tooltipTitleFontSize: 14,

        // String - Tooltip title font weight style
        tooltipTitleFontStyle: "bold",

        // String - Tooltip title font colour
        tooltipTitleFontColor: "#fff",

        // Number - pixel width of padding around tooltip text
        tooltipYPadding: 6,

        // Number - pixel width of padding around tooltip text
        tooltipXPadding: 6,

        // Number - Size of the caret on the tooltip
        tooltipCaretSize: 8,

        // Number - Pixel radius of the tooltip border
        tooltipCornerRadius: 6,

        // Number - Pixel offset from point x to tooltip edge
        tooltipXOffset: 10,

        // String - Template string for single tooltips
        tooltipTemplate: "<%if (label){%><%=label%>: <%}%><%= value %>",

        // String - Template string for multiple tooltips
        multiTooltipTemplate: "<%= value %>",

        // Function - Will fire on animation progression.
        onAnimationProgress: function(){},

        // Function - Will fire on animation completion.
        onAnimationComplete: function(){}
    };

    var hosts_states_queue_length = {{ hosts_states_queue_length }};
    var services_states_queue_length = {{ services_states_queue_length }};
    var states_queue = {
        "nb_hosts_up": [], "nb_hosts_unreachable": [], "nb_hosts_down": [], "nb_hosts_unknown": [],
        "nb_services_ok": [], "nb_services_warning": [], "nb_services_critical": [], "nb_services_unknown": []
    };

    %for state in graphs['pie_graph_hosts']['states']:
        for (var i=0; i<hosts_states_queue_length; i++) {
            states_queue["nb_hosts_{{state}}"].push(0);
        }
    %end
    %for state in graphs['pie_graph_services']['states']:
        for (var i=0; i<services_states_queue_length; i++) {
            states_queue["nb_services_{{state}}"].push(0);
        }
    %end

    var pie_graph_hosts_parameters = {
        "up": {
            color:"#5bb75b",
            highlight: "#5AD3D1",
            label: "Up"
        },
        "unreachable": {
            color: "#faa732",
            highlight: "#5AD3D1",
            label: "Unreachable"
        },
        "down": {
            color: "#da4f49",
            highlight: "#5AD3D1",
            label: "Down"
        },
        "unknown": {
            color: "#5AD3D1",
            highlight: "#5AD3D1",
            label: "Unknown"
        }
    };
    var pie_graph_hosts_options = {
        legendTemplate: [
            '<div id="pie_graph_hosts_legend">',
                '<% for (var i=0; i<segments.length; i++)\{\%>',
                    '<div>',
                        '<span style="background-color:<%=segments[i].fillColor%>; display: inline-block; width: 12px; height: 12px; margin-right: 5px;"></span>',
                        '<small>',
                        '<%=segments[i].label%>',
                        '<%if(segments[i].value)\{\%>',
                            ' (<%=segments[i].value%>)',
                        '<%\}\%>',
                        '</small>',
                    '</div>',
                '<%}%>',
            '</div>'
        ].join('')
    };

    var line_graph_hosts_states = {{ !json.dumps(graphs['pie_graph_hosts']['states']) }};
    var line_graph_hosts_data = {
        labels: [],
        datasets: {
            "up": {
                label: "Hosts up",
                fillColor: "rgba(91,183,91,0.2)",
                strokeColor: "rgba(91,183,91,1)",
                pointColor: "rgba(91,183,91,1)",
                pointStrokeColor: "#fff",
                pointHighlightFill: "#fff",
                pointHighlightStroke: "rgba(220,220,220,1)"
            },
            "unreachable": {
                label: "Hosts unreachable",
                fillColor: "rgba(250,167,50,0.2)",
                strokeColor: "rgba(250,167,50,1)",
                pointColor: "rgba(250,167,50,1)",
                pointStrokeColor: "#fff",
                pointHighlightFill: "#fff",
                pointHighlightStroke: "rgba(151,187,205,1)"
           },
           "down": {
                label: "Hosts down",
                fillColor: "rgba(218,79,73,0.2)",
                strokeColor: "rgba(218,79,73,1)",
                pointColor: "rgba(218,79,73,1)",
                pointStrokeColor: "#fff",
                pointHighlightFill: "#fff",
                pointHighlightStroke: "rgba(220,220,220,1)"
           },
           "unknown": {
                label: "Hosts unknown",
                fillColor: "rgba(90,211,209,0.2)",
                strokeColor: "rgba(90,211,209,1)",
                pointColor: "rgba(90,211,209,1)",
                pointStrokeColor: "#fff",
                pointHighlightFill: "#fff",
                pointHighlightStroke: "rgba(220,220,220,1)"
           }
        }
    };
    // Labels are refresh periods ...
    for (i=-hosts_states_queue_length; i<=0; i++) {
        line_graph_hosts_data['labels'].push(moment().subtract(-i * app_refresh_period, 'seconds').fromNow());
    }
    var line_graph_hosts_options = {
        ///Boolean - Whether grid lines are shown across the chart
        scaleShowGridLines : true,

        //String - Colour of the grid lines
        scaleGridLineColor : "rgba(0,0,0,.05)",

        //Number - Width of the grid lines
        scaleGridLineWidth : 1,

        //Boolean - Whether to show horizontal lines (except X axis)
        scaleShowHorizontalLines: false,

        //Boolean - Whether to show vertical lines (except Y axis)
        scaleShowVerticalLines: false,

        //Boolean - Whether the line is curved between points
        bezierCurve : true,

        //Number - Tension of the bezier curve between points
        bezierCurveTension : 0.4,

        //Boolean - Whether to show a dot for each point
        pointDot : true,

        //Number - Radius of each point dot in pixels
        pointDotRadius : 4,

        //Number - Pixel width of point dot stroke
        pointDotStrokeWidth : 1,

        //Number - amount extra to add to the radius to cater for hit detection outside the drawn point
        pointHitDetectionRadius : 20,

        //Boolean - Whether to show a stroke for datasets
        datasetStroke : true,

        //Number - Pixel width of dataset stroke
        datasetStrokeWidth : 2,

        //Boolean - Whether to fill the dataset with a colour
        datasetFill : true,

        pointDot: true,

        //String - A legend template
        legendTemplate: [
            '<div id="line_graph_hosts_legend">',
                '<% for (var i=0; i<datasets.length; i++)\{\%>',
                    '<div>',
                        '<span style="background-color:<%=datasets[i].strokeColor%>; display: inline-block; width: 12px; height: 12px; margin-right: 5px;"></span>',
                        '<small>',
                        '<%=datasets[i].label%>',
                        '<%if(datasets[i].value)\{\%>',
                            ' (<%=datasets[i].value%>)',
                        '<%\}\%>',
                        '</small>',
                    '</div>',
                '<%}%>',
            '</div>'
        ].join('')
    };

    var pie_graph_services_parameters = {
        "ok": {
            color:"#5bb75b",
            highlight: "#5AD3D1",
            label: "Ok"
        },
        "warning": {
            color: "#faa732",
            highlight: "#5AD3D1",
            label: "Warning"
        },
        "critical": {
            color: "#da4f49",
            highlight: "#5AD3D1",
            label: "Critical"
        },
        "unknown": {
            color: "#5AD3D1",
            highlight: "#5AD3D1",
            label: "Unknown"
        }
    }
    var pie_graph_services_options = {
        legendTemplate: [
            '<div id="pie_graph_services_legend">',
                '<% for (var i=0; i<segments.length; i++)\{\%>',
                    '<div>',
                        '<span style="background-color:<%=segments[i].fillColor%>; display: inline-block; width: 12px; height: 12px; margin-right: 5px;"></span>',
                        '<small>',
                        '<%=segments[i].label%>',
                        '<%if(segments[i].value)\{\%>',
                            ' (<%=segments[i].value%>)',
                        '<%\}\%>',
                        '</small>',
                    '</div>',
                '<%}%>',
            '</div>'
        ].join('')
    }

    var line_graph_services_states = {{ !json.dumps(graphs['line_graph_services']['states']) }};
    var line_graph_services_data = {
        labels: [],
        datasets: {
            "ok": {
                label: "Services ok",
                fillColor: "rgba(91,183,91,0.2)",
                strokeColor: "rgba(91,183,91,1)",
                pointColor: "rgba(91,183,91,1)",
                pointStrokeColor: "#fff",
                pointHighlightFill: "#fff",
                pointHighlightStroke: "rgba(220,220,220,1)"
            },
            "warning": {
                label: "Services warning",
                fillColor: "rgba(250,167,50,0.2)",
                strokeColor: "rgba(250,167,50,1)",
                pointColor: "rgba(250,167,50,1)",
                pointStrokeColor: "#fff",
                pointHighlightFill: "#fff",
                pointHighlightStroke: "rgba(151,187,205,1)"
           },
           "critical": {
                label: "Services critical",
                fillColor: "rgba(218,79,73,0.2)",
                strokeColor: "rgba(218,79,73,1)",
                pointColor: "rgba(218,79,73,1)",
                pointStrokeColor: "#fff",
                pointHighlightFill: "#fff",
                pointHighlightStroke: "rgba(220,220,220,1)"
           },
           "unknown": {
                label: "Services unknown",
                fillColor: "rgba(90,211,209,0.2)",
                strokeColor: "rgba(90,211,209,1)",
                pointColor: "rgba(90,211,209,1)",
                pointStrokeColor: "#fff",
                pointHighlightFill: "#fff",
                pointHighlightStroke: "rgba(220,220,220,1)"
           }
        }
    };
    // Labels are refresh periods ...
    for (i=-services_states_queue_length; i<=0; i++) {
        line_graph_services_data['labels'].push(moment().subtract(-i * app_refresh_period, 'seconds').fromNow());
    }
    var line_graph_services_options = {
        ///Boolean - Whether grid lines are shown across the chart
        scaleShowGridLines : true,

        //String - Colour of the grid lines
        scaleGridLineColor : "rgba(0,0,0,.05)",

        //Number - Width of the grid lines
        scaleGridLineWidth : 1,

        //Boolean - Whether to show horizontal lines (except X axis)
        scaleShowHorizontalLines: false,

        //Boolean - Whether to show vertical lines (except Y axis)
        scaleShowVerticalLines: false,

        //Boolean - Whether the line is curved between points
        bezierCurve : true,

        //Number - Tension of the bezier curve between points
        bezierCurveTension : 0.4,

        //Boolean - Whether to show a dot for each point
        pointDot : true,

        //Number - Radius of each point dot in pixels
        pointDotRadius : 4,

        //Number - Pixel width of point dot stroke
        pointDotStrokeWidth : 1,

        //Number - amount extra to add to the radius to cater for hit detection outside the drawn point
        pointHitDetectionRadius : 20,

        //Boolean - Whether to show a stroke for datasets
        datasetStroke : true,

        //Number - Pixel width of dataset stroke
        datasetStrokeWidth : 2,

        //Boolean - Whether to fill the dataset with a colour
        datasetFill : true,

        pointDot: true,

        //String - A legend template
        //legendTemplate : "<ul class=\"<%=name.toLowerCase()%>-legend\"><% for (var i=0; i<datasets.length; i++){%><li><span style=\"background-color:<%=datasets[i].strokeColor%>\"></span><%if(datasets[i].label){%><%=datasets[i].label%><%}%></li><%}%></ul>"
        legendTemplate: [
            '<div id="line_graph_services_legend">',
                '<% for (var i=0; i<datasets.length; i++)\{\%>',
                    '<div>',
                        '<span style="background-color:<%=datasets[i].strokeColor%>; display: inline-block; width: 12px; height: 12px; margin-right: 5px;"></span>',
                        '<small>',
                        '<%=datasets[i].label%>',
                        '<%if(datasets[i].value)\{\%>',
                            '<%=datasets[i].value%>',
                        '<%\}\%>',
                        '</small>',
                    '</div>',
                '<%}%>',
            '</div>'
        ].join('')
    };
</script>
