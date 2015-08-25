%from shinken.bin import VERSION

<div class="modal-header">
  <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
  <h4 class="modal-title">About Shinken Web UI:</h4>
</div>
<div class="modal-body">
  <!-- About Form -->
  <form class="form-horizontal">
  <fieldset>
     <div class="control-group">
        <label class="control-label" for="app_version">Web User Interface Version</label>
        <div class="controls">
           <input readonly="" name="app_version" type="text" class="form-control" placeholder="Not set" class="input-medium" value="Shinken Web UI, version: {{app.app_version if app is not None else ''}}">
        </div>
     </div>

     <div class="control-group">
        <label class="control-label" for="shinken_version">Shinken Framework Version</label>
        <div class="controls">
           <input readonly="" name="shinken_version" type="text" class="form-control" placeholder="Not set" class="input-medium" value="Shinken Framework, version: {{VERSION}}">
        </div>
     </div>

     <div class="control-group">
        <label class="control-label" for="app_copyright">Copyright</label>
        <div class="controls">
           <input readonly="" name="app_copyright" type="text" class="form-control" placeholder="Not set" class="input-medium" value="{{app.app_copyright if app is not None else ''}}">
        </div>
     </div>

     <div class="control-group">
        <label class="control-label" for="app_release">Release notes</label>
        <div class="controls">
           <textarea readonly="" name="app_release" rows="5" class="form-control" placeholder="Not set">{{app.app_release if app is not None else ''}}</textarea>
        </div>
     </div>
  </fieldset>
  </form>
</div>
<div class="modal-footer">
  <a href="#" class="btn btn-default" data-dismiss="modal">Close</a>
</div>
