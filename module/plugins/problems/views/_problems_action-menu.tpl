%if app.can_action():
<nav id="action-menu" class="navbar navbar-default navbar-element visible-xs" role="navigation" style="display:none;">
  <ul class="nav">
    %s = app.datamgr.get_services_synthesis(user=user, elts=all_pbs)
    %h = app.datamgr.get_hosts_synthesis(user=user, elts=all_pbs)
    <li> <a href="#" class="js-try-to-fix" title="Try to fix the selected problems" data-placement="right">
        <i class="fa fa-magic"></i> <span class="hidden-xs">Try to fix</span>
    </a> </li>
    <li> <a href="#" class="js-recheck" title="Recheck the selected elements" data-placement="right">
        <i class="fa fa-refresh"></i> <span class="hidden-xs">Recheck</span>
    </a> </li>
    <li> <a href="#" class="js-submit-ok" title="Set the selected problems as OK/UP" data-placement="right">
        <i class="fa fa-share"></i> <span class="hidden-xs">Set Ok</span>
    </a> </li>
    <li> <a href="#" class="js-add-acknowledge" title="Acknowledge the selected problems" data-placement="right">
        <i class="fa fa-check"></i> <span class="hidden-xs">Acknowledge</span>
    </a> </li>
    <li> <a href="#" class="js-schedule-downtime" title="Schedule a one day downtime for the selected elements" data-placement="right">
        <i class="fa fa-ambulance"></i> <span class="hidden-xs">Schedule a downtime</span>
    </a> </li>
    %if s and s['nb_ack']:
    <li> <a href="#" class="js-remove-acknowledge" class="text-danger" title="Remove the acknowledge for the selected problems" data-placement="right">
        <i class="fa fa-check text-danger"></i> <span class="hidden-xs">Unacknowledge</span>
    </a> </li>
    %end
    %if s and s['nb_downtime']:
    <li> <a href="#" class="js-delete-all-downtimes" class="text-danger" title="Delete all downtimes for the selected elements" data-placement="right">
        <i class="fa fa-ambulance"></i> <span class="hidden-xs">Delete all downtimes</span>
    </a> </li>
    %end
  </ul>
</nav>
%end
