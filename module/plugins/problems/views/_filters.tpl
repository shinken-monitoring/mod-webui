%setdefault("search_string", "")
%setdefault("common_bookmarks", app.get_common_bookmarks())
%setdefault("user_bookmarks", app.get_user_bookmarks(user))

<form class="navbar-form navbar-left" method="get" action="all">
  <div class="dropdown form-group text-left">
    <button class="btn btn-default dropdown-toggle" type="button" id="filters_menu" data-toggle="dropdown" aria-expanded="true">Filters <span class="caret"></span></button>
    <ul class="dropdown-menu" role="menu" aria-labelledby="filters_menu">
      <li role="presentation"><a role="menuitem" tablindex="-1" href="?search=ack:true">Acknowledged</a></li>
      <li role="presentation"><a role="menuitem" tablindex="-1" href="?search=isnot:UP isnot:OK isnot:PENDING ack:false downtime:false">Problems</a></li>
      <li role="presentation"><a role="menuitem" tablindex="-1" href="#" data-toggle="modal" data-target="#searchSyntax"><strong><i class="fa fa-question-circle"></i> Search syntax</strong></a></li>
    </ul>
  </div>
  <div class="form-group">
    <label class="sr-only" for="search">Filter</label>
    <div class="input-group">
      <span class="input-group-addon"><i class="fa fa-search"></i></span>
      <!--:TODO:maethor:150609: Make the responsive-->
      <input class="form-control" style="width:500px;" type="search" id="search" name="search" value="{{ search_string }}">
    </div>
  </div>
  <div class="dropdown form-group text-left">
    <button class="btn btn-default dropdown-toggle" type="button" id="bookmarks_menu" data-toggle="dropdown" aria-expanded="true"><i class="fa fa-bookmark"></i> Bookmarks <span class="caret"></span></button>
    <ul class="dropdown-menu dropdown-menu-right" role="menu" aria-labelledby="bookmarks_menu">
      <li role="presentation" class="dropdown-header">User bookmarks</li>
      %for b in user_bookmarks:
      <li role="presentation"><a role="menuitem" tablindex="-1" href="{{!b['uri']}}">{{!b['name']}}</a></li>
      %end
      <li role="presentation" class="dropdown-header">Global bookmarks</li>
      %for b in common_bookmarks:
      <li role="presentation"><a role="menuitem" tablindex="-1" href="{{!b['uri']}}">{{!b['name']}}</a></li>
      %end
      <!--<li role="presentation" class="divider"></li>-->
      <!--<li role="presentation"><a role="menuitem" tablindex="-1" href="#filtering" data-toggle="modal" data-target="#filtering"><i class="fa fa-plus"></i> Create new bookmark</a></li>-->
    </ul>
  </div>
</form>


<div class="modal fade" id="searchSyntax" tabindex="-1" role="dialog" aria-labelledby="Search syntax" aria-hidden=true>
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header">
        <button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
        <h4 class="modal-title">Searching hosts and services</h4>
      </div>
      <div class="modal-body">
        To search for services and hosts (elements), use the following search qualifiers in any combination.
        <h3>Search hosts or services</h3>
        <p>
          By default, searching for elements will return both hosts and services. However, you can use the type qualifier to restrict search results to hosts or services only.
        </p>
        <code>www type:host</code>
        <em>Not implemented yet</em>
        <h3>Search by the state of an element</h3>
        <p>The <code>is</code> and <code>isnot</code> qualifiers finds elements by a certain state. For example:</p>
        <code>is:DOWN</code> Matches hosts that are DOWN.<br>
        <code>isnot:0</code> Matches services and hosts that are not OK or UP (all the problems).<br>
        <code>load isnot:ok</code> Matches services with the word "load", in states warning, critical, unknown or pending.<br>

        <h3>TODO…</h3>
      </div>
    </div>
  </div>
</div>
