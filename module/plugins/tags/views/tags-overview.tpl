%rebase layout globals(), css=['tags/css/tags-overview.css'], js=['tags/js/tags-overview.js'], title='Hosts tags overview', menu_part='', refresh=True

<div id="content_container">
	<div class="row">
		<h3 class="col-lg-10 no-topmargin">Hosts tags overview</h3>
		<span class="col-lg-2 btn-group">
			<a href="#" id="listview" class="btn btn-small switcher quickinfo pull-right" data-original-title='List'> <i class="icon-align-justify"></i> </a>
			<a href="#" id="gridview" class="btn btn-small switcher active quickinfo pull-right" data-original-title='Grid'> <i class="icon-th"></i> </a>
		</span>
	</div>

	<ul id="groups" class="grid row">
		%for tag in htags:
			%nHosts=0
			%hUp=0
			%hDown=0
			%hUnreachable=0
			%hPending=0
			%business_impact = 0
			%hosts = app.datamgr.get_hosts_tagged_with(tag[0])
			%for h in hosts:
				%business_impact = max(business_impact, h.business_impact)
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
			<li class="clearfix">
				<section class="left">
					<h3>{{tag[0]}}
						%for i in range(0, business_impact-2):
						<img alt="icon state" src="/static/images/star.png">
						%end
					</h3>
					<span class="meta">
						<span class="icon-stack font-green"> <i class="icon-circle-blank icon-stack-base"></i> <i class="icon-ok"></i></span><span>{{hUp}}</span>
						&nbsp; <span class="icon-stack font-orange"> <i class="icon-circle-blank icon-stack-base"></i> <i class="icon-exclamation"></i></span><span>{{hUnreachable}}</span>
						&nbsp; <span class="icon-stack font-red"> <i class="icon-circle-blank icon-stack-base"></i> <i class="icon-arrow-down"></i></span><span>{{hDown}}</span>
						&nbsp; <span class="icon-stack"> <i class="icon-circle-blank icon-stack-base"></i> <i class="icon-question"></i></span><span>{{hPending}}</span>
					</span>
				</section>
				
				<section class="right">
					<span class="sum">{{nHosts}} element(s)</span>
					<span class="darkview">
					<a href="/tag/{{tag[0]}}" class="firstbtn"><i class="icon-zoom-in"></i> Details</a>
					</span>
				</section>
			</li>
		%end
	</ul>
</div>