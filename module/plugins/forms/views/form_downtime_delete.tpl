<script type="text/javascript">
   function submit_local_form() {
      // Launch downtimes deletion request and bailout this modal view
      delete_downtime('{{name}}', '{{downtime}}');
      // If a comment is to be added ...
      if ($('#reason').val()) {
         add_comment("{{name}}", '{{user.get_name()}}', $('#reason').val());
      }
      start_refresh();
      $('#modal').modal('hide');
   }
</script>

<div class="modal-header">
   <a class="close" data-dismiss="modal">×</a>
   <h3>Confirm downtime '{{downtime}}' deletion</h3>
</div>

<div class="modal-body">
   <form name="input_form" role="form">
      <div class="form-group">
         <textarea name="reason" id="reason" class="form-control" rows="5" placeholder="Comment ...">Dowtime '{{downtime}}' for {{name}} deleted by {{user.get_name()}}.</textarea>
      </div>

      <a href="javascript:submit_local_form();" class="btn btn-danger btn-lg btn-block"> <i class="fa fa-save"></i> Submit</a>
   </form>
</div>
