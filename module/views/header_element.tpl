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
           <img src="/static/logo/{{app.company_logo}}?v={{app.app_version}}" alt="Company logo" />
        </a>
      </div>
   </div>

   <ul id="nav-filters" class="nav navbar-nav navbar-search hidden-xs">
      <!-- Search engine and filtering ... -->
      %include("_filters.tpl", search_id="search")
   </ul>

   <ul class="nav navbar-nav navbar-top-links navbar-right hidden-xs">
     <!-- Right part ... -->
     %s = app.datamgr.get_services_synthesis(user=user)
     %s_count = s['nb_elts']
     %h = app.datamgr.get_hosts_synthesis(user=user)
     %h_count = h['nb_elts']
     <div id="hosts-states-popover-content" class="hidden">
       <table class="table table-invisible table-condensed">
         <tbody>
            <tr>
               %for state in "up", "unreachable", "down", "unknown", "ack", "downtime":
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
               %for state in "ok", "warning", "critical", "unreachable", "unknown", "ack", "downtime":
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
      <li id="overall-framework-states" class="hidden-sm">
         %state = app.datamgr.get_framework_status()
         %color = 'font-critical' if state == 2 else 'font-warning' if state > 0 else ''
         <a id="framework-state" class="btn btn-ico" href="/system" title="Monitoring framework status">
            <i class="fas fa-heartbeat {{ color }}"></i>
         </a>
      </li>
      <!--end-framework-states-->

      <!-- Do not remove the next comment!
         Everything between 'begin-hosts-states' comment and 'end-hosts-states' comment
         may be used by the layout page refresh.
      -->
      <!--begin-hosts-states-->
      <li id="overall-hosts-states">
         %h = app.datamgr.get_important_hosts_synthesis(user=user)
         %state = app.datamgr.get_percentage_hosts_state(user, False)
         %color = 'critical' if state <= app.hosts_states_warning else 'warning' if state <= app.hosts_states_critical else ''
         <a id="hosts-states-popover"
            class="btn btn-ico btn-badge hosts-all" data-count="{{ h['nb_elts'] }}" data-problems="{{ h['nb_problems'] }}"
            href="/all?search=type:host"
            data-toggle="popover popover-hosts" data-title="Important hosts (bi >= {{ app.important_problems_business_impact }}):
            <strong>{{h['nb_elts']}}</strong> <em>(out of {{h_count}})</em> hosts, {{h["nb_problems"] if h["nb_problems"] else 'no'}} problems" data-html="true">
            <i class="fas fa-server"></i>
            %if h['nb_problems']:
            <span class="badge badge-{{color}}">{{h["nb_problems"]}}</span>
            %end
         </a>
      </li>
      <!--end-hosts-states-->

      <!-- Do not remove the next comment!
         Everything between 'begin-services-states' comment and 'end-services-states' comment
         may be used by the layout page refresh.
      -->
      <!--begin-services-states-->
      <li id="overall-services-states">
         %s = app.datamgr.get_important_services_synthesis(user=user)
         %state = app.datamgr.get_percentage_service_state(user, False)
         %color = 'critical' if state <= app.services_states_warning else 'warning' if state <= app.services_states_critical else ''
         <a id="services-states-popover"
            class="btn btn-ico btn-badge services-all" data-count="{{ s['nb_elts'] }}" data-problems="{{ s['nb_problems'] }}"
            href="/all?search=type:service"
            data-toggle="popover popover-services" data-title="Important services (bi >= {{ app.important_problems_business_impact }}):
            <strong>{{s['nb_elts']}}</strong> <em>(out of {{s_count}})</em> services, {{s["nb_problems"] if s["nb_problems"] else 'no'}} problems" data-html="true">
            <i class="fas fa-hdd"></i>
            %if s["nb_problems"]:
            <span class="badge badge-{{color}}">{{s["nb_problems"]}}</span>
            %end
         </a>
      </li>
      <!--end-services-states-->

      <li role="separator" class="divider hidden-sm"></li>

      <li class="hidden-sm">
         <a class="btn btn-ico" href="/dashboard/currently" title="Dashboard currently">
            <i class="fas fa-eye"></i>
         </a>
      </li>

      %if refresh:
      <li class="hidden-sm">
         <button class="btn btn-ico js-toggle-page-refresh">
            <i id="header_loading" class="fas fa-sync"></i>
         </button>
      </li>
      %end

      %if app.play_sound:
      <li class="hidden-sm">
         <button class="btn btn-ico js-toggle-sound-alert">
            <i id="sound_alerting" class="fas fa-music"></i>
         </button>
      </li>
      %end

      <li role="separator" class="divider"></li>

      <!-- User info -->
      <li class="dropdown">
        <a href="#" class="btn btn-ico btn-user dropdown-toggle" data-toggle="dropdown" style="background-image: url({{ user.avatar_url }}?s=33;" title="{{ username }}">
           <!--<img src="/avatar/{{ username }}" class="img-circle" size="32px">-->
           <!--<i class="fas fa-user" title="{{ username }}"></i>-->
         </a>

         <ul class="dropdown-menu">
           <li class="dropdown-header">{{ username }}</li>
           <li class="divider"></li>
           <li><a href="https://github.com/shinken-monitoring/mod-webui/wiki" target="_blank">Documentation</a></li>
           <li class="disabled"><a href="#actions" data-toggle="modal">Actions</a></li>
           <li><a href="/user/pref" data-toggle="modal">Preferences</a></li>
           <li class="divider"></li>
           <li><a href="/user/logout" data-toggle="modal" data-target="/user/logout"><i class="fas fa-sign-out"></i> Logout</a></li>
         </ul>
      </li>
   </ul>


  <!--SIDEBAR-->
  <div class="navbar-default sidebar" role="navigation">
    <div class="sidebar-nav navbar-collapse collapse">
      <ul id="side-filters" class="nav navbar-nav navbar-search visible-xs">
         <!-- Search engine and filtering ... -->
         %include("_filters.tpl", search_id="sidebar-search")
      </ul>

      <ul class="nav" id="sidebar-menu">
        %if app:
        <li> <a href="{{ app.get_url('Dashboard') }}"> <i class="fas fa-fw fa-tachometer-alt sidebar-icon font-blue"></i>
          &nbsp;Dashboard </a> </li>
        <li> <a href="{{ app.get_url('Problems') }}"> <i class="fas fa-fw fa-exclamation-circle sidebar-icon font-red"></i>
          &nbsp;Problems </a> </li>

        <li class="divider"></li>

        <!--<li>Groups and tags</li>-->
        <li> <a href="#" aria-expanded="false"><i class="fas fa-fw fa-sitemap sidebar-icon"></i>
        &nbsp;Groups and tags<i class="fa arrow"></i></a>
          <ul class="nav nav-second-level">
            <li> <a href="{{ app.get_url('HostsGroups') }}"> <i class="fas fa-fw fa-sitemap sidebar-icon"></i>
               &nbsp;Hosts groups </a> </li>
            <li> <a href="{{ app.get_url('ServicesGroups') }}"> <i class="fas fa-fw fa-sitemap sidebar-icon"></i>
               &nbsp;Services groups </a> </li>
            <li> <a href="{{ app.get_url('HostsTags') }}"> <i class="fas fa-fw fa-tags sidebar-icon"></i>
               &nbsp;Hosts tags </a> </li>
            <li> <a href="{{ app.get_url('ServicesTags') }}"> <i class="fas fa-fw fa-tags sidebar-icon"></i>
               &nbsp;Services tags </a> </li>
          </ul>
        </li>
        <li> <a href="#" aria-expanded="false"><i class="fas fa-fw fa-chart-bar sidebar-icon"></i>
        &nbsp;Tactical views<i class="fa arrow"></i></a>
          <ul class="nav nav-second-level">
            <li> <a href="{{ app.get_url('Impacts') }}"> <i class="fas fa-fw fa-bolt sidebar-icon"></i>
               &nbsp;Impacts </a> </li>
            <li> <a href="{{ app.get_url('Minemap') }}"> <i class="fas fa-fw fa-table sidebar-icon"></i>
               &nbsp;Minemap </a> </li>
            <li> <a href="{{ app.get_url('Worldmap') }}"> <i class="fas fa-fw fa-globe sidebar-icon"></i>
               &nbsp;World map </a> </li>
            <li> <a href="{{ app.get_url('Wall') }}"> <i class="fas fa-fw fa-th-large sidebar-icon"></i>
               &nbsp;Wall </a> </li>
            %if app.logs_module.is_available():
            <li> <a href="{{ app.get_url('Availability') }}"> <i class="fas fa-fw fa-chart-bar sidebar-icon"></i>
               &nbsp;Availability </a> </li>
            %end
          </ul>
        </li>
        %if user.is_administrator():
        <li> <a href="#" aria-expanded="false"><i class="fas fa-fw fa-cogs sidebar-icon"></i>
        %if not app.alignak:
        &nbsp;System<i class="fa arrow"></i></a>
          <ul class="nav nav-second-level">
            <li> <a href="{{ app.get_url('System') }}"> <i class="fas fa-fw fa-heartbeat sidebar-icon"></i>
               &nbsp;Status </a> </li>
            %if app.logs_module.is_available():
            <li> <a href="{{ app.get_url('History') }}"> <i class="fas fa-fw fa-list sidebar-icon"></i>
               &nbsp;Logs </a> </li>
            <li> <a href="{{ app.get_url('GlobalStats') }}"> <i class="fas fa-fw fa-bell-o sidebar-icon"></i>
               &nbsp;Alerts </a> </li>
            %end
          </ul>
        %else:
        &nbsp;Alignak<i class="fa arrow"></i></a>
          <ul class="nav nav-second-level">
            <li> <a href="{{ app.get_url('System') }}"> <i class="fas fa-fw fa-heartbeat sidebar-icon"></i>
               &nbsp;Status </a> </li>
            <li> <a href="{{ app.get_url('AlignakStatus') }}"> <i class="fas fa-fw fa-heartbeat sidebar-icon"></i>
               &nbsp;Live state</a> </li>
            <li> <a href="{{ app.get_url('AlignakEvents') }}"> <i class="fas fa-fw fa-th-list sidebar-icon"></i>
               &nbsp;Events log</a> </li>
            <!--
            <li> <a href="{{ app.get_url('AlignakStats') }}"> <i class="fas fa-fw fa-th-list sidebar-icon"></i>
               &nbsp;Events stats</a> </li>
               -->
            %if app.logs_module.is_available():
            <li> <a href="{{ app.get_url('History') }}"> <i class="fas fa-fw fa-th-list sidebar-icon"></i>
               &nbsp;Mongo Logs </a> </li>
            <li> <a href="{{ app.get_url('GlobalStats') }}"> <i class="fas fa-fw fa-bell-o sidebar-icon"></i>
               &nbsp;Alerts </a> </li>
            %end
          </ul>
        %end
        </li>
        <li> <a href="#" aria-expanded="false"><i class="fas fa-fw fa-wrench sidebar-icon"></i>
        &nbsp;Configuration<i class="fa arrow"></i></a>
          <ul class="nav nav-second-level">
            %if not app.alignak:
            <li> <a href="{{ app.get_url('Parameters') }}"> <i class="fas fa-fw fa-cogs sidebar-icon"></i>
               &nbsp;Parameters </a> </li>
            %else:
            <li> <a href="{{ app.get_url('AlignakParameters') }}"> <i class="fas fa-fw fa-cogs sidebar-icon"></i>
               &nbsp;Parameters </a> </li>
            %end
            <li> <a href="{{ app.get_url('Contacts') }}"> <i class="fas fa-fw fa-user sidebar-icon"></i>
               &nbsp;Contacts </a> </li>
            <li> <a href="{{ app.get_url('ContactsGroups') }}"> <i class="fas fa-fw fa-users sidebar-icon"></i>
               &nbsp;Contact Groups </a> </li>
            <li> <a href="{{ app.get_url('Commands') }}"> <i class="fas fa-fw fa-terminal sidebar-icon"></i>
               &nbsp;Commands </a> </li>
            <li> <a href="{{ app.get_url('TimePeriods') }}"> <i class="fas fa-fw fa-calendar sidebar-icon"></i>
               &nbsp;Time periods </a> </li>
          </ul>
        </li>
        %end
        %other_uis = app.get_ui_external_links()
        %if len(other_uis) > 0:
        <li> <a href="#" aria-expanded="false"><i class="fas fa-fw fa-rocket sidebar-icon"></i>
        &nbsp;External<i class="fa arrow"></i></a>
          <ul class="nav nav-second-level">
            %for c in other_uis:
            <li>
              <a href="{{c['uri']}}" target="_blank"><i class="fas fa-fw fa-rocket sidebar-icon"></i>
              &nbsp;{{c['label']}}</a>
            </li>
            %end
          </ul>
        </li>
        %end
        %end
        <li class="visible-xs">
           <a href="/user/logout" data-toggle="modal" data-target="/user/logout"><i class="fas fa-fw fa-sign-out sidebar-icon"></i> Logout</a>
        </li>
      </ul>
    </div>
  </div>
</nav>

%if app.play_sound:
<audio id="alert-sound" volume="1.0">
   <source src="/static/sound/alert.wav" type="audio/wav">
   Your browser does not support the <code>HTML5 Audio</code> element.
   <EMBED src="/static/sound/alert.wav" autostart=true loop=false volume=100 >
</audio>
%end
