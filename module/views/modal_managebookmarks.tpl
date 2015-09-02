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
  <div id='bookmarks'></div>
  <div id='bookmarksro'></div>
</div>
