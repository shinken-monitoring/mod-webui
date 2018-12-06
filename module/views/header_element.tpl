%setdefault('app', None)
%setdefault('user', None)

%username = 'anonymous'
%user = app.get_user()
%if user is not None:
%username = user.get_name()
%end


<!-- Header Navbar -->
<nav class="header navbar navbar-static-top navbar-inverse navbar-fixed-top" role="navigation">
   <div class="navbar-header">
      <button type="button" class="navbar-toggle" data-toggle="collapse" data-target=".navbar-collapse" onclick="flush_selected_elements();">
         <span class="sr-only">Toggle navigation</span>
         <span class="icon-bar"></span>
         <span class="icon-bar"></span>
         <span class="icon-bar"></span>
      </button>
      <div class="navbar-brand-div">
        <a href="/" class="logo navbar-brand">
           <img src="/static/logo/{{app.company_logo}}?v={{app.app_version}}" alt="Company logo" style="padding: 7px;" />
        </a>
      </div>
   </div>

   <ul class="nav navbar-nav hidden-xs" id="nav-filters">
      <!-- Page filtering ... -->
      %include("_filters.tpl")
   </ul>

   <ul class="nav navbar-nav navbar-top-links navbar-right hidden-xs">
     <!-- Right part ... -->
     %s = app.datamgr.get_services_synthesis(user=user)
     %h = app.datamgr.get_hosts_synthesis(user=user)
     <div id="hosts-states-popover-content" class="hidden">
       <table class="table table-invisible table-condensed">
         <tbody>
            <tr>
               %for state in "up", "unreachable", "down", "pending", "unknown", "ack", "downtime":
               <td data-title="{{ h["pct_" + state] }}% {{ state }}">
                 %label = "%s" % h["nb_" + state]
                 %if state in ['ack', 'downtime']:
                 <a href="/all?search=type:host is:{{state}}">
                 %else:
                 <a href="/all?search=type:host is:{{state}} isnot:ack isnot:downtime">
                 %end
                 {{!helper.get_fa_icon_state_and_label(cls="host", state=state, label=label, disabled=(not h["nb_" + state]))}}
                 </a>
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
               <td data-title="{{ s["pct_" + state] }}% {{ state }}">
                 %label = "%s" % s["nb_" + state]
                 %if state in ['ack', 'downtime']:
                 <a href="/all?search=type:service is:{{state}}">
                 %else:
                 <a href="/all?search=type:service is:{{state}} isnot:ack isnot:downtime">
                 %end
                 {{!helper.get_fa_icon_state_and_label(cls="service", state=state, label=label, disabled=(not s["nb_" + state]))}}
                 </a>
               </td>
               %end
            </tr>
         </tbody>
       </table>
     </div>

      <!-- Do not remove the next comment!
         Everything between 'begin-framework-states' comment and 'end-framework-states' comment
         may be used by the layout page refresh.
      -->
      <!--begin-framework-states-->
      <li id="overall-framework-states">
         %state = app.datamgr.get_framework_status()
         %color = 'font-critical' if state == 2 else 'font-warning' if state > 0 else ''
         <a id="framework-state" class="btn btn-primary" href="/system" title="Monitoring framework status">
            <i class="fa fa-heartbeat {{ color }}"></i>
         </a>
      </li>
      <!--end-framework-states-->

      <!-- Do not remove the next comment!
         Everything between 'begin-hosts-states' comment and 'end-hosts-states' comment
         may be used by the layout page refresh.
      -->
      <!--begin-hosts-states-->
      <li id="overall-hosts-states">
         %state = app.datamgr.get_percentage_hosts_state(user, False)
         %color = 'font-critical' if state <= app.hosts_states_warning else 'font-warning' if state <= app.hosts_states_critical else ''
         <a id="hosts-states-popover"
            class="btn btn-primary hosts-all" data-count="{{ h['nb_elts'] }}" data-problems="{{ h['nb_problems'] }}"
            href="/all?search=type:host"
            data-toggle="popover popover-hosts" data-title="Overall hosts states: {{h['nb_elts']}} hosts, {{h["nb_problems"]}} problems" data-html="true">
            <i class="fa fa-server {{ color }}"></i>
            %if h['nb_problems']:
            <span class="badge">{{h["nb_problems"]}}</span>
            %end
         </a>
      </li>
      <!--end-hosts-states-->

      <!-- Do not remove the next comment!
         Everything between 'begin-services-states' comment and 'end-services-states' comment
         may be used by the layout page refresh.
      -->
      <!--begin-services-states-->
      <li id="overall-services-states" style="margin-right: 15px;">
         %state = app.datamgr.get_percentage_service_state(user, False)
         %color = 'font-critical' if state <= app.services_states_warning else 'font-warning' if state <= app.services_states_critical else ''
         <a id="services-states-popover"
            class="btn btn-primary services-all" data-count="{{ s['nb_elts'] }}" data-problems="{{ s['nb_problems'] }}"
            href="/all?search=type:service"
            data-toggle="popover popover-services" data-title="Overall services states: {{s['nb_elts']}} services, {{s["nb_problems"]}} problems" data-html="true">
            <i class="fa fa-hdd-o {{ color }}"></i>
            %if s["nb_problems"]:
            <span class="badge label-{{label}}">{{s["nb_problems"]}}</span>
            %end
         </a>
      </li>
      <!--end-services-states-->

      <li>
         <a class="btn btn-ico" href="/dashboard/currently" title="Dashboard currently">
            <i class="fa fa-eye"></i>
         </a>
      </li>

      %if refresh:
      <li>
         <button class="btn btn-ico js-toggle-page-refresh">
            <i id="header_loading" class="fa fa-refresh"></i>
         </button>
      </li>
      %end

      %if app.play_sound:
      <li class="hidden-sm hidden-xs hidden-md">
         <button class="btn btn-ico js-toggle-sound-alert" href="#">
            <span id="sound_alerting" class="fa-stack">
              <i class="fa fa-music fa-stack-1x"></i>
              <i class="fa fa-ban fa-stack-2x text-danger"></i>
            </span>
         </button>
      </li>
      %end

      <!-- User info -->
      <li class="dropdown">
        <a href="#" class="btn btn-ico btn-user dropdown-toggle" data-toggle="dropdown" style="background-image: url({{ user.avatar_url }}?s=33;" title="{{ username }}">
           <!--<img src="/avatar/{{ username }}" class="img-circle" size="32px">-->
           <!--<i class="fa fa-user" title="{{ username }}"></i>-->
         </a>

         <ul class="dropdown-menu">
           <li class="dropdown-header">{{ username }}</li>
           <li class="divider"></li>
           <li><a href="https://github.com/shinken-monitoring/mod-webui/wiki" target="_blank">Documentation</a></li>
           <li class="disabled"><a href="#actions" data-toggle="modal">Actions</a></li>
           <li><a href="/user/pref" data-toggle="modal">Preferences</a></li>
           <li class="divider"></li>
           <li><a href="/user/logout" data-toggle="modal" data-target="/user/logout"><i class="fa fa-sign-out"></i> Logout</a></li>
         </ul>
      </li>
   </ul>


  <!--SIDEBAR-->
  <div class="navbar-default sidebar" role="navigation">
    <div class="sidebar-nav navbar-collapse collapse">
      <ul class="nav" id="sidebar-menu">
        <li class="sidebar-search visible-xs">
          <form class="navbar-form navbar-left" method="get" action="/all">
            <div class="input-group custom-search-form">
              <input class="form-control" type="search" id="search" name="search" value="{{ app.get_search_string() }}">
              <span class="input-group-btn">
                <button class="btn btn-default" type="submit">
                  <i class="fa fa-search"></i>
                </button>
              </span>
            </div>
          </form>
        </li>
      <!--%include("_filters.tpl")-->
        %if app:
        <li> <a href="{{ app.get_url('Dashboard') }}"> <span class="fa fa-dashboard sidebar-icon font-unknown"></span>
        Dashboard</a> </li>
        <li> <a href="{{ app.get_url('Problems') }}"> <span class="fa fa-exclamation-circle sidebar-icon font-critical"></span>
        Problems</a> </li>
        <li class="divider"></li>
        <!--<li>Groups and tags</li>-->
        <li> <a href="#"><i class="fa fa-sitemap sidebar-icon"></i>
        Groups and tags<i class="fa arrow"></i></a>
          <ul class="nav nav-second-level">
            <li> <a href="{{ app.get_url('HostsGroups') }}"> <span class="fa fa-sitemap sidebar-icon"></span> Hosts groups </a> </li>
            <li> <a href="{{ app.get_url('ServicesGroups') }}"> <span class="fa fa-sitemap sidebar-icon"></span> Services groups </a> </li>
            <li> <a href="{{ app.get_url('HostsTags') }}"> <span class="fa fa-tags sidebar-icon"></span> Hosts tags </a> </li>
            <li> <a href="{{ app.get_url('ServicesTags') }}"> <span class="fa fa-tags sidebar-icon"></span> Services tags </a> </li>
          </ul>
        </li>
        <li> <a href="#"><i class="fa fa-bar-chart sidebar-icon"></i>
        Tactical views<i class="fa arrow"></i></a>
          <ul class="nav nav-second-level">
            <li> <a href="{{ app.get_url('Impacts') }}"> <span class="fa fa-bolt sidebar-icon"></span> Impacts </a> </li>
            <li> <a href="{{ app.get_url('Minemap') }}"> <span class="fa fa-table sidebar-icon"></span> Minemap </a> </li>
            <li> <a href="{{ app.get_url('Worldmap') }}"> <span class="fa fa-globe sidebar-icon"></span> World map </a> </li>
            <li> <a href="{{ app.get_url('Wall') }}"> <span class="fa fa-th-large sidebar-icon"></span> Wall </a> </li>
            %if app.logs_module.is_available():
            <li> <a href="{{ app.get_url('Availability') }}"> <span class="fa fa-bar-chart sidebar-icon"></span> Availability </a> </li>
            %end
          </ul>
        </li>
        %if user.is_administrator():
        %if not app.alignak:
        <li> <a href="#"><i class="fa fa-gears sidebar-icon"></i>
        System<i class="fa arrow"></i></a>
          <ul class="nav nav-second-level">
            <li> <a href="{{ app.get_url('System') }}"> <span class="fa fa-heartbeat sidebar-icon"></span> Status </a> </li>
            %if app.logs_module.is_available():
            <li> <a href="{{ app.get_url('History') }}"> <span class="fa fa-th-list sidebar-icon"></span> Logs </a> </li>
            <li> <a href="{{ app.get_url('GlobalStats') }}"> <span class="fa fa-bell-o sidebar-icon"></span> Alerts </a> </li>
            %end
          </ul>
        </li>
        %else:
        <li> <a href="#"><i class="fa fa-gears sidebar-icon"></i>
        Alignak<i class="fa arrow"></i></a>
          <ul class="nav nav-second-level">
            <li> <a href="{{ app.get_url('System') }}"> <span class="fa fa-heartbeat sidebar-icon"></span> Status </a> </li>
            <li> <a href="{{ app.get_url('AlignakStatus') }}"> <span class="fa fa-heartbeat sidebar-icon"></span> Status </a> </li>
            %if app.logs_module.is_available():
            <li> <a href="{{ app.get_url('History') }}"> <span class="fa fa-th-list sidebar-icon"></span> Mongo Logs </a> </li>
            <li> <a href="{{ app.get_url('GlobalStats') }}"> <span class="fa fa-bell-o sidebar-icon"></span> Alerts </a> </li>
            <li> <a href="{{ app.get_url('AlignakEvents') }}"> <span class="fa fa-th-list sidebar-icon"></span> Logs </a> </li>
            <li> <a href="{{ app.get_url('GlobalStats') }}"> <span class="fa fa-bell-o sidebar-icon"></span> Alerts </a> </li>
            %end
          </ul>
        </li>
        %end
        <li> <a href="#"><i class="fa fa-wrench sidebar-icon"></i>
        Configuration<i class="fa arrow"></i></a>
          <ul class="nav nav-second-level">
            <li> <a href="{{ app.get_url('Parameters') }}"> <span class="fa fa-gears sidebar-icon"></span> Parameters </a> </li>
            <li> <a href="{{ app.get_url('Contacts') }}"> <span class="fa fa-user sidebar-icon"></span> Contacts </a> </li>
            <li> <a href="{{ app.get_url('ContactsGroups') }}"> <span class="fa fa-users sidebar-icon"></span> Contact Groups </a> </li>
            <li> <a href="{{ app.get_url('Commands') }}"> <span class="fa fa-terminal sidebar-icon"></span> Commands </a> </li>
            <li> <a href="{{ app.get_url('TimePeriods') }}"> <span class="fa fa-calendar sidebar-icon"></span> Time periods </a> </li>
          </ul>
        </li>
        %end
        %other_uis = app.get_ui_external_links()
        %if len(other_uis) > 0:
        <li> <a href="#"><i class="fa fa-rocket sidebar-icon"></i>
        External<i class="fa arrow"></i></a>
          <ul class="nav nav-second-level">
            %for c in other_uis:
            <li>
              <a href="{{c['uri']}}" target="_blank"><span class="fa fa-rocket sidebar-icon"></span> {{c['label']}}</a>
            </li>
            %end
          </ul>
        </li>
        %end
        %end
        <li class="visible-xs">
           <a href="/user/logout" data-toggle="modal" data-target="/user/logout"><i class="fa fa-sign-out sidebar-icon"></i> Logout</a>
        </li>

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
%end
