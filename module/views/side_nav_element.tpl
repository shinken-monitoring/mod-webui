%if not 'app' in locals(): app = None
%if not 'user' in locals(): user = None
%username = 'anonymous'
%if user is not None: 
%if hasattr(user, 'alias'):
%	username = user.alias
%else:
%	username = user.get_name()
%end
%end

<div class="snap-drawers">
	<div class="snap-drawer snap-drawer-left">
		<div>
			<h3>Shinken</h3>
			<ul>
				<li><i class="cursor icon-dashboard"></i>		<a href="/dashboard">Dashboard</a></li>
				<li><i class="cursor icon-bolt"></i>			<a href="/impacts">Impacts</a></li>
				<li><i class="cursor icon-sitemap"></i>			<a href="/hostgroups">Hosts groups</a></li>
				<li><i class="cursor icon-sitemap"></i>			<a href="/servicegroups">Services groups</a></li>
				<li><i class="cursor icon-table"></i>			<a href="/minemaps">Minemap</a></li>
				<li><i class="cursor icon-compass"></i>			<a href="/worldmap">Worldmap</a></li>
				<li><i class="cursor icon-th-large"></i>		<a href="/wall">Wall</a></li>
				<li><i class="cursor icon-gears"></i>			<a href="/system">System</a></li>
				<li><i class="cursor icon-list"></i>			<a href="/system/logs">Logs</a></li>
			</ul>
		</div>
		<div style="position: absolute; bottom: 2px; width: 100%;">
			<h4>{{username.capitalize()}}</h4>
			<ul>
				<li><i class="cursor icon-cogs"></i>			<a class="disabled" href="/config">Configuration</a></li>
				<li><i class="cursor icon-pencil"></i>			<a class="disabled" href="/profile">Profile</a></li>
				<li><i class="cursor icon-external-link"></i>	<a href="http://www.shinken-monitoring.org/wiki/">Help</a></li>
				<li><i class="cursor icon-signout"></i>			<a class="btn-danger" href="/user/logout">Logout</a></li>
			</ul>
		</div>


		<!--
		<div class="opt" style="position: absolute; bottom: 2px;">
			<ul class="nav nav-pills">
				<li><a href="/system/logs"><i class="icon-rocket"></i></a></li>
				<li class="dropup">
					<a class="dropdown-toggle" data-toggle="dropdown" href="#">
						<i class="icon-random"></i> <span class="caret"></span>
					</a>
					<ul class="dropdown-menu">
						<li><a href=":7767">Shinken UI </a></li>
						%if app:
						%other_uis = app.get_external_ui_link()
						%if len(other_uis) > 0:
						<li class="divider"></li>
						%end
						%for c in other_uis:
						<li><a href="{{c['uri']}}">{{c['label']}}</a></li>
						%end
						%end
					</ul>
				</li>
				<li class="dropup">
					<a class="dropdown-toggle" data-toggle="dropdown" href="#">
						<i class="icon-cogs"></i> <span class="caret"></span>
					</a>
					<ul class="dropdown-menu">
						<li> <a class="disabled-link" href="#"><i class="icon-pencil"></i> Edit profile</a> </li>
						<li> <a class="" href="http://www.shinken-monitoring.org/wiki/"><i class="icon-external-link"></i> Help</a></li>
						<li> <i class="icon-github"></i> icon-github</li>
					</ul>
				</li>
				<li><a href="/user/logout" data-original-title='Logout'><i class="icon-signout font-red"></i></a></li>
			</ul>
		</div>
		-->
	</div>
</div>
