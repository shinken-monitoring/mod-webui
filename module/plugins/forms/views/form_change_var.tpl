<script type="text/javascript">
   function submit_local_form() {
      $("select option:selected").each(function() {
         console.debug("Change variable '"+$(this).text()+"'="+$('#output').val());
         change_custom_var("{{name}}", $(this).text(), $('#output').val());
      });
      $('#modal').modal('hide')
   }
</script>


<div class="modal-header">
  <a class="close" data-dismiss="modal">×</a>
  <h3>Change custom variable for {{name}}</h3>
</div>

<div class="modal-body">
  <div class="row">
    <form name="input_form" role="form">
      <div class="form-group">
        <label class="col-sm-2 control-label">Variable</label>
        <select id="custom_var" name="custom_var">
          %if len(elt.customs) > 0:
          %for p in sorted(elt.customs):
          <option value="{{p}}" {{'selected' if p==variable else ''}} data-var-value="{{elt.customs[p]}}">{{p}}</option>
          %end
          %end
        </select>
        <script>
          $("#custom_var").change(function() {
            $( "select option:selected" ).each(function() {
              //alert("Selected: "+$(this).text()+' = '+$(this).data('var-value'));
              $('#output').val($(this).data('var-value'));
            });
          });
        </script>
      </div>

      <div class="form-group">
        <label class="col-sm-2 control-label">Value</label>
        <input class="col-sm-9" type="text" id="output" name="output" value="{{value}}" placeholder="Value ...">
      </div>

      <div class="col-sm-12" style="margin-top: 10px;"><a href="javascript:submit_local_form();" class="btn btn-primary btn-lg btn-block"> <i class="fa fa-save"></i> Submit</a></div>
    </form>
  </div>
</div>
