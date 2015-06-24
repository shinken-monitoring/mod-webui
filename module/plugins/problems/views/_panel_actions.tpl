<!-- Actions panel -->

<div class="panel panel-default" id="actions" style="display:none;">
   <div class="panel-body text-center">
     <div class="btn-group">
       <a href="javascript:try_to_fix_all();" class="btn btn-default" title="Try to fix all selected problems (launch event handler if defined)">
         <i class="fa fa-magic"></i> Try to fix
       </a>
       <a href="javascript:recheck_now_all()" class="btn btn-default" title="Launch the check command for all selected services">
         <i class="fa fa-refresh"></i> Recheck
       </a>
       <a href="javascript:submit_check_ok_all()" class="btn btn-default" title="Force selected services to be considered as Ok">
         <i class="fa fa-share"></i> Submit Result OK
       </a>
       <a href="javascript:acknowledge_all('{{user.get_name()}}')" class="btn btn-default" title="Acknowledge all selected problems">
         <i class="fa fa-check"></i> Acknowledge
       </a>
       <a href="javascript:downtime_all('{{user.get_name()}}')" class="btn btn-default" title="Schedule a one day downtime for all selected problems">
         <i class="fa fa-ambulance"></i> Schedule a downtime
       </a>
       <a href="javascript:remove_all('{{user.get_name()}}')" class="btn btn-default" title="Ignore checks for selected services (disable checks, notifications, event handlers and force Ok)">
         <i class="fa fa-eraser"></i> Delete from WebUI
       </a>
     </div>
   </div>
</div>