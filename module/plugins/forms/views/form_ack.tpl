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
		// Launch acknowledge request and bailout this modal view
		do_acknowledge("{{name}}", $('#reason').val(), '{{username}}');
    start_refresh();
		$('#modal').modal('hide');
	}
</script>

<div class="modal-dialog">
	<div class="modal-content">
		<div class="modal-header">
			<a class="close" data-dismiss="modal">×</a>
			<h3>Acknowledge {{name}}</h3>
		</div>

		<div class="modal-body">
			<form name="input_form" role="form">
        <div class="form-group">
          <label>Reason</label>
          <textarea type="textarea" name="reason" id="reason" autofocus="" class="input-group col-sm-offset-1 col-sm-10" rows="5" placeholder="Reason..."/>
        </div>
        
        <a href="javascript:submit_local_form();" class="btn btn-primary btn-lg btn-block"> <i class="fa fa-save"></i> Submit</a>
			</form>
		</div>
	</div>
</div>