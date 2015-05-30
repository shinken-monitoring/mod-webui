<!-- Actions panel -->
<div class="panel panel-info" id="actions">
  <div class="panel-heading">Actions</div>
  <div class="panel-body">
    <ul class="list-group">
      <li class="list-group-item" title="Try to fix all selected problems (launch event handler if defined)">
        <a href="javascript:try_to_fix_all();">
          <i class="fa fa-magic"></i> Try to fix
        </a>
      </li>
      <li class="list-group-item" title="Launch the check command for all selected services">
        <a href="javascript:recheck_now_all()">
          <i class="fa fa-refresh"></i> Recheck
        </a>
      </li>
      <li class="list-group-item" title="Force selected services to be considered as Ok">
        <a href="javascript:submit_check_ok_all()">
          <i class="fa fa-share"></i> Submit Result OK
        </a>
      </li>
      <li class="list-group-item" title="Acknowledge all selected problems">
        <a href="javascript:acknowledge_all('{{user.get_name()}}')">
          <i class="fa fa-check"></i> Acknowledge
        </a>
      </li>
      <li class="list-group-item" title="Schedule a one day downtime for all selected problems">
        <a href="javascript:downtime_all('{{user.get_name()}}')">
          <i class="fa fa-ambulance"></i> Schedule a downtime
        </a>
      </li>
      <li class="list-group-item" title="Ignore checks for selected services (disable checks, notifications, event handlers and force Ok)">
        <a href="javascript:remove_all('{{user.get_name()}}')">
          <i class="fa fa-eraser"></i> Delete from WebUI
        </a>
      </li>
    </ul>
  </div>
</div>
%end
