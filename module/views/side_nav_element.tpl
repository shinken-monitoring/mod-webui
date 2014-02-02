%if not 'app' in locals(): app = None

<div class="snap-drawers">
	<div class="snap-drawer snap-drawer-left">
		<div>
			<h3>Shinken</h3>
			<ul>
				<li><a href="/dashboard">Dashboard</a></li>
				<li><a href="/impacts">Impacts</a></li>
				<li><a href="/worldmap">Worldmap</a></li>
				<li><a href="/wall">Wall</a></li>
				<li><a href="/system">System</a></li>
			</ul>
		</div>
		<div class="opt" style="position: absolute; bottom: 2px;">
			<ul class="nav nav-pills">
				<li><a href="#"><i class="icon-rocket"></i></a></li>
				<li class="dropup">
					<a class="dropdown-toggle" data-toggle="dropdown" href="#">
						<i class="icon-random"></i> <span class="caret"></span>
					</a>
					<ul class="dropdown-menu">
						<li><a href=":7767">Shinken UI </a></li>
						<!-- We will add also others UIs on the global menu -->
						%if app:
						%other_uis = app.get_external_ui_link()
						<!-- If we add others UIs, we separate them from the inner ones-->
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
	</div>
</div>
