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
    <div class="input-group" id="search-group">
      <input class="form-control" type="search" id="search" name="search" value="{{ app.get_search_string() }}">
      <span class="input-group-addon">
        <span class="hidden-addons">
          <div class="dropdown form-group text-left">
            <a href="#" class="dropdown-toggle" type="button" id="filters_menu" data-toggle="dropdown" aria-expanded="false" title="Filters"><i class="fa fa-filter"></i><span class="hidden-sm hidden-xs hidden-md"></a>
            <ul class="dropdown-menu" role="menu" aria-labelledby="filters_menu">
              <li role="presentation"><a role="menuitem" href="/all?search=&title=All resources">All resources</a></li>
              <li role="presentation"><a role="menuitem" href="/all?search=type:host&title=All hosts">All hosts</a></li>
              <li role="presentation"><a role="menuitem" href="/all?search=type:service&title=All services">All services</a></li>
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
          <div class="dropdown form-group text-left">
            <a href="#" class="dropdown-toggle" type="button" id="bookmarks_menu" data-toggle="dropdown" aria-expanded="false" title="Bookmarks"><i class="fa fa-bookmark-o"></i><span class="hidden-sm hidden-xs hidden-md"></a>
            <ul class="dropdown-menu" role="menu" aria-labelledby="bookmarks_menu">
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
        </span>
        <i class="fa fa-search"></i>
      </span>
    </div>
  </div>
</form>
