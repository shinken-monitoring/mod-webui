%services = []
%for s in app.datamgr.get_services(user):
	%if not s.get_name() in services:
		%services.append(s.get_name())
	%end
%end
%# Now services contains a list of unique service identifiers ...

<div class="modal-dialog">
	<div class="modal-content">
		<div class="modal-header">
			<a class="close" data-dismiss="modal">×</a>
			<h3>Selected services list</h3>
		</div>

		<div class="modal-body">
			<form class="well" name="services_selection" action="/logs/set_services_list" method="post">
				<div class="form-group">
					<select id="services_list_select" name="servicesList[]" class="multiselect" multiple="multiple">
						%for s in services:
						%if s in params['logs_services']:
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
	$('#services_list_select').multiselect({
		maxHeight: 400,
		buttonWidth: '500px',
		includeSelectAllOption: true,
		enableFiltering: true
    });
</script>
