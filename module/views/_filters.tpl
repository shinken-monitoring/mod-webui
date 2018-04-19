%setdefault("common_bookmarks", app.prefs_module.get_common_bookmarks())
%setdefault("user_bookmarks", app.prefs_module.get_user_bookmarks(user))

%if 'search_engine' in app.request.route.config and app.request.route.config['search_engine']:
%search_action = app.request.fullpath
%search_name = app.request.route.name
%else:
%search_action = '/all'
%search_name = ''
%end

<form class="navbar-form navbar-left" method="get" action="{{ search_action }}">

  <div class="form-group">
    <label class="sr-only" for="search">Filter</label>
    <div class="input-group">
      <span class="input-group-addon hidden-xs hidden-sm" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
        <i class="fa fa-search"></i><span>{{ search_name }}</span></span>

      <ul class="dropdown-menu dropdown-menu-left" role="menu">
        <li><a role="menuitem" href="/all?search={{ app.get_search_string() }}"><span class="btn fa fa-search"></span>All</a></li>
        <li><a role="menuitem" href="/impacts?search={{ app.get_search_string() }}"><span class="btn fa fa-bolt"></span>Impacts</a></li>
        <li><a role="menuitem" href="/worldmap?search={{ app.get_search_string() }}"><span class="btn fa fa-map"></span>Worldmap</a></li>
        <li><a role="menuitem" href="/minemap?search={{ app.get_search_string() }}"><span class="btn fa fa-table"></span>Minemap</a></li>
        <li><a role="menuitem" href="/technical?search={{ app.get_search_string() }}"><span class="btn fa fa-th-large"></span>Matrix</a></li>
        <li><a role="menuitem" href="/wall?search={{ app.get_search_string() }}"><span class="btn fa fa-th-large"></span>Wall</a></li>
        <li><a role="menuitem" href="/availability?search={{ app.get_search_string() }}"><span class="btn fa fa-bar-chart"></span>Availability</a></li>
      </ul>

      <input class="form-control" type="search" id="search" name="search" value="{{ app.get_search_string() }}">



    </div>




  </div>
  <div class="dropdown form-group text-left">
    <button class="btn btn-default dropdown-toggle" type="button" id="bookmarks_menu" data-toggle="dropdown" aria-expanded="true"><i class="fa fa-bookmark"></i><span class="hidden-sm hidden-xs hidden-md"> Bookmarks</span> <span class="caret"></span></button>
    <ul class="dropdown-menu dropdown-menu-right" role="menu" aria-labelledby="bookmarks_menu">
      <script type="text/javascript">
         %for b in user_bookmarks:
            declare_bookmark("{{!b['name']}}","{{!b['uri']}}");
         %end
         %for b in common_bookmarks:
            declare_bookmarksro("{{!b['name']}}","{{!b['uri']}}");
         %end
      </script>
    </ul>
  </div>

  <div class="dropdown form-group text-left">
    <button class="btn btn-default dropdown-toggle" type="button" id="filters_menu" data-toggle="dropdown" aria-expanded="true"><i class="fa fa-filter"></i><span class="hidden-sm hidden-xs hidden-md"> Filters</span> <span class="caret"></span></button>
    <ul class="dropdown-menu" role="menu" aria-labelledby="filters_menu">
      <li role="presentation"><a role="menuitem" href="/all?search=&title=All resources">All resources</a></li>
      <li role="presentation"><a role="menuitem" href="/all?search=type:host&title=All hosts">All hosts</a></li>
      <li role="presentation"><a role="menuitem" href="/all?search=type:service&title=All services">All services</a></li>
      <li role="presentation" class="divider"></li>
      <li role="presentation"><a role="menuitem" href="{{ search_action }}?search=is:probe&title=All Probes">All Probes</a></li>
      <li role="presentation"><a role="menuitem" href="{{ search_action }}?search=tech:gpon is:probe&title=GPON Probes">GPON Probes</a></li>
      <li role="presentation"><a role="menuitem" href="{{ search_action }}?search=tech:wimax is:probe&title=WiMAX Probes">WiMAX Probes</a></li>
      <li role="presentation"><a role="menuitem" href="{{ search_action }}?search=tech:docsis is:probe&title=DOCSIS Probes">DOCSIS Probes</a></li>
      <li role="presentation" class="divider"></li>
      <li role="presentation"><a role="menuitem" href="/all?search=isnot:0 isnot:ack isnot:downtime&title=New problems">New problems</a></li>
      <li role="presentation"><a role="menuitem" href="/all?search=is:ack&title=Acknowledged problems">Acknowledged problems</a></li>
      <li role="presentation"><a role="menuitem" href="/all?search=is:downtime&title=Scheduled downtimes">Scheduled downtimes</a></li>
      <li role="presentation" class="divider"></li>
      <li role="presentation"><a role="menuitem" href="?search=bp:>=5">Impact : {{!helper.get_business_impact_text(5, text=True)}}</a></li>
      <li role="presentation"><a role="menuitem" href="?search=bp:>=4">Impact : {{!helper.get_business_impact_text(4, text=True)}}</a></li>
      <li role="presentation"><a role="menuitem" href="?search=bp:>=3">Impact : {{!helper.get_business_impact_text(3, text=True)}}</a></li>
      <li role="presentation"><a role="menuitem" href="?search=bp:>=2">Impact : {{!helper.get_business_impact_text(2, text=True)}}</a></li>
      <li role="presentation"><a role="menuitem" href="?search=bp:>=1">Impact : {{!helper.get_business_impact_text(1, text=True)}}</a></li>
      <li role="presentation"><a role="menuitem" href="?search=bp:>=0">Impact : {{!helper.get_business_impact_text(0, text=True)}}</a></li>
      <li role="presentation" class="divider"></li>
      <li role="presentation"><a role="menuitem" onclick="display_modal('/modal/helpsearch')"><strong><i class="fa fa-question-circle"></i> Search syntax</strong></a></li>
    </ul>
  </div>


</form>
