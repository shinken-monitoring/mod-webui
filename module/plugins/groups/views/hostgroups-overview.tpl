%rebase layout globals(), css=['groups/css/groups-overview.css'], js=['groups/js/groups-overview.js'], title='Hosts groups overview', menu_part='', refresh=True

%helper = app.helper
%datamgr = app.datamgr

<div id="content_container">
	<div class="row">
		<h3 class="col-lg-10 no-topmargin">Hosts groups overview</h3>
		<span class="col-lg-2 btn-group">
			<a href="#" id="listview" class="btn btn-small switcher quickinfo pull-right" data-original-title='List'> <i class="icon-align-justify"></i> </a>
			<a href="#" id="gridview" class="btn btn-small switcher active quickinfo pull-right" data-original-title='Grid'> <i class="icon-th"></i> </a>
		</span>
	</div>

	<ul id="groups" class="grid row">
		%even=''
		%nHosts=0
		%hUp=0
		%hDown=0
		%hUnreachable=0
		%hPending=0 # Pending / unknown
		%for h in datamgr.get_hosts():
			%nHosts=nHosts+1
			%if h.state == 'UP':
				%hUp=hUp+1
			%elif h.state == 'DOWN':
				%hDown=hDown+1
			%elif h.state == 'UNREACHABLE':
				%hUnreachable=hUnreachable+1
			%else:
				%hPending=hPending+1
			%end
		%end
		<li class="clearfix {{even}}">
			<section class="left">
				<h3>All hosts</h3>
				<span class="meta">
					<span class="icon-stack font-green"> <i class="icon-circle-blank icon-stack-base"></i> <i class="icon-ok"></i></span> <span class="num">{{hUp}}</span>
					&nbsp; <span class="icon-stack font-orange"> <i class="icon-circle-blank icon-stack-base"></i> <i class="icon-exclamation"></i></span> <span class="num">{{hUnreachable}}</span>
					&nbsp; <span class="icon-stack font-red"> <i class="icon-circle-blank icon-stack-base"></i> <i class="icon-arrow-down"></i></span> <span class="num">{{hDown}}</span>
					&nbsp; <span class="icon-stack"> <i class="icon-circle-blank icon-stack-base"></i> <i class="icon-question"></i></span> <span class="num">{{hPending}}</span>
				</span>
				<span class="meta"> <span class="label label-important pulsate">Business impact</span> </span>
			</section>
			
			<section class="right">
				<span class="hostsum">{{nHosts}} hosts</span>
				<span class="darkview">
				<a href="/hostgroup/all" class="firstbtn"><i class="icon-zoom-in"></i> Details</a>
				<a href="/minemap/all" class="firstbtn"><i class="icon-cogs"></i> Minemap</a>
				</span>
			</section>
		</li>

		%even='alt'
		%for group in hgroups:
			%if even =='':
				%even='alt'
			%else:
				%even=''
			%end

			%nHosts=0
			%hUp=0
			%hDown=0
			%hUnreachable=0
			%hPending=0
			%for h in group.get_hosts():
				%nHosts=nHosts+1
				%if h.state == 'UP':
					%hUp=hUp+1
				%elif h.state == 'DOWN':
					%hDown=hDown+1
				%elif h.state == 'UNREACHABLE':
					%hUnreachable=hUnreachable+1
				%else:
					%hPending=hPending+1
				%end
			%end
			<li class="clearfix {{even}}">
				<section class="left">
					<h3>{{group.get_name()}}</h3>
					<span class="meta">
						<span class="icon-stack font-green"> <i class="icon-circle-blank icon-stack-base"></i> <i class="icon-ok"></i></span> <span class="num">{{hUp}}</span>
						&nbsp; <span class="icon-stack font-orange"> <i class="icon-circle-blank icon-stack-base"></i> <i class="icon-exclamation"></i></span> <span class="num">{{hUnreachable}}</span>
						&nbsp; <span class="icon-stack font-red"> <i class="icon-circle-blank icon-stack-base"></i> <i class="icon-arrow-down"></i></span> <span class="num">{{hDown}}</span>
						&nbsp; <span class="icon-stack"> <i class="icon-circle-blank icon-stack-base"></i> <i class="icon-question"></i></span> <span class="num">{{hPending}}</span>
					</span>
					<span class="meta"> <span class="label label-important pulsate">Business impact</span> </span>
				</section>
				
				<section class="right">
					<span class="hostsum">{{nHosts}} hosts</span>
					<span class="darkview">
					<a href="/hostgroup/{{group.get_name()}}" class="firstbtn"><i class="icon-zoom-in"></i> Details</a>
					<a href="/minemap/{{group.get_name()}}" class="firstbtn"><i class="icon-cogs"></i> Minemap</a>
					</span>
				</section>
			</li>
		%end
	</ul>
</div>