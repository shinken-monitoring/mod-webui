%setdefault("search_string", "")
%setdefault("common_bookmarks", app.prefs_module.get_common_bookmarks())
%setdefault("user_bookmarks", app.prefs_module.get_user_bookmarks(user))

<form class="navbar-form navbar-left hidden-xs" method="get" action="all">
  <div class="dropdown form-group text-left">
    <button class="btn btn-default dropdown-toggle" type="button" id="filters_menu" data-toggle="dropdown" aria-expanded="true"><i class="fa fa-filter"></i><span class="hidden-sm hidden-xs hidden-md"> Filters</span> <span class="caret"></span></button>
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
  <div class="form-group">
    <label class="sr-only" for="search">Filter</label>
    <div class="input-group">
      <span class="input-group-addon hidden-xs hidden-sm"><i class="fa fa-search"></i></span>
      <input class="form-control" type="search" id="search" name="search" value="{{ search_string }}">
    </div>
  </div>
  <div class="dropdown form-group text-left">
    <button class="btn btn-default dropdown-toggle" type="button" id="bookmarks_menu" data-toggle="dropdown" aria-expanded="true"><i class="fa fa-bookmark"></i><span class="hidden-sm hidden-xs hidden-md"> Bookmarks</span> <span class="caret"></span></button>
    <ul class="dropdown-menu dropdown-menu-right" role="menu" aria-labelledby="bookmarks_menu">
      <li role="presentation" class="dropdown-header">User bookmarks</li>
      %for b in user_bookmarks:
      <li role="presentation"><a role="menuitem" tabindex="-1" href="{{!b['uri']}}">{{!b['name']}}</a></li>
      <script type="text/javascript">
         declare_bookmark("{{!b['name']}}","{{!b['uri']}}");
      </script>
      %end
      <li role="presentation" class="dropdown-header">Global bookmarks</li>
      %for b in common_bookmarks:
      <li role="presentation"><a role="menuitem" tabindex="-1" href="{{!b['uri']}}">{{!b['name']}}</a></li>
      <script type="text/javascript">
         declare_bookmarksro("{{!b['name']}}","{{!b['uri']}}");
      </script>
      %end
      %if search_string:
      <li role="presentation" class="divider"></li>
      <li role="presentation"><a role="menuitem" tabindex="-1" href="#" data-toggle="modal" data-target="#newBookmark"><i class="fa fa-plus"></i> Bookmark the current filter</a></li>
      <li role="presentation"><a role="menuitem" tabindex="-1" href="#" data-toggle="modal" data-target="#manageBookmarks"><i class="fa fa-tags"></i> Manage bookmarks</a></li>
      %end
    </ul>
  </div>
</form>


<!-- NEW BOOKMARK MODAL -->
<div class="modal fade" id="newBookmark" tabindex="-1" role="dialog" aria-labelledby="New Bookmark" aria-hidden=true>
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header">
        <button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
        <h3 class="modal-title">New Bookmark</h3>
      </div>

      <div class="modal-body">
        <form role="form" name='bookmark_save' id='bookmark_save'>
          <div class="form-group">
            <label for="bookmark_name" class="control-label">Bookmark name</label>
            <input class="form-control input-sm" id="bookmark_name" name="bookmark_name" placeholder="..." aria-describedby="help_bookmark_name">
            <span id="help_bookmark_name" class="help-block">Use an identifier to create a bookmark referencing the current applied filters.</span>
          </div>
          <a class='btn btn-success' href='javascript:add_new_bookmark();'> <i class="fa fa-save"></i> Save</a>
        </form>
      </div>
    </div>
  </div>
</div>

<!-- MANAGE BOOKMARKS MODAL -->
<div class="modal fade" id="manageBookmarks" tabindex="-1" role="dialog" aria-labelledby="Manage Bookmarks" aria-hidden=true>
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header">
        <button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
        <h3 class="modal-title">Manage Bookmarks</h3>
      </div>

      <div class="modal-body">
        <div id='bookmarks'></div>
        <div id='bookmarksro'></div>
      </div>
    </div>
  </div>
</div>

