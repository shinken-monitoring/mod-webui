<div class="navbar-default sidebar" role="navigation">
  <div class="sidebar-nav navbar-collapse collapse">
    <ul id="side-filters" class="nav navbar-nav navbar-search visible-xs">
       <!-- Search engine and filtering ... -->
       %include("_filters.tpl", search_id="sidebar-search")
    </ul>

    <ul class="nav" id="sidebar-menu">
      %if app:
      <li><a href="{{ app.get_url('Dashboard') }}" title="Dashboard">
          <i class="fas fa-fw fa-tachometer-alt sidebar-icon font-blue"></i>
          <span class="sidebar-label">Dashboard</span>
      </a></li>
      <li><a href="{{ app.get_url('Problems') }}" title="Problems">
          <i class="fas fa-fw fa-exclamation-circle sidebar-icon font-red"></i>
          <span class="sidebar-label">Problems</span>
      </a></li>

      <li class="divider"></li>

      <!--<li>Groups and tags</li>-->
      <li><a href="#" aria-expanded="false" title="Groups and tags" onclick="expand_sidebar()">
          <i class="fas fa-fw fa-sitemap sidebar-icon"></i>
          <span class="sidebar-label">Groups and tags</span>
        </a>
        <ul class="nav nav-second-level">
          <li><a href="{{ app.get_url('HostsGroups') }}" title="Hosts groups">
              <i class="fas fa-fw fa-sitemap sidebar-icon"></i>
              <span class="sidebar-label">Hosts groups</span>
          </a></li>
          <li><a href="{{ app.get_url('ServicesGroups') }}" title="Services groups">
              <i class="fas fa-fw fa-sitemap sidebar-icon"></i>
              <span class="sidebar-label">Services groups</span>
          </a></li>
          <li><a href="{{ app.get_url('HostsTags') }}" title="Hosts tags">
              <i class="fas fa-fw fa-tags sidebar-icon"></i>
              <span class="sidebar-label">Hosts tags</span>
          </a></li>
          <li><a href="{{ app.get_url('ServicesTags') }}" title="Services tags">
              <i class="fas fa-fw fa-tags sidebar-icon"></i>
              <span class="sidebar-label">Services tags</span>
          </a></li>
        </ul>
      </li>
      %if app.prefs_module.get_ui_user_preference(user, 'show_deprecated_views') == 'true':
      <li><a href="#" aria-expanded="false" title="Tactical views" onclick="expand_sidebar()">
          <i class="fas fa-fw fa-chart-bar sidebar-icon"></i>
          <span class="sidebar-label">Tactical views</span>
        </a>
        <ul class="nav nav-second-level">
          <li><a href="{{ app.get_url('Impacts') }}" title="Impacts">
              <i class="fas fa-fw fa-bolt sidebar-icon"></i>
              <span class="sidebar-label">Impacts</span>
          </a></li>
          <li><a href="{{ app.get_url('Minemap') }}" title="Minemap">
              <i class="fas fa-fw fa-table sidebar-icon"></i>
              <span class="sidebar-label">Minemap</span>
          </a></li>
          <li><a href="{{ app.get_url('Worldmap') }}" title="Worldmap">
              <i class="fas fa-fw fa-globe sidebar-icon"></i>
              <span class="sidebar-label">World map</span>
          </a></li>
          <li><a href="{{ app.get_url('Wall') }}" title="Wall">
              <i class="fas fa-fw fa-th-large sidebar-icon"></i>
              <span class="sidebar-label">Wall</span>
          </a></li>
          %if app.logs_module.is_available():
          <li><a href="{{ app.get_url('Availability') }}" title="Availability">
              <i class="fas fa-fw fa-chart-bar sidebar-icon"></i>
              <span class="sidebar-label">Availability</span>
          </a></li>
          %end
        </ul>
      </li>
      %end
      %if user.is_administrator():
      <li><a href="#" aria-expanded="false" title="System" onclick="expand_sidebar()">
          <i class="fas fa-fw fa-cogs sidebar-icon"></i>
          <span class="sidebar-label">System</span>
        </a>
          %if not app.alignak:
            <ul class="nav nav-second-level">
              <li><a href="{{ app.get_url('System') }}" title="Status">
                  <i class="fas fa-fw fa-heartbeat sidebar-icon"></i>
                  <span class="sidebar-label">Status</span>
              </a></li>
              %if app.logs_module.is_available():
              <li><a href="{{ app.get_url('History') }}" title="Logs">
                  <i class="fas fa-fw fa-list sidebar-icon"></i>
                  <span class="sidebar-label">Logs</span>
              </a></li>
              <li><a href="{{ app.get_url('GlobalStats') }}" title="Alerts">
                  <i class="fas fa-fw fa-bell sidebar-icon"></i>
                  <span class="sidebar-label">Alerts</span>
              </a></li>
              %end
            </ul>
          %else:
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
                 <span class="sidebar-label">Mongo Logs</span> </a> </li>
              <li> <a href="{{ app.get_url('GlobalStats') }}"> <i class="fas fa-fw fa-bell sidebar-icon"></i>
                 <span class="sidebar-label">Alerts</span> </a> </li>
              %end
            </ul>
          %end
      </li>
      <li><a href="#" aria-expanded="false" title="Configuration" onclick="expand_sidebar()">
          <i class="fas fa-fw fa-wrench sidebar-icon"></i>
          <span class="sidebar-label">Configuration</span>
        </a>
        <ul class="nav nav-second-level">
          %if not app.alignak:
          <li> <a href="{{ app.get_url('Parameters') }}" title="Parameters">
              <i class="fas fa-fw fa-cogs sidebar-icon"></i>
              <span class="sidebar-label">Parameters</span>
          </a></li>
          %else:
          <li> <a href="{{ app.get_url('AlignakParameters') }}"> <i class="fas fa-fw fa-cogs sidebar-icon"></i>
              &nbsp;Parameters </a> </li>
          %end
          <li> <a href="{{ app.get_url('Contacts') }}" title="Contacts">
              <i class="fas fa-fw fa-user sidebar-icon"></i>
              <span class="sidebar-label">Contacts</span>
          </a></li>
          <li> <a href="{{ app.get_url('ContactsGroups') }}" title="Contact Groups">
              <i class="fas fa-fw fa-users sidebar-icon"></i>
              <span class="sidebar-label">Contact Groups</span>
          </a></li>
          <li> <a href="{{ app.get_url('Commands') }}" title="Commands">
              <i class="fas fa-fw fa-terminal sidebar-icon"></i>
              <span class="sidebar-label">Commands</span>
          </a></li>
          <li> <a href="{{ app.get_url('TimePeriods') }}" title="Time periods">
              <i class="fas fa-fw fa-calendar sidebar-icon"></i>
              <span class="sidebar-label">Time periods</span>
          </a></li>
        </ul>
      </li>
      %end
      %other_uis = app.get_ui_external_links()
      %if len(other_uis) > 0:
      <li><a href="#" aria-expanded="false" title="External" onclick="expand_sidebar()">
          <i class="fas fa-fw fa-rocket sidebar-icon"></i>
          <span class="sidebar-label">External</span>
        </a>
        <ul class="nav nav-second-level">
          %for c in other_uis:
          <li>
            <a href="{{c['uri']}}" target="_blank" title="{{ c['label'] }}">
              <i class="fas fa-fw fa-rocket sidebar-icon"></i>
              <span class="sidebar-label">{{c['label']}}</span>
            </a>
          </li>
          %end
        </ul>
      </li>
      %end
      %end
      <li class="visible-xs">
         <a href="/user/logout" data-toggle="modal" data-target="/user/logout"><i class="fas fa-fw fa-sign-out-alt sidebar-icon"></i> Logout</a>
      </li>

      <li role="separator" style="margin: 20px;"></li>

      <li class="hidden-xs text-center">
        <a href="#" onclick="toggle_sidebar()" class="js-sidebar-toggle"><i class="fas fa-arrow-left sidebar-icon"></i></a>
      </li>
    </ul>

    <div class="nav hidden-xs" id="sidebar-menu-bottom">
      <div onclick="display_modal('/modal/about')" class="text-center">
        <img src='/favicon.ico' width='24px;'>
      </div>
    </div>
  </div>
</div>
