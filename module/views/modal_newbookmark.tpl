<div class="modal-header">
  <button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
  <h3 class="modal-title">New Bookmark</h3>
</div>

<div class="modal-body">
  <form role="form" name='bookmark_save' id='bookmark_save'>
    <div class="form-group">
      <label for="bookmark_name" class="control-label">Bookmark name</label>
      <input class="form-control input-sm" id="new_bookmark_name" name="bookmark_name" placeholder="..." aria-describedby="help_bookmark_name">
      <span id="help_bookmark_name" class="help-block">Use an identifier to create a bookmark referencing the current applied filters.</span>
    </div>
    <a class='btn btn-success' action="add-bookmark" data-bookmark_type="user" data-filter=""> <i class="fa fa-save"></i> Save</a>
  </form>
</div>
