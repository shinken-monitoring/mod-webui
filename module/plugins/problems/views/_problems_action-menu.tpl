%if app.can_action():
<nav id="action-menu" class="navbar navbar-default navbar-element" role="navigation" style="display:none;">
  <ul class="nav">
    %s = app.datamgr.get_services_synthesis(user=user, elts=all_pbs)
    %h = app.datamgr.get_hosts_synthesis(user=user, elts=all_pbs)
    <li> <a href="#" action="event-handler" title="Try to fix the selected problems">
        <i class="fa fa-magic"></i> <span class="hidden-xs">Try to fix</span>
    </a> </li>
    <li> <a href="#" action="recheck" title="Launch the check command for selected problems">
        <i class="fa fa-refresh"></i> <span class="hidden-xs">Recheck</span>
    </a> </li>
    <li> <a href="#" action="check-result" title="Set the selected problems as OK/UP">
        <i class="fa fa-share"></i> <span class="hidden-xs">Set Ok</span>
    </a> </li>
    <li> <a href="#" action="add-acknowledge" title="Acknowledge the selected problems">
        <i class="fa fa-check"></i> <span class="hidden-xs">Acknowledge</span>
    </a> </li>
    <li> <a href="#" action="schedule-downtime" title="Schedule a one day downtime for the selected problems">
        <i class="fa fa-ambulance"></i> <span class="hidden-xs">Schedule a downtime</span>
    </a> </li>
    %if s and s['nb_ack']:
    <li> <a href="#" action="remove-acknowledge" class="text-danger" title="Remove the acknowledge for the selected problems">
        <i class="fa fa-check text-danger"></i> <span class="hidden-xs">Unacknowledge</span>
    </a> </li>
    %end
    %if s and s['nb_downtime']:
    <li> <a href="#" action="delete-all-downtimes" class="text-danger" title="Delete all downtimes for the selected problems">
        <i class="fa fa-ambulance"></i> <span class="hidden-xs">Delete all downtimes</span>
    </a> </li>
    %end
  </ul>
</nav>
%end
