<script type="text/javascript">
   function submit_local_form() {
      // Launch add a comment request and bailout this modal view
      add_comment("{{name}}", '{{user.get_name()}}', $('#comment').val());
      // add_comment("{{name}}", '{{user.get_name()}}', encodeURI( $('#comment').val() ));
      start_refresh();
      $('#modal').modal('hide');
   }
</script>

<div class="modal-header">
  <a class="close" data-dismiss="modal">×</a>
  <h3>Add a comment for {{name}}</h3>
</div>

<div class="modal-body">
  <form name="input_form" role="form">
    <div class="form-group">
      <textarea name="comment" id="comment" class="form-control" rows="5" placeholder="Comment…">Comment added by {{user.get_name()}}</textarea>
    </div>

    <a href="javascript:submit_local_form();" class="btn btn-primary btn-lg btn-block"> <i class="fa fa-save"></i> Submit</a>
  </form>
</div>
