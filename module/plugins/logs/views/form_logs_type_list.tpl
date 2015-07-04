%logs_types = [ 'INFO', 'WARNING', 'ERROR', 'CURRENT SERVICE STATE', 'INITIAL SERVICE STATE', 'SERVICE ALERT', 'SERVICE DOWNTIME ALERT', 'SERVICE FLAPPING ALERT', 'CURRENT HOST STATE', 'INITIAL HOST STATE', 'HOST ALERT', 'HOST DOWNTIME ALERT', 'HOST FLAPPING ALERT', 'SERVICE NOTIFICATION', 'HOST NOTIFICATION', 'PASSIVE SERVICE CHECK', 'PASSIVE HOST CHECK', 'SERVICE EVENT HANDLER', 'HOST EVENT HANDLER', 'EXTERNAL COMMAND']

<div class="modal-dialog">
	<div class="modal-content">
		<div class="modal-header">
			<a class="close" data-dismiss="modal">×</a>
			<h3>Logs type list</h3>
		</div>

		<div class="modal-body">
			<form class="well" name="hosts_selection" action="/logs/set_logs_type_list" method="post">
				<div class="form-group">
					<select id="hosts_list_select" name="logs_typeList[]" class="multiselect" multiple="multiple">
						%for s in logs_types:
						%if s in params['logs_type']:
							<option value="{{s}}" selected="selected">{{s}}</option>
						%else:
							<option value="{{s}}">{{s}}</option>
						%end
						%end
					</select>
				</div>
				
				<div class="form-group">
					<button class="btn btn-primary" type="submit" name="setList" value="setList" ><i class="glyphicon glyphicon-cog"></i> Configure</button>
					<button class="btn" type="submit" name="cancel" value="cancel"><i class="glyphicon glyphicon-remove"></i> Cancel</button>
				</div>
			</form>
		</div>
	</div>
</div>

<script type="text/javascript">
	$('#hosts_list_select').multiselect({
		maxHeight: 400,
		buttonWidth: '500px',
		includeSelectAllOption: true,
		enableFiltering: true
    });
</script>
