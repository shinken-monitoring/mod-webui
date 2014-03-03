<script type="text/javascript">
	function submit_local_form() {
		var form = document.forms['modal_form'];

		var comment = form.comment.value;

		add_comment("{{name}}", '{{user.get_name()}}', comment);
		$('#modal').modal('hide')
	}
</script>


<div class="modal-dialog">
	<div class="modal-content">
		<div class="modal-header">
			<a class="close" data-dismiss="modal">×</a>
			<h3>Add a comment on {{name}}</h3>
		</div>

		<div class="modal-body">
			<form class="form-horizontal" role="form">
			  <div class="form-group">
			    <label class="col-sm-2 control-label">Comment</label>
			    <div class="col-sm-10">
			      <textarea type="textarea" name='comment' class="form-control-static col-sm-12" rows=5 placeholder="Comment…"/>
			    </div>
			  </div>
			</form>
		</div>

		<div class="modal-footer">
			<a href="javascript:submit_local_form();" class="btn btn-primary"> <i class="icon-save"></i> Submit</a>
			<a href="#" class="btn" data-dismiss="modal">Close</a>
		</div>
	</div>
</div>