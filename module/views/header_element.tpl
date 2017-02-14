%setdefault('app', None)
%setdefault('user', None)

%username = 'anonymous'
%if user is not None:
%username = user.get_name()
%end


<!-- Header Navbar -->
<nav class="header navbar navbar-default navbar-static-top" style="margin-bottom:0px;">
   <div class="navbar-header">
      <button type="button" class="navbar-toggle collapsed" data-toggle="collapse" data-target="#bs-example-navbar-collapse-1">
         <span class="sr-only">Toggle navigation</span>
         <span class="icon-bar"></span>
         <span class="icon-bar"></span>
         <span class="icon-bar"></span>
      </button>
      <a onclick="display_modal('/modal/about')" class="logo navbar-brand">
         <img src="/static/logo/{{app.company_logo}}" alt="Company logo" />
      </a>
   </div>

   <ul class="nav navbar-nav">
      <!-- Page filtering ... -->
      %include("_filters.tpl")
   </ul>

   <!-- Right part ... -->
   %s = app.datamgr.get_services_synthesis(user=user)
   %h = app.datamgr.get_hosts_synthesis(user=user)
   <div id="hosts-states-popover-content" class="hidden">
      <table class="table table-invisible table-condensed">
         <tbody>
            <tr>
               %for state in "up", "unreachable", "down", "pending", "unknown", "ack", "downtime":
               <td>
                 %label = "%s <i>(%s%%)</i>" % (h["nb_" + state], h["pct_" + state])
                 {{!helper.get_fa_icon_state_and_label(cls="host", state=state, label=label, disabled=(not h["nb_" + state]))}}
               </td>
               %end
            </tr>
         </tbody>
      </table>
   </div>
   <div id="services-states-popover-content" class="hidden">
      <table class="table table-invisible table-condensed">
         <tbody>
            <tr>
               %for state in "ok", "warning", "critical", "pending", "unknown", "ack", "downtime":
               <td>
                 %label = "%s <i>(%s%%)</i>" % (s["nb_" + state], s["pct_" + state])
                 {{!helper.get_fa_icon_state_and_label(cls="service", state=state, label=label, disabled=(not s["nb_" + state]))}}
               </td>
               %end
            </tr>
         </tbody>
      </table>
   </div>

   <ul class="nav navbar-top-links navbar-right">
      <!-- Do not remove the next comment!
         Everything between 'begin-hosts-states' comment and 'end-hosts-states' comment
         may be used by the layout page refresh.
      -->
      <!--begin-hosts-states-->
      <li id="overall-hosts-states">
         %state = app.datamgr.get_percentage_hosts_state(user, False)
         %label = 'danger' if state <= app.hosts_states_warning else 'warning' if state <= app.hosts_states_critical else 'success'
         <a id="hosts-states-popover"
            class="hosts-all" data-count="{{ h['nb_elts'] }}" data-problems="{{ h['nb_problems'] }}"
            href="/all?search=type:host"
            data-original-title="Hosts states" data-toggle="popover popover-hosts" title="Overall hosts states: {{h['nb_elts']}} hosts, {{h["nb_problems"]}} problems" data-html="true" data-trigger="hover">
            <i class="fa fa-server"></i>
            <span class="label label-as-badge label-{{label}}">{{h["nb_problems"]}}</span>
         </a>
      </li>
      <!--end-hosts-states-->

      <!-- Do not remove the next comment!
         Everything between 'begin-services-states' comment and 'end-services-states' comment
         may be used by the layout page refresh.
      -->
      <!--begin-services-states-->
      <li id="overall-services-states">
         %state = app.datamgr.get_percentage_service_state(user, False)
         %label = 'danger' if state <= app.services_states_warning else 'warning' if state <= app.services_states_critical else 'success'
         <a id="services-states-popover"
            class="services-all" data-count="{{ s['nb_elts'] }}" data-problems="{{ s['nb_problems'] }}"
            href="/all?search=type:service"
            data-original-title="Services states" data-toggle="popover popover-services" title="Overall services states: {{s['nb_elts']}} services, {{s["nb_problems"]}} problems" data-html="true" data-trigger="hover">
            <i class="fa fa-bars"></i>
            <span class="label label-as-badge label-{{label}}">{{s["nb_problems"]}}</span>
         </a>
      </li>
      <!--end-services-states-->

      <li>
         <a class="quickinfo" data-original-title='Currently' href="/dashboard/currently" title="Dashboard currently">
            <i class="fa fa-eye"></i>
         </a>
      </li>

      %if refresh:
      <li>
         <a class="quickinfo" action="toggle-page-refresh" data-original-title='Refreshing' href="#">
            <i id="header_loading" class="fa fa-refresh"></i>
         </a>
      </li>
      %end

      %if app.play_sound:
      <li class="hidden-sm hidden-xs hidden-md">
         <a class="quickinfo" action="toggle-sound-alert" data-original-title='Sound alerting' href="#">
            <span id="sound_alerting" class="fa-stack">
              <i class="fa fa-music fa-stack-1x"></i>
              <i class="fa fa-ban fa-stack-2x text-danger"></i>
            </span>
         </a>
      </li>
      %end

      <!-- User info -->
      <li class="dropdown user user-menu">
         <a href="#" class="dropdown-toggle" data-original-title='User menu' data-toggle="dropdown">
            <i class="fa fa-user"></i>
            <span><span class="username hidden-sm hidden-xs hidden-md">{{username}}</span> <i class="caret"></i></span>
         </a>

         <ul class="dropdown-menu">
            <li class="user-header">
               <div class="panel panel-info" id="user_info">
                  <div class="panel-body panel-default">
                     <!-- User image / name -->
                     <p class="username">{{username}}</p>
                     %if app.can_action():
                     <p class="usercategory">
                        <small>{{'Administrator' if user.is_administrator() else 'User'}}</small>
                     </p>
                     %end
                     <img src="{{user.get_picture()}}" class="img-circle user-logo" alt="{{username}}" title="Photo: {{username}}">
                  </div>
                  <div class="panel-footer">
                     <!-- User actions -->
                     <div class="btn-group" role="group">
                        <a href="https://github.com/shinken-monitoring/mod-webui/wiki" target="_blank" class="btn btn-default btn-flat"><i class="fa fa-book"></i> </a>
                     </div>
                     <div class="btn-group" role="group">
                        <a href="#actions" data-toggle="modal" class="btn btn-default btn-flat disabled"><span class="fa fa-gear"></span> </a>
                        <a href="/user/pref" data-toggle="modal" class="btn btn-default btn-flat"><span class="fa fa-pencil"></span> </a>
                     </div>
                     <div class="btn-group" role="group">
                        <a href="/user/logout" class="btn btn-default btn-flat" data-toggle="modal" data-target="/user/logout"><span class="fa fa-sign-out"></span> </a>
                     </div>
                  </div>
               </div>
            </li>
         </ul>
      </li>
   </ul>


  <!--SIDEBAR-->
  <div class="navbar-default sidebar" role="navigation">
    <div class="sidebar-nav">
      <ul class="nav" id="sidebar-menu">
        %if app:
        <li> <a href="{{ app.get_url('Dashboard') }}"> <span class="fa fa-dashboard"></span>
        <span class="hidden-xs">Dashboard</span> </a> </li>
        <li> <a href="{{ app.get_url('Problems') }}"> <span class="fa fa-ambulance"></span>
        <span class="hidden-xs">Problems</span> </a> </li>
        <li> <a href="#"><i class="fa fa-sitemap"></i>
        <span class="hidden-xs">Groups and tags</span> <i class="fa arrow"></i></a>
          <ul class="nav nav-second-level">
            <li> <a href="{{ app.get_url('HostsGroups') }}"> <span class="fa fa-sitemap"></span> Hosts groups </a> </li>
            <li> <a href="{{ app.get_url('ServicesGroups') }}"> <span class="fa fa-sitemap"></span> Services groups </a> </li>
            <li> <a href="{{ app.get_url('HostsTags') }}"> <span class="fa fa-tags"></span> Hosts tags </a> </li>
            <li> <a href="{{ app.get_url('ServicesTags') }}"> <span class="fa fa-tags"></span> Services tags </a> </li>
          </ul>
        </li>
        <li> <a href="#"><i class="fa fa-bar-chart"></i>
        <span class="hidden-xs">Tactical views</span> <i class="fa arrow"></i></a>
          <ul class="nav nav-second-level">
            <li> <a href="{{ app.get_url('Impacts') }}"> <span class="fa fa-bolt"></span> Impacts </a> </li>
            <li> <a href="{{ app.get_url('Minemap') }}"> <span class="fa fa-table"></span> Minemap </a> </li>
            <li> <a href="{{ app.get_url('Worldmap') }}"> <span class="fa fa-globe"></span> World map </a> </li>
            <li> <a href="{{ app.get_url('Wall') }}"> <span class="fa fa-th-large"></span> Wall </a> </li>
            %if app.logs_module.is_available():
            <li> <a href="{{ app.get_url('Availability') }}"> <span class="fa fa-bar-chart"></span> Availability </a> </li>
            %end
          </ul>
        </li>
        %if user.is_administrator():
        <li> <a href="#"><i class="fa fa-gears"></i>
        <span class="hidden-xs">System</span> <i class="fa arrow"></i></a>
          <ul class="nav nav-second-level">
            <li> <a href="{{ app.get_url('System') }}"> <span class="fa fa-heartbeat"></span> Status </a> </li>
            %if app.logs_module.is_available():
            <li> <a href="{{ app.get_url('History') }}"> <span class="fa fa-th-list"></span> Logs </a> </li>
            %end
          </ul>
        </li>
        <li> <a href="#"><i class="fa fa-wrench"></i>
        <span class="hidden-xs">Configuration</span> <i class="fa arrow"></i></a>
          <ul class="nav nav-second-level">
            <li> <a href="{{ app.get_url('Parameters') }}"> <span class="fa fa-gears"></span> Parameters </a> </li>
            <li> <a href="{{ app.get_url('Contacts') }}"> <span class="fa fa-user"></span> Contacts </a> </li>
            <li> <a href="{{ app.get_url('ContactsGroups') }}"> <span class="fa fa-users"></span> Contact Groups </a> </li>
            <li> <a href="{{ app.get_url('Commands') }}"> <span class="fa fa-terminal"></span> Commands </a> </li>
            <li> <a href="{{ app.get_url('TimePeriods') }}"> <span class="fa fa-calendar"></span> Time periods </a> </li>
          </ul>
        </li>
        %end
        %other_uis = app.get_ui_external_links()
        %if len(other_uis) > 0:
        <li> <a href="#"><i class="fa fa-rocket"></i>
        <span class="hidden-xs">External</span> <i class="fa arrow"></i></a>
          <ul class="nav nav-second-level">
            %for c in other_uis:
            <li>
              <a href="{{c['uri']}}" target="_blank"><span class="fa fa-rocket"></span> {{c['label']}}</a>
            </li>
            %end
          </ul>
        </li>
        %end
        %end

      </ul>
    </div>
    <!-- /.sidebar-collapse -->
  </div>
  <!-- /.navbar-static-side -->
</nav>

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

<script type="text/javascript">
   // Activate the popover ...
   $('#hosts-states-popover').popover({
      placement: 'bottom',
      animation: true,
      template: '<div class="popover img-popover"><div class="arrow"></div><div class="popover-inner"><h3 class="popover-title"></h3><div class="popover-content"><p></p></div></div></div>',
      content: function() {
         return $('#hosts-states-popover-content').html();
      }
   });

   // Activate the popover ...
   $('#services-states-popover').popover({
      placement: 'bottom',
      animation: true,
      template: '<div class="popover img-popover"><div class="arrow"></div><div class="popover-inner"><h3 class="popover-title"></h3><div class="popover-content"><p></p></div></div></div>',
      content: function() {
         return $('#services-states-popover-content').html();
      }
   });
</script>
