<script type="text/javascript">
	function submit_local_form() {
		// Launch acknowledge request and bailout this modal view
		add_comment("{{name}}", '{{user.get_name()}}', $('#comment').val());
    start_refresh();
		$('#modal').modal('hide');
	}
</script>


<div class="modal-dialog">
	<div class="modal-content">
		<div class="modal-header">
			<a class="close" data-dismiss="modal">×</a>
			<h3>Add a comment for {{name}}</h3>
		</div>

		<div class="modal-body">
			<form name="input_form" role="form">
        <div class="form-group">
          <label>Comment</label>
          <textarea type="textarea" name='comment' id='comment' class="input-group col-sm-offset-1 col-sm-10" rows="5" placeholder="Comment..."/>
        </div>
        
        <div class="col-sm-12" style="margin-top: 10px;"><a href="javascript:submit_local_form();" class="btn btn-primary btn-lg btn-block"> <i class="fa fa-save"></i> Submit</a></div>
			</form>
		</div>
	</div>
</div>
