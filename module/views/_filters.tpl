%setdefault("search_string", "")
%setdefault("common_bookmarks", app.get_common_bookmarks())
%setdefault("user_bookmarks", app.get_user_bookmarks(user))

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
      <li role="presentation"><a role="menuitem" href="#" data-toggle="modal" data-target="#searchSyntax"><strong><i class="fa fa-question-circle"></i> Search syntax</strong></a></li>
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
      %end
      <li role="presentation" class="dropdown-header">Global bookmarks</li>
      %for b in common_bookmarks:
      <li role="presentation"><a role="menuitem" tabindex="-1" href="{{!b['uri']}}">{{!b['name']}}</a></li>
      %end
      %if search_string:
      <li role="presentation" class="divider"></li>
      <li role="presentation"><a role="menuitem" tabindex="-1" href="#" data-toggle="modal" data-target="#newBookmark"><i class="fa fa-plus"></i> Bookmark the current filter</a></li>
      <li role="presentation"><a role="menuitem" tabindex="-1" href="#" data-toggle="modal" data-target="#manageBookmarks"><i class="fa fa-tags"></i> Manage bookmarks</a></li>
      %end
    </ul>
  </div>
</form>


<!-- DOCUMENTATION MODAL -->
<div class="modal fade" id="searchSyntax" tabindex="-1" role="dialog" aria-labelledby="Search syntax" aria-hidden=true>
  <div class="modal-dialog modal-lg">
    <div class="modal-content">
      <div class="modal-header">
        <button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
        <h3 class="modal-title">Searching hosts and services</h3>
      </div>

      <div class="modal-body">
        To search for services and hosts (elements), use the following search qualifiers in any combination.

        <h4>Search hosts or services</h4>
        <p>
          By default, searching for elements will return both hosts and services. However, you can use the type qualifier to restrict search results to hosts or services only.
        </p>
        <code>www type:host</code> Matches hosts with "www" in their hostname.

        <h4>Search by the state of an element</h4>
        <p>The <code>is</code> and <code>isnot</code> qualifiers finds elements by a certain state. For example:</p>
        <code>is:DOWN</code> Matches hosts that are DOWN.<br>
        <code>isnot:0</code> Matches services and hosts that are not OK or UP (all the problems). Equivalent to <code>isnot:OK isnot:UP</code><br>
        <code>load isnot:ok</code> Matches services with the word "load", in states warning, critical, unknown or pending.<br>
        <code>is:ack</code> Matches elements that are acknownledged.<br>
        <code>is:downtime</code> Matches elements that are in a scheduled downtime.<br>

        <h4>Search by the business impact of an element</h4>
        <p>The <code>bp</code> qualifier finds elements by it's business priority. For example:</p>
        <code>bp:5</code> Matches hosts and services that are top for business.<br>
        <code>bp:>1</code> Matches hosts and services with a business impact greater than 1.<br>

        <h4>Search by host group, service group, contact, host tag and service tag</h4>
        Examples:
        <code>hg:infra</code> Matches hosts in the group "infra".<br>
        <code>sg:shinken</code> Matches services in the group "shinken".<br>
        <code>cg:admin</code> Matches hosts and services related to "admin" contact.<br>
        <code>htag:linux</code> Matches hosts tagged "linux".<br>
        <code>stag:mysql</code> Matches services tagged "mysql".<br>
        Obviously, you can't combine htag and stag qualifiers in a search and expect to get results.

        <h4>Find hosts and services by realm</h4>
        <p>The <code>realm</code> qualifier finds elements by a certain realm. For example:</p>
        <code>realm:aws</code> Matches all AWS hosts and services.
      </div>
    </div>
  </div>
</div>

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

