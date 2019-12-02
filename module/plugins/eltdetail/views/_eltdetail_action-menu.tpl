%if app.can_action():
<nav id="action-menu" class="navbar navbar-default sidebar dropup" role="navigation">
  <ul class="nav">
    %if elt.is_problem and elt.event_handler_enabled and elt.event_handler:
    <li> <a href="#" class="js-try-to-fix" title="Try to fix the current problem for this {{elt_type}}"
        data-placement="right"
        data-element="{{helper.get_uri_name(elt)}}" >
        <i class="fas fa-magic"></i> <span class="hidden-xs">Try to fix</span>
    </a> </li>
    %end
    <li> <a href="#" class="js-recheck" title="Launch the defined check command for this {{elt_type}}"
        data-placement="right"
        data-element="{{helper.get_uri_name(elt)}}" >
        <i class="fas fa-refresh"></i> <span class="hidden-xs">Recheck</span>
    </a> </li>
    %if (elt.passive_checks_enabled):
    <li> <a href="#" class="js-submit-ok" title="Set this {{elt_type}} as ok"
        data-placement="right"
        data-element="{{helper.get_uri_name(elt)}}" >
        <i class="fas fa-share"></i> <span class="hidden-xs">Submit check result</span>
    </a> </li>
    %end
    %if elt.state != elt.ok_up and not elt.problem_has_been_acknowledged:
    <li> <a href="#" class="js-add-acknowledge" title="Acknowledge this {{elt_type}} problem"
        data-placement="right"
        data-element="{{helper.get_uri_name(elt)}}" >
        <i class="fas fa-check"></i> <span class="hidden-xs">Acknowledge</span>
    </a> </li>
    %end
    %if elt.problem_has_been_acknowledged:
    <li> <a href="#" class="js-remove-acknowledge" title="Remove the acknowledge for this {{elt_type}} problem"
        data-placement="right"
        data-element="{{helper.get_uri_name(elt)}}" >
        <i class="fas fa-check"></i> <span class="hidden-xs">Unacknowledge</span>
    </a> </li>
    %end
    <li> <a href="#" class="js-schedule-downtime" title="Schedule a downtime for this {{elt_type}}"
        data-placement="right"
        data-element="{{helper.get_uri_name(elt)}}" >
        <i class="far fa-clock"></i> <span class="hidden-xs">Schedule a downtime</span>
    </a> </li>
    %if elt.downtimes:
    <li> <a href="#" class="js-delete-all-downtimes" title="Delete all downtimes for this {{elt_type}}"
        data-placement="right"
        data-element="{{helper.get_uri_name(elt)}}" >
        <i class="far fa-clock"></i> <span class="hidden-xs">Delete all downtimes</span>
    </a> </li>
    %end
    %if elt_type=='host' and app.helpdesk_module.is_available():
    <li> <a href="#" class="js-create-ticket" title="Create a ticket for this {{elt_type}}"
        data-placement="right"
        data-element="{{helper.get_uri_name(elt)}}" >
        <i class="fas fa-medkit"></i> <span class="hidden-xs">Create a ticket</span>
    </a> </li>
    %end
  </ul>
</nav>
%end
