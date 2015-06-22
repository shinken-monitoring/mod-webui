%rebase("fullscreen", js=['dashboard/js/screenfull.js'], css=['dashboard/css/dashboard-currently.css'], title='Shinken currently', print_header=False, print_menu=False, print_title=False, print_footer=False, refresh=True)

%helper = app.helper

<script type="text/javascript">
   $(document).ready(function(){
      // Date / time
      $('#clock').jclock({ format: '%H:%M:%S' });
      $('#date').jclock({ format: '%A, %B %d' });

      // On resize ...
      $(window).bind("load resize", function() {
         topOffset = 0;
         width = (this.window.innerWidth > 0) ? this.window.innerWidth : this.screen.width;

         height = ((this.window.innerHeight > 0) ? this.window.innerHeight : this.screen.height) - 1;
         height = height - topOffset;
         if (height < 1) height = 1;
         if (height > topOffset) {
            $("#page-wrapper").css("min-height", (height) + "px");
            $("section.content").css("min-height", (height-25) + "px");
         }
         
         $('#state-icons').each(function() {
            $(this).css('margin-top', (height - $('#back-home').height() - $('#date-time').height() - $('#overall-state').height() - $(this).height() - 26) + "px");
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


%if username != 'anonymous':
<div id="back-home">
   <ul class="nav nav-pills">
      <li> <a href="/dashboard" class="font-darkgrey"><i class="fa fa-home"></i></a> </li>
   </ul>
</div>
%end
<div id="date-time">
   <div id="clock"></div>
   <div id="date"></div>
</div>

%synthesis = helper.get_synthesis(app.get_all_hosts_and_services(user))
%s = synthesis['services']
%h = synthesis['hosts']
%search_string=""

<div id="overall-state">
   <div class="panel panel-default panel-darkgrey">
      <div class="panel-body">
         <table class="table table-invisible table-condensed">
            <tbody>
              %if 'type:service' not in search_string:
               <tr>
                  <td>
                  <b>{{h['nb_elts']}} hosts:&nbsp;</b> 
                  </td>
                
                  %for state in 'up', 'unreachable', 'down', 'pending', 'unknown', 'ack', 'downtime':
                  <td>
                    %label = "%s <i>(%s%%)</i>" % (h['nb_' + state], h['pct_' + state])
                    {{!helper.get_fa_icon_state_and_label(cls='host', state=state, label=label, disabled=(not h['nb_' + state]))}}
                  </td>
                  %end
               </tr>
               %end
               %if 'type:host' not in search_string:
               <tr>
                  <td>
                     <b>{{s['nb_elts']}} services:&nbsp;</b> 
                  </td>
             
                  %for state in 'ok', 'warning', 'critical', 'pending', 'unknown', 'ack', 'downtime':
                  <td>
                    %label = "%s <i>(%s%%)</i>" % (s['nb_' + state], s['pct_' + state])
                    {{!helper.get_fa_icon_state_and_label(cls='service', state=state, label=label, disabled=(not s['nb_' + state]))}}
                  </td>
                  %end
               </tr>
               %end
            </tbody>
         </table>
      </div>
   </div>
</div>

<div id="state-icons">
   <div class="panel panel-default panel-darkgrey">
      <div class="panel-body">
   <!-- Hosts -->
   <div class="col-xs-6 col-sm-3">
      %if username != 'anonymous':
      <a href="/all?search=type:host is:UP" class="btn btn-sm">
      %end
         <div>
            %state = 100.0-h['pct_up']
            %threshold_warning=5.0
            %threshold_critical=10.0
            %font='ok' if state < threshold_warning else 'warning' if state < threshold_critical else 'critical'
            <span class="badger-big badger-left">{{h['nb_up']}} / {{h['nb_elts']}}</span>
            <span class="badger-big badger-right alert-{{font}}">{{h['pct_up']}}%</span>
         </div>
         
         <i class="fa fa-5x fa-server font-white"></i>
         <p class="icon_title font-{{font}}">&nbsp;Hosts up</p>
         
      %if username != 'anonymous':
      </a>
      %end
   </div>

   <div class="col-xs-6 col-sm-3">
      %if username != 'anonymous':
      <a href="/all?search=type:host is:UNREACHABLE" class="btn btn-sm">
      %end
         <div>
            %state = h['pct_unreachable']
            %threshold_warning=5.0
            %threshold_critical=10.0
            %font='ok' if state < threshold_warning else 'warning' if state < threshold_critical else 'critical'
            <span class="badger-big badger-left">{{h['nb_unreachable']}} / {{h['nb_elts']}}</span>
            <span class="badger-big badger-right alert-{{font}}">{{h['pct_unreachable']}}%</span>
         </div>
         
         <i class="fa fa-5x fa-server font-white"></i>
         <p class="icon_title font-{{font}}">&nbsp;Hosts unreachable</p>
         
      %if username != 'anonymous':
      </a>
      %end
   </div>

   <div class="col-xs-6 col-sm-3">
      %if username != 'anonymous':
      <a href="/all?search=type:host is:DOWN" class="btn btn-sm">
      %end
         <div>
            %state = h['pct_down']
            %threshold_warning=5.0
            %threshold_critical=10.0
            %font='ok' if state < threshold_warning else 'warning' if state < threshold_critical else 'critical'
            <span class="badger-big badger-left">{{h['nb_down']}} / {{h['nb_elts']}}</span>
            <span class="badger-big badger-right alert-{{font}}">{{h['pct_down']}}%</span>
         </div>
         
         <i class="fa fa-5x fa-server font-white"></i>
         <p class="icon_title font-{{font}}">&nbsp;Hosts down</p>
         
      %if username != 'anonymous':
      </a>
      %end
   </div>

   <div class="col-xs-6 col-sm-3">
      %if username != 'anonymous':
      <a href="/all?search=type:host is:UNKNOWN" class="btn btn-sm">
      %end
         <div>
            %state = h['pct_unknown']
            %threshold_warning=5.0
            %threshold_critical=10.0
            %font='ok' if state < threshold_warning else 'warning' if state < threshold_critical else 'critical'
            <span class="badger-big badger-left">{{h['nb_unknown']}} / {{h['nb_elts']}}</span>
            <span class="badger-big badger-right alert-{{font}}">{{h['pct_unknown']}}%</span>
         </div>
         
         <i class="fa fa-5x fa-server font-white"></i>
         <p class="icon_title font-{{font}}">&nbsp;Hosts unknown</p>
         
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
            %state = 100-s['pct_ok']
            %threshold_warning=5.0
            %threshold_critical=10.0
            %font='ok' if state < threshold_warning else 'warning' if state < threshold_critical else 'critical'
            <span class="badger-big badger-left">{{s['nb_ok']}} / {{s['nb_elts']}}</span>
            <span class="badger-big badger-right alert-{{font}}">{{s['pct_ok']}}%</span>
         </div>
         
         <i class="fa fa-5x fa-bars font-white"></i>
         <p class="icon_title font-{{font}}">&nbsp;Services ok</p>
         
      %if username != 'anonymous':
      </a>
      %end
   </div>

   <div class="col-xs-6 col-sm-3">
      %if username != 'anonymous':
      <a href="/all?search=type:service is:WARNING" class="btn btn-sm">
      %end
         <div>
            %state = s['pct_warning']
            %threshold_warning=5.0
            %threshold_critical=10.0
            %font='ok' if state < threshold_warning else 'warning' if state < threshold_critical else 'critical'
            <span class="badger-big badger-left">{{s['nb_warning']}} / {{s['nb_elts']}}</span>
            <span class="badger-big badger-right alert-{{font}}">{{s['pct_warning']}}%</span>
         </div>
         
         <i class="fa fa-5x fa-bars font-white"></i>
         <p class="icon_title font-{{font}}">&nbsp;Services warning</p>
         
      %if username != 'anonymous':
      </a>
      %end
   </div>

   <div class="col-xs-6 col-sm-3">
      %if username != 'anonymous':
      <a href="/all?search=type:service is:CRITICAL" class="btn btn-sm">
      %end
         <div>
            %state = s['pct_critical']
            %threshold_warning=5.0
            %threshold_critical=10.0
            %font='ok' if state < threshold_warning else 'warning' if state < threshold_critical else 'critical'
            <span class="badger-big badger-left">{{s['nb_critical']}} / {{s['nb_elts']}}</span>
            <span class="badger-big badger-right alert-{{font}}">{{s['pct_critical']}}%</span>
         </div>
         
         <i class="fa fa-5x fa-bars font-white"></i>
         <p class="icon_title font-{{font}}">&nbsp;Services critical</p>
         
      %if username != 'anonymous':
      </a>
      %end
   </div>

   <div class="col-xs-6 col-sm-3">
      %if username != 'anonymous':
      <a href="/all?search=type:host is:UNKNOWN" class="btn btn-sm">
      %end
         <div>
            %state = s['pct_unknown']
            %threshold_warning=5.0
            %threshold_critical=10.0
            %font='ok' if state < threshold_warning else 'warning' if state < threshold_critical else 'critical'
            <span class="badger-big badger-left">{{s['nb_unknown']}} / {{s['nb_elts']}}</span>
            <span class="badger-big badger-right alert-{{font}}">{{s['pct_unknown']}}%</span>
         </div>
         
         <i class="fa fa-5x fa-bars font-white"></i>
         <p class="icon_title font-{{font}}">&nbsp;Services unknown</p>
         
      %if username != 'anonymous':
      </a>
      %end
   </div>

   <!-- Problems / impacts -->
   <div class="col-xs-6 col-sm-3 col-md-6">
      %if username != 'anonymous':
      <a href="/problems" class="btn btn-sm" title="Left">
      %end
         <div>
            %h_state, s_state = app.get_overall_it_state(app.get_user_auth(), id=True)
            %h_problems = app.get_overall_it_problems_count(app.get_user_auth(), type='host')
            <span class="badger-big badger-left alert-{{'critical' if h_state == 2 else 'warning' if h_state == 1 else 'ok'}}">{{h_problems}}</span>
            {{!helper.get_fa_icon_state(cls='host', state='down') if h_state == 2 else ''}}
            {{!helper.get_fa_icon_state(cls='host', state='unreachable') if h_state == 1 else ''}}
            {{!helper.get_fa_icon_state(cls='host', state='up') if h_state == 0 else ''}}
            {{!helper.get_fa_icon_state(cls='service', state='critical') if s_state == 2 else ''}}
            {{!helper.get_fa_icon_state(cls='service', state='warning') if s_state == 1 else ''}}
            {{!helper.get_fa_icon_state(cls='service', state='ok') if s_state == 0 else ''}}
            %s_problems = app.get_overall_it_problems_count(app.get_user_auth(), type='service')
            <span class="badger-big badger-left alert-{{'critical' if s_state == 2 else 'warning' if s_state == 1 else 'ok'}}">{{s_problems}}</span>
         </div>

         <i class="fa fa-5x fa-exclamation-triangle font-white"></i>
         <p class="icon_title itproblem">&nbsp;IT Problems</p>
         
      %if username != 'anonymous':
      </a>
      %end
   </div>

   <div class="col-xs-6 col-sm-3 col-md-6">
      %if username != 'anonymous':
      <a href="/impacts" class="slidelink btn btn-sm">
      %end
         <div>
            %overall_state = app.get_overall_state(app.get_user_auth())
            <span title="Number of not acknownledged IT problems." class="badger-big alert-{{'ok' if overall_state == 0 else 'warning' if overall_state == 1 else 'critical'}}">{{app.get_overall_state_problems_count(app.get_user_auth())}}</span>
         </div>
         
         <i class="fa fa-5x fa-flash font-white"></i>
         <p class="icon_title impacts">&nbsp;Impacts</p>
         
      %if username != 'anonymous':
      </a>
      %end
   </div>
      </div>
   </div>
</div>
