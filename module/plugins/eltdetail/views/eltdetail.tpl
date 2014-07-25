%import time

%# If got no element, bailout
%if not elt:
%rebase layout title='Invalid element name'

Invalid element name

%else:

%helper = app.helper
%datamgr = app.datamgr

%from shinken.macroresolver import MacroResolver

%elt_type = elt.__class__.my_type

%top_right_banner_state = datamgr.get_overall_state()

%# Look for actions if we must show them or not
%global_disabled = ''
%if app.manage_acl and not helper.can_action(user):
  %global_disabled = 'disabled-link'
%end

%if elt_type=='host':
  %# Count hosts services for different states
  %sOK=0
  %sWARNING=0
  %sCRITICAL=0
  %sPENDING=0
  %sUNKNOWN=0

  %for s in elt.services:
    %if s.state == 'OK':
      %sOK=sOK+1
    %elif s.state == 'WARNING':
      %sWARNING=sWARNING+1
    %elif s.state == 'CRITICAL':
      %sCRITICAL=sCRITICAL+1
    %elif s.state == 'PENDING':
      %sPENDING=sPENDING+1
    %else:
      %sUNKNOWN=sUNKNOWN+1
    %end
  %end
%end

%rebase layout title=elt_type.capitalize() + ' / ' + elt.get_full_name(), js=['eltdetail/js/jquery.color.js', 'eltdetail/js/bootstrap-switch.js', 'eltdetail/js/jquery.Jcrop.js', 'eltdetail/js/hide.js', 'eltdetail/js/dollar.js', 'eltdetail/js/gesture.js', 'eltdetail/js/graphs.js', 'eltdetail/js/depgraph.js', 'eltdetail/js/custom_views.js', 'eltdetail/js/screenfull.js', 'eltdetail/js/shinken-gauge.js', 'eltdetail/js/timeline.js', 'timeline/js/timeline.js'], css=['eltdetail/css/bootstrap-switch.css', 'eltdetail/css/eltdetail.css', 'eltdetail/css/hide.css', 'eltdetail/css/gesture.css', 'eltdetail/css/jquery.Jcrop.css', 'eltdetail/css/shinken-gauge.css', 'timeline/css/timeline.css'], user=user, app=app, refresh=True

<script type="text/javascript">
	var elt_name = '{{elt.get_full_name()}}';

	var graphstart={{graphstart}};
	var graphend={{graphend}};

	$(document).ready(function(){
		/* Hide gesture panel */
		$('#gesture_panel').hide();

		// Also hide the button under IE (gesture don't work under it)
		if (navigator.appName == 'Microsoft Internet Explorer'){
			$('#btn_show_gesture').hide();
		}
		
		/* Look at the # part of the URI. If it match a nav name, go for it*/
		if (window.location.hash.length > 0) {
      $('.nav-tabs a[href="' + window.location.hash + '"]').tab('show');
		} else {
			$('.nav-tabs a:first').tab('show');
		}
		
    // When a nav item is selected update the page hash
    $('a[data-toggle="tab"]').on('shown.bs.tab', function (e) {
      window.location.hash = $(e.target).attr('href');
    })
  });
</script>


%# Main variables
%elt_name = elt.host_name if elt_type=='host' else elt.service_description+' on '+elt.host.host_name
%elt_display_name = elt.display_name if elt_type=='host' else elt.service_description

	<!-- First row : tags and actions ... -->
	%if elt.action_url != '' or len(elt.get_host_tags()) != 0 or (elt_type=='host' and len(elt.hostgroups) > 0) or (elt_type=='service' and len(elt.servicegroups) > 0):
	<div class="row">
    <div class="col-sm-12">
      %if (elt_type=='host' and len(elt.hostgroups) > 0) or (elt_type=='service' and len(elt.servicegroups) > 0):
			<div class="btn-group pull-right">
				<button class="btn btn-primary btn-xs"><i class="fa fa-sitemap"></i> Groups</button>
				<button class="btn btn-primary btn-xs dropdown-toggle" data-toggle="dropdown">
					<span class="caret"></span>
				</button>
        <ul class="dropdown-menu pull-right">
          %if elt_type=='host':
            %for hg in elt.hostgroups:
            <li><a href="/hostgroup/{{hg.get_name()}}">{{hg.get_name()}} ({{hg.alias}})</a></li>
            %end
          %else:
            %for sg in elt.servicegroups:
            <li><a href="/servicegroup/{{sg.get_name()}}">{{sg.get_name()}} ({{sg.alias}})</a></li>
            %end
          %end
				</ul>
			</div>
			<div class="pull-right">
				&nbsp;&nbsp;
			</div>
      %end
			%if elt.action_url != '':
			<div class="btn-group pull-right">
				%action_urls = elt.action_url.split('|')
				%if len(action_urls) == 1:
				<button class="btn btn-info btn-xs"><i class="fa fa-external-link"></i> Action</button>
				%else:
				<button class="btn btn-info btn-xs"><i class="icon-cog"></i> Actions</button>
				%end
				<button class="btn btn-info btn-xs dropdown-toggle" data-toggle="dropdown">
					<span class="caret"></span>
				</button>
				<!-- Do not know why but MacroResolver sometimes throws an exception !!! -->
        <ul class="dropdown-menu pull-right">
					%action_urls = elt.action_url.split('|')
					%if len(action_urls) > 0:
						%for triplet in action_urls:
              %try:
                %if len(triplet.split(',')) == 3:
                  %( action_url, icon, alt) = triplet.split(',')
                  <li><a href="{{ MacroResolver().resolve_simple_macros_in_string(action_url, elt.get_data_for_checks()) }}" target=_blank><img src={{icon}} alt="{{alt}}"></a></li>
                %else:
                  %if len(triplet.split(',')) == 1:
                    <li><a id="action-link" href="{{ MacroResolver().resolve_simple_macros_in_string(triplet, elt.get_data_for_checks()) }}" target=_blank>{{ MacroResolver().resolve_simple_macros_in_string(triplet, elt.get_data_for_checks()) }}</a></li>
                  %end
                %end
              %except:
                <li><a id="action-link" href="{{ triplet }}" target=_blank>{{ triplet }}</a></li>
              %end
						%end
					%end
				</ul>
			</div>
			<div class="pull-right">
				&nbsp;&nbsp;
			</div>
			%end
      %if len(elt.get_host_tags()) != 0:
			<div id="tags" class="btn-group pull-right">
				<script>
					%for t in sorted(elt.get_host_tags()):
					var a = $('<a href="/all?search=htag:{{t}}"/>').appendTo($('#tags'));
					$('<img />')
            .attr({ 'src': '/static/images/tags/{{t.lower()}}.png', 'alt': '{{t.lower()}}', 'title': 'Tag: {{t.lower()}}' })
            .load(function() {
            })
            .error(function() {
              $(this).hide();
              $("<span/>").attr({ 'class': 'btn btn-default btn-xs'}).append('{{t}}').appendTo(a);
            })
            .appendTo(a);
					var span = $("<span/>").append('&nbsp;').appendTo($('#tags'));
					%end
				</script>
			</div>
			%end
			<div class="clearfix"></div>
    </div>
	</div>
	%end

	<!-- Second row : host/service overview ... -->
	<div class="row" style="padding: 5px;">
    <div class="panel-group" id="Overview">
      <div class="panel panel-default">
        <div class="panel-heading">
          <div class="panel-heading fitted-header cursor" data-toggle="collapse" data-parent="#Overview" href="#collapseOne">
            <h4 class="panel-title">Overview {{elt_name}}
              %if elt.display_name or elt.alias:
                %if elt.display_name:
                  ({{elt.display_name}})
                %else:
                  ({{elt.alias}})
                %end
              %end
              %for i in range(0, elt.business_impact-2):
              <img alt="icon state" src="/static/images/star.png">
              %end
            </h4>
          </div>
        </div>
        
        <div id="collapseOne" class="panel-collapse collapse">
          <div class="row">
            %if elt_type=='host':
              <dl class="col-lg-4 dl-horizontal">
                <dt>Alias:</dt>
                <dd>{{elt.alias}}</dd>

                <dt>Address:</dt>
                <dd>{{elt.address}}</dd>

                <dt>Importance:</dt>
                <dd>{{!helper.get_business_impact_text(elt)}}</dd>
              </dl>
              
              <dl class="col-lg-4 dl-horizontal">
                <dt>Parents:</dt>
                %if len(elt.parents) > 0:
                <dd>
                %for parent in elt.parents:
                <a href="/host/{{parent.get_name()}}" class="link">{{parent.alias}} ({{parent.get_name()}})</a>
                %end
                </dd>
                %else:
                <dd>(none)</dd>
                %end


                <dt>Member of:</dt>
                %if len(elt.hostgroups) > 0:
                <dd>
                %for hg in elt.hostgroups:
                <a href="/hostgroup/{{hg.get_name()}}" class="link">{{hg.alias}} ({{hg.get_name()}})</a>
                %end
                </dd>
                %else:
                <dd>(none)</dd>
                %end

                <dt>Notes:</dt>
                %if elt.notes != '' and elt.notes_url != '':
                <dd><a href="{{elt.notes_url}}" target=_blank>{{elt.notes}}</a></dd>
                %elif elt.notes == '' and elt.notes_url != '':
                <dd><a href="{{elt.notes_url}}" target=_blank>{{elt.notes_url}}</a></dd>
                %elif elt.notes != '' and elt.notes_url == '':
                <dd>{{elt.notes}}</dd>
                %else:
                <dd>(none)</dd>
                %end
              </dl>
            %else:
              <dl class="col-lg-4 dl-horizontal">
                <dt>Host:</dt>
                <dd><a href="/host/{{elt.host.host_name}}" class="link">{{elt.host.host_name}}
                %if elt.host.display_name or elt.host.alias:
                  %if elt.host.display_name:
                    ({{elt.host.display_name}})
                  %else:
                    ({{elt.host.alias}})
                  %end
                %end
                </a></dd>

                <dt>Importance:</dt>
                <dd>{{!helper.get_business_impact_text(elt)}}</dd>
              </dl>
              
              <dl class="col-lg-4 dl-horizontal">
                <dt>Member of:</dt>
                %if len(elt.servicegroups) > 0:
                <dd>
                %for sg in elt.servicegroups:
                <a href="/servicegroup/{{sg.get_name()}}" class="link">{{sg.alias}} ({{sg.get_name()}})</a>
                %end
                </dd>
                %else:
                <dd>(none)</dd>
                %end

                <dt>Notes: </dt>
                %if elt.notes != '' and elt.notes_url != '':
                <dd><a href="{{elt.notes_url}}" target=_blank>{{elt.notes}}</a></dd>
                %elif elt.notes == '' and elt.notes_url != '':
                <dd><a href="{{elt.notes_url}}" target=_blank>{{elt.notes_url}}</a></dd>
                %elif elt.notes != '' and elt.notes_url == '':
                <dd>{{elt.notes}}</dd>
                %else:
                <dd>(none)</dd>
                %end
              </dl>
            %end
              
            %if len(elt.customs) > 0:
            <dl class="col-lg-4 dl-horizontal">
              %for p in sorted(elt.customs):
                <dt>{{p}}</dt>
                <dd>{{elt.customs[p]}}</dd>
              %end
            </dl>
            %end
          </div>

          %if elt_type=='host':
          <div class="row" style="padding: 3px; border-top: 1px dotted #ccc;" >
            <ul class="list-inline list-unstyled">
              <li class="col-lg-1"></li>
              <li class="col-lg-2"> <span class="fa-stack font-ok"> <i class="fa fa-circle fa-stack-2x"></i> <i class="glyphicon glyphicon-ok fa-stack-1x fa-inverse"></i></span> <span class="num">{{sOK}}</span> Ok</li>
              <li class="col-lg-2"> <span class="fa-stack font-warning"> <i class="fa fa-circle fa-stack-2x"></i> <i class="fa fa-exclamation fa-stack-1x fa-inverse"></i></span> <span class="num">{{sWARNING}}</span> Warning</li>
              <li class="col-lg-2"> <span class="fa-stack font-critical"> <i class="fa fa-circle fa-stack-2x"></i> <i class="fa fa-arrow-down fa-stack-1x fa-inverse"></i></span> <span class="num">{{sCRITICAL}}</span> Critical</li>
              <li class="col-lg-2"> <span class="fa-stack font-pending"> <i class="fa fa-circle fa-stack-2x"></i> <i class="fa fa-arrow-right fa-stack-1x fa-inverse"></i></span> <span class="num">{{sPENDING}}</span> Pending</li>
              <li class="col-lg-2"> <span class="fa-stack font-unknown"> <i class="fa fa-circle fa-stack-2x"></i> <i class="fa fa-question fa-stack-1x fa-inverse"></i></span> <span class="num">{{sUNKNOWN}}</span> Unknown</li>
              <li class="col-lg-1"></li>
            </ul>
          </div>
          %end
        </div>
      </div>
    </div>
	</div>

	<!-- Third row : business impact alerting ... -->
  %if elt.is_problem and elt.business_impact > 2 and not elt.problem_has_been_acknowledged:
	<div class="row" style="padding: 5px;">
    <div class="col-lg-2 hidden-md"></div>
    <div class="col-lg-8 col-md-12">
      <div style="padding: 10px 35px 5px 15px;" class="alert alert-critical no-bottommargin pulsate row">
        <div class="col-lg-2 font-white" style="font-size: 30px; padding-top: 0px;"> <i class="fa fa-bolt"></i> </div>
        <p class="col-lg-10 font-white">This element has got an important impact on your business, please <b>fix it</b> or <b>acknowledge it</b>.</p>
      </div>
    </div>
    <div class="col-lg-2 hidden-md"></div>
  </div>
  %end
  
	<!-- Fourth row : host/service -->
	<div class="row" style="padding: 5px;">
		<div class="col-md-6 col-lg-3 tabbable verticaltabs-container">
			<ul class="nav nav-tabs">
				%if params['tab_information']=='yes':
				<li class="active"><a href="#information" data-toggle="tab">Information</a></li>
				%end
				%if params['tab_additional']=='yes':
				<li><a href="#additional" data-toggle="tab">Additional information</a></li>
				%end
				%if params['tab_commands']=='yes' and app.manage_acl and helper.can_action(user):
				<li><a href="#commands" data-toggle="tab">Commands</a></li>
				%end
				%if params['tab_gesture']=='yes':
				<li><a href="#gesture" data-toggle="tab">Gesture</a></li>
				%end
				%if params['tab_configuration']=='yes':
				<li><a href="#configuration" data-toggle="tab">Configuration</a></li>
				%end
			</ul>

			<div class="tab-content">
				%if params['tab_information']=='yes':
				<div class="tab-pane fade in active" id="information">
					<h4>{{elt_type.capitalize()}} information:</h4>

					<table class="table-condensed col-sm-12" style="table-layout: fixed; word-wrap: break-word;">
						<thead>
							<tr>
								<th style="width: 40%"></th>
								<th style="width: 60%"></th>
							</tr>
						</thead>
						<tbody>
							<tr>
								<td><strong>Status:</strong></td>
								<td>
									<button class="col-lg-12 btn alert-small alert-{{elt.state.lower()}} quickinforight" data-original-title="since {{helper.print_duration(elt.last_state_change, just_duration=True, x_elts=2)}}">{{elt.state}}</button>
								</td>
							</tr>
							<tr>
								<td><strong>Flapping:</strong></td>
								<td>
									<button class="col-lg-12 btn alert-small trim-{{helper.yes_no(elt.is_flapping)}} quickinforight" data-original-title="{{helper.print_float(elt.percent_state_change)}}% state change">{{helper.yes_no(elt.is_flapping)}}</button>
								</td>
							</tr>
							<tr>
								<td><strong>Downtime:</strong></td>
								<td>
									<button class="col-lg-12 btn alert-small trim-{{helper.yes_no(elt.in_scheduled_downtime)}}" type="button">{{helper.yes_no(elt.in_scheduled_downtime)}}</button>
								</td>
							</tr>
							
							<tr>
								<td colspan="2"><hr/></td>
							</tr>
							
							<tr>
								<td><strong>Last Check:</strong></td>
								<td><span class="quickinfo" data-original-title='Last check was at {{time.asctime(time.localtime(elt.last_chk))}}'>was {{helper.print_duration(elt.last_chk)}}</span></td>
							</tr>
							<tr>
								<td><strong></strong></td>
								<td class="truncate_output"><em>
								%if len(elt.output) > app.max_output_length:
									%if app.allow_html_output:
										<div class='check-output check-output-{{elt.state.lower()}}' rel="tooltip" data-original-title="{{elt.output}}"> {{!helper.strip_html_output(elt.output[:app.max_output_length])}}</div>
									%else:
										<div class='check-output check-output-{{elt.state.lower()}}' rel="tooltip" data-original-title="{{elt.output}}"> {{elt.output[:app.max_output_length]}}</div>
									%end
								%else:
									%if app.allow_html_output:
										<div class='check-output check-output-{{elt.state.lower()}}'> {{!helper.strip_html_output(elt.output)}}</div>
									%else:
										<div class='check-output check-output-{{elt.state.lower()}}'> {{elt.output}} </div>
									%end
								%end
								</em></td>
							</tr>
							
							<tr>
								<td colspan="2"><hr/></td>
							</tr>
							
							<tr>
								<td><strong>Last State Change:</strong></td>
								<td>{{time.asctime(time.localtime(elt.last_state_change))}}</td>
							</tr>
							<tr>										
								<td><strong>Current Attempt:</strong></td>
								<td>{{elt.attempt}}/{{elt.max_check_attempts}} ({{elt.state_type}} state)</td>
							</tr>
							<tr>		
								<td><strong>Next Active Check:</strong></td>
								<td><span class="quickinfo" data-original-title='Next active check at {{time.asctime(time.localtime(elt.next_chk))}}'>{{helper.print_duration(elt.next_chk)}}</span></td>
							</tr>
						</tbody>
					</table>
				</div>
				%end

				%if params['tab_additional']=='yes':
				<div class="tab-pane fade" id="additional">
					<h4>Additional Informations</h4>
					
					<table class="table-condensed col-sm-12" style="table-layout: fixed; word-wrap: break-word;">
						<thead>
							<tr>
								<th style="width: 40%"></th>
								<th style="width: 60%"></th>
							</tr>
						</thead>
						<tbody>
							<tr>
								<td><strong>Check command:</strong></td>
								<td>
                %try:
                  {{ MacroResolver().resolve_simple_macros_in_string(elt.get_check_command(), elt.get_data_for_checks()) }}
                %except:
                  {{elt.get_check_command()}}
                %end
                </td>
							</tr>
							<tr>
								<td><strong>Check output:</strong></td>
								<td class="truncate_output">
								%if len(elt.output) > app.max_output_length:
									%if app.allow_html_output:
										<div class='check-output check-output-{{elt.state.lower()}}' rel="tooltip" data-original-title="{{elt.output}}"> {{!helper.strip_html_output(elt.output[:app.max_output_length])}}</div>
									%else:
										<div class='check-output check-output-{{elt.state.lower()}}' rel="tooltip" data-original-title="{{elt.output}}"> {{elt.output[:app.max_output_length]}}</div>
									%end
								%else:
									%if app.allow_html_output:
										<div class='check-output check-output-{{elt.state.lower()}}'> {{!helper.strip_html_output(elt.output)}}</div>
									%else:
										<div class='check-output check-output-{{elt.state.lower()}}'> {{elt.output}} </div>
									%end
								%end
								</td>
							</tr>
              %if elt.long_output:
							<tr>
								<td><strong>Long output:</strong></td>
								<td class="truncate_output">
                  <div class='check-output check-output-{{elt.state.lower()}}'> {{elt.long_output}} </div>
								</td>
							</tr>
              %end
							<tr>
								<td><strong>Performance data:</strong></td>
								<td class="truncate_perf">
									{{elt.perf_data if len(elt.perf_data) > 0 else '(none)'}}
								</td>
							</tr>
							
							<tr>
								<td colspan="2"><hr/></td>
							</tr>
							
							<tr>
								<td><strong>Check latency / duration:</strong></td>
								<td>
									{{'%.2f' % elt.latency}} / {{'%.2f' % elt.execution_time}} seconds
								</td>
							</tr>
							<tr>
								<td><strong>Last notification:</strong></td>
								<td>
									{{helper.print_date(elt.last_notification)}} (notification {{elt.current_notification_number}})
								</td>
							</tr>
              %if elt.notification_interval:
							<tr>
								<td><strong>Notification interval:</strong></td>
								<td>
									{{elt.notification_interval}} mn
								</td>
							</tr>
              %end
              %if elt.notification_period:
              <tr>
								<td><strong>Notification period:</strong></td>
								<td>
									{{elt.notification_period.get_name()}}
								</td>
							</tr>
              %end
						</tbody>
					</table>
				</div>
				<script type="text/javascript">
					$(document).ready(function() {
						$('.truncate_output').jTruncate({
							length: 200,
							minTrail: 0,
							moreText: "[see all]",
							lessText: "[hide extra]",
							ellipsisText: " <strong>(...)</strong>",
							moreAni: "fast",
							lessAni: 2000
						});

						$('.truncate_perf').jTruncate({
							length: 100,
							minTrail: 0,
							moreText: "[see all]",
							lessText: "[hide extra]",
							ellipsisText: " <strong>(...)</strong>",
							moreAni: "fast",
							lessAni: 2000
						});
					});
				</script>
				%end

				%if params['tab_commands']=='yes' and app.manage_acl and helper.can_action(user):
				<div class="tab-pane fade" id="commands">
					<h4>Commands:</h4>

					<table class="table-condensed col-sm-12" style="table-layout: fixed; word-wrap: break-word;">
						<thead>
							<tr>
								<th style="width: 60%"></th>
								<th style="width: 40%"></th>
							</tr>
						</thead>
						<tbody>
							<tr>
								<td><strong>Try to fix:</strong></td>
								<td>
									%disabled_s = ''
									%if not elt.event_handler:
									%disabled_s = 'disabled'
									%end
									<button type="button" id="bt-event-handler" class="col-lg-12 {{disabled_s}} {{global_disabled}} btn btn-primary btn-sm">Try to fix</button>
									<script>
										$('#bt-event-handler').click(function () {
											try_to_fix('{{elt.get_full_name()}}');
										});
									</script>
								</td>
							</tr>
							
							<tr>
								<td><strong>Acknowledge:</strong></td>
								<td>
									%disabled_s = ''
									%if elt.problem_has_been_acknowledged:
									%disabled_s = 'disabled'
									%end
									<button type="button" id="bt-acknowledge" class="col-lg-12 {{disabled_s}} {{global_disabled}} btn btn-primary btn-sm">Acknowledge</button>
									<script>
										$('#bt-acknowledge').click(function () {
											// href="/forms/acknowledge/{{helper.get_uri_name(elt)}}"
										});
									</script>
								</td>
							</tr>
							
							<tr>
								<td><strong>Recheck now:</strong></td>
								<td>
									<button type="button" id="bt-recheck" class="col-lg-12 {{disabled_s}} {{global_disabled}} btn btn-primary btn-sm">Recheck</button>
									<script>
										$('#bt-recheck').click(function () {
											recheck_now('{{elt.get_full_name()}}');
										});
									</script>
								</td>
							</tr>
							
							<tr>
								<td><strong>Check result:</strong></td>
								<td>
									<button type="button" id="bt-check-result" class="col-lg-12 {{disabled_s}} {{global_disabled}} btn btn-primary btn-sm">Submit</button>
									<script>
										$('#bt-check-result').click(function () {
											// href="/forms/submit_check/{{helper.get_uri_name(elt)}}"
										});
									</script>
								</td>
							</tr>
							
							<tr>
								<td><strong>Custom notification:</strong></td>
								<td>
									%disabled_s = 'disabled'
									<button type="button" id="bt-custom-notification" class="col-lg-12 {{disabled_s}} {{global_disabled}} btn btn-primary btn-sm">Submit</button>
									<script>
										$('#bt-custom-notification').click(function () {
										});
									</script>
								</td>
							</tr>
							
							<tr>
								<td><strong>Schedule downtime:</strong></td>
								<td>
									%disabled_s = ''
									<button type="button" id="bt-schedule-downtime" class="col-lg-12 {{disabled_s}} {{global_disabled}} btn btn-primary btn-sm">Submit</button>
									<script>
										$('#bt-schedule-downtime').click(function () {
											// href="/forms/downtime/{{helper.get_uri_name(elt)}}"
										});
									</script>
								</td>
							</tr>
							
							<!--
              <tr>
								<td><strong>Edit host:</strong></td>
								<td>
									%disabled_s = 'disabled'
									<button type="button" id="bt-edit-host" class="col-lg-12 {{disabled_s}} {{global_disabled}} btn btn-primary btn-sm">Edit</button>
									<script>
										$('#bt-edit-host').click(function () {
										});
									</script>
								</td>
							</tr>
              -->
							
							<tr>
								<td colspan="2"><hr/></td>
							</tr>
							
							<tr>
								<td><strong>Active checks:</strong></td>
								<td>
									<input type="checkbox" id="ck-active-checks" {{'checked' if elt.active_checks_enabled else ''}} {{'readonly' if global_disabled != '' else ''}}>
									<script>
										$('#ck-active-checks').bootstrapSwitch();
										$('#ck-active-checks').on('switch-change', function (e, data) {
											toggle_active_checks("{{elt.get_full_name()}}", !data.value);
										});
									</script>
								</td>
							</tr>
							<tr>
								<td><strong>Passive checks:</strong></td>
								<td>
									<input type="checkbox" id="ck-passive-checks" {{'checked' if elt.passive_checks_enabled else ''}} {{'readonly' if global_disabled != '' else ''}}>
									<script>
										$('#ck-passive-checks').bootstrapSwitch();
										$('#ck-passive-checks').on('switch-change', function (e, data) {
											toggle_passive_checks("{{elt.get_full_name()}}", !data.value);
										});
									</script>
								</td>
							</tr>
							<tr>
								<td><strong>Check freshness:</strong></td>
								<td>
									<input type="checkbox" id="ck-check-freshness" {{'checked' if elt.check_freshness else ''}} {{'readonly' if global_disabled != '' else ''}}>
									<script>
										$('#ck-check-freshness').bootstrapSwitch();
										$('#ck-check-freshness').on('switch-change', function (e, data) {
											toggle_freshness_check("{{elt.get_full_name()}}", !data.value);
										});
									</script>
								</td>
							</tr>
							
							<tr>
								<td><strong>Notifications:</strong></td>
								<td>
									<input type="checkbox" id="ck-notifications" {{'checked' if elt.notifications_enabled else ''}} {{'readonly' if global_disabled != '' else ''}}>
									<script>
										$('#ck-notifications').bootstrapSwitch();
										$('#ck-notifications').on('switch-change', function (e, data) {
											toggle_notifications("{{elt.get_full_name()}}", !data.value);
										});
									</script>
								</td>
							</tr>
							%if elt.event_handler:
							<tr>
								<td><strong>Event handler:</strong></td>
								<td>
									<input type="checkbox" id="ck-event-handler" {{'checked' if elt.event_handler_enabled else ''}} {{'readonly' if global_disabled != '' else ''}}>
									<script>
										$('#ck-event-handler').bootstrapSwitch();
										$('#ck-event-handler').on('switch-change', function (e, data) {
											toggle_event_handlers("{{elt.get_full_name()}}", !data.value);
										});
									</script>
								</td>
							</tr>
							%end
							<tr>
								<td><strong>Flap detection:</strong></td>
								<td>
									<input type="checkbox" id="ck-flap-detection" {{'checked' if elt.flap_detection_enabled else ''}} {{'readonly' if global_disabled != '' else ''}}>
									<script>
										$('#ck-flap-detection').bootstrapSwitch();
										$('#ck-flap-detection').on('switch-change', function (e, data) {
											toggle_flap_detection("{{elt.get_full_name()}}", !data.value);
										});
									</script>
								</td>
							</tr>
						</tbody>
					</table>
				</div>
				%end

				%if params['tab_gesture']=='yes':
				<div class="tab-pane fade" id="gesture">
					<h4>Gesture</h4>
					<canvas id="gestureCanvas" height="200" class="" style="border: 1px solid black;"></canvas>
					<div class="gesture_button">
						<img title="By keeping a left click pressed and drawing a check, you will launch an acknowledgement." alt="gesture acknowledge" src="/static/eltdetail/images/gesture-check.png"/> Acknowledge
					</div>
					<div class="gesture_button">
						<img title="By keeping a left click pressed and drawing a circle, you will launch an recheck." alt="gesture recheck" src="/static/eltdetail/images/gesture-circle.png"/> Recheck
					</div>
					<div class="gesture_button">
						<img title="By keeping a left click pressed and drawing a check, you will launch a try to fix command." alt="gesture fix" src="/static/eltdetail/images/gesture-zigzag.png"/> Fix
					</div>
				</div>
				%end

				%if params['tab_configuration']=='yes':
				<div class="tab-pane fade" id="configuration">
					<h4>{{elt_type.capitalize()}} configuration:</h4>

          <table class="table-condensed col-sm-12 table-bordered" style="table-layout: fixed; word-wrap: break-word;">
						<colgroup>
							<col style="width: 70%"></col>
							<col style="width: 30%"></col>
						</colgroup>
						<tbody>
							<tr>
								<td><strong>Active checks:</strong></td>
								<td><span class="{{'glyphicon glyphicon-ok font-green' if elt.active_checks_enabled else 'glyphicon glyphicon-remove font-red'}}"></span></td>
							</tr>
							<tr>
								<td><strong>Passive checks:</strong></td>
								<td><i class="{{'glyphicon glyphicon-ok font-green' if elt.passive_checks_enabled else 'glyphicon glyphicon-remove font-red'}}"></span></td>
							</tr>
							
							%if (elt.passive_checks_enabled):
							<tr>
								<td><strong>Freshness check:</strong></td>
								<td><span class="{{'glyphicon glyphicon-ok font-green' if elt.check_freshness else 'glyphicon glyphicon-remove font-red'}}"></span></td>
							</tr>
							%if (elt.check_freshness):
							<tr>
								<td><strong>Freshness threshold:</strong></td>
								<td>{{elt.freshness_threshold}}</td>
							</tr>
							%end
							%end
							
							<tr>
								<td><strong>Notifications:</strong></td>
								<td><span class="{{'glyphicon glyphicon-ok font-green' if elt.notifications_enabled else 'glyphicon glyphicon-remove font-red'}}"></span></td>
							</tr>
							<tr>
								<td><strong>Event handlers:</strong></td>
								<td><span class="{{'glyphicon glyphicon-ok font-green' if elt.event_handler_enabled else 'glyphicon glyphicon-remove font-red'}}"></span></td>
							</tr>
							<tr>
								<td><strong>Flap detection:</strong></td>
								<td><span class="{{'glyphicon glyphicon-ok font-green' if elt.flap_detection_enabled else 'glyphicon glyphicon-remove font-red'}}"></span></td>
							</tr>
						</tbody>
					</table>
				</div>
				%end
			</div>
		</div>

		<!-- Detail info box start -->
		<div class="col-md-6 col-lg-8 tabbable">
			<ul class="nav nav-tabs">
				%_go_active = 'active'
				%if params['tab_custom_views']=='yes':
				%for cvname in elt.custom_views:
				<li class="{{_go_active}} cv_pane" data-cv-name="{{cvname}}" data-elt-name='{{elt.get_full_name()}}' id='tab-cv-{{cvname}}'><a class='link_to_tab' href="#cv{{cvname}}" data-toggle="tab">{{cvname.capitalize()}}</a></li>
					%_go_active = ''
				%_go_active = ''
				%end
				%end

				%if params['tab_impacts']=='yes':
				<li class="{{_go_active}}"><a class='link_to_tab' href="#impacts" data-toggle="tab">Services</a></li>
				%end
				%if params['tab_comments']=='yes':
			    <li><a class='link_to_tab' href="#comments" data-toggle="tab">Comments</a></li>
				%end
				%if params['tab_downtimes']=='yes':
				<li><a class='link_to_tab' href="#downtimes" data-toggle="tab">Downtimes</a></li>
				%end
				%if params['tab_timeline']=='yes':
				<li class='timeline_pane'><a class='link_to_tab' href="#timeline" data-toggle="tab" id='tab_to_timeline'>Timeline</a></li>
				%end
				%if params['tab_graphs']=='yes':
				<li><a class='link_to_tab' href="#graphs" data-toggle="tab" id='tab_to_graphs'>Graphs</a></li>
				%end
				%if params['tab_depgraph']=='yes':
				<li><a class='link_to_tab' href="#depgraph" data-toggle="tab" id='tab_to_depgraph'>Impact graph</a></li>
				%end
			</ul>
			
			<div class="tab-content">
				<!-- Tab custom views -->
				%if params['tab_custom_views']=='yes':
				%_go_active = 'active'
				%_go_fadein = 'in'
				%for cvname in elt.custom_views:
				<div class="tab-pane fade {{_go_active}} {{_go_fadein}}" data-cv-name="{{cvname}}" data-elt-name='{{elt.get_full_name()}}' id="cv{{cvname}}">
					Cannot load the pane {{cvname}}.
				</div>
				%_go_active = ''
				%_go_fadein = ''
				%end
				%end
				<!-- Tab custom views end -->

				<!-- Tab Summary Start-->
				%if params['tab_impacts']=='yes':
				<div class="tab-pane fade {{_go_active}} {{_go_fadein}}" id="impacts">
					<div class='row-fluid well col-lg-12'>
					
						<div class="row-fluid">
							<div class="col-lg-12">
								<!-- Show our father dependencies if we got some -->
								%if len(elt.parent_dependencies) > 0:
								<h4>Root cause:</h4>
								<a id="togglelink-{{elt.get_dbg_name()}}" href="javascript:toggleBusinessElt('{{elt.get_dbg_name()}}')"> {{!helper.get_button('Show dependency tree', img='/static/images/expand.png')}}</a>
								<div class="clear"></div>
								{{!helper.print_business_rules(datamgr.get_business_parents(elt), source_problems=elt.source_problems)}}
								%end

								<!-- If we are an host and not a problem, show our services -->
								%if elt_type=='host' and not elt.is_problem:
								%if len(elt.services) > 0:
								%if len(elt.parent_dependencies) > 0:
								<!-- Only if we displayed parent's dependencies ... -->
								<hr/>
								%end
								<h4>My services:</h4>
								<div class="host-services">
									<div class='pull-left'>
										%_html_id = helper.get_html_id(elt)
										{{!helper.print_aggregation_tree(helper.get_host_service_aggregation_tree(elt), _html_id)}}
									</div>
								</div>
								%elif len(elt.parent_dependencies) == 0:
								<div class="alert alert-info">
									<p class="font-blue">No services available</p>
								</div>
								%end
								%end #of the only host part

								<!-- If we are a root problem and got real impacts, show them! -->
								%if elt.is_problem and len(elt.impacts) != 0:
								%if len(elt.parent_dependencies) > 0:
								<!-- Only if we displayed parent's dependencies ... -->
								<hr/>
								%end
								<h4>My impacts:</h4>
								<div class='host-services'>
									%max_impacts_displayed = int(params['cfg_nb_impacts'])
									%nb = 0
									%for i in helper.get_impacts_sorted(elt):
										%nb += 1
										%if nb == max_impacts_displayed+1:
										<div class="pull-right" id="hidden_impacts_or_services_button">
											<a href="javascript:show_hidden_impacts_or_services()"> {{!helper.get_button('Show all impacts', img='/static/images/expand.png')}}</a>
										</div>
										%end
										<div class="service {{"hidden_impacts_services" if nb > max_impacts_displayed else ""}}">
											<div>
												<img style="width:16px; height:16px" alt="icon state" src="{{helper.get_icon_state(i)}}">
												<span class='alert-small alert-{{i.state.lower()}}' style="font-size:110%">{{i.state}}</span> for <span style="font-size:110%">{{!helper.get_link(i, short=True)}}</span> since {{helper.print_duration(i.last_state_change, just_duration=True, x_elts=2)}}
												%for i in range(0, i.business_impact-2):
												<img alt="icon state" src="/static/images/star.png">
												%end
											</div>
										</div>
									%end
								</div>
								%# end of the 'is problem' if
								%end
							</div>
						</div>
					</div>
				</div>
				%end
				<!-- Tab Summary End-->

				<!-- Tab Comments Start -->
				%if params['tab_comments']=='yes':
				<div class="tab-pane fade" id="comments">
					<div class='row-fluid well col-lg-12'>
						<div id="log_container" class="row-fluid">
							%if len(elt.comments) > 0:
							<table class="table table-condensed table-hover">
								<thead>
									<tr>
										<th class="col-lg-2">Author</th>
										<th class="col-lg-6">Comment</th>
										<th class="col-lg-3">Date</th>
										<th class="col-lg-1"></th>
									</tr>
								</thead>
								<tbody>
								%for c in elt.comments:
									<tr>
										<td><strong>{{c.author}}</strong></td>
										<td><strong>{{c.comment}}</strong></td>
										<td><strong>{{helper.print_date(c.entry_time)}} - {{helper.print_date(c.expire_time)}}</strong></td>
										<td><a class="fa fa-trash-o {{global_disabled}} font-red" href="javascript:delete_comment('{{elt.get_full_name()}}', {{c.id}})"></a></td>
									</tr>
								%end
								</tbody>
							</table>

							%else:
							<div class="alert alert-info">
								<p class="font-blue">No comments available</p>
							</div>
							%end
						</div>
						
						<button type="button" class="btn btn-primary btn-sm" href="/forms/comment/{{helper.get_uri_name(elt)}}" data-toggle="modal" data-target="#modal"><i class="fa fa-plus"></i> Add a comment</button>
						<button type="button" class="btn btn-primary btn-sm" href="/forms/comment_delete/{{helper.get_uri_name(elt)}}" data-toggle="modal" data-target="#modal"><i class="fa fa-minus"></i> Delete all comments</button>
					</div>
				</div>
				%end
				<!-- Tab Comments End -->

				<!-- Tab Downtimes Start -->
				%if params['tab_downtimes']=='yes':
				<div class="tab-pane fade" id="downtimes">
					<div class='row-fluid well col-lg-12'>
						<div id="log_container" class="row-fluid">
							%if len(elt.downtimes) > 0:
							<table class="table table-condensed table-hover">
							  <thead>
								<tr>
								  <th class="col-lg-2"></th>
								  <th class="col-lg-1"></th>
								  <th class="col-lg-5"></th>
								  <th class="col-lg-5"></th>
								  <th class="col-lg-1"></th>
								</tr>
							  </thead>
							  <tbody>
								%for dt in elt.downtimes:
								<tr>
								  <td><strong>{{dt.author}}</strong></td>
								  <td><span class="label pull-right">Downtime</span></td>
								  <td><strong>{{dt.comment}}</strong></td>
								  <td><strong>{{helper.print_date(dt.start_time)}} - {{helper.print_date(dt.end_time)}}</strong></td>
								  <td><a class="fa fa-trash-o {{global_disabled}} font-red" href="javascript:delete_downtime('{{elt.get_full_name()}}', {{dt.id}})"></a></td>
								</tr>
								%end
							  </tbody>
							</table>

							%else:
							<div class="alert alert-info">
								<p class="font-blue">No downtimes available</p>
							</div>
							%end
						</div>
						
						<button type="button" class="btn btn-primary btn-sm" href="/forms/downtime/{{helper.get_uri_name(elt)}}" data-toggle="modal" data-target="#modal" class="btn btn-primary"><i class="fa fa-plus"></i> Add a downtime</button>
						<button type="button" class="btn btn-primary btn-sm" href="/forms/downtime_delete/{{helper.get_uri_name(elt)}}" data-toggle="modal" data-target="#modal" class="btn btn-primary"><i class="fa fa-minus"></i> Delete all downtimes</button>
					</div>
				</div>
				%end
				<!-- Tab Downtimes End -->

				<!-- Tab Timeline Start -->
				%if params['tab_timeline']=='yes':
				<div class="tab-pane fade" id="timeline">
					<div class='row-fluid well col-lg-12'>
					<div class='row-fluid well col-lg-12 jcrop'>
						<div id="inner_timeline" data-elt-name='{{elt.get_full_name()}}'>
							<span class="alert alert-error">Cannot load the timeline graph.</span>
						</div>
					</div>
					</div>
				</div>
				%end
				<!-- Tab Graph End -->

				<!-- Tab Graph Start -->
				%if params['tab_graphs']=='yes':
				<div class="tab-pane fade" id="graphs">
          %# Set source as '' or module ui-graphite will try to fetch templates from default 'detail'
					%uris = app.get_graph_uris(elt, graphstart, graphend, '')
					%if len(uris) == 0:
					<div class="alert alert-info">
					    <div class="font-blue"><strong>Oh snap!</strong> No graphs available!</div>
					</div>
					<script language="javascript">
						$('#tab_to_graphs').hide();
					</script>
					%else:
					<!-- <h4>Graphs</h4> -->
					<div class='row-fluid well col-lg-12'>
						<!-- Get the uris for the 5 standard time ranges in advance	 -->
						%now = int(time.time())
						%fourhours = now - 3600*4
						%lastday =   now - 86400
						%lastweek =  now - 86400*7
						%lastmonth = now - 86400*31
						%lastyear =  now - 86400*365

						%# Let's get all the uris at once.
            %# Set source as '' or module ui-graphite will trye to fetch from default 'detail'
						%uris_4h = app.get_graph_uris(elt, fourhours, now, '')
						%uris_1d = app.get_graph_uris(elt, lastday, now, '')
						%uris_1w = app.get_graph_uris(elt, lastweek, now, '')
						%uris_1m = app.get_graph_uris(elt, lastmonth, now, '')
						%uris_1y = app.get_graph_uris(elt, lastyear, now, '')

						<!-- Use of javascript to change the content of a div!-->
						<div class='col-lg-2 cursor'><a onclick="setHTML(html_4h,{{fourhours}});" > 4 hours</a></div>
						<div class='col-lg-2 cursor'><a onclick="setHTML(html_1d,{{lastday}});" > 1 day</a></div>
						<div class='col-lg-2 cursor'><a onclick="setHTML(html_1w,{{lastweek}});" > 1 week</a></div>
						<div class='col-lg-2 cursor'><a onclick="setHTML(html_1m,{{lastmonth}});" > 1 month</a></div>
						<div class='col-lg-2 cursor'><a onclick="setHTML(html_1y,{{lastyear}});" > 1 year</a></div>
					</div>

					<script language="javascript">
					function setHTML(html,start) {
						<!-- change the content of the div --!>
						document.getElementById("real_graphs").innerHTML=html;

						<!-- and call the jcrop javascript --!>
						$('.jcropelt').Jcrop({
							onSelect: update_coords,
							onChange: update_coords
						});
						graphstart=start;
						get_range();
					}

					<!-- let's create the html content for each time range --!>
					<!-- This is quite ugly here. I do the same thing 4 times --!->
					<!-- someone said "function" ? You're right.--!>
					<!-- but the mix between python and javascript is not a easy thing for me --!>
					html_4h='<p>';
					html_1d='<p>';
					html_1w='<p>';
					html_1m='<p>';
					html_1y='<p>';

					%for g in uris_4h:
					%(img_src, link) = app.get_graph_img_src( g['img_src'], g['link'])
					var img_src="{{img_src}}";
					html_4h = html_4h + '<img src="'+ img_src.replace("'","\'") +'" class="jcropelt"/>';
					html_4h = html_4h + '<a href="{{link}}" class="btn"><i class="fa fa-plus"></i> Show more</a>';
					html_4h = html_4h + '<a href="javascript:graph_zoom(\'/{{elt_type}}/{{elt.get_full_name()}}?\')" class="btn"><i class="icon-zoom-in"></i> Zoom</a>';
					html_4h = html_4h + '<br>';
					%end
					html_4h=html_4h+'</p>';

					%for g in uris_1d:
					%(img_src, link) = app.get_graph_img_src( g['img_src'], g['link'])
					var img_src="{{img_src}}";
					html_1d = html_1d +'<img src="'+ img_src.replace("'","\'") +'" class="jcropelt"/>';
					html_1d = html_1d + '<a href={{link}}" class="btn"><i class="fa fa-plus"></i> Show more</a>';
					html_1d = html_1d + '<a href="javascript:graph_zoom(\'/{{elt_type}}/{{elt.get_full_name()}}?\')" class="btn"><i class="icon-zoom-in"></i> Zoom</a>';
					html_1d = html_1d + '<br>';
					%end
					html_1d=html_1d+'</p>';

					%for g in uris_1w:
					%(img_src, link) = app.get_graph_img_src( g['img_src'], g['link'])
					var img_src="{{img_src}}";
					html_1w = html_1w + '<img src="'+ img_src.replace("'","\'") +'" class="jcropelt"/>';
					html_1w = html_1w + '<a href="{{link}}" class="btn"><i class="fa fa-plus"></i> Show more</a>';
					html_1w = html_1w + '<a href="javascript:graph_zoom(\'/{{elt_type}}/{{elt.get_full_name()}}?\')" class="btn"><i class="icon-zoom-in"></i> Zoom</a>';
					html_1w = html_1w + '<br>';
					%end

					%for g in uris_1m:
					%(img_src, link) = app.get_graph_img_src( g['img_src'], g['link'])
					var img_src="{{img_src}}";
					html_1m = html_1m + '<img src="'+ img_src.replace("'","\'") +'" class="jcropelt"/>';
					html_1m = html_1m + '<a href="{{link}}" class="btn"><i class="fa fa-plus"></i> Show more</a>';
					html_1m = html_1m + '<a href="javascript:graph_zoom(\'/{{elt_type}}/{{elt.get_full_name()}}?\')" class="btn"><i class="icon-zoom-in"></i> Zoom</a>';
					html_1m = html_1m + '<br>';
					%end

					%for g in uris_1y:
					%(img_src, link) = app.get_graph_img_src( g['img_src'], g['link'])
					var img_src="{{img_src}}";
					html_1y = html_1y + '<img src="'+ img_src.replace("'","\'") +'" class="jcropelt"/>';
					html_1y = html_1y + '<a href="{{link}}" class="btn"><i class="fa fa-plus"></i> Show more</a>';
					html_1y = html_1y + '<a href="javascript:graph_zoom(\'/{{elt_type}}/{{elt.get_full_name()}}?\')" class="btn"><i class="icon-zoom-in"></i> Zoom</a>';
					html_1y = html_1y + '<br>';
					%end
					</script>

					<div class='row-fluid well col-lg-12 jcrop'>
						<div id='real_graphs'>
						<!-- Let's keep this part visible. This is the custom and default range -->
						%for g in uris:
							%(img_src, link) = app.get_graph_img_src( g['img_src'], g['link'])
							<p>
								<img src="{{img_src}}" class="jcropelt"/>
								<a href="{{link}}" class="btn"><i class="fa fa-plus"></i> Show more</a>
								<a href="javascript:graph_zoom('/{{elt_type}}/{{elt.get_full_name()}}?')" class="btn"><i class="icon-zoom-in"></i> Zoom</a>
							</p>
						%end      
						</div>
					</div>
					%end
				</div>
				%end
				<!-- Tab Graph End -->

				<!-- Tab Dep graph Start -->
				%if params['tab_depgraph']=='yes':
				<script>
				$(function() {
					$('#supported').text('Supported/allowed: ' + !!screenfull.enabled);
					if (!screenfull.enabled) {
						return false;
					}

					$('#fullscreen-request').click(function() {
						screenfull.request($('#inner_depgraph')[0]);
					});

					// Trigger the onchange() to set the initial values
					screenfull.onchange();
				});
				</script>
				<div class="tab-pane fade" id="depgraph" class="col-lg-12">
					<div class='row-fluid well col-lg-12 jcrop'>
						<div class="btn-group btn-group-sm pull-right">
							<button type="button" id="fullscreen-request" class="btn btn-primary"><i class="fa fa-plus"></i> Fullscreen</button>
						</div>
						<div id="inner_depgraph" data-elt-name='{{elt.get_full_name()}}'>
							<span class="alert alert-error">Cannot load dependency graph.</span>
						</div>
					</div>
				</div>
				%end
				<!-- Tab Dep graph End -->
			</div>
		<!-- Detail info box end -->
		</div>
	</div>


%#End of the element exist or not case
%end
