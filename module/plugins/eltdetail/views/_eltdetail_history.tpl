%if app.logs_module.is_available():
<div class="tab-pane fade" id="history">
  <div class="panel panel-default">
    <div class="panel-body">
      <div id="inner_history" data-element='{{elt.get_full_name()}}'>
      </div>
    </div>
  </div>
</div>
%end
