<script type="text/javascript">
   function submit_local_form() {
      // Launch acknowledge request and bailout this modal view
      do_acknowledge("{{name}}", $('#reason').val(), '{{user.get_name()}}');
      
      %if elt.__class__.my_type=='host':
      if ($('#ack_services').is(":checked")) {
      %for service in elt.services:
      %if service.state != service.ok_up and not service.problem_has_been_acknowledged:
         do_acknowledge("{{name}}/{{service.get_name()}}", $('#reason').val(), '{{user.get_name()}}');
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
   <h3>Acknowledge {{name}}</h3>
</div>

<div class="modal-body">
   <form name="input_form" role="form">
      %if elt.__class__.my_type=='host':
      <div class="form-group">
         <input name="ack_services" id="ack_services" type="checkbox" checked="checked">Acknowledge all services for the host?</input>
      </div>
      %end
      
      <div class="form-group">
         <textarea name="reason" id="reason" class="form-control" rows="5" placeholder="Reason…">Acknowledged from WebUI by {{user.get_name()}}.</textarea>
      </div>
       
      <a href="javascript:submit_local_form();" class="btn btn-primary btn-lg btn-block"> <i class="fa fa-save"></i> Submit</a>
   </form>
</div>
