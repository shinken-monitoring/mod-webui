<script type="text/javascript">
	function submit_local_form() {
		var form = document.forms['input_form'];

		var output = form.output.value;
		var return_code = form.return_code.value;

		submit_check("{{name}}", return_code, output);
		$('#modal').modal('hide')
	}
</script>


<div class="modal-dialog">
	<div class="modal-content">
		<div class="modal-header">
			<a class="close" data-dismiss="modal">×</a>
			<h3>Submit check for {{name}}</h3>
		</div>
		
		<div class="modal-body">
			<form name="input_form" class="form-horizontal" role="form">
				<div class="form-group">
					<label class="col-sm-2 control-label">Status</label>
					<select name='return_code'>
					%if obj_type == 'host':
						<option value='0'>UP</option>
						<option value='1'>DOWN</option>
					%else:
						<option value='0'>OK</option>
						<option value='1'>WARNING</option>
						<option value='2'>CRITICAL</option>
						<option value='3'>UNKNOWN</option>
					%end
					</select>
				</div>

				<div class="form-group">
					<label class="col-sm-2 control-label">Output</label>
					<input type="text" name='output' class="col-sm-9" placeholder="Check output...">
				</div>

				<!--
				<div class="form-group">
					<label class="col-sm-2 control-label">Perfdata</label>
					<input type="text" name='perfdata' class="col-sm-9" placeholder="Perfdata...">
				</div>
				-->
			</form>
		</div>
		
		<div class="modal-footer">
			<a href="javascript:submit_local_form();" class="btn btn-primary"> <i class="fa fa-save"></i> Submit</a>
			<a href="#" class="btn" data-dismiss="modal">Close</a>
		</div>
	</div>
</div>