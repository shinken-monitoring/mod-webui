<script type="text/javascript">
   function submit_local_form() {
      submit_check("{{name}}", $('#return_code').val(), $('#output').val());
      add_comment("{{name}}", '{{user.get_name()}}', "Submitted a check result: "+$('#return_code').val()+" - "+$('#output').val());
      $('#modal').modal('hide')
   }
</script>


<div class="modal-header">
  <a class="close" data-dismiss="modal">×</a>
  <h3>Submit check for {{name}}</h3>
</div>

<div class="modal-body">
  <form class="form-horizontal" name="input_form" role="form">
    <div class="form-group">
      <label for="return_code" class="col-sm-2 control-label">Status</label>
      <div class="col-sm-10">
        <select class="form-control" id='return_code' name='return_code'>
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
    </div>

    <div class="form-group">
      <label for="output" class="col-sm-2 control-label">Output</label>
      <div class="col-sm-10">
        <input class="form-control" type="text" id="output" name="output" placeholder="Check output…">
      </div>
    </div>

    <!--
    <div class="form-group">
      <label class="col-sm-2 control-label">Perfdata</label>
      <input type="text" name='perfdata' class="col-sm-9" placeholder="Perfdata...">
    </div>
    -->
    <a href="javascript:submit_local_form();" class="btn btn-primary btn-lg btn-block"> <i class="fa fa-save"></i> Submit</a>
  </form>
</div>
