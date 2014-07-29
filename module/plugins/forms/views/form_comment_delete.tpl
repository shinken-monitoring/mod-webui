%username = 'anonymous'
%if user is not None: 
%if hasattr(user, 'alias'):
%	username = user.alias
%else:
%	username = user.get_name()
%end
%end

<script type="text/javascript">
	function submit_local_form() {
		// Launch comments deletion and bailout this modal view
		delete_all_comments('{{name}}');
    // If a comment is to be added ...
    if ($('#comment').val()) {
      add_comment("{{name}}", '{{username}}', $('#comment').val());
    }
    start_refresh();
		$('#modal').modal('hide');
	}
</script>


<div class="modal-dialog">
	<div class="modal-content">
		<div class="modal-header">
			<a class="close" data-dismiss="modal">×</a>
			<h3>Deletion confirm</h3>
		</div>

		<div class="modal-body">
			<form name="input_form" role="form">
				<div class="form-group">
          <label>Comment</label>
          <textarea type="textarea" name='comment' id='comment' class="input-group col-sm-offset-1 col-sm-10" rows="5" placeholder="Comment..."/>
					<label class="col-sm-12 control-label text-center">Are you sure you want to delete all comments ?</label>
          <br/>
				</div>
        
        <div class="col-sm-12" style="margin-top: 10px;"><a href="javascript:submit_local_form();" class="btn btn-primary btn-lg btn-block"> <i class="fa fa-save"></i> Delete</a></div>
			</form>
		</div>
	</div>
</div>