%if 'app' not in locals(): app = None

<!-- Fixed navbar -->
<div id="toolbar" class="navbar navbar-inverse navbar-fixed-top">
	<div class="container" style="margin-left:0; padding-left: 0; padding-right: 0;">
		<div id="ol" class="col-sm-8" style="font-size: 20px; margin-top: 10px;"><i class="icon-align-justify font-darkgrey"></i> </div>
		<ul class="nav navbar-nav col-sm-4">
			<li class="dropdown pull-right">
				<a href="#" class="dropdown-toggle" data-toggle="dropdown">Hi {{user.get_name().capitalize()}} <b class="caret"></b></a>
				<ul class="dropdown-menu">
					<li> <a class="disabled-link" href="#"><i class="icon-pencil"></i> Edit profile</a> </li>
					<li> <a class="" href="http://www.shinken-monitoring.org/wiki/"><i class="icon-external-link"></i> Help</a></li>
					<li class="divider"></li>
					<li> <a href="/user/logout" data-original-title='Logout'><i class="icon-off"></i> Logout</a></li>
				</ul>
			</li>
			<li class="divider-vertical"></li>
			%# Check for the selected element, if there is one
			%if menu_part == '/dashboard':
			<li class="pull-right"><a class="quickinfo" data-original-title='Currently' href="/dashboard/currently"><i class="nav-icon icon-fullscreen"></i></a></li>
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
