%setdefault('refresh', True)
%rebase("fullscreen", css=['dashboard/css/currently.css'], title='Shinken currently')

%helper = app.helper

<script type="text/javascript">
   $(document).ready(function(){
      // Date / time
      $('#clock').jclock({ format: '%H:%M:%S' });
      $('#date').jclock({ format: '%A, %B %d' });

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

      // On resize ...
      $(window).bind("load resize", function() {
         width = (this.window.innerWidth > 0) ? this.window.innerWidth : this.screen.width;
         height = ((this.window.innerHeight > 0) ? this.window.innerHeight : this.screen.height) - 1;

         if (height < 1) height = 1;
         //$("#page-wrapper").css("min-height", (height-5) + "px");
         $("#page-wrapper").css("min-height", (height-39) + "px");
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

%if username != 'anonymous':
<div id="back-home">
   <ul class="nav nav-pills navbar-left">
      <li> <a class="font-darkgrey" href="/dashboard"><i class="fa fa-home"></i></a> </li>
      <li> <a class="font-darkgrey" href="#" action="fullscreen-request" class="font-darkgrey"><i class="fa fa-desktop"></i></a> </li>
   </ul>
   %if app.play_sound:
   <ul class="nav nav-pills navbar-right">
      <li>
         <a class="font-darkgrey" action="toggle-sound-alert" data-original-title='Sound alerting' href="#">
            <span id="sound_alerting" class="fa-stack">
              <i class="fa fa-music fa-stack-1x"></i>
              <i class="fa fa-ban fa-stack-2x text-danger"></i>
            </span>
         </a>
      </li>
   </ul>
   %end
</div>
%end
<div id="date-time">
   <h1 id="clock"></h1>
   <h3 id="date"></h3>
</div>

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
   $('[action="toggle-sound-alert"]').on('click', function (e, data) {
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

<div id="one-eye-overall">
   <div class="panel panel-default panel-darkgrey">
      <div class="panel-body">
         <table class="table table-invisible table-condensed">
            <tbody>
               <tr id="one-eye-overall-hosts" data-hosts-problems="{{ len(app.datamgr.get_problems(user=user, search='type:host')) }}">
                  <td class="font-white"><center>
                  <b>{{h['nb_elts']}} hosts</b>
                  </center></td>
                  %for state in 'up', 'unreachable', 'down', 'pending', 'unknown', 'ack', 'downtime':
                  <td>
                     %label = "%s <i>(%s%%)</i>" % (h['nb_' + state], h['pct_' + state])
                     <a href="/all?search=type:host is:{{state}}">
                        {{!helper.get_fa_icon_state_and_label(cls='host', state=state, label=label, disabled=(not h['nb_' + state]))}}
                     </a>
                  </td>
                  %end
               </tr>
               <tr id="one-eye-overall-services" data-services-problems="{{ len(app.datamgr.get_problems(user=user, search='type:service')) }}">
                  <td class="font-white"><center>
                  <b>{{s['nb_elts']}} services</b>
                  </center></td>
                  %for state in 'ok', 'warning', 'critical', 'pending', 'unknown', 'ack', 'downtime':
                  <td>
                     %label = "%s <i>(%s%%)</i>" % (s['nb_' + state], s['pct_' + state])
                     <a href="/all?search=type:service is:{{state}}">
                        {{!helper.get_fa_icon_state_and_label(cls='service', state=state, label=label, disabled=(not s['nb_' + state]))}}
                     </a>
                  </td>
                  %end
               </tr>
            </tbody>
         </table>
      </div>
   </div>
</div>

<div id="one-eye-icons">
   <div class="panel panel-default panel-darkgrey">
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

   <div class="panel panel-default panel-darkgrey">
      <div class="panel-body">
         <!-- Problems / impacts -->
         <div class="col-xs-6 col-sm-3 col-md-6">
            %if username != 'anonymous':
            <a href="/problems" class="btn btn-sm">
            %end
               <div>
                  %h_state, s_state = app.datamgr.get_overall_it_state(user)
                  %h_problems = len(app.datamgr.get_problems(user, search='type:host', sorter=None))
                  %font='unknown' if h_state >= 3 else 'critical' if h_state >= 2 else 'warning' if h_state >= 1 else 'ok'
                  <span title="Number of hosts problems." class="badger-big badger-left font-{{font}}">{{h_problems}}</span>
                  {{!helper.get_fa_icon_state(cls='host', state='down') if h_state == 2 else ''}}
                  {{!helper.get_fa_icon_state(cls='host', state='unreachable') if h_state == 1 else ''}}
                  {{!helper.get_fa_icon_state(cls='host', state='up') if h_state == 0 else ''}}
                  {{!helper.get_fa_icon_state(cls='service', state='critical') if s_state == 2 else ''}}
                  {{!helper.get_fa_icon_state(cls='service', state='warning') if s_state == 1 else ''}}
                  {{!helper.get_fa_icon_state(cls='service', state='ok') if s_state == 0 else ''}}
                  %s_problems = len(app.datamgr.get_problems(user, search='type:service', sorter=None))
                  <span title="Number of services problems." class="badger-big badger-right font-{{font}}">{{s_problems}}</span>
               </div>

               <i class="fa fa-5x fa-exclamation-triangle"></i>
               <p class="badger-title itproblem">&nbsp;IT Problems</p>

            %if username != 'anonymous':
            </a>
            %end
         </div>

         <div class="col-xs-6 col-sm-3 col-md-6">
            %if username != 'anonymous':
            <a href="/impacts" class="btn btn-sm">
            %end
               <div>
                  %overall_state = app.datamgr.get_overall_state(user)
                  %font='unknown' if overall_state >= 3 else 'critical' if overall_state >= 2 else 'warning' if overall_state >= 1 else 'ok'
                  <span title="Number of impacts." class="badger-big font-{{font}}">{{len(app.datamgr.get_impacts(user))}}</span>
               </div>

               <i class="fa fa-5x fa-flash"></i>
               <p class="badger-title impacts">&nbsp;Impacts</p>

            %if username != 'anonymous':
            </a>
            %end
         </div>
      </div>
   </div>
</div>
