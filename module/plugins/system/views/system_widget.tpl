%helper = app.helper

%rebase widget globals()

%types = [ ('scheduler', schedulers), ('poller', pollers), ('broker', brokers), ('reactionner', reactionners), ('receiver', receivers)]

<table class="table table-condensed no-bottommargin topmmargin">
	
	<th class="no-border">Name</th>
	<th class="no-border">Alive</th>
	<th class="no-border">Attempts</th>
	<th class="no-border">Last check</th>
	<th class="no-border">Realm</th>

	%for (sat_type, sats) in types:
		%for s in sats:
		<tr>
			<td> {{s.get_name()}}</td>
			<td> 
				<div class="medium-pulse aroundpulse">
				%# " We put a 'pulse' around the elements if it's an important one "
				%if not s.alive:
					<span class="medium-pulse pulse"></span>
				%end
					<img class="medium-pulse" src="{{helper.get_icon_state(s)}}" />
				</div>
			</td>
			<td> {{s.attempt}}/{{s.max_check_attempts}}</td>
			<td title='{{helper.print_date(s.last_check)}}'>{{helper.print_duration(s.last_check, just_duration=True, x_elts=2)}}</td>
			<td>{{s.realm}}</td>
		</tr>
		%# End of this satellite
		%end
	%end
</table>