%helper = app.helper
%datamgr = app.datamgr

%search_string = app.get_search_string()

%rebase("layout", css=['impacts/css/impacts.css'], js=['impacts/js/impacts.js'], title='All critical impacts for your business', refresh=True)

%import time

<div id="impacts-container">
   %if not impacts:
   <center>
     <h3>No impacts.</h3>
   </center>
   %else:

   <div class="impacts-panel col-sm-5">
      %# " We look for separate bad and good elements, so we remember last state"
      %last_was_bad = False
      %# " By default we won't expand an impact."
      <script type="text/javascript">
         var impact_to_expand = -1;
      </script>

      %for imp_id in impacts:
      %impact = impacts[imp_id]

      %# "When we switch, add a HR to really separate things"
      %if impact.state_id == 0 and last_was_bad and imp_id != 1:
      <hr/>
      %last_was_bad = False
      %end
      
      %if impact.state_id != 0:
      %last_was_bad = True
      %end

      %if imp_id == 1 and impact.state_id != 0:
      <script type="text/javascript">
         impact_to_expand = {{imp_id}};
      </script>
      %end

      <div class="impact" id="{{imp_id}}">
         <div class="impact-blade">
            <div class="impact-icon pull-left">{{! helper.get_fa_icon_state(obj=impact)}}</div>
            <div class="show-problem pull-right" id="show-problem-{{imp_id}}"><i class="fa fa-arrow-right"></i></div>
            <div class="impact-rows">
               <span>
                  {{impact.get_full_name()}}
                  %if impact.business_impact > 2:
                     {{!helper.get_business_impact_text(impact.business_impact)}}
                  %end
               </span> is <span class="font-{{impact.state.lower()}}">{{impact.state}}</span>
               <span>since {{helper.print_duration(impact.last_state_change, just_duration=True, x_elts=2)}}</span>
            </div>
         </div>
      </div>
      %# end of the for imp_id in impacts:
      %end
   </div>

   %# "#######    Now we will output right panel with all root problems"
   <div class="problems-panels col-sm-7">
      %# I init pb_id
      %pb_id = 0

      %for imp_id in impacts:
      %impact = impacts[imp_id]

      <div class="problems-panel panel panel-default" id="problems-{{imp_id}}" style="display: none;">
         <div class="panel-heading">
            <button id="{{imp_id}}" aria-hidden="true" data-dismiss="modal" class="impact close pull-right" type="button">×</button>
            <h4>
               {{! helper.get_fa_icon_state(obj=impact)}} {{impact.get_full_name()}} is {{impact.state}}
            </h4>
         </div>
         
         <div class="panel-body">
            <div class="row">
               <div class="col-sm-10 btn-group btn-group-justified">
                  <a href="{{!helper.get_link_dest(impact)}}" class="btn btn-default" role="button"><i class="fa fa-search"></i> Details</a>
                  <a href="/depgraph/{{impact.get_full_name()}}" class="btn btn-default" role="button" title="Impact map of {{impact.get_full_name()}}"> <i class="fa fa-map-marker"></i> Impact map</a>
               </div>
            </div>
            
            %if len(impact.parent_dependencies) > 0:
            <hr/>
            Dependencies:
            {{!helper.print_business_rules(datamgr.get_business_parents(user, impact), source_problems=impact.source_problems)}}
            %end

            <hr/>
            %##### OK, we print root problem NON ack first
            %l_pb_id = 0
            %unack_pbs = [pb for pb in impact.source_problems if not pb.problem_has_been_acknowledged]
            %ack_pbs = [pb for pb in impact.source_problems if pb.problem_has_been_acknowledged]
            %nb_unack_pbs = len(unack_pbs)
            %nb_ack_pbs = len(ack_pbs)
            %if nb_unack_pbs > 0:
            Root problems unacknowledged:
            %end

            %guessed = []
            %if impact.state_id != 0 and len(unack_pbs+ack_pbs) == 0:
            %guessed = datamgr.guess_root_problems(impact)
            %end

            <ul class="list-group">

            %for pb in unack_pbs+ack_pbs+guessed:
            %   pb_id += 1
            % l_pb_id += 1

            %if nb_ack_pbs != 0 and l_pb_id == nb_unack_pbs + 1:
            Acknowledged problems:
            %end

            %if len(guessed) != 0 and l_pb_id == nb_unack_pbs + nb_ack_pbs + 1:
            Pure guessed root problems:
            %end
            <li class="list-group-item">
               {{! helper.get_fa_icon_state(obj=pb)}} {{!helper.get_link(pb)}}
               %if pb.business_impact > 2:
                  ({{!helper.get_business_impact_text(pb.business_impact)}})
               %end
               is <span class="font-{{pb.state.lower()}}"><strong>{{pb.state}}</strong></span>
               since <span title="{{time.strftime("%d %b %Y %H:%M:%S", time.localtime(pb.last_state_change))}}">{{helper.print_duration(pb.last_state_change, just_duration=True, x_elts=2)}}</span>

               <div class="btn-group" role="group" aria-label="Actions">
                  %disabled='' if pb.event_handler_enabled and pb.event_handler else 'disabled'
                  <button class="btn btn-default btn-xs {{disabled}}" 
                        action="event-handler"
                        data-toggle="tooltip" data-placement="bottom" title="Try to fix (launch event handler)"
                        data-element="{{helper.get_uri_name(pb)}}" 
                        >
                     <i class="fa fa-magic"></i><span class="hidden-sm hidden-xs"> Try to fix</span>
                  </button>
                  %disabled='' if pb.active_checks_enabled else 'disabled'
                  <button class="btn btn-default btn-xs {{disabled}}" 
                        action="recheck"
                        data-toggle="tooltip" data-placement="bottom" title="Launch the check command"
                        data-element="{{helper.get_uri_name(pb)}}" 
                        >
                     <i class="fa fa-refresh"></i><span class="hidden-sm hidden-xs"> Refresh</span>
                  </button>
                  <button class="btn btn-default btn-xs" 
                        action="check-result"
                        data-toggle="tooltip" data-placement="bottom" title="Submit a check result"
                        data-element="{{helper.get_uri_name(pb)}}" 
                        data-user="{{user}}" 
                        >
                     <i class="fa fa-share"></i><span class="hidden-sm hidden-xs"> Submit check result</span>
                  </button>
                  %disabled='' if pb.state != pb.ok_up and not pb.problem_has_been_acknowledged else 'disabled'
                  <button class="btn btn-default btn-xs {{disabled}}" 
                        action="add-acknowledge"
                        data-toggle="tooltip" data-placement="bottom" title="Acknowledge this problem"
                        data-element="{{helper.get_uri_name(pb)}}" 
                        >
                     <i class="fa fa-check"></i><span class="hidden-sm hidden-xs"> Acknowledge</span>
                  </button>

                  <button class="btn btn-default btn-xs" 
                        action="schedule-downtime"
                        data-toggle="tooltip" data-placement="bottom" title="Schedule a downtime for this problem"
                        data-element="{{helper.get_uri_name(pb)}}" 
                        >
                   <i class="fa fa-ambulance"></i><span class="hidden-sm hidden-xs"> Downtime</span>
                  </button>
                  <button class="btn btn-default btn-xs" 
                        action="ignore-checks"
                        data-toggle="tooltip" data-placement="bottom" title="Ignore checks for the service (disable checks, notifications, event handlers and force Ok)"
                        data-element="{{helper.get_uri_name(pb)}}" 
                        data-user="{{user}}" 
                        >
                     <i class="fa fa-eraser"></i><span class="hidden-sm hidden-xs"> Remove</span>
                  </button>
               </div>
            </li>
            %# end for pb in impact.source_problems:
            %end
            </ul>
         </div>
      </div>
      %# end for imp_id in impacts:
      %end
   </div>
   %end
</div>
