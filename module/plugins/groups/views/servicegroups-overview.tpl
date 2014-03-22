%rebase layout globals(), css=['groups/css/groups-overview.css'], js=['groups/js/groups-overview.js'], title='Services groups overview', menu_part='', refresh=True

%helper = app.helper
%datamgr = app.datamgr

<div id="content_container">
	<div class="row">
		<h3 class="col-lg-10 no-topmargin">Services groups overview</h3>
		<span class="col-lg-2 btn-group">
			<a href="#" id="listview" class="btn btn-small switcher quickinfo pull-right" data-original-title='List'> <i class="icon-align-justify"></i> </a>
			<a href="#" id="gridview" class="btn btn-small switcher active quickinfo pull-right" data-original-title='Grid'> <i class="icon-th"></i> </a>
		</span>
	</div>

	<ul id="groups" class="grid row">
		%even=''
		%nServices=0
		%sOk=0
		%sCritical=0
		%sWarning=0
		%sPenging=0
		%for h in datamgr.get_services():
			%nServices=nServices+1
			%if h.state == 'OK':
				%sOk=sOk+1
			%elif h.state == 'CRITICAL':
				%sCritical=sCritical+1
			%elif h.state == 'WARNING':
				%sWarning=sWarning+1
			%else:
				%sPenging=sPenging+1
			%end
		%end
		<li class="clearfix {{even}}">
			<section class="left">
				<h3>All services</h3>
				<span class="meta">
					<span class="icon-stack font-green"> <i class="icon-circle-blank icon-stack-base"></i> <i class="icon-ok"></i></span> <span class="num">{{sOk}}</span>
					&nbsp; <span class="icon-stack font-orange"> <i class="icon-circle-blank icon-stack-base"></i> <i class="icon-exclamation"></i></span> <span class="num">{{sWarning}}</span>
					&nbsp; <span class="icon-stack font-red"> <i class="icon-circle-blank icon-stack-base"></i> <i class="icon-arrow-down"></i></span> <span class="num">{{sCritical}}</span>
					&nbsp; <span class="icon-stack"> <i class="icon-circle-blank icon-stack-base"></i> <i class="icon-question"></i></span> <span class="num">{{sPenging}}</span>
				</span>
				<span class="meta"> <span class="label label-important pulsate">Business impact</span> </span>
			</section>
			
			<section class="right">
				<span class="sum">{{nServices}} services</span>
				<span class="darkview">
				<a href="/servicegroup/all" class="firstbtn"><i class="icon-zoom-in"></i> Details</a>
				<a href="/minemap/all" class="firstbtn"><i class="icon-cogs"></i> Minemap</a>
				</span>
			</section>
		</li>

		%even='alt'
		%for group in sgroups:
			%if even =='':
				%even='alt'
			%else:
				%even=''
			%end

			%nServices=0
			%sOk=0
			%sCritical=0
			%sWarning=0
			%sPenging=0 # Pending / unknown
			%business_impact = 0
			%for h in group.get_services():
				%business_impact = max(business_impact, h.business_impact)
				%nServices=nServices+1
				%if h.state == 'OK':
					%sOk=sOk+1
				%elif h.state == 'CRITICAL':
					%sCritical=sCritical+1
				%elif h.state == 'WARNING':
					%sWarning=sWarning+1
				%else:
					%sPenging=sPenging+1
				%end
			%end
			<li class="clearfix {{even}}">
				<section class="left">
					<h3>{{group.get_name()}}
						%for i in range(0, business_impact-2):
						<img alt="icon state" src="/static/images/star.png">
						%end
					</h3>
					<span class="meta">
						<span class="icon-stack font-green"> <i class="icon-circle-blank icon-stack-base"></i> <i class="icon-ok"></i></span> <span class="num">{{sOk}}</span>
						&nbsp; <span class="icon-stack font-orange"> <i class="icon-circle-blank icon-stack-base"></i> <i class="icon-exclamation"></i></span> <span class="num">{{sWarning}}</span>
						&nbsp; <span class="icon-stack font-red"> <i class="icon-circle-blank icon-stack-base"></i> <i class="icon-arrow-down"></i></span> <span class="num">{{sCritical}}</span>
						&nbsp; <span class="icon-stack"> <i class="icon-circle-blank icon-stack-base"></i> <i class="icon-question"></i></span> <span class="num">{{sPenging}}</span>
					</span>
					<span class="meta"> <span class="label label-important pulsate">Business impact</span> </span>
				</section>
				
				<section class="right">
					<span class="sum">{{nServices}} services</span>
					<span class="darkview">
					<a href="/servicegroup/{{group.get_name()}}" class="firstbtn"><i class="icon-zoom-in"></i> Details</a>
					<a href="/minemap/{{group.get_name()}}" class="firstbtn"><i class="icon-cogs"></i> Minemap</a>
					</span>
				</section>
			</li>
		%end
	</ul>
</div>