%setdefault('app', None)
%setdefault('user', None)

%username = 'anonymous'
%if user is not None:
%username = user.get_name()
%end


<!-- Header Navbar -->
<nav class="header navbar navbar-static-top navbar-inverse" role="navigation">
   <div class="navbar-header">
      <button type="button" class="navbar-toggle" data-toggle="collapse" data-target=".navbar-collapse">
         <span class="sr-only">Toggle navigation</span>
         <span class="icon-bar"></span>
         <span class="icon-bar"></span>
         <span class="icon-bar"></span>
      </button>
      <a href="/" class="logo navbar-brand">
         <img src="/static/logo/{{app.company_logo}}" alt="Company logo" style="padding: 7px;" />
      </a>
   </div>

   <ul class="nav navbar-nav hidden-xs">
      <!-- Page filtering ... -->
      %include("_filters.tpl")
   </ul>

   <ul class="nav navbar-nav navbar-top-links navbar-right">
     <!-- Right part ... -->
     %s = app.datamgr.get_services_synthesis(user=user)
     %h = app.datamgr.get_hosts_synthesis(user=user)
     <div id="hosts-states-popover-content" class="hidden">
       <table class="table table-invisible table-condensed">
         <tbody>
            <tr>
               %for state in "up", "unreachable", "down", "pending", "unknown", "ack", "downtime":
               <td title="{{ h["pct_" + state] }}% {{ state }}">
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
               <td title="{{ s["pct_" + state] }}% {{ state }}">
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
            data-original-title="Hosts states" data-toggle="popover popover-hosts" title="Overall hosts states: {{h['nb_elts']}} hosts, {{h["nb_problems"]}} problems" data-html="true">
            <i class="fa fa-server {{ color }}"></i>
            %if color:
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
            data-original-title="Services states" data-toggle="popover popover-services" title="Overall services states: {{s['nb_elts']}} services, {{s["nb_problems"]}} problems" data-html="true">
            <i class="fa fa-hdd-o {{ color }}"></i>
            %if color:
            <span class="badge label-{{label}}">{{s["nb_problems"]}}</span>
            %end
         </a>
      </li>
      <!--end-services-states-->

      <li>
         <a class="btn btn-ico" data-original-title='Currently' href="/dashboard/currently" title="Dashboard currently">
            <i class="fa fa-eye"></i>
         </a>
      </li>

      %if refresh:
      <li>
         <button class="btn btn-ico js-toggle-page-refresh" data-original-title='Refreshing'>
            <i id="header_loading" class="fa fa-refresh"></i>
         </button>
      </li>
      %end

      %if app.play_sound:
      <li class="hidden-sm hidden-xs hidden-md">
         <button class="btn btn-ico js-toggle-sound-alert" data-original-title='Sound alerting' href="#">
            <span id="sound_alerting" class="fa-stack">
              <i class="fa fa-music fa-stack-1x"></i>
              <i class="fa fa-ban fa-stack-2x text-danger"></i>
            </span>
         </button>
      </li>
      %end

      <!-- User info -->
      <li class="dropdown">
        <a href="#" class="btn btn-ico btn-user dropdown-toggle" data-original-title='User menu' data-toggle="dropdown" style="background-image: url({{ user.avatar_url }}?s=33;" title="{{ username }}">
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
        <li> <a href="{{ app.get_url('Dashboard') }}"> <span class="fa fa-dashboard"></span>
        Dashboard</a> </li>
        <li> <a href="{{ app.get_url('Problems') }}"> <span class="fa fa-ambulance"></span>
        Problems</a> </li>
        <li> <a href="#"><i class="fa fa-sitemap"></i>
        Groups and tags<i class="fa arrow"></i></a>
          <ul class="nav nav-second-level">
            <li> <a href="{{ app.get_url('HostsGroups') }}"> <span class="fa fa-sitemap"></span> Hosts groups </a> </li>
            <li> <a href="{{ app.get_url('ServicesGroups') }}"> <span class="fa fa-sitemap"></span> Services groups </a> </li>
            <li> <a href="{{ app.get_url('HostsTags') }}"> <span class="fa fa-tags"></span> Hosts tags </a> </li>
            <li> <a href="{{ app.get_url('ServicesTags') }}"> <span class="fa fa-tags"></span> Services tags </a> </li>
          </ul>
        </li>
        <li> <a href="#"><i class="fa fa-bar-chart"></i>
        Tactical views<i class="fa arrow"></i></a>
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
        System<i class="fa arrow"></i></a>
          <ul class="nav nav-second-level">
            <li> <a href="{{ app.get_url('System') }}"> <span class="fa fa-heartbeat"></span> Status </a> </li>
            %if app.logs_module.is_available():
            <li> <a href="{{ app.get_url('History') }}"> <span class="fa fa-th-list"></span> Logs </a> </li>
            %end
          </ul>
        </li>
        <li> <a href="#"><i class="fa fa-wrench"></i>
        Configuration<i class="fa arrow"></i></a>
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
        External<i class="fa arrow"></i></a>
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
   $('.js-toggle-sound-alert').on('click', function (e, data) {
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
      container: 'body',
      trigger: 'manual',
      animation: false,
      template: '<div class="popover img-popover"><div class="arrow"></div><div class="popover-inner"><h3 class="popover-title"></h3><div class="popover-content"><p></p></div></div></div>',
      content: function() {
         return $('#hosts-states-popover-content').html();
      }
   }).on("mouseenter", function () {
      var _this = this;
      $(this).popover("show");
      $(this).siblings(".popover").on("mouseleave", function () {
          $(_this).popover('hide');
      });
   }).on("mouseleave", function () {
      var _this = this;
      setTimeout(function () {
          if (!$(".popover:hover").length) {
              $(_this).popover("hide");
          }
      }, 100);
   });

   // Activate the popover ...
   $('#services-states-popover').popover({
      placement: 'bottom',
      container: 'body',
      trigger: 'manual',
      animation: false,
      template: '<div class="popover img-popover"><div class="arrow"></div><div class="popover-inner"><h3 class="popover-title"></h3><div class="popover-content"><p></p></div></div></div>',
      content: function() {
         return $('#services-states-popover-content').html();
      }
   }).on("mouseenter", function () {
      var _this = this;
      $(this).popover("show");
      $(this).siblings(".popover").on("mouseleave", function () {
          $(_this).popover('hide');
      });
   }).on("mouseleave", function () {
      var _this = this;
      setTimeout(function () {
          if (!$(".popover:hover").length) {
              $(_this).popover("hide");
          }
      }, 100);
   });
</script>
