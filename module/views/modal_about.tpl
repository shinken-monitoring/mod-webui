%if alignak:
%from alignak.version import VERSION
%else:
%from shinken.bin import VERSION
%end


<div class="modal-header">
  <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
  <h4 class="modal-title">About {{fmwk}} Web UI:</h4>
</div>
<div class="modal-body">
  <!-- About Form -->
  <form class="form-horizontal">
  <fieldset>
     <div class="control-group">
        <label class="control-label" for="app_version">Web User Interface Version</label>
        <div class="controls">
           <input readonly="" name="app_version" type="text" class="form-control" placeholder="Not set" class="input-medium" value="{{fmwk}} Web UI, version: {{app.app_version if app is not None else ''}}">
        </div>
     </div>

     <div class="control-group">
        <label class="control-label" for="fmwk_version">{{fmwk}} Framework Version</label>
        <div class="controls">
           <input readonly="" name="fmwk_version" type="text" class="form-control" placeholder="Not set" class="input-medium" value="{{fmwk}} Framework, version: {{VERSION}}">
        </div>
     </div>

     <div class="control-group">
        <label class="control-label" for="app_copyright">Copyright</label>
        <div class="controls">
           <input readonly="" name="app_copyright" type="text" class="form-control" placeholder="Not set" class="input-medium" value="(c) {{app.app_copyright if app is not None else ''}} - {{app.app_license if app is not None else ''}}">
        </div>
     </div>

     <div class="control-group">
        <label class="control-label" for="app_release">Release notes</label>
        <div class="controls">
          <a href="https://github.com/shinken-monitoring/mod-webui/releases">https://github.com/shinken-monitoring/mod-webui/releases</a>
        </div>
     </div>
  </fieldset>
  </form>
</div>
<div class="modal-footer">
  <a href="#" class="btn btn-default" data-dismiss="modal">Close</a>
</div>
