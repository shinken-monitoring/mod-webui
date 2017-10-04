<script type="text/javascript">
   function submit_local_form() {
      // Launch comment deletion and bailout this modal view
      delete_comment('{{name}}', '{{comment}}');
      start_refresh();
      $('#modal').modal('hide');
   }
</script>

<div class="modal-header">
  <a class="close" data-dismiss="modal">×</a>
  <h3>Confirm comment '{{comment}}' deletion</h3>
</div>

<div class="modal-body">
  <form name="input_form" role="form">
    <a href="javascript:submit_local_form();" class="btn btn-danger btn-lg btn-block"> <i class="fa fa-save"></i> Submit</a>
  </form>
</div>
