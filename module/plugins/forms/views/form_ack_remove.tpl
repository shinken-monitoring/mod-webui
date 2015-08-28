<script type="text/javascript">
   function submit_local_form() {
      // Launch acknowledge removal request and bailout this modal view
      delete_acknowledge('{{name}}');
      // If a comment is to be added ...
      if ($('#reason').val()) {
         add_comment("{{name}}", '{{user.get_name()}}', $('#reason').val());
      }
      
      %if elt.__class__.my_type=='host':
      if ($('#ack_services').is(":checked")) {
      %for service in elt.services:
      %if service.problem_has_been_acknowledged:
         delete_acknowledge("{{name}}/{{service.get_name()}}");
         if ($('#reason').val()) {
            add_comment("{{name}}/{{service.get_name()}}", '{{user.get_name()}}', $('#reason').val());
         }
      %end
      %end
      }
      %end

      start_refresh();
      $('#modal').modal('hide');
   }
</script>

<div class="modal-header">
  <a class="close" data-dismiss="modal">×</a>
  <h3>Confirm acknowledge deletion</h3>
</div>

<div class="modal-body">
  <form name="input_form" role="form">
      %if elt.__class__.my_type=='host':
      <div class="form-group">
         <input name="ack_services" id="ack_services" type="checkbox" checked="checked">Delete acknowledge for all services for the host?</input>
      </div>
      %end
      
    <div class="form-group">
      <textarea name="reason" id="reason" class="form-control" rows="5" placeholder="Comment ...">Acknowledge deleted from WebUI by {{user.get_name()}}.</textarea>
    </div>
    
    <a href="javascript:submit_local_form();" class="btn btn-danger btn-lg btn-block"> <i class="fa fa-save"></i> Submit</a>
  </form>
</div>
