%if app.logs_module.is_available():
<div class="tab-pane fade" id="history">
  <div class="panel panel-default" style="border-top:none; border-radius:0;">
    <div class="panel-body">
      <div id="inner_history" data-host='{{ elt.host_name }}' data-service='{{ elt.service_description if elt_type == 'service' else '' }}'>
      </div>

      <div class="text-center" id="loading-spinner">
        <h3><i class="fas fa-spinner fa-spin"></i> Loading history data…</h3>
      </div>
    </div>
  </div>
</div>
%end
