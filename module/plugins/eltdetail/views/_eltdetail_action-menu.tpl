%if app.can_action():
<nav id="action-menu" class="navbar navbar-default navbar-element dropup" role="navigation">
  <ul class="nav">
    <li> <a href="#" class="js-add-comment" title="Add a comment for this {{elt_type}}"
        data-element="{{helper.get_uri_name(elt)}}" >
        <i class="fa fa-plus"></i> Add a comment
    </a> </li>
    %if elt.is_problem and elt.event_handler_enabled and elt.event_handler:
    <li> <a href="#" class="js-try-to-fix" title="Try to fix the current problem for this {{elt_type}}"
        data-element="{{helper.get_uri_name(elt)}}" >
        <i class="fa fa-magic"></i> Try to fix
    </a> </li>
    %end
    <li> <a href="#" class="js-recheck" title="Launch the defined check command for this {{elt_type}}"
        data-element="{{helper.get_uri_name(elt)}}" >
        <i class="fa fa-refresh"></i> Recheck
    </a> </li>
    %if (elt.passive_checks_enabled):
    <li> <a href="#" class="js-submit-ok" title="Set this {{elt_type}} as ok"
        data-element="{{helper.get_uri_name(elt)}}" >
        <i class="fa fa-share"></i> Submit check result
    </a> </li>
    %end
    %if elt.state != elt.ok_up and not elt.problem_has_been_acknowledged:
    <li> <a href="#" class="js-add-acknowledge" title="Acknowledge this {{elt_type}} problem"
        data-element="{{helper.get_uri_name(elt)}}" >
        <i class="fa fa-check"></i> Acknowledge
    </a> </li>
    %end
    %if elt.problem_has_been_acknowledged:
    <li> <a href="#" class="js-remove-acknowledge" title="Remove the acknowledge for this {{elt_type}} problem"
        data-element="{{helper.get_uri_name(elt)}}" >
        <i class="fa fa-check"></i> Unacknowledge
    </a> </li>
    %end
    <li> <a href="#" class="js-schedule-downtime" title="Schedule a downtime for this {{elt_type}}"
        data-element="{{helper.get_uri_name(elt)}}" >
        <i class="fa fa-ambulance"></i> Schedule a downtime
    </a> </li>
    %if elt.downtimes:
    <li> <a href="#" class="js-delete-all-downtimes" title="Delete all downtimes for this {{elt_type}}"
        data-element="{{helper.get_uri_name(elt)}}" >
        <i class="fa fa-ambulance"></i> Delete all downtimes
    </a> </li>
    %end
    %if elt_type=='host' and app.helpdesk_module.is_available():
    <li> <a href="#" class="js-create-ticket" title="Create a ticket for this {{elt_type}}"
        data-element="{{helper.get_uri_name(elt)}}" >
        <i class="fa fa-medkit"></i> Create a ticket
    </a> </li>
    %end
  </ul>
</nav>
%end
