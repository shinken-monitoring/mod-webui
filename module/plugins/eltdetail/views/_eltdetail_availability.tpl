%if app.logs_module.is_available() and elt_type=='host':
<div class="tab-pane fade" id="availability">
  <div class="panel panel-default">
    <div class="panel-body">
      <div id="inner_availability" data-element='{{elt.get_full_name()}}'>
      </div>
    </div>
  </div>
</div>
%end
