%# If got no group, bailout
%if not group:
%rebase layout title='Invalid name'

Invalid element name

%else:

%helper = app.helper
%datamgr = app.datamgr

%elt_type = group.__class__.my_type

%nHosts=0
%hUp=0
%hDown=0
%hUnreachable=0
%hPending=0
%for h in group.get_hosts():
	%nHosts=nHosts+1
	%if h.state == 'UP':
		%hUp=hUp+1
	%end
	%if h.state == 'DOWN':
		%hDown=hDown+1
	%end
	%if h.state == 'UNREACHABLE':
		%hUnreachable=hUnreachable+1
	%end
	%if h.state == 'PENDING':
		%hPending=hPending+1
	%end
%end
%if nHosts != 0:
	%pctUp=100 * hUp / nHosts
	%pctDown=100 * hDown / nHosts
	%pctUnreachable=100 * hUnreachable / nHosts
	%pctPending=100 * hPending / nHosts
%else:
	%pctUp=0
	%pctDown=0
	%pctUnreachable=0
	%pctPending=0
%end

%end

%rebase layout globals(), title=elt_type.capitalize() + ' detail about ' + group.get_name(), refresh=True

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

<div class="">

	<div class="panel panel-default">
		<div class="panel-heading">
			<h3 class="panel-title">{{group.alias}} / ({{group.get_name()}})</h3>
		</div>
		<div class="panel-body">
			<table class="col-lg-2 leftmargin">
				<tr>
					<td>Members:</td>
					<td>{{nHosts}} hosts</td>
				</tr>
			</table>
			<div class="pull-right progress col-lg-9 no-bottommargin no-leftpadding no-rightpadding" style="height: 45px;">
				<div title="{{pctUp}}% hosts Up" class="progress-bar progress-bar-success quickinfo" role="progressbar" data-original-title='{{pctUp}}% Up' style="width: {{pctUp}}%; vertical-align:midddle; line-height: 45px;">{{pctUp}}% Up</div>
				<div title="{{pctDown}}% hosts Down" class="progress-bar progress-bar-danger quickinfo" data-original-title='{{pctDown}}% Unreachable' style="width: {{pctDown}}%; vertical-align:midddle; line-height: 45px;">{{pctDown}}% Down</div>
				<div title="{{pctUnreachable}}% hosts Unreachable" class="progress-bar progress-bar-warning quickinfo" data-original-title='{{pctUnreachable}}% Down' style="width: {{pctUnreachable}}%; vertical-align:midddle; line-height: 45px;">{{pctUnreachable}}% Unreachable</div>
				<div title="{{pctPending}}% hosts Pending" class="progress-bar progress-bar-info quickinfo" data-original-title='{{pctPending}}% Warning' style="width: {{pctPending}}%; vertical-align:midddle; line-height: 45px;">{{pctPending}}% Pending</div>
			</div>
		</div>
	</div>

	<div>
		<div class='col-lg-12'>
			&nbsp;
			%include pagination_element navi=navi, app=app, page="eltgroup/"+group.get_name(), div_class="center no-margin"
		</div>
	</div>

	<div>
		<div class="clearfix">
			<table class="table table-hover">
				<tbody>
					<tr>
						<th><em>Status</em></th>
						<th>Host</th>
						<!--
						<th><em>Status</em></th>
						-->
						<th>Service</th>
						<th>Last Check</th>
						<th>Duration</th>
						<th>Attempt</th>
						<th>Status Information</th>
					</tr>
%for h in hosts:
					<tr id="host_{{h.get_name()}}" class="{{h.state.lower()}}">
						<td ><em>{{h.state}}</em></td>
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
	</div>

	<div>
		<div class='span12'>
			&nbsp;
			%include pagination_element navi=navi, app=app, page="eltgroup/"+group.get_name(), div_class="center no-margin"
		</div>
	</div>
</div>


<script>
	initialize = function() {
%for h in group.get_hosts():
		var rows = $('table.table tr.service_{{h.get_name()}}');
		
		$('#host_{{h.get_name()}}').click(function() {
			$(".service_{{h.get_name()}}").toggle();
		});

		$('#showWhiteButton').click(function() {
			var white = rows.filter('.white').show();
			rows.not( white ).hide();
		});
%end
	};

	//Ok go initialize the map with all elements when it's loaded
	$(document).ready(initialize);
</script>
