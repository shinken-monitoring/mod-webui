<div class="modal-dialog">
	<div class="modal-content">
		<div class="modal-header">
			<a class="close" data-dismiss="modal">×</a>
			<h3>Selected hosts list</h3>
		</div>

		<div class="modal-body">
			<form class="well" name="hosts_selection" action="/logs/set_hosts_list" method="post">
				<div class="form-group">
					<select id="hosts_list_select" name="hostsList[]" class="multiselect" multiple="multiple">
						%for h in app.datamgr.get_hosts(user):
						%if h.get_name() in params['logs_hosts']:
							<option value="{{h.get_name()}}" selected="selected">{{h.get_name()}} ({{h.state}})</option>
						%else:
							<option value="{{h.get_name()}}">{{h.get_name()}} ({{h.state}})</option>
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
