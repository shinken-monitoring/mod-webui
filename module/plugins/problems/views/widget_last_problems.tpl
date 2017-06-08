<!-- Problems table -->
%setdefault('commands', True)

%helper = app.helper

%rebase("widget")

%if not pbs:
   <span>No problems!</span>
%else:
   %include("_problems_synthesis.tpl", all_pbs=all_pbs, search_string='', widget=True)

   <table class="table table-condensed">
      <tbody>
      %for pb in pbs:
         <tr>
            <td title="{{pb.get_name()}} - {{pb.output}} - Since {{helper.print_duration(pb.last_state_change)}} - Last check: {{helper.print_duration(pb.last_chk)}}" class="align-center">
               {{!helper.get_fa_icon_state(pb, useTitle=False)}}
            </td>

            <td>
               <small>{{!helper.get_link(pb)}}</small>
            </td>

            <td class="hidden-sm hidden-xs hidden-md">
               <small>{{!helper.get_business_impact_text(pb.business_impact)}}</small>
            </td>

            %if app.can_action() and commands:
            <td align="right">
                <div class="btn-group" role="group" data-type="actions" aria-label="Actions">
                    %if pb.event_handler_enabled and pb.event_handler:
                    <button class="btn btn-default btn-xs js-try-to-fix"
                        title="Try to fix (launch event handler)"
                        data-element="{{helper.get_uri_name(pb)}}"
                        >
                        <i class="fa fa-magic"></i>
                    </button>
                    %end
                    <button class="btn btn-default btn-xs js-recheck"
                        title="Launch the check command"
                        data-element="{{helper.get_uri_name(pb)}}"
                        >
                        <i class="fa fa-refresh"></i>
                    </button>
                    <button class="btn btn-default btn-xs js-submit-ok"
                        title="Submit a check result"
                        data-element="{{helper.get_uri_name(pb)}}"
                        data-user="{{user}}"
                        >
                        <i class="fa fa-share"></i>
                    </button>
                    %if pb.state != pb.ok_up and not pb.problem_has_been_acknowledged:
                    <button class="btn btn-default btn-xs js-add-acknowledge"
                        title="Acknowledge this problem"
                        data-element="{{helper.get_uri_name(pb)}}"
                        >
                        <i class="fa fa-check"></i>
                    </button>
                    %end
                    %if pb.state != pb.ok_up and not pb.in_scheduled_downtime:
                    <button class="btn btn-default btn-xsi js-schedule-downtime"
                        title="Schedule a downtime for this problem"
                        data-element="{{helper.get_uri_name(pb)}}"
                        >
                        <i class="fa fa-ambulance"></i>
                    </button>
                    %end
                </div>
            </td>
            %end
         </tr>
      %end
      </tbody>
   </table>
%end
