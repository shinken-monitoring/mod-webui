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

      %if user.is_administrator():
      <li id="overall-toggle-notifications" class="hidden-sm">
         <!--%state = app.datamgr.get_framework_status()-->
         <!--%color = 'font-critical' if state == 2 else 'font-warning' if state > 0 else ''-->
         <!--<a id="toggle-notifications" class="btn btn-ico" href="/system" title="Toggle notifications">-->
            <!--<i class="fas fa-envelope {{ color }}"></i>-->
         <!--</a>-->

          %if 'notifications_enabled' not in app.datamgr.get_configs()[0] or app.datamgr.get_configs()[0]['notifications_enabled']:
         <button class="btn btn-ico js-disable-notifications" title="Disable all notifications">
            <i class="fas fa-bell-slash"></i>
         </button>
          %else:
         <button class="btn btn-ico js-enable-notifications" title="Enable all notifications">
            <i class="fas fa-bell text-success"></i>
         </button>
         %end
      </li>
      %end

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
        <a href="#" class="btn btn-ico btn-user dropdown-toggle" data-toggle="dropdown" style="background-image: url({{ user.avatar_url }}?s=33;" title="Profile & Settings">
           <!--<img src="/avatar/{{ username }}" class="img-circle" size="32px">-->
           <!--<i class="fas fa-user" title="{{ username }}"></i>-->
         </a>

         <ul class="dropdown-menu">
           <li class="dropdown-header">Logged in as {{ username }}</li>
           <li class="divider"></li>
           <li><a href="https://github.com/shinken-monitoring/mod-webui/wiki" target="_blank"><i class="fas fa-book"></i>&nbsp; Documentation</a></li>
           <!--<li class="disabled"><a href="#actions" data-toggle="modal"><i class="fas fa-doc"></i> Actions</a></li>-->
           <li><a href="/user/pref" data-toggle="modal"><i class="fas fa-wrench"></i>&nbsp; Preferences</a></li>
           <li class="divider"></li>
           %if user.previous_login:
           <li><a href='/user/login_as/{{ user.previous_login }}'><i class="fas fa-sign-in-alt"></i>&nbsp; Login back to {{ user.previous_login }}</a></li>
           %end
           <li><a href="/user/logout" data-toggle="modal" data-target="/user/logout"><i class="fas fa-sign-out-alt"></i>&nbsp; Logout</a></li>
         </ul>
      </li>
   </ul>


  <!--SIDEBAR-->
  %include("sidebar")
</nav>

%if app.play_sound:
<audio id="alert-sound" volume="1.0">
   <source src="/static/sound/alert.wav" type="audio/wav">
   Your browser does not support the <code>HTML5 Audio</code> element.
   <EMBED src="/static/sound/alert.wav" autostart=true loop=false volume=100 >
</audio>
%end
