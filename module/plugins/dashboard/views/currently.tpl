%setdefault('refresh', True)
%rebase("fullscreen", css=['dashboard/css/currently.css'], js=['dashboard/js/Chart.Core.js', 'dashboard/js/Chart.Doughnut.js', 'dashboard/js/Chart.Line.js'], title='Shinken currently')

%import json

%setdefault('panels', None)
%create_panels_preferences = False
%if not 'panel_counters_hosts' in panels:
%panels['panel_counters_hosts'] = {'collapsed': False}
%panels['panel_counters_services'] = {'collapsed': False}
%panels['panel_percentage_hosts'] = {'collapsed': False}
%panels['panel_percentage_services'] = {'collapsed': False}
%panels['panel_piecharts_hosts'] = {'collapsed': False}
%panels['panel_piecharts_services'] = {'collapsed': False}
%panels['panel_barcharts_hosts'] = {'collapsed': False}
%panels['panel_barcharts_services'] = {'collapsed': False}
%create_panels_preferences = True
%end

%setdefault('graphs', None)
%setdefault('hosts_states', ['up','down','unreachable','unknown'])
%setdefault('services_states', ['ok','warning','critical','unknown'])

%create_graphs_preferences = False
%if not 'pie_hosts_graph' in graphs:
%graphs['pie_hosts_graph'] = {'legend': True, 'title': True, 'states': hosts_states}
%graphs['pie_services_graph'] = {'legend': True, 'title': True, 'states': services_states}
%graphs['line_hosts_graph'] = {'legend': True, 'title': True, 'states': hosts_states}
%graphs['line_services_graph'] = {'legend': True, 'title': True, 'states': services_states}
%create_graphs_preferences = True
%end

%setdefault('hosts_states_queue_length', 50)
%setdefault('services_states_queue_length', 50)


%helper = app.helper

<script type="text/javascript">
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
    function on_page_refresh() {
        var hosts_count = parseInt($('#one-eye-overall .hosts-all').data("count"));
        var hosts_problems = parseInt($('#one-eye-overall .hosts-all').data("problems"));
        var services_count = parseInt($('#one-eye-overall .services-all').data("count"));
        var services_problems = parseInt($('#one-eye-overall .services-all').data("problems"));

        // Refresh user's preferences
        get_user_preference('panels', function(data) {
            panels=data;
            get_user_preference('graphs', function(data) {
                graphs=data;

                if ($("#chart-hosts").length !== 0) {
                    var data = [];
                    %for state in graphs['pie_hosts_graph']['states']:
                        var counter_value = parseInt($('#one-eye-overall span.hosts-count[data-state="{{state}}"]').data("count"));

                        // Update table rows
                        row = pie_hosts_graph_parameters["{{state}}"];
                        row['value'] = counter_value;
                        data.push(row)
                    %end

                    // Update graph
                    var ctx = $("#chart-hosts canvas").get(0).getContext("2d");
                    var myPieChart = new Chart(ctx).Doughnut(data, pie_hosts_graph_options);
                    if (graphs['pie_hosts_graph'].title) {
                        $("#chart-hosts .title").show();
                        $("#chart-hosts .title span").html(hosts_count + " hosts").show();
                    } else {
                        $("#chart-hosts .title").hide();
                    }
                    if (graphs['pie_hosts_graph']['legend']) {
                        if (line_hosts_graph_options) {
                            $("#chart-hosts .legend").show();
                            if ($("#chart-hosts span.legend").length) {
                                if (! $("#pie_hosts_graph_options-legend").length) {
                                    $("#chart-hosts .legend span").append(myPieChart.generateLegend());
                                }
                                // TODO: Update ...
                            }
                        }
                    } else {
                        $("#chart-hosts .legend").hide();
                    }
                }

                // Hosts line chart
                if ($("#chart-hosts-serie").length !== 0) {
                    var data = [];
                    data['labels'] = line_hosts_graph_data['labels'];
                    data['datasets'] = [];
                    %for state in graphs['line_hosts_graph']['states']:
                        var counter_value = parseInt($('#one-eye-overall span.hosts-count[data-state="{{state}}"]').data("count"));

                        // Update table rows
                        row = line_hosts_graph_data['datasets']["{{state}}"];
                        row['data'] = states_queue["nb_hosts_{{state}}"];
                        data['datasets'].push(row);

                        if (states_queue["nb_hosts_{{state}}"].length > hosts_states_queue_length) {
                            states_queue["nb_hosts_{{state}}"].shift();
                        }
                        states_queue["nb_hosts_{{state}}"].push( counter_value );
                    %end

                    // Get the context of the canvas element we want to select
                    var ctx = $("#chart-hosts-serie canvas").get(0).getContext("2d");
                    var myLineChart = new Chart(ctx).Line(data, line_hosts_graph_options);
                    if (graphs['line_hosts_graph']['title']) {
                        $("#chart-hosts-serie .title").show();
                        $("#chart-hosts-serie .title span").html(hosts_count + " hosts");
                    } else {
                        $("#chart-hosts-serie .title").hide();
                    }
                    if (graphs['line_hosts_graph']['legend']) {
                        if (line_hosts_graph_options) {
                            $("#chart-hosts-serie .legend").show();
                            if ($("#chart-hosts-serie span.legend").length) {
                                if (! $("#line_hosts_graph_options-legend").length) {
                                    $("#chart-hosts-serie span.legend").append(myLineChart.generateLegend());
                                }
                                // TODO: Update ...
                            }
                        }
                    } else {
                        $("#chart-hosts-serie .legend").hide();
                    }
                }

                // Services pie chart
                if ($("#chart-services").length !== 0) {
                    var data = [];
                    %for state in graphs['pie_services_graph']['states']:
                        var counter_value = parseInt($('#one-eye-overall span.services-count[data-state="{{state}}"]').data("count"));

                        // Update table rows
                        row = pie_services_graph_parameters["{{state}}"];
                        row['value'] = counter_value;
                        data.push(row)
                    %end

                    // Get the context of the canvas element we want to select
                    var ctx = $("#chart-services canvas").get(0).getContext("2d");
                    var myPieChart = new Chart(ctx).Doughnut(data, pie_services_graph_options);
                    if (graphs['pie_services_graph']['title']) {
                        $("#chart-services .title").show();
                        $("#chart-services .title span").html(services_count + " services");
                    } else {
                        $("#chart-services .title").hide();
                    }
                    if (graphs['pie_services_graph']['legend']) {
                        if (pie_services_graph_options) {
                            $("#chart-services .legend").show();
                            if ($("#chart-services span.legend").length) {
                                if (! $("#pie_services_graph_options-legend").length) {
                                    $("#chart-services span.legend").append(myPieChart.generateLegend());
                                }
                            }
                        }
                    } else {
                        $("#chart-services .legend").hide();
                    }
                }

                // Services line chart
                if ($("#chart-services-serie").length !== 0) {
                    var data = [];
                    data['labels'] = line_services_graph_data['labels'];
                    data['datasets'] = [];
                    %for state in graphs['line_services_graph']['states']:
                        var counter_value = parseInt($('#one-eye-overall span.services-count[data-state="{{state}}"]').data("count"));

                        // Update table rows
                        row = line_services_graph_data['datasets']["{{state}}"];
                        row['data'] = states_queue["nb_services_{{state}}"];
                        data['datasets'].push(row);

                        if (states_queue["nb_services_{{state}}"].length > services_states_queue_length) {
                            states_queue["nb_services_{{state}}"].shift();
                        }
                        states_queue["nb_services_{{state}}"].push(counter_value);
                    %end

                    // Get the context of the canvas element we want to select
                    var ctx = $("#chart-services-serie canvas").get(0).getContext("2d");
                    var myLineChart = new Chart(ctx).Line(data, line_services_graph_options);
                    if (graphs['line_services_graph']['title']) {
                        $("#chart-services-serie .title").show();
                        $("#chart-services-serie .title span").html(services_count + " services");
                    } else {
                        $("#chart-services-serie .title").hide();
                    }
                    if (graphs['line_services_graph']['legend']) {
                        if (line_services_graph_options) {
                            $("#chart-services-serie .legend").hide();
                            if ($("#chart-services-serie span.legend").length) {
                                if (! $("#line_services_graph_options-legend").length) {
                                    $("#chart-services-serie span.legend").append(myLineChart.generateLegend());
                                }
                            }
                        }
                    } else {
                        $("#chart-services-serie .legend").hide();
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

        /*
        setTimeout(function() {
            $('#one-eye-toolbar').hide();
        }, 2000);
        */

        // Toggle sound ...
        if (sessionStorage.getItem("sound_play") == '1') {
            $('#sound_alerting i.fa-ban').addClass('hidden');
        } else {
            $('#sound_alerting i.fa-ban').removeClass('hidden');
        }

        // Panels collapse state
        $('body').on('hidden.bs.collapse', '.panel', function () {
            stop_refresh();
            panels[$(this).attr('id')].collapsed = true;
            $(this).find('.fa-minus-square').removeClass('fa-minus-square').addClass('fa-plus-square');
            save_user_preference('panels', JSON.stringify(panels), function() {
                start_refresh();
                do_refresh();
            });
        });
        $('body').on('shown.bs.collapse', '.panel', function () {
            stop_refresh();
            panels[$(this).attr('id')].collapsed = false;
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
                do_refresh();
            });
        });
        $('body').on('click', '[data-action="toggle-legend"]', function () {
            stop_refresh();
            graphs[$(this).data('graph')].legend = ! graphs[$(this).data('graph')].legend;
            save_user_preference('graphs', JSON.stringify(graphs), function() {
                start_refresh();
                do_refresh();
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

%synthesis = helper.get_synthesis(app.datamgr.search_hosts_and_services("", user))
%s = synthesis['services']
%h = synthesis['hosts']

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
                       <span id="date"></span>
                       <span id="clock"></span>
                    </p>
                </li>
            </ul>
        </div>
    </div>
</div>
</div>
%end

<div class="container-fluid">
<div class="row" style="position: absolute; top:60px; left: 0; z-index: 1000">
    <div id="one-eye-overall" class="col-xs-12">
        <div class="col-md-6">
            <div class="panel panel-default" id="panel_counters_hosts">
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
                            <!--
                            %label = "%s <em><small>(%s%%)</small></em>" % (h['nb_' + state], h['pct_' + state])
                            %label = "<br/>%s<br/><em>(%s)</em>" % (state, h['nb_' + state])
                            <a href="/all?search=type:host is:{{state}} isnot:ack isnot:downtime">
                                {{!helper.get_fa_icon_state_and_label(cls='host', state=state, label=label)}}
                            </a>
                            -->
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
        <div class="col-md-6">
            <div class="panel panel-default" id="panel_counters_services">
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
                            <!--
                            %label = "%s <i>(%s%%)</i>" % (s['nb_' + state], s['pct_' + state])
                            <a href="/all?search=type:host is:{{state}}">
                                {{!helper.get_fa_icon_state_and_label(cls='service', state=state, label=label, disabled=(not s['nb_' + state]))}}
                            </a>
                            -->
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
        <div class="col-md-6">
            <div class="panel panel-default" id="panel_percentage_hosts">
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
                        <!-- Hosts -->
                        <div class="col-xs-6 col-sm-3">
                            %if username != 'anonymous':
                            <a href="/all?search=type:host is:UP" class="btn btn-sm">
                            %end
                               <div>
                                  %state = h['pct_up']
                                  %font='ok' if state >= app.hosts_states_critical else 'warning' if state >= app.hosts_states_warning  else 'critical'
                                  <!--<span class="badger-big badger-left font-{{font}}">{{h['nb_up']}} / {{h['nb_elts']}}</span>-->
                                  <span class="badger-big badger-right font-{{font}}">{{h['pct_up']}}%</span>
                               </div>

                               <i class="fa fa-5x fa-server font-{{font}}"></i>
                               <p class="badger-title font-{{font}}">&nbsp;Hosts up</p>

                            %if username != 'anonymous':
                            </a>
                            %end
                        </div>

                        <div class="col-xs-6 col-sm-3">
                            %if username != 'anonymous':
                            <a href="/all?search=type:host is:UNREACHABLE" class="btn btn-sm">
                            %end
                               <div>
                                  %state = 100.0-h['pct_unreachable']
                                  %font='ok' if state >= app.hosts_states_critical else 'warning' if state >= app.hosts_states_warning else 'critical'
                                  <!--<span class="badger-big badger-left font-{{font}}">{{h['nb_unreachable']}} / {{h['nb_elts']}}</span>-->
                                  <span class="badger-big badger-right font-{{font}}">{{h['pct_unreachable']}}%</span>
                               </div>

                               <i class="fa fa-5x fa-server font-{{font}}"></i>
                               <p class="badger-title font-{{font}}">&nbsp;Hosts unreachable</p>

                            %if username != 'anonymous':
                            </a>
                            %end
                        </div>

                        <div class="col-xs-6 col-sm-3">
                            %if username != 'anonymous':
                            <a href="/all?search=type:host is:DOWN" class="btn btn-sm">
                            %end
                               <div>
                                  %state = 100.0-h['pct_down']
                                  %font='ok' if state >= app.hosts_states_critical else 'warning' if state >= app.hosts_states_warning else 'critical'
                                  <!--<span class="badger-big badger-left font-{{font}}">{{h['nb_down']}} / {{h['nb_elts']}}</span>-->
                                  <span class="badger-big badger-right font-{{font}}">{{h['pct_down']}}%</span>
                               </div>

                               <i class="fa fa-5x fa-server font-{{font}}"></i>
                               <p class="badger-title font-{{font}}">&nbsp;Hosts down</p>

                            %if username != 'anonymous':
                            </a>
                            %end
                        </div>

                        <div class="col-xs-6 col-sm-3">
                            %if username != 'anonymous':
                            <a href="/all?search=type:host is:UNKNOWN" class="btn btn-sm">
                            %end
                               <div>
                                  %state = 100.0-h['pct_unknown']
                                  %font='ok' if state >= app.hosts_states_critical else 'warning' if state >= app.hosts_states_warning else 'critical'
                                  <!--<span class="badger-big badger-left font-{{font}}">{{h['nb_unknown']}} / {{h['nb_elts']}}</span>-->
                                  <span class="badger-big badger-right font-{{font}}">{{h['pct_unknown']}}%</span>
                               </div>

                               <i class="fa fa-5x fa-server font-{{font}}"></i>
                               <p class="badger-title font-{{font}}">&nbsp;Hosts unknown</p>

                            %if username != 'anonymous':
                            </a>
                            %end
                        </div>
                    </div>
                </div>
            </div>
        </div>
        <div class="col-md-6">
            <div class="panel panel-default" id="panel_percentage_services">
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
                        <!-- Services -->
                        <div class="col-xs-6 col-sm-3">
                            %if username != 'anonymous':
                            <a href="/all?search=type:service is:OK" class="btn btn-sm">
                            %end
                               <div>
                                  %state = s['pct_ok']
                                  %font='ok' if state >= app.services_states_critical else 'warning' if state >= app.services_states_warning else 'critical'
                                  <!--<span class="badger-big badger-left font-{{font}}">{{s['nb_ok']}} / {{s['nb_elts']}}</span>-->
                                  <span class="badger-big badger-right font-{{font}}">{{s['pct_ok']}}%</span>
                               </div>

                               <i class="fa fa-5x fa-bars font-{{font}}"></i>
                               <p class="badger-title font-{{font}}">&nbsp;Services ok</p>

                            %if username != 'anonymous':
                            </a>
                            %end
                        </div>

                        <div class="col-xs-6 col-sm-3">
                            %if username != 'anonymous':
                            <a href="/all?search=type:service is:WARNING" class="btn btn-sm">
                            %end
                               <div>
                                  %state = 100.0-s['pct_warning']
                                  %font='ok' if state >= app.services_states_critical else 'warning' if state >= app.services_states_warning else 'critical'
                                  <!--<span class="badger-big badger-left font-{{font}}">{{s['nb_warning']}} / {{s['nb_elts']}}</span>-->
                                  <span class="badger-big badger-right font-{{font}}">{{s['pct_warning']}}%</span>
                               </div>

                               <i class="fa fa-5x fa-bars font-{{font}}"></i>
                               <p class="badger-title font-{{font}}">&nbsp;Services warning</p>

                            %if username != 'anonymous':
                            </a>
                            %end
                        </div>

                        <div class="col-xs-6 col-sm-3">
                            %if username != 'anonymous':
                            <a href="/all?search=type:service is:CRITICAL" class="btn btn-sm">
                            %end
                               <div>
                                  %state = 100.0-s['pct_critical']
                                  %font='ok' if state >= app.services_states_critical else 'warning' if state >= app.services_states_warning else 'critical'
                                  <!--<span class="badger-big badger-left font-{{font}}">{{s['nb_critical']}} / {{s['nb_elts']}}</span>-->
                                  <span class="badger-big badger-right font-{{font}}">{{s['pct_critical']}}%</span>
                               </div>

                               <i class="fa fa-5x fa-bars font-{{font}}"></i>
                               <p class="badger-title font-{{font}}">&nbsp;Services critical</p>

                            %if username != 'anonymous':
                            </a>
                            %end
                        </div>

                        <div class="col-xs-6 col-sm-3">
                            %if username != 'anonymous':
                            <a href="/all?search=type:host is:UNKNOWN" class="btn btn-sm">
                            %end
                               <div>
                                  %state = 100.0-s['pct_unknown']
                                  %font='ok' if state >= app.services_states_critical else 'warning' if state >= app.services_states_warning else 'critical'
                                  <!--<span class="badger-big badger-left font-{{font}}">{{s['nb_unknown']}} / {{s['nb_elts']}}</span>-->
                                  <span class="badger-big badger-right font-{{font}}">{{s['pct_unknown']}}%</span>
                               </div>

                               <i class="fa fa-5x fa-bars font-{{font}}"></i>
                               <p class="badger-title font-{{font}}">&nbsp;Services unknown</p>

                            %if username != 'anonymous':
                            </a>
                            %end
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <div id="livestate-graphs" class="col-xs-12">
        <div class="col-md-6">
            <div class="panel panel-default" id="panel_piecharts_hosts">
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
                                    <a href="#" data-action="toggle-legend" data-graph="pie_hosts_graph" class="{{'active' if graphs['pie_hosts_graph']['legend'] else ''}}">
                                        {{! helper.get_on_off(graphs['pie_hosts_graph']['legend'], 'Display graph legend?')}}&nbsp;display legend
                                    </a>
                                </li>
                                <li class="divider"></li>
                                <li>
                                    <a href="#" data-action="toggle-title" data-graph="pie_hosts_graph" class="{{'active' if graphs['pie_hosts_graph']['title'] else ''}}">
                                        {{! helper.get_on_off(graphs['pie_hosts_graph']['title'], 'Display graph title?')}}&nbsp;display title
                                    </a>
                                </li>
                            </ul>
                        </div>
                        <a href="#p_panel_piecharts_hosts" data-toggle="collapse" type="button" class="btn btn-xs"><i class="fa {{'fa-minus-square' if not panels['panel_piecharts_hosts']['collapsed'] else 'fa-plus-square'}} fa-fw"></i></a>
                    </div>
                </div>
                <div id="p_panel_piecharts_hosts" class="panel-collapse collapse {{'in' if not panels['panel_piecharts_hosts']['collapsed'] else ''}}">
                    <div class="panel-body">
                        <!-- Chart -->
                        <div id="chart-hosts">
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
        <div class="col-md-6">
            <div class="panel panel-default" id="panel_piecharts_services">
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
                                    <a href="#" data-action="toggle-legend" data-graph="pie_services_graph" class="{{'active' if graphs['pie_services_graph']['legend'] else ''}}">
                                        {{! helper.get_on_off(graphs['pie_services_graph']['legend'], 'Display graph legend?')}}&nbsp;display legend
                                    </a>
                                </li>
                                <li class="divider"></li>
                                <li>
                                    <a href="#" data-action="toggle-title" data-graph="pie_services_graph" class="{{'active' if graphs['pie_services_graph']['title'] else ''}}">
                                        {{! helper.get_on_off(graphs['pie_services_graph']['title'], 'Display graph title?')}}&nbsp;display title
                                    </a>
                                </li>
                            </ul>
                        </div>
                        <a href="#p_panel_piecharts_services" data-toggle="collapse" type="button" class="btn btn-xs"><i class="fa {{'fa-minus-square' if not panels['panel_piecharts_services']['collapsed'] else 'fa-plus-square'}} fa-fw"></i></a>
                    </div>
                </div>
                <div id="p_panel_piecharts_services" class="panel-collapse collapse {{'in' if not panels['panel_piecharts_services']['collapsed'] else ''}}">
                    <div class="panel-body">
                        <!-- Chart -->
                        <div id="chart-services">
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
        <div class="col-md-6">
            <div class="panel panel-default" id="panel_barcharts_hosts">
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
                                    <a href="#" data-action="toggle-legend" data-graph="line_hosts_graph" class="{{'active' if graphs['line_hosts_graph']['legend'] else ''}}">
                                        {{! helper.get_on_off(graphs['line_hosts_graph']['legend'], 'Display graph legend?')}}&nbsp;display legend
                                    </a>
                                </li>
                                <li class="divider"></li>
                                <li>
                                    <a href="#" data-action="toggle-title" data-graph="line_hosts_graph" class="{{'active' if graphs['line_hosts_graph']['title'] else ''}}">
                                        {{! helper.get_on_off(graphs['line_hosts_graph']['title'], 'Display graph title?')}}&nbsp;display title
                                    </a>
                                </li>
                            </ul>
                        </div>
                        <a href="#p_panel_barcharts_hosts" data-toggle="collapse" type="button" class="btn btn-xs"><i class="fa {{'fa-minus-square' if not panels['panel_barcharts_hosts']['collapsed'] else 'fa-plus-square'}} fa-fw"></i></a>
                    </div>
                </div>
                <div id="p_panel_barcharts_hosts" class="panel-collapse collapse {{'in' if not panels['panel_barcharts_hosts']['collapsed'] else ''}}">
                    <div class="panel-body">
                        <!-- Chart -->
                        <div id="chart-hosts-serie">
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
        <div class="col-md-6">
            <div class="panel panel-default" id="panel_barcharts_services">
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
                                    <a href="#" data-action="toggle-legend" data-graph="line_services_graph" class="{{'active' if graphs['line_services_graph']['legend'] else ''}}">
                                        {{! helper.get_on_off(graphs['line_services_graph']['legend'], 'Display graph legend?')}}&nbsp;display legend
                                    </a>
                                </li>
                                <li class="divider"></li>
                                <li>
                                    <a href="#" data-action="toggle-title" data-graph="line_services_graph" class="{{'active' if graphs['line_services_graph']['title'] else ''}}">
                                        {{! helper.get_on_off(graphs['line_services_graph']['title'], 'Display graph title?')}}&nbsp;display title
                                    </a>
                                </li>
                            </ul>
                        </div>
                        <a href="#p_panel_barcharts_services" data-toggle="collapse" type="button" class="btn btn-xs"><i class="fa {{'fa-minus-square' if not panels['panel_barcharts_services']['collapsed'] else 'fa-plus-square'}} fa-fw"></i></a>
                    </div>
                </div>
                <div id="p_panel_barcharts_services" class="panel-collapse collapse {{'in' if not panels['panel_barcharts_services']['collapsed'] else ''}}">
                    <div class="panel-body">
                        <!-- Chart -->
                        <div id="chart-services-serie">
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
 * Expert configuration for home page graphs.
 * ------------------------------------------
 */

    Chart.defaults.global.responsive = true;

    var hosts_states_queue_length = {{ hosts_states_queue_length }};
    var services_states_queue_length = {{ services_states_queue_length }};
    var states_queue = {
        "nb_hosts_up": [], "nb_hosts_unreachable": [], "nb_hosts_down": [], "nb_hosts_unknown": [],
        "nb_services_ok": [], "nb_services_warning": [], "nb_services_critical": [], "nb_services_unknown": []
    };

    %for state in graphs['pie_hosts_graph']['states']:
        for (var i=0; i<hosts_states_queue_length; i++) {
            states_queue["nb_hosts_{{state}}"].push(0);
        }
    %end
    %for state in graphs['pie_services_graph']['states']:
        for (var i=0; i<services_states_queue_length; i++) {
            states_queue["nb_services_{{state}}"].push(0);
        }
    %end

    var pie_hosts_graph_parameters = {
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
    var pie_hosts_graph_options = {
        legendTemplate: [
            '<div id="pie_hosts_graph_options-legend">',
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

    var line_hosts_graph_states = {{ !json.dumps(graphs['pie_hosts_graph']['states']) }};
    var line_hosts_graph_data = {
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
    // Labels are number of elements in queue ...
    for (i=-hosts_states_queue_length; i<=0; i++) {
        line_hosts_graph_data['labels'].push(i);
    }
    var line_hosts_graph_options = {
        datasetFill: true
        , pointDot: true
        , legendTemplate: [
            '<div id="line_hosts_graph_options-legend">',
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

    var pie_services_graph_parameters = {
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
    var pie_services_graph_options = {
        legendTemplate: [
            '<div id="pie_services_graph_options-legend">',
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

    var line_services_graph_states = {{ !json.dumps(graphs['line_hosts_graph']['states']) }};
    var line_services_graph_data = {
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
    // Labels are number of elements in queue ...
    for (i=-services_states_queue_length; i<=0; i++) {
        line_services_graph_data['labels'].push(i);
    }
    var line_services_graph_options = {
        datasetFill: true
        , pointDot: true
        , legendTemplate: [
            '<div id="line_services_graph_options-legend">',
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
