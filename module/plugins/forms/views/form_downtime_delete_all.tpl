%user = app.get_user()
<script type="text/javascript">
   function submit_local_form() {
      // Launch downtimes deletion request and bailout this modal view
      delete_all_downtimes("{{name}}");
      // If a comment is to be added ...
      if ($('#reason').val()) {
         add_comment("{{name}}", '{{user.get_username()}}', $('#reason').val());
      }

      %if elt.__class__.my_type=='host':
      if ($('#dwn_services').is(":checked")) {
      %for service in elt.services:
         delete_all_downtimes("{{name}}/{{service.get_name()}}");
      %end
      }
      %end

      enable_refresh();
      $('#modal').modal('hide');
   }
</script>

<div class="modal-header">
   <a class="close" data-dismiss="modal">×</a>
   <h3>Confirm downtime(s) deletion</h3>
</div>

<div class="modal-body">
   <form name="input_form" role="form">
      %if elt.__class__.my_type=='host':
      <div class="checkbox">
        <label>
          <input name="dwn_services" id="dwn_services" type="checkbox"> Also delete on all services</input>
        </label>
      </div>
      %end

      <div class="form-group">
         <textarea name="reason" id="reason" class="form-control" rows="5" placeholder="Comment…">All dowtimes deleted for {{name}} by {{user.get_name()}}.</textarea>
      </div>

      <a href="javascript:submit_local_form();" class="btn btn-danger btn-lg btn-block"> <i class="fas fa-save"></i> Submit</a>
   </form>
</div>
