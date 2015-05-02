<script type="text/javascript">
	function submit_local_form() {
		submit_check("{{name}}", $('#return_code').val(), $('#output').val());
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
      <div class="row">
        <form name="input_form" role="form">
          <div class="form-group">
            <label class="col-sm-2 control-label">Status</label>
            <select id='return_code' name='return_code'>
            %if obj_type == 'host':
              <option value='0'>UP</option>
              <option value='1'>DOWN</option>
              <option value='2'>UNREACHABLE</option>
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
            <input class="col-sm-9" type="text" id="output" name="output" placeholder="Check output...">
          </div>

          <!--
          <div class="form-group">
            <label class="col-sm-2 control-label">Perfdata</label>
            <input type="text" name='perfdata' class="col-sm-9" placeholder="Perfdata...">
          </div>
          -->
          <div class="col-sm-12" style="margin-top: 10px;"><a href="javascript:submit_local_form();" class="btn btn-primary btn-lg btn-block"> <i class="fa fa-save"></i> Submit</a></div>
        </form>
      </div>
		</div>
	</div>
</div>
