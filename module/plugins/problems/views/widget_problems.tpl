
%helper = app.helper

%rebase("widget")

%if not pbs:
   <span>No problems!</span>
%else:
   <table class="table table-condensed">
      <tbody>
      %for pb in pbs:
         <tr>
            <td class="align-center">
               {{!helper.get_fa_icon_state(pb)}}
            </td>

            <td class="align-left">
               <small>{{!helper.get_link(pb)}}</small>
            </td>

            <td class="hidden-sm hidden-xs hidden-md">
               <small>{{!helper.get_business_impact_text(pb.business_impact)}}</small>
            </td>

            %if app.can_action():
            <td align="right">
                <div class="btn-group" role="group" data-type="actions" aria-label="Actions">
                    %if pb.event_handler_enabled and pb.event_handler:
                    <button class="btn btn-default btn-xs"
                        data-type="action" action="event-handler"
                        data-toggle="tooltip" data-placement="bottom" title="Try to fix (launch event handler)"
                        data-element="{{helper.get_uri_name(pb)}}"
                        >
                        <i class="fa fa-magic"></i>
                    </button>
                    %end
                    <button class="btn btn-default btn-xs"
                        data-type="action" action="recheck"
                        data-toggle="tooltip" data-placement="bottom" title="Launch the check command"
                        data-element="{{helper.get_uri_name(pb)}}"
                        >
                        <i class="fa fa-refresh"></i>
                    </button>
                    <button class="btn btn-default btn-xs"
                        data-type="action" action="check-result"
                        data-toggle="tooltip" data-placement="bottom" title="Submit a check result"
                        data-element="{{helper.get_uri_name(pb)}}"
                        data-user="{{user}}"
                        >
                        <i class="fa fa-share"></i>
                    </button>
                    %if pb.state != pb.ok_up and not pb.problem_has_been_acknowledged:
                    <button class="btn btn-default btn-xs"
                        data-type="action" action="add-acknowledge"
                        data-toggle="tooltip" data-placement="bottom" title="Acknowledge this problem"
                        data-element="{{helper.get_uri_name(pb)}}"
                        >
                        <i class="fa fa-check"></i>
                    </button>
                    %end
                    %if pb.state != pb.ok_up and not pb.in_scheduled_downtime:
                    <button class="btn btn-default btn-xs"
                        data-type="action" action="schedule-downtime"
                        data-toggle="tooltip" data-placement="bottom" title="Schedule a downtime for this problem"
                        data-element="{{helper.get_uri_name(pb)}}"
                        >
                        <i class="fa fa-ambulance"></i>
                    </button>
                    %end
                    <button class="btn btn-default btn-xs"
                        data-type="action" action="ignore-checks"
                        data-toggle="tooltip" data-placement="bottom" title="Ignore checks for the service (disable checks, notifications, event handlers and force Ok)"
                        data-element="{{helper.get_uri_name(pb)}}"
                        data-user="{{user}}"
                        >
                        <i class="fa fa-eraser"></i>
                    </button>
                </div>
            </td>
            %end
         </tr>
      %end
      </tbody>
   </table>
%end
