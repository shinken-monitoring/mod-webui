%import time

%# If got no Elt, bailout
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
	%sOK=0
	%sWARNING=0
	%sCRITICAL=0
	%sUNKNOWN=0

	%for h in elt.services:
		%if h.state == 'OK':
			%sOK=sOK+1
		%end
		%if h.state == 'WARNING':
			%sWARNING=sWARNING+1
		%end
		%if h.state == 'CRITICAL':
			%sCRITICAL=sCRITICAL+1
		%end
		%if h.state == 'UNKNOWN':
			%sUNKNOWN=sUNKNOWN+1
		%end
	%end
%end

%rebase layout title=elt_type.capitalize() + ' / ' + elt.get_full_name(), js=['eltdetail/js/jquery.color.js', 'eltdetail/js/jquery.Jcrop.js', 'eltdetail/js/iphone-style-checkboxes.js', 'eltdetail/js/hide.js', 'eltdetail/js/dollar.js', 'eltdetail/js/gesture.js', 'eltdetail/js/graphs.js', 'eltdetail/js/tags.js', 'eltdetail/js/depgraph.js', 'eltdetail/js/custom_views.js', 'eltdetail/js/tabs.js', 'eltdetail/js/screenfull.js', 'eltdetail/js/shinken-gauge.js'], css=['eltdetail/css/eltdetail.css', 'eltdetail/css/hide.css', 'eltdetail/css/gesture.css', 'eltdetail/css/jquery.Jcrop.css', 'eltdetail/css/shinken-gauge.css'], user=user, app=app, refresh=True

%# " We will save our element name so gesture functions will be able to call for the good elements."
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
			$('ul.nav-tabs > li > a[href="' + window.location.hash + '"]').tab('show');
		}
		else {
			$('ul.nav-tabs > li > a:first').tab('show');
		}
	});

  // Now we hook the global search thing
	$('.typeahead').typeahead({
		// note that "value" is the default setting for the property option
		source: function (typeahead, query) {
			$.ajax({url: "/lookup/"+query,
				success: function (data){
					typeahead.process(data)}
				});
		},
		onselect: function(obj) { 
			$("ul.typeahead.dropdown-menu").find('li.active').data(obj);
		}
	});
</script>

  %#  "Content Container Start"

  %#app.insert_template('cv_linux', globals())
  %#app.insert_template('cv_windows', globals())

  <div id="content_container">
  	<div class="row">
  		<!-- <h1 class="col-lg-7 state_{{elt.state.lower()}} icon_down no-margin"> <img class="imgsize3" alt="icon state" src="{{helper.get_icon_state(elt)}}" />{{elt.state}}: {{elt.get_full_name()}}</h1>  -->

		%if elt.action_url != '':
			<div class="col-lg-10">
				<span class="pull-right leftmargin" id="host_tags">
					%tags = elt.get_host_tags()
					%for t in tags:
					<script>add_tag_image('/static/images/sets/{{t.lower()}}/tag.png','{{t}}');</script>
					%end
				</span>
			</div>
			<div class="col-lg-2">
				<div class="btn-group pull-right">
					%action_urls = elt.action_url.split('|')
					%if len(action_urls) == 1:
					<button class="btn btn-primary btn-xs"><i class="icon-cog"></i> Action</button>
					%else:
					<button class="btn btn-primary btn-xs"><i class="icon-cog"></i> Actions</button>
					%end
					<button class="btn btn-primary btn-xs dropdown-toggle" data-toggle="dropdown">
						<span class="caret"></span>
					</button>
					<ul class="dropdown-menu pull-right">
						%action_urls = elt.action_url.split('|')
						%if len(action_urls) > 0:
							%for triplet in action_urls:
								%if len(triplet.split(',')) == 3:
									%( action_url, icon, alt) = triplet.split(',')
									<li><a href="{{ MacroResolver().resolve_simple_macros_in_string(action_url, elt.get_data_for_checks()) }}" target=_blank><img src={{icon}} alt="{{alt}}"></a></li>
								%else:
									%if len(triplet.split(',')) == 1:
										<li><a id="action-link" href="{{ MacroResolver().resolve_simple_macros_in_string(triplet, elt.get_data_for_checks()) }}" target=_blank>{{ MacroResolver().resolve_simple_macros_in_string(triplet, elt.get_data_for_checks()) }}</a></li>
									%end
								%end
							%end
						%end
				    </ul>
			    </div>
			</div>	
		%else:
		    <div class="col-lg-12">
		   		<span class="pull-right leftmargin" id="host_tags">
		   			%tags = elt.get_host_tags()
		   			%for t in tags:
		    		<script>add_tag_image('/static/images/sets/{{t.lower()}}/tag.png','{{t}}');</script>
		    		%end
		    	</span>
		    </div>
		%end	
	</div>

	<div class="accordion" id="fitted-accordion">
		<div class="fitted-box overall-summary accordion-group">
			<div class="accordion-heading">
				%if elt_type=='host':
				<div class="panel-heading fitted-header" data-toggle="collapse" data-parent="#accordion" href="#collapseOne">
					<h4 class="panel-title">Overview {{elt.host_name}}
						%if len(elt.display_name) > 0:
							({{elt.display_name}})
						%end
						%for i in range(0, elt.business_impact-2):
						<img alt="icon state" src="/static/images/star.png">
						%end
					</h4>
				</div>
				%else:
				<div class="panel-heading fitted-header" data-toggle="collapse" data-parent="#accordion" href="#collapseOne">
					<h4 class="panel-title">Overview ({{elt.service_description}}) on {{elt.host.host_name}}
						%if len(elt.host.display_name) > 0:
							({{elt.host.display_name}})
						%end
						%for i in range(0, elt.business_impact-2):
						<img alt="icon state" src="/static/images/star.png">
						%end
					</h4>
				</div>
				%end
			</div>
			<div id="collapseOne" class="accordion-body collapse">
				<div class="fitted-bar ">
					<table class="col-lg-4 leftmargin">
						%#Alias, parents and hostgroups are for host only
						%if elt_type=='host':
						<tr>
							<td>Alias:</td>
							<td>{{elt.alias}}</td>
						</tr>
						<tr>
							<td>Address:</td>
							<td>{{elt.address}}</td>
						</tr>
						<tr>
							<td>Importance:</td>
							<td>{{!helper.get_business_impact_text(elt)}}</td>
						</tr>
					</table>

					<table class="col-lg-3">
						<tr>
							<td>Parents:</td>
							%if len(elt.parents) > 0:
							<td>{{','.join([h.get_name() for h in elt.parents])}}</td>
							%else:
							<td>No parents</td>
							%end
						</tr>
						<tr>
							<td>Member of:</td>
							%if len(elt.hostgroups) > 0:
							<td>
							%for hg in elt.hostgroups:
							<a href="/group/{{hg.get_name()}}" class="link">{{hg.alias}} ({{hg.get_name()}})</a>
							%end
							</td>
							%else:
							<td> No groups </td>
							%end
						</tr>
						%# End of the host only case, so now service
						%else:
						<tr>
							<td>Host:</td>
							<td><a href="/host/{{elt.host.host_name}}" class="link">{{elt.host.host_name}}
							%if len(elt.host.display_name) > 0:
								({{elt.host.display_name}})
							%end
							</a></td>
						</tr>
						<tr>
							<td>Member of:</td>
							%if len(elt.servicegroups) > 0:
							<td>{{','.join([sg.get_name() for sg in elt.servicegroups])}}</td>
							%else:
							<td> No groups </td>
							%end
						</tr>
						%end
						<tr>
							<td>Notes: </td>
							%if elt.notes != '' and elt.notes_url != '':
							<td><a href="{{elt.notes_url}}" target=_blank>{{elt.notes}}</a></td>
							%elif elt.notes == '' and elt.notes_url != '':
							<td><a href="{{elt.notes_url}}" target=_blank>{{elt.notes_url}}</a></td>
							%elif elt.notes != '' and elt.notes_url == '':
							<td>{{elt.notes}}</td>
							%else:
							<td>(none)</td>
							%end
						</tr>
					</table>
					<div class="col-lg-4">
						%#   " If the elements is a root problem with a huge impact and not ack, ask to ack it!"
						%if elt.is_problem and elt.business_impact > 2 and not elt.problem_has_been_acknowledged:
						<div style="padding: 10px 35px 5px 15px;" class="alert alert-critical no-bottommargin pulsate row">
							<div class="col-lg-2 font-white" style="font-size: 30px; padding-top: 0px;"> <i class="icon-bolt"></i> </div>
							<p class="col-lg-10 font-white">This element has got an important impact on your business, please <b>fix it</b> or <b>acknowledge it</b>.</p>
							%# "end of the 'SOLVE THIS' highlight box"
							%end
						</div>
					</div>
				</div>
				%if elt_type=='host':
				<div class="row">
					<ul>
						<li class="col-lg-3"> <span class="icon-stack font-green"> <i class="icon-circle-blank icon-stack-base"></i> <i class="icon-ok"></i></span> <span class="num">{{sOK}}</span> OK</li>
						<li class="col-lg-3"> <span class="icon-stack font-orange"> <i class="icon-circle-blank icon-stack-base"></i> <i class="icon-exclamation"></i></span> <span class="num">{{sWARNING}}</span> Warning</li>
						<li class="col-lg-3"> <span class="icon-stack font-red"> <i class="icon-circle-blank icon-stack-base"></i> <i class="icon-arrow-down"></i></span> <span class="num">{{sCRITICAL}}</span> Critical</li>
						<li class="col-lg-3"> <span class="icon-stack"> <i class="icon-circle-blank icon-stack-base"></i> <i class="icon-question"></i></span> <span class="num">{{sUNKNOWN}}</span> Unknown</li>
					</ul>
				</div>
				%end
			</div>
	    </div>
	</div>
	<!-- Switch Start -->

	%# By default all is unabled
	% chk_freshness = chk_active_state = chk_passive_state = not_state =  evt_state = flp_state = 'checked=""'
	%if not (elt.check_freshness):
	%chk_freshness = 'unchecked=""'
	%end
	%if not (elt.active_checks_enabled):
	%chk_active_state = 'unchecked=""'
	%end
	%if not (elt.passive_checks_enabled):
	%chk_passive_state = 'unchecked=""'
	%end
	%if not elt.notifications_enabled:
	%not_state = 'unchecked=""'
	%end
	%if not elt.event_handler_enabled:
	%evt_state = 'unchecked=""'
	%end
	%if not elt.flap_detection_enabled:
	%flp_state = 'unchecked=""'
	%end

	<script type="text/javascript">
	$(document).ready(function() {
		$('#btn-active-check').iphoneStyle({
			resizeContainer: false,
			resizeHandle: false,
			onChange : function(elt, b){toggle_checks("{{elt.get_full_name()}}", !b);}
		});

		$('#btn-passive-check').iphoneStyle({
			resizeContainer: false,
			resizeHandle: false,
			onChange : function(elt, b){toggle_checks("{{elt.get_full_name()}}", !b);}
		});

		$('#btn-not').iphoneStyle({
			resizeContainer: false,
			resizeHandle: false,
			onChange : function(elt, b){toggle_notifications("{{elt.get_full_name()}}", !b);}
		});

		$('#btn-evt').iphoneStyle({
			resizeContainer: false,
			resizeHandle: false,
			onChange : function(elt, b){toggle_event_handlers("{{elt.get_full_name()}}", !b);}
		});

		$('#btn-flp').iphoneStyle({
			resizeContainer: false,
			resizeHandle: false,
			onChange : function(elt, b){toggle_flap_detection("{{elt.get_full_name()}}", !b);}

		});
	}); 
	</script>

	<!-- Start -->
	<div class="row">
		<!-- Start Host/Services-->
		<div class="tabbable verticaltabs-container col-sm-4 col-lg-3"> <!-- Wrap the Bootstrap Tabs/Pills in this container to position them vertically -->
			<ul class="nav nav-tabs">
				<li class="active"><a href="#basic" data-toggle="tab">{{elt_type.capitalize()}} Information:</a></li>
				<li><a href="#additional" data-toggle="tab">Additional Informations:</a></li>
				<li><a href="#commands" data-toggle="tab">Commands:</a></li>
				<li><a href="#gesture" data-toggle="tab">Gesture:</a></li>
			</ul>

			<div class="tab-content">
				<div class="tab-pane fade in active" id="basic">
					%if elt_type=='host':
					<h4>Host Information:</h4>
					%else:
					<h4>Service Information:</h4>
					%end:

					<script type="text/javascript">
					$().ready(function() {
						$('.truncate').jTruncate({
							length: 100,
							minTrail: 0,
							moreText: "[see all]",
							lessText: "[hide extra]",
							ellipsisText: " (truncated)",
							moreAni: "fast",
							lessAni: 2000
						});
					});
					</script>

					<table class="">
						<tr>
							<td class="column1"><b>Status:</b></td>
							<td><button class="col-lg-11 btn alert-small alert-{{elt.state.lower()}} quickinforight" data-original-title="since {{helper.print_duration(elt.last_state_change, just_duration=True, x_elts=2)}}">{{elt.state}}</button> </td>
						</tr>
						<tr>
							<td class="column1"><b>Flapping:</b></td>
							<td><button class="col-lg-11 btn alert-small trim-{{helper.yes_no(elt.in_scheduled_downtime)}}" quickinfo="{{helper.print_float(elt.percent_state_change)}}% state change">{{helper.yes_no(elt.is_flapping)}}</button></td>
						</tr>
						<tr>
							<td class="column1"><b>In Scheduled Downtime?</b></td>
							<td><!-- <span class="btn span11 alert-small trim-{{helper.yes_no(elt.in_scheduled_downtime)}}">{{helper.yes_no(elt.in_scheduled_downtime)}}</span> -->
							<button class="col-lg-11 btn alert-small trim-{{helper.yes_no(elt.in_scheduled_downtime)}}" type="button">{{helper.yes_no(elt.in_scheduled_downtime)}}</button>
							</td>
						</tr>
					</table>
					<hr>
					<div class="truncate">
						%if len(elt.output) > app.max_output_length:
							%if app.allow_html_output:
								<div class='output' rel="tooltip" data-original-title="{{elt.output}}"> {{!helper.strip_html_output(elt.output[:app.max_output_length])}}</div>
							%else:
								<div class='output' rel="tooltip" data-original-title="{{elt.output}}"> {{elt.output[:app.max_output_length]}}</div>
							%end
						%else:
							%if app.allow_html_output:
								<div class='output'> {{!helper.strip_html_output(elt.output)}}</div>
							%else:
								<div class='output'> {{elt.output}} </div>
							%end
						%end
						%if elt.long_output:
							<br/> {{elt.long_output}}
						%end
					</div>
					<hr>
					<table class="table">
						<tr>
							<td class="column1"><b>Last Check:</b></td>
							<td><span class="quickinfo" data-original-title='Last check was at {{time.asctime(time.localtime(elt.last_chk))}}'>was {{helper.print_duration(elt.last_chk)}}</span></td>
						</tr>
						<tr>		
							<td class="column1"><b>Last State Change:</b></td>
							<td>{{time.asctime(time.localtime(elt.last_state_change))}}</td>
						</tr>
						<tr>										
							<td class="column1"><b>Current Attempt:</b></td>
							<td>{{elt.attempt}}/{{elt.max_check_attempts}} ({{elt.state_type}} state)</td>
						</tr>
						<tr>		
							<td class="column1"><b>Next Active Check:</b></td>
							<td><span class="quickinfo" data-original-title='Next active check at {{time.asctime(time.localtime(elt.next_chk))}}'>{{helper.print_duration(elt.next_chk)}}</span></td>
						</tr>
					</table>
				</div>

				<div class="tab-pane fade" id="additional">
					<script type="text/javascript">
					$().ready(function() {
						$('.truncate_perf').jTruncate({
							length: 50,
							minTrail: 0,
							moreText: "[see all]",
							lessText: "[hide extra]",
							ellipsisText: " <b>(truncated)</b>",
							moreAni: "fast",
							lessAni: 2000
						});
					});
					</script>

					<h4>Additional Informations</h4>
					<table class="table tabletop">
						<tbody class="tabletop">
						<tr class="tabletop">
							<td class="column1"><b>Performance Data</b></td>
							%# "If there any perf data?"
							%if len(elt.perf_data) > 0:
							<td class="column2 truncate_perf">{{elt.perf_data}}</td>
							%else:
							<td class="column2 truncate_perf">&nbsp;</td>
							%end
						</tr>
						<tr>			
							<td class="column1"><b>Check Latency / Duration</b></td>
							<td>{{'%.2f' % elt.latency}} / {{'%.2f' % elt.execution_time}} seconds</td>
						</tr>
						<tr>			
							<td class="column1"><b>Last Notification</b></td>
							<td class="column2">{{helper.print_date(elt.last_notification)}} (notification {{elt.current_notification_number}})</td>
						</tr>
						<tr>
							<td class="column1"><b>Notification interval</b></td>
							<td class="column2">{{elt.notification_interval}} mn (period : {{elt.notification_period.timeperiod_name}})</td>
						</tr>
						<tr>
							<td class="column1"><b>Current Attempt</b></td>
							<td class="column2">{{elt.attempt}}/{{elt.max_check_attempts}} ({{elt.state_type}} state)</td>
						</tr>
						</tbody>
					</table>
					<hr>
					<div>
						<div>
						<span><b>Active checks</b></span>
						<input {{chk_active_state}} class="iphone" type="checkbox" id='btn-active-check'>
						</div>
						<div>
						<span><b>Passive checks</b></span>
						<input {{chk_passive_state}} class="iphone" type="checkbox" id='btn-passive-check'>
						</div>
						%if (elt.passive_checks_enabled):
						%if (elt.check_freshness):
						<span><b>- Freshness check:</b> {{elt.freshness_threshold}}</span>
						%end
						%end
						<div>
						<span><b>Notifications</b></span>
						<input {{not_state}} class="iphone" type="checkbox" id='btn-not'>
						</div>
						<div>
						<span><b>Event handler</b></span>
						<input {{evt_state}} class="iphone" type="checkbox" id='btn-evt'>
						</div>
						<div>
						<span><b>Flap detection</b></span>
						<input {{flp_state}} class="iphone" type="checkbox" id='btn-flp'>
						</div>
					</div>
				</div>

				<div class="tab-pane fade" id="commands">
					<h4>Commands</h4>
					<div>
						<ul style="padding-top:5px" class="nav nav-list">
							%disabled_s = ''
							%if not elt.event_handler:
							%disabled_s = 'disabled-link'
							%end
							<li><a class='{{disabled_s}} {{global_disabled}}' href="javascript:try_to_fix('{{elt.get_full_name()}}')"><i class="icon-pencil"></i> Try to fix it!</a></li>
							%disabled_s = ''
							%if elt.problem_has_been_acknowledged:
							%disabled_s = 'disabled-link'
							%end
							<li><a class='{{disabled_s}} {{global_disabled}}' href="/forms/acknowledge/{{helper.get_uri_name(elt)}}" data-toggle="modal" data-target="#modal"> <img src="/static/img/icons/atwork.png" alt="atwork" height="15" width="17" /> Acknowledge it!</a></li>
							<li><a class='{{global_disabled}}' href="javascript:recheck_now('{{elt.get_full_name()}}')"><i class="icon-repeat"></i> Recheck now</a></li>
							<li><a class='{{global_disabled}}' href="/forms/submit_check/{{helper.get_uri_name(elt)}}" data-toggle="modal" data-target="#modal"><i class="icon-share-alt"></i> Submit Check Result</a></li>
							<li><a class='disabled-link {{global_disabled}}' href="#"><i class="icon-comment"></i> Send Custom Notification</a></li>
							<li><a class='{{global_disabled}}' href="/forms/downtime/{{helper.get_uri_name(elt)}}" data-toggle="modal" data-target="#modal"><i class="icon-fire"></i> Schedule Downtime</a></li>
							<li class="divider"></li>
							<li><a class='disabled-link' href="#"><i class="icon-edit"></i> Edit {{elt_type.capitalize()}}</a></li>
						</ul>
				    </div>
				</div>

				<div class="tab-pane fade" id="gesture">
					<h4>Gesture</h4>
					<canvas id="canvas" height="200" class="" style="border: 1px solid black;"></canvas>
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
			</div>
		</div>

		<!-- Detail info box start -->
		<div class="col-sm-8 col-lg-9 tabbable">
			<ul class="nav nav-tabs" style="margin-bottom: 12px;">
			  %_go_active = 'active'
			  %for cvname in elt.custom_views:
			     <li class="{{_go_active}} cv_pane" data-cv-name="{{cvname}}" data-elt-name='{{elt.get_full_name()}}' id='tab-cv-{{cvname}}'><a class='link_to_tab' href="#cv{{cvname}}" data-toggle="tab">{{cvname.capitalize()}}</a></li>
			     %_go_active = ''
			  %end

				<li class="{{_go_active}}"><a class='link_to_tab' href="#impacts" data-toggle="tab">Services</a></li>
			    <li><a class='link_to_tab' href="#comments" data-toggle="tab">Comments</a></li>
				<li><a class='link_to_tab' href="#downtimes" data-toggle="tab">Downtimes</a></li>
				<li><a class='link_to_tab' href="#graphs" data-toggle="tab" id='tab_to_graphs'>Graphs</a></li>
				<li><a class='link_to_tab' href="#depgraph" data-toggle="tab" id='tab_to_depgraph'>Impact graph</a></li>
				<!--<li><a href="/depgraph/{{elt.get_full_name()}}" title="Impact map of {{elt.get_full_name()}}">Impact map</a></li> -->
			</ul>
			<div class="tab-content">

				<!-- First custom views -->
				%_go_active = 'active'
				%for cvname in elt.custom_views:
					<div class="tab-pane {{_go_active}}" data-cv-name="{{cvname}}" data-elt-name='{{elt.get_full_name()}}' id="cv{{cvname}}">
						Cannot load the pane {{cvname}}.
					</div>
					%_go_active = ''
				%end

				<!-- Tab Summary Start-->
				<div class="tab-pane {{_go_active}}" id="impacts">
					<!-- Start of the Whole info pack. We got a row of 2 thing : 
					left is information, right is related elements -->
					<div class="row-fluid">
					<!-- So now it's time for the right part, replaceted elements -->
					<div class="span12">
						<!-- Show our father dependencies if we got some -->
						%#    Now print the dependencies if we got somes
						%if len(elt.parent_dependencies) > 0:
						<h4 class="span12">Root cause:</h4>
						<a id="togglelink-{{elt.get_dbg_name()}}" href="javascript:toggleBusinessElt('{{elt.get_dbg_name()}}')"> {{!helper.get_button('Show dependency tree', img='/static/images/expand.png')}}</a>
						<div class="clear"></div>
						{{!helper.print_business_rules(datamgr.get_business_parents(elt), source_problems=elt.source_problems)}}
						%end
						<hr/>

						<!-- If we are an host and not a problem, show our services -->
						%# " Only print host service if elt is an host of course"
						%# " If the host is a problem, services will be print in the impacts, so don't"
						%# " print twice "
						%if elt_type=='host' and not elt.is_problem:
						%if len(elt.services) > 0:
						<h4 class="span10 no-topmargin">My services:</h4>
						%elif len(elt.parent_dependencies) == 0:
						<div class="alert alert-info">
							<p class="font-blue">No services available</p>
						</div>
						%end
						<div class="host-services span11">
							<div class='pull-left'>
								%_html_id = helper.get_html_id(elt)
								{{!helper.print_aggregation_tree(helper.get_host_service_aggregation_tree(elt), _html_id)}}
							</div>
							<div>&nbsp;</div>
						</div>
						%end #of the only host part

						<!-- If we are a root problem and got real impacts, show them! -->
						%if elt.is_problem and len(elt.impacts) != 0:
							<h4 class="span10">My impacts:</h4>
							<div class='host-services'>
								%nb = 0
								%for i in helper.get_impacts_sorted(elt):
								%nb += 1
								%if nb == 8:
								<div style="float:right;" id="hidden_impacts_or_services_button"><a href="javascript:show_hidden_impacts_or_services()"> {{!helper.get_button('Show all impacts', img='/static/images/expand.png')}}</a></div>
								%end
								%if nb < 8:
								<div class="service">
									%else:
									<div class="service hidden_impacts_services">
										%end
										<div>
											<img style="width : 16px; height:16px" alt="icon state" src="{{helper.get_icon_state(i)}}">
											<span class='alert-small alert-{{i.state.lower()}}' style="font-size:110%">{{i.state}}</span> for <span style="font-size:110%">{{!helper.get_link(i, short=True)}}</span> since {{helper.print_duration(i.last_state_change, just_duration=True, x_elts=2)}}
											%for i in range(0, i.business_impact-2):
											<img alt="icon state" src="/static/images/star.png">
											%end
										</div>
									</div>
									%# End of this impact
									%end
								</div>
						%# end of the 'is problem' if
						%end
						</div><!-- End of the right part -->
						</div>
						<!-- End of the row with the 2 blocks-->
				</div>
				<!-- Tab Summary End-->

				<!-- Tab Comments Start -->
				<div class="tab-pane" id="comments">
					<button type="button" class="btn btn-primary btn-sm" href="/forms/comment/{{helper.get_uri_name(elt)}}" data-toggle="modal" data-target="#modal"><i class="icon-plus"></i> Add comment</button>
					<button type="button" class="btn btn-primary btn-sm" href="/forms/comment_delete/{{helper.get_uri_name(elt)}}" data-toggle="modal" data-target="#modal"><i class="icon-minus"></i> Delete all comments</button>

		      		<div id="log_container" class="row-fluid">
		      			%if len(elt.comments) > 0:
		      			<table class="table table-condensed table-hover">
							<thead>
								<tr>
									<th class="span2"></th>
									<th class="span1"></th>
									<th class="span6"></th>
									<th class="span4"></th>
									<th class="span1"></th>
								</tr>
							</thead>
							<tbody>
						  	%for c in elt.comments:
								<tr>
									<td><strong>{{c.author}}</strong></td>
									<td><span class="label pull-right">Comments</span></td>
									<td><strong>{{c.comment}}</strong></td>
									<td><strong>{{helper.print_date(c.entry_time)}} - {{helper.print_date(c.expire_time)}}</strong></td>
									<td><a class="icon-trash {{global_disabled}} font-red" href="javascript:delete_comment('{{elt.get_full_name()}}', {{c.id}})"></a></td>
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
		      	</div>
				<!-- Tab Comments End -->

				<!-- Tab Downtimes Start -->
				<div class="tab-pane" id="downtimes">
					<button type="button" class="btn btn-primary btn-sm" href="/forms/downtime/{{helper.get_uri_name(elt)}}" data-toggle="modal" data-target="#modal" class="btn btn-primary"><i class="icon-plus"></i> Add a downtime</button>
					<button type="button" class="btn btn-primary btn-sm" href="/forms/downtime_delete/{{helper.get_uri_name(elt)}}" data-toggle="modal" data-target="#modal" class="btn btn-primary"><i class="icon-minus"></i> Delete all downtimes</button>

		      		<div id="log_container" class="row-fluid">
		      			%if len(elt.downtimes) > 0:
		      			<table class="table table-condensed table-hover">
						  <thead>
						    <tr>
						      <th class="span2"></th>
						      <th class="span1"></th>
						      <th class="span5"></th>
						      <th class="span5"></th>
						      <th class="span1"></th>
						    </tr>
						  </thead>
						  <tbody>
						  	%for dt in elt.downtimes:
						    <tr>
						      <td><strong>{{dt.author}}</strong></td>
						      <td><span class="label pull-right">Downtime</span></td>
						      <td><strong>{{dt.comment}}</strong></td>
						      <td><strong>{{helper.print_date(dt.start_time)}} - {{helper.print_date(dt.end_time)}}</strong></td>
						      <td><a class="icon-trash {{global_disabled}} font-red" href="javascript:delete_downtime('{{elt.get_full_name()}}', {{dt.id}})"></a></td>
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
			</div>
				<!-- Tab Downtimes End -->

				<!-- Tab Graph Start -->
				<div class="tab-pane" id="graphs">
					%uris = app.get_graph_uris(elt, graphstart, graphend)
					%if len(uris) == 0:
					<div class="alert alert-info">
					    <div class="font-blue"><strong>Oh snap!</strong> No graphs available!</div>
					</div>
					<script language="javascript">
						$('#tab_to_graphs').hide();
					</script>
					%else:
					<h4>Graphs</h4>
					<div class='row-fluid well span6'>
		      			<!-- Get the uris for the 4 standard time ranges in advance	 -->
		      			%now = int(time.time())
		      			%fourhours = now - 3600*4
		      			%lastday =   now - 86400
		      			%lastweek =  now - 86400*7
		      			%lastmonth = now - 86400*31
		      			%lastyear =  now - 86400*365

		      			%# Let's get all the uris at once.
		      			%uris_4h = app.get_graph_uris(elt, fourhours, now)
		      			%uris_1d = app.get_graph_uris(elt, lastday, now)
		      			%uris_1w = app.get_graph_uris(elt, lastweek, now)
		      			%uris_1m = app.get_graph_uris(elt, lastmonth, now)
		      			%uris_1y = app.get_graph_uris(elt, lastyear, now)

		      			<!-- Use of javascript to change the content of a div!-->										
		      			<div class='span2'><a onclick="setHTML(html_4h,{{fourhours}});" class=""> 4 hours</a></div>
		      			<div class='span2'><a onclick="setHTML(html_1d,{{lastday}});" class=""> 1 day</a></div>
		      			<div class='span2'><a onclick="setHTML(html_1w,{{lastweek}});" class=""> 1 week</a></div>
		      			<div class='span2'><a onclick="setHTML(html_1m,{{lastmonth}});" class=""> 1 month</a></div>
		      			<div class='span2'><a onclick="setHTML(html_1y,{{lastyear}});" class=""> 1 year</a></div>
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

		      		<!-- let's create the html content for each time rand --!>
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
		      		html_4h = html_4h + '<a href="{{link}}" class="btn"><i class="icon-plus"></i> Show more</a>';
		      		html_4h = html_4h + '<a href="javascript:graph_zoom(\'/{{elt_type}}/{{elt.get_full_name()}}?\')" class="btn"><i class="icon-zoom-in"></i> Zoom</a>';
		      		html_4h = html_4h + '<br>';
		      		%end
		      		html_4h=html_4h+'</p>';

		      		%for g in uris_1d:
                    %(img_src, link) = app.get_graph_img_src( g['img_src'], g['link'])
		      		var img_src="{{img_src}}";
		      		html_1d = html_1d +'<img src="'+ img_src.replace("'","\'") +'" class="jcropelt"/>';
		      		html_1d = html_1d + '<a href={{link}}" class="btn"><i class="icon-plus"></i> Show more</a>';
		      		html_1d = html_1d + '<a href="javascript:graph_zoom(\'/{{elt_type}}/{{elt.get_full_name()}}?\')" class="btn"><i class="icon-zoom-in"></i> Zoom</a>';
		      		html_1d = html_1d + '<br>';
		      		%end
		      		html_1d=html_1d+'</p>';

		      		%for g in uris_1w:
                    %(img_src, link) = app.get_graph_img_src( g['img_src'], g['link'])
		      		var img_src="{{img_src}}";
		      		html_1w = html_1w + '<img src="'+ img_src.replace("'","\'") +'" class="jcropelt"/>';
		      		html_1w = html_1w + '<a href="{{link}}" class="btn"><i class="icon-plus"></i> Show more</a>';
		      		html_1w = html_1w + '<a href="javascript:graph_zoom(\'/{{elt_type}}/{{elt.get_full_name()}}?\')" class="btn"><i class="icon-zoom-in"></i> Zoom</a>';
		      		html_1w = html_1w + '<br>';
		      		%end

		      		%for g in uris_1m:
                    %(img_src, link) = app.get_graph_img_src( g['img_src'], g['link'])
		      		var img_src="{{img_src}}";
		      		html_1m = html_1m + '<img src="'+ img_src.replace("'","\'") +'" class="jcropelt"/>';
		      		html_1m = html_1m + '<a href="{{link}}" class="btn"><i class="icon-plus"></i> Show more</a>';
		      		html_1m = html_1m + '<a href="javascript:graph_zoom(\'/{{elt_type}}/{{elt.get_full_name()}}?\')" class="btn"><i class="icon-zoom-in"></i> Zoom</a>';
		      		html_1m = html_1m + '<br>';
		      		%end

		      		%for g in uris_1y:
                    %(img_src, link) = app.get_graph_img_src( g['img_src'], g['link'])
		      		var img_src="{{img_src}}";
		      		html_1y = html_1y + '<img src="'+ img_src.replace("'","\'") +'" class="jcropelt"/>';
		      		html_1y = html_1y + '<a href="{{link}}" class="btn"><i class="icon-plus"></i> Show more</a>';
		      		html_1y = html_1y + '<a href="javascript:graph_zoom(\'/{{elt_type}}/{{elt.get_full_name()}}?\')" class="btn"><i class="icon-zoom-in"></i> Zoom</a>';
		      		html_1y = html_1y + '<br>';
		      		%end


		      		</script>

					<div class='row-fluid well span8 jcrop'>
						<div id='real_graphs'>
						<!-- Let's keep this part visible. This is the custom and default range -->
						%for g in uris:
							%(img_src, link) = app.get_graph_img_src( g['img_src'], g['link'])
							<p>
								<img src="{{img_src}}" class="jcropelt"/>
								<a href="{{link}}" class="btn"><i class="icon-plus"></i> Show more</a>
								<a href="javascript:graph_zoom('/{{elt_type}}/{{elt.get_full_name()}}?')" class="btn"><i class="icon-zoom-in"></i> Zoom</a>
							</p>
						%end      
						</div>
					</div>
				%end
			</div>
				<!-- Tab Graph End -->

				<!-- Tab Dep graph Start -->
				<script>
				$(function() {
					$('#supported').text('Supported/allowed: ' + !!screenfull.enabled);
					if (!screenfull.enabled) {
						return false;
					}

					$('#fullscreen-request').click(function() {
						screenfull.request($('#inner_depgraph')[0]);
						// Does not require jQuery, can be used like this too:
						// screenfull.request(document.getElementById('container'));
					});

					// Trigger the onchange() to set the initial values
					screenfull.onchange();
				});
				</script>
				<div class="tab-pane" id="depgraph" class="span12">
					<div class="btn-group btn-group-sm">
						<button type="button" id="fullscreen-request" class="btn btn-primary"><i class="icon-plus"></i> Fullscreen</button>
					</div>
					<div id="inner_depgraph" data-elt-name='{{elt.get_full_name()}}'>
						<span class="alert alert-error">Cannot load dependency graph.</span>
					</div>
				</div>
				<!-- Tab Dep graph End -->
			</div>
		<!-- Detail info box end -->
	</div>
	<!-- End ... -->
</div>

%#End of the Host Exist or not case
%end


