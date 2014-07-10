%# If got no group, bailout
%if not group:
%rebase layout title='Invalid group name'

Invalid group name

%else:

%if group=='all':
%groupname = 'all'
%groupalias = 'All services'
%else:
%groupname = group.get_name()
%groupalias = group.alias
%end

%helper = app.helper
%datamgr = app.datamgr

%nServices=0
%sOk=0
%sCritical=0
%sWarning=0
%sPending=0
%sUnknown=0
%for s in services:
	%nServices=nServices+1
	%if s.state == 'OK':
		%sOk=sOk+1
	%elif s.state == 'CRITICAL':
		%sCritical=sCritical+1
	%elif s.state == 'WARNING':
		%sWarning=sWarning+1
	%elif s.state == 'PENDING':
		%sPending=sPending+1
	%else:
		%sUnknown=sUnknown+1
	%end
%end
%if nServices != 0:
	%pctOk			= round(100.0 * sOk / nServices, 2)
	%pctCritical	= round(100.0 * sCritical / nServices, 2)
	%pctWarning		= round(100.0 * sWarning / nServices, 2)
	%pctPending		= round(100.0 * sPending / nServices, 2)
	%pctUnknown		= round(100.0 * sUnknown / nServices, 2)
%else:
	%pctOk			= 0
	%pctCritical	= 0
	%pctWarning		= 0
	%pctPending		= 0
	%pctUnknown		= 0
%end

%end

%rebase layout globals(), title='Services group detail for ' + groupname, refresh=True

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
				<span>Currently displaying {{nServices}} services out of {{length}}</span>
			</div>
			<div class="pull-right progress col-lg-7 no-bottommargin no-leftpadding no-rightpadding" style="height: 45px;">
				<div title="{{sOk}} services Ok" class="progress-bar progress-bar-success quickinfo" role="progressbar" 
					data-original-title='{{sOk}} Ok' 
					style="width: {{pctOk}}%; vertical-align:midddle; line-height: 45px;">{{pctOk}}% Ok</div>
					
				<div title="{{sCritical}} services Critical" class="progress-bar progress-bar-danger quickinfo" 
					data-original-title='{{sCritical}} Critical' 
					style="width: {{pctCritical}}%; vertical-align:midddle; line-height: 45px;">{{pctCritical}}% Critical</div>
					
				<div title="{{sWarning}} services Unreachable" class="progress-bar progress-bar-warning quickinfo" 
					data-original-title='{{sWarning}} Warning' 
					style="width: {{pctWarning}}%; vertical-align:midddle; line-height: 45px;">{{pctWarning}}% Warning</div>
					
				<div title="{{sPending}} services Pending/Unknown" class="progress-bar progress-bar-info quickinfo" 
					data-original-title='{{sPending}} Pending' 
					style="width: {{pctPending}}%; vertical-align:midddle; line-height: 45px;">{{pctPending}}% Pending</div>
					
				<div title="{{sPending}} services Pending/Unknown" class="progress-bar progress-bar-info quickinfo" 
					data-original-title='{{sUnknown}} Unknown' 
					style="width: {{pctUnknown}}%; vertical-align:midddle; line-height: 45px;">{{pctUnknown}}% Unknown</div>
			</div>
		</div>
	</div>

	<div class='col-lg-12'>
		%include pagination_element navi=navi, app=app, page="servicegroup/"+groupname, div_class="center no-margin"
	</div>

	<div class="clearfix">
		<table class="table table-hover">
			<tbody>
				<tr>
					<th>State</th>
					<th>Host</th>
					<th>Service</th>
					<th>Output</th>
					<th>Last Check</th>
					<th>Duration</th>
					<th>Attempt</th>
					<th>Status Information</th>
				</tr>
				%for s in services:
					<tr id="service_{{s.get_name()}}" class="{{s.state.lower()}}">
						<td >{{s.state}}</td>
						<td>
							<span><a href="/host/{{s.host.host_name}}">{{s.host.host_name}}</a></span>
						</td>
						<td>
							<span><a href="/service/{{s.host.host_name}}/{{s.get_name()}}">{{s.get_name()}}</a></span>
						</td>

						<td style="white-space: normal">
							<span>{{s.output}}</span>
						</td>
						<td>{{helper.print_duration(s.last_chk)}}</td>
						<td>{{s.get_duration()}}</td>
						<td>{{s.attempt}}/{{s.max_check_attempts}}</td>
						<td><span class="{{s.state.lower()}}">{{s.state}}</span></td>	
					</tr>
				%end
			</tbody>
		</table>
	</div>

	<div class='col-lg-12'>
		%include pagination_element navi=navi, app=app, page="servicegroup/"+groupname, div_class="center no-margin"
	</div>
</div>
