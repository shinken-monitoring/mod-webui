%rebase("layout", css=['tags/css/tags-overview.css'], js=['tags/js/tags-overview.js'], title='Services tags overview')

<div class="row">
  <span class="btn-group pull-right">
    <a href="#" id="listview" class="btn btn-small switcher quickinfo pull-right" data-original-title='List'> <i class="fa fa-align-justify"></i> </a>
    <a href="#" id="gridview" class="btn btn-small switcher active quickinfo pull-right" data-original-title='Grid'> <i class="fa fa-th"></i> </a>
  </span>
</div>

<div class="row">
	<ul id="groups" class="grid row">
		%for tag in stags:
			%nServices=0
			%sOk=0
			%sCritical=0
			%sWarning=0
			%sPending=0
			%business_impact = 0
			%for s in tag['services']:
				%business_impact = max(business_impact, s.business_impact)
				%nServices=nServices+1
				%if s.state == 'OK':
					%sOk=sOk+1
				%elif s.state == 'CRITICAL':
					%sCritical=sCritical+1
				%elif s.state == 'WARNING':
					%sWarning=sWarning+1
				%else:
					%sPending=sPending+1
				%end
			%end
			<li class="clearfix">
				<section class="left">
					<h3>{{tag['name']}}
						%for i in range(0, business_impact-2):
						<img alt="icon state" src="/static/images/star.png">
						%end
					</h3>
          <span class="meta">
            <span class="fa-stack font-ok"> <i class="fa fa-circle fa-stack-2x"></i> <i class="fa fa-check fa-stack-1x fa-inverse"></i></span> 
            <span class="num">
              %if sOk > 0:
              {{sOk}}
              %else:
              <em>{{sOk}}</em>
              %end
            </span>
            <span class="fa-stack font-warning"> <i class="fa fa-circle fa-stack-2x"></i> <i class="fa fa-exclamation fa-stack-1x fa-inverse"></i></span> 
            <span class="num">
              %if sWarning > 0:
              {{sWarning}}
              %else:
              <em>{{sWarning}}</em>
              %end
            </span>
            <span class="fa-stack font-critical"> <i class="fa fa-circle fa-stack-2x"></i> <i class="fa fa-arrow-down fa-stack-1x fa-inverse"></i></span> 
            <span class="num">
              %if sCritical > 0:
              {{sCritical}}
              %else:
              <em>{{sCritical}}</em>
              %end
            </span> 
            <span class="fa-stack font-unknown"> <i class="fa fa-circle fa-stack-2x"></i> <i class="fa fa-question fa-stack-1x fa-inverse"></i></span> 
            <span class="num">
              %if sPending > 0:
              {{sPending}}
              %else:
              <em>{{sPending}}</em>
              %end
            </span>
          </span>
				</section>
				
				<section class="right">
					%if nServices == 1:
					<span class="sum">{{nServices}} element</span>
					%else:
					<span class="sum">{{nServices}} elements</span>
					%end
					<span class="darkview">
					<a href="/services-tag/{{tag['name']}}" class="firstbtn"><i class="fa fa-angle-double-down"></i> Details</a>
					</span>
				</section>
			</li>
		%end
	</ul>
</div>
