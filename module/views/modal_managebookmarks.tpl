%setdefault("user_bookmarks", app.prefs_module.get_user_bookmarks(user))
%setdefault("common_bookmarks", app.prefs_module.get_common_bookmarks())

%for b in user_bookmarks:
<script type="text/javascript">
   declare_bookmark("{{!b['name']}}","{{!b['uri']}}");
</script>
%end

%for b in common_bookmarks:
<script type="text/javascript">
   declare_bookmarksro("{{!b['name']}}","{{!b['uri']}}");
</script>
%end

<div class="modal-header">
  <button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
  <h3 class="modal-title">Manage Bookmarks</h3>
</div>

<div class="modal-body">
   %if user_bookmarks:
   <h4>User bookmarks</h4>
   <ul class="list-group">
      %for b in user_bookmarks:
      <li class="list-group-item" role="presentation">
         <a role="menuitem" tabindex="-1" href="{{!b['uri']}}"><i class="fa fa-bookmark"></i> {{!b['name']}}</a>
         <button action="delete-bookmark" data-bookmark="{{!b['name']}}" data-bookmark_type="user" class="btn btn-xs btn-danger pull-right"><i class="fa fa-minus"></i> Delete</button>
         <span class="pull-right">&nbsp;</span>
         <button action="globalize-bookmark" data-bookmark="{{!b['name']}}" data-bookmark_type="user" class="btn btn-xs btn-info pull-right"><i class="fa fa-plus"> Make it global</i></button>
      </li>
      %end
   </ul>
   %end
   
   %if common_bookmarks:
   <h4>Global bookmarks</h4>
   <ul class="list-group">
      %for b in common_bookmarks:
      <li class="list-group-item" role="presentation">
         <a role="menuitem" tabindex="-1" href="{{!b['uri']}}"><i class="fa fa-bookmark"></i> {{!b['name']}}</a>
         <button action="delete-bookmark" data-bookmark="{{!b['name']}}" data-bookmark_type="global" class="btn btn-xs btn-danger pull-right"><i class="fa fa-minus"></i> Delete</button>
      </li>
      %end
   </ul>
   %end
</div>
