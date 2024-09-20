%if app.logs_module.is_available():
<div class="tab-pane fade" id="history">
  <div class="panel panel-default" style="border-top:none; border-radius:0;">
    <div class="panel-body">
      <div class="pull-right">
      <a class="btn btn-default btn-sm" href="/logs/json?service={{ elt.service_description if elt_type == 'service' else '' }}&host={{ elt.host_name }}" download><i class="fas fa-download"></i> Download</a>
      %if elt_type == 'host':
      %if app.request.query.get('logtype', ''):
      <a class="btn btn-default btn-sm" href="?logtype=#history"><i class="fas fa-filter"></i> Display host with all services</a>
      %else:
      <a class="btn btn-default btn-sm" href="?logtype=HOST#history"><i class="fas fa-filter"></i> Display host only</a>
      %end
      %end
      </div>

      <div id="inner_history" data-host='{{ elt.host_name }}' data-service='{{ elt.service_description if elt_type == 'service' else '' }}' data-logtype='{{ app.request.query.get('logtype', '') }}'>
      </div>

      <div class="text-center" id="loading-spinner">
        <h3><i class="fas fa-spinner fa-spin"></i> Loading history data…</h3>
      </div>
    </div>
  </div>
</div>
%end
