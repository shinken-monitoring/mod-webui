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
		%for tag in stags:
			%nServices=0
			%hUp=0
			%hDown=0
			%hUnreachable=0
			%hPending=0
			%business_impact = 0
			%services = app.datamgr.get_services_tagged_with(tag[0])
			%for s in services:
				%business_impact = max(business_impact, s.business_impact)
				%nServices=nServices+1
				%if s.state == 'UP':
					%sUp=sUp+1
				%elif s.state == 'CRITICAL':
					%sDown=sDown+1
				%elif s.state == 'UNREACHABLE':
					%sUnreachable=sUnreachable+1
				%else:
					%sPending=sPending+1
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
						<span class="icon-stack font-green"> <i class="icon-circle-blank icon-stack-base"></i> <i class="icon-ok"></i></span><span>{{sUp}}</span>
						&nbsp; <span class="icon-stack font-orange"> <i class="icon-circle-blank icon-stack-base"></i> <i class="icon-exclamation"></i></span><span>{{sUnreachable}}</span>
						&nbsp; <span class="icon-stack font-red"> <i class="icon-circle-blank icon-stack-base"></i> <i class="icon-arrow-down"></i></span><span>{{sCritical}}</span>
						&nbsp; <span class="icon-stack"> <i class="icon-circle-blank icon-stack-base"></i> <i class="icon-question"></i></span><span>{{sPending}}</span>
					</span>
				</section>
				
				<section class="right">
					%if nServices == 1:
					<span class="sum">{{nServices}} element</span>
					%else:
					<span class="sum">{{nservices}} elements</span>
					%end
					<!-- <span class="sum">{{nHosts}} element(s)</span> -->
					<span class="darkview">
					<a href="/tag/{{tag[0]}}" class="firstbtn"><i class="icon-zoom-in"></i> Details</a>
					</span>
				</section>
			</li>
		%end
	</ul>
</div>