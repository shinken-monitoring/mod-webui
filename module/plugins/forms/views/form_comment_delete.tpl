<script type="text/javascript">
	function submit_local_form() {
		var form = document.forms['modal_form'];

		delete_all_comments('{{name}}');
		$('#modal').modal('hide')
	}
</script>


<div class="modal-dialog">
	<div class="modal-content">
		<div class="modal-header">
			<a class="close" data-dismiss="modal">×</a>
			<h3>Deletion confirm</h3>
		</div>

		<div class="modal-body">
			<form name="input_form" class="form-horizontal" role="form">
				<div class="form-group">
					<label class="col-sm-12 control-label">Are you sure you want to delete all comments ?</label>
					<div class="col-sm-1">
						<textarea type="textarea" name='comment' class="span4 hide" rows=5 placeholder="Comment…"/>
					</div>
				</div>
			</form>
		</div>

		<div class="modal-footer">
			<a href="javascript:submit_local_form();" class="btn btn-danger"> <i class="icon-trash"></i> Delete</button></a>
			<a href="#" class="btn" data-dismiss="modal"> Close</a>
		</div>
	</div>
</div>