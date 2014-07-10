%# If got no group, bailout
%if not group:
%rebase layout title='Invalid group name'

Invalid group name

%else:

%if group=='all':
%groupname = 'all'
%groupalias = 'All hosts and services'
%else:
%groupname = group.get_name()
%groupalias = group.alias
%end

%helper = app.helper
%datamgr = app.datamgr

%nHosts=0
%hUp=0
%hDown=0
%hUnreachable=0
%hPending=0
%hUnknown=0
%for h in hosts:
	%nHosts=nHosts+1
	%if h.state == 'UP':
		%hUp=hUp+1
	%elif h.state == 'DOWN':
		%hDown=hDown+1
	%elif h.state == 'UNREACHABLE':
		%hUnreachable=hUnreachable+1
	%elif h.state == 'PENDING':
		%hPending=hPending+1
	%else:
		%hUnknown=hUnknown+1
	%end
%end
%if nHosts != 0:
	%pctUp			= round(100.0 * hUp / nHosts, 2)
	%pctDown		= round(100.0 * hDown / nHosts, 2)
	%pctUnreachable	= round(100.0 * hUnreachable / nHosts, 2)
	%pctPending		= round(100.0 * hPending / nHosts, 2)
	%pctUnknown		= round(100.0 * hUnknown / nHosts, 2)
%else:
	%pctUp			= 0
	%pctDown		= 0
	%pctUnreachable	= 0
	%pctPending		= 0
	%pctUnknown		= 0
%end

%end

%rebase layout globals(), title='Hosts group detail for ' + groupname, refresh=True

<style>
.warning, .unreachable {
  color: #c09853;
}
.critical, .down {
  color: #b94a48;
}
.pending, .unknown {
  color: #3a87ad;
}
.ok, .up {
  color: #468847;
}
</style>

<div id="content_container">
	<div class="panel panel-default">
		<div class="panel-heading">
			<h3 class="panel-title">{{groupname}} ({{groupalias}})</h3>
		</div>
		<div class="panel-body">
			<div class="pull-left col-lg-4">
				<span>Currently displaying {{nHosts}} hosts out of {{length}}</span>
			</div>
			<div class="pull-right progress col-lg-7 no-bottommargin no-leftpadding no-rightpadding" style="height: 45px;">
				<div title="{{hUp}} hosts Up" class="progress-bar progress-bar-success quickinfo" role="progressbar" 
					data-original-title='{{hUp}} Up' 
					style="width: {{pctUp}}%; vertical-align:midddle; line-height: 45px;">{{pctUp}}% Up</div>
					
				<div title="{{hDown}} hosts Down" class="progress-bar progress-bar-danger quickinfo" 
					data-original-title='{{hDown}} Down' 
					style="width: {{pctDown}}%; vertical-align:midddle; line-height: 45px;">{{pctDown}}% Down</div>
					
				<div title="{{hUnreachable}} hosts Unreachable" class="progress-bar progress-bar-warning quickinfo" 
					data-original-title='{{hUnreachable}} Unreachable' 
					style="width: {{pctUnreachable}}%; vertical-align:midddle; line-height: 45px;">{{pctUnreachable}}% Unreachable</div>
					
				<div title="{{hPending}} hosts Pending" class="progress-bar progress-bar-info quickinfo" 
					data-original-title='{{hPending}} Pending' 
					style="width: {{pctPending}}%; vertical-align:midddle; line-height: 45px;">{{pctPending}}% Pending</div>
					
				<div title="{{hPending}} hosts Pending/Unknown" class="progress-bar progress-bar-info quickinfo" 
					data-original-title='{{hUnknown}} Unknown' 
					style="width: {{pctPending}}%; vertical-align:midddle; line-height: 45px;">{{pctUnknown}}% Unknown</div>
			</div>
		</div>
	</div>

	<div class='col-lg-12'>
		%include pagination_element navi=navi, app=app, page="hostgroup/"+groupname, div_class="center no-margin"
	</div>

	<div class="clearfix">
		<table class="table table-hover">
			<tbody>
				<tr>
					<th>State</th>
					<th>Host</th>
					<th>Service</th>
					<th>Last Check</th>
					<th>Duration</th>
					<th>Attempt</th>
					<th>Status Information</th>
				</tr>
				%for h in hosts:
					<tr id="host_{{h.get_name()}}" class="{{h.state.lower()}}">
						<td >{{h.state}}</td>
						<td>
							<span><a href="/host/{{h.get_name()}}">{{h.get_name()}}</a></span>
						</td>

						<td style="white-space: normal">
							<span>{{h.get_check_command()}}</span>
						</td>
						<td>{{helper.print_duration(h.last_chk)}}</td>
						<td>{{h.get_duration()}}</td>
						<td>{{h.attempt}}/{{h.max_check_attempts}}</td>
						<td><span class="{{h.state.lower()}}">{{h.state}}</span></td>	
					</tr>
					%for s in h.services:
						<tr class="service service_{{h.get_name()}} {{s.state.lower()}}" style="display: none; line-height: 14px;">
							<td></td>
							<td></td>

							<td style="white-space: normal" class="{{s.state.lower()}}">
								<span><a href="/service/{{h.get_name()}}/{{s.get_name()}}">{{s.get_name()}}</a></span>
							</td>
							<td>{{helper.print_duration(s.last_chk)}}</td>
							<td>{{s.get_duration()}}</td>
							<td>{{s.attempt}}/{{s.max_check_attempts}}</td>
							<td><span class="{{s.state.lower()}}">{{s.state}}</span></td>	
						</tr>
					%end
				%end
			</tbody>
		</table>
	</div>

	<div class='col-lg-12'>
		%include pagination_element navi=navi, app=app, page="hostgroup/"+groupname, div_class="center no-margin"
	</div>
</div>


<script>
	initialize = function() {
%for h in hosts:
		$('#host_{{h.get_name()}}').click(function() {
			$(".service_{{h.get_name()}}").toggle();
		});
%end
	};

	//Ok go initialize the map with all elements when it's loaded
	$(document).ready(initialize);
</script>
