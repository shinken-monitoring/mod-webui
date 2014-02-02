%if 'app' not in locals(): app = None

<!-- Fixed navbar -->
<div id="toolbar" class="navbar navbar-inverse navbar-fixed-top">
	<div class="container" style="margin-left:0; padding-left: 0; padding-right: 0;">
		<div id="ol" class="col-sm-1" style="font-size: 20px; margin-top: 10px;"><i class="icon-align-justify font-darkgrey"></i> </div>
		<ol class="col-sm-7 breadcrumb">
			<li><a href="/">Home</a></li>
			<li class="active">{{title or 'No title'}}</li>
		</ol>

		<ul class="nav navbar-nav col-sm-4">
			%# Check for the selected element, if there is one
			%if menu_part == '/dashboard':
			<li class="pull-right"><a class="quickinfo" data-original-title='Currently' href="/dashboard/currently"><i class="icon-fullscreen"></i></a></li>
			%else:
			<li></li>
			%end

			%if app:
			%overall_itproblem = app.datamgr.get_overall_it_state()
			%if overall_itproblem == 0:
			<li class="pull-right"><a href="/problems" class="quickinfo" data-original-title='IT Problems'><i class="icon-ambulance"></i><span class="pulsate badger badger-ok">OK!</span> </a></li>
			%elif overall_itproblem == 1:
			<li class="pull-right"><a href="/problems" class="quickinfo" data-original-title='IT Problems'><i class="icon-ambulance"></i><span class="pulsate badger badger-warning">{{app.datamgr.get_nb_all_problems(app.get_user_auth())}}</span> </a></li>
			%elif overall_itproblem == 2:
			<li class="pull-right"><a href="/problems" class="quickinfo" data-original-title='IT Problems'><i class="icon-ambulance"></i><span class="pulsate badger badger-critical">{{app.datamgr.get_nb_all_problems(app.get_user_auth())}}</span> </a></li>
			%end
			%end

			%if app:
			%overall_state = app.datamgr.get_overall_state()
			%if overall_state == 2:
			<li class="pull-right"><a href="/impacts" class="quickinfo" data-original-title='Impacts'><i class="icon-impact"></i><span class="pulsate badger badger-critical">{{app.datamgr.get_len_overall_state()}}</span> </a></li>
			%elif overall_state == 1:
			<li class="pull-right"><a href="/impacts" class="quickinfo" data-original-title='Impacts'><i class="icon-impact"></i><span class="pulsate badger badger-warning">{{app.datamgr.get_len_overall_state()}}</span> </a></li>
			%end
			%end
		</ul>
	</div>
</div>
