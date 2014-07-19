%helper = app.helper
%datamgr = app.datamgr

%rebase layout globals(), js=['impacts/js/impacts.js'], title='All critical impacts for your business', css=['impacts/css/impacts.css'], refresh=True, user=user


%# Look for actions if we must show them or not
%global_disabled = ''
%if not helper.can_action(user):
%global_disabled = 'disabled-link'
%end

<div id="impact-container">
	<div class="impacts-panel col-md-4">
    %# " We look for separate bad and good elements, so we remember last state"
    %last_was_bad = False
    %# " By default we won't expand an impact."
    <script type="text/javascript">
      var  impact_to_expand = -1;
    </script>

		%for imp_id in impacts:
		%   impact = impacts[imp_id]

		%# "When we swich, add a HR to really separate things"
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

		<div class="impact pblink" id="{{imp_id}}">
			<div class="col-sm-11 impact-blade">
				<div class="show-problem" id="show-problem-{{imp_id}}"> </div>

				%for i in range(2, impact.business_impact):
				<div class="criticity-icon-{{i-1}}">
					<img src="static/images/star.png" alt="Star">
				</div>
				%end

				<div class="impact-icon"><img src="{{helper.get_icon_state(impact)}}"> </div>
				<div class="impact-rows">
					<div class="impact-row">
						<span class="impact-name">{{impact.get_name()}}</span> is <span class="impact-state-text">{{impact.state}}</span>
					</div>
					<div class="impact-row">
						<span class="impact-duration">since {{helper.print_duration(impact.last_state_change, just_duration=True, x_elts=2)}}</span>
					</div>
				</div>
			</div>
			<div class="col-sm-1 impact-arrow"> <i class="fa fa-angle-double-right font-white"></i> </div>
		</div>
		%# end of the for imp_id in impacts:
		%end
	</div>

	%# "#######    Now we will output righ panel with all root problems"
	<div class="problems-panels col-md-8">

		%# I init pb_id
		%pb_id = 0

		%for imp_id in impacts:
		%impact = impacts[imp_id]

		<div class="problems-panel panel panel-default" id="problems-{{imp_id}}" style="visibility: hidden; zoom: 1; opacity: 0; ">
			<div class="panel-heading">
          <button id="{{imp_id}}" aria-hidden="true" data-dismiss="modal" class="pblink close pull-right" type="button">×</button>
					%for i in range(2, impact.business_impact):
					<div class="criticity-inpb-icon-{{i-1}}">
						<img src="static/images/star.png" alt="Star">
					</div>
					%end
					<h3 class="state_{{impact.state.lower()}}">  <img style="width: 64px; height:64px" src="{{helper.get_icon_state(impact)}}" />{{impact.state}}: {{impact.get_full_name()}}</h2>
			</div>
			
			<div class="panel-body">
        <div class="row">
          <div class="pull-right">
            <a href="{{!helper.get_link_dest(impact)}}" class="btn btn-default" role="button"><i class="glyphicon glyphicon-search"></i> Details</a>
            <a href="/depgraph/{{impact.get_full_name()}}" class="btn btn-default" role="button" title="Impact map of {{impact.get_full_name()}}"> <i class="fa fa-map-marker"></i> Impact map</a>
          </div>

          %if len(impact.parent_dependencies) > 0:
            <a id="togglelink-{{impact.get_dbg_name()}}" href="javascript:toggleBusinessElt('{{impact.get_dbg_name()}}')"> {{!helper.get_button('Show dependency tree', img='/static/images/expand.png')}}</a>
            <br style="clear: both">
            {{!helper.print_business_rules(datamgr.get_business_parents(impact), source_problems=impact.source_problems)}}
          %end
        </div>

        %##### OK, we print root problem NON ack first
        <hr/>

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

        %for pb in unack_pbs+ack_pbs+guessed:
        %   pb_id += 1
        % l_pb_id += 1

        %if nb_ack_pbs != 0 and l_pb_id == nb_unack_pbs + 1:
        Acknowledged problems:
        %end

        %if len(guessed) != 0 and l_pb_id == nb_unack_pbs + nb_ack_pbs + 1:
        Pure guessed root problems:
        %end

        <div class="problem" id="{{pb_id}}">
          <div class="alert-{{pb.state.lower()}}"> 
            <img src="{{helper.get_icon_state(pb)}}" /> {{!helper.get_link(pb)}} is {{pb.state}} since {{helper.print_duration(pb.last_state_change, just_duration=True, x_elts=2)}}
          </div>
          <div class="problem-actions opacity_hover">
            %disabled_s = ''
            %if not pb.event_handler:
            %disabled_s = 'disabled'
            %end
            <div class="action-fixit"><a class='{{disabled_s}} {{global_disabled}}' href="#" onclick="try_to_fix('{{pb.get_full_name()}}')"> <i class="fa fa-pencil"></i>Try to fix it</a></div>
            
            %if not pb.problem_has_been_acknowledged:
            <div class="action-ack">
              <a class='{{global_disabled}}' href="/forms/acknowledge/{{helper.get_uri_name(pb)}}" data-toggle="modal" data-target="#modal"><i class="fa fa-check"></i> Acknowledge it!</a>
            </div>
            %end
          </div>
        </div>
        %# end for pb in impact.source_problems:
        %end
			</div>
    </div>
	%# end for imp_id in impacts:
	%end
  </div>
</div>