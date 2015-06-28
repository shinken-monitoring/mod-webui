%rebase("layout", css=['groups/css/groups-overview.css'], title='Hosts groups overview', refresh=True)

%helper = app.helper
%hosts = app.get_hosts(user)
%h = helper.get_synthesis(hosts)['hosts']


<div id="hostsgroups">
   <!-- Progress bar -->
   <div class="panel panel-default">
      <div class="panel-body">
         <div class="pull-left col-sm-2">
            <span class="pull-right">Total hosts: {{h['nb_elts']}}</span>
         </div>
         <div class="pull-left progress col-sm-10 no-leftpadding no-rightpadding">
            <div title="{{h['nb_up']}} hosts Up" class="progress-bar progress-bar-success quickinfo" role="progressbar" 
               data-toggle="tooltip" data-placement="bottom" 
               style="width: {{h['pct_up']}}%;">{{h['pct_up']}}% Up</div>

            <div title="{{h['nb_down']}} hosts Down" class="progress-bar progress-bar-danger quickinfo" 
               data-toggle="tooltip" data-placement="bottom" 
               style="width: {{h['pct_down']}}%;">{{h['pct_down']}}% Down</div>

            <div title="{{h['nb_unreachable']}} hosts Unreachable" class="progress-bar progress-bar-warning quickinfo" 
               data-toggle="tooltip" data-placement="bottom" 
               style="width: {{h['pct_unreachable']}}%;">{{h['pct_unreachable']}}% Unreachable</div>

            <div title="{{h['nb_pending']}} hosts Pending" class="progress-bar progress-bar-info quickinfo" 
               data-toggle="tooltip" data-placement="bottom" 
               style="width: {{h['pct_pending']}}%;">{{h['pct_pending']}}% Pending</div>

            <div title="{{h['nb_unknown']}} hosts Unknown" class="progress-bar progress-bar-info quickinfo" 
               data-toggle="tooltip" data-placement="bottom" 
               style="width: {{h['pct_unknown']}}%;">{{h['pct_unknown']}}% Unknown</div>
         </div>
      </div>
   </div>

   <!-- Groups list -->
   <ul id="groups" class="list-group">
      %even='alt'
      %if level==0:
         %nHosts=h['nb_elts']
         %nGroups=len(hostgroups)
         <li class="all_groups list-group-item clearfix {{even}} {{'alert-danger' if h['nb_elts'] == h['nb_down'] and h['nb_elts'] != 0 else ''}}">
            <section class="left">
               <h3>
                  <a role="menuitem" href="/all?search=type:host"><i class="fa fa-angle-double-down"></i>
                     All hosts {{!helper.get_business_impact_text(h['bi'])}}
                  </a>
               </h3>
               <div>
                  %for state in 'up', 'unreachable', 'down', 'pending':
                  <span class="{{'font-' + state if h['nb_' + state] > 0 else 'font-greyed'}}">
                    %label = "%s <i>(%s%%)</i>" % (h['nb_' + state], h['pct_' + state])
                    {{!helper.get_fa_icon_state_and_label(cls='host', state=state, label=label)}}
                  </span>
                  %end
               </div>
               <div>
                  %for state in 'unknown', 'ack', 'downtime':
                  <span class="{{'font-' + state if h['nb_' + state] > 0 else 'font-greyed'}}">
                    %label = "%s <i>(%s%%)</i>" % (h['nb_' + state], h['pct_' + state])
                    {{!helper.get_fa_icon_state_and_label(cls='host', state=state, label=label)}}
                  </span>
                  %end
               </div>
            </section>
            
            <section class="right">
               <div class="btn-group btn-group-justified" role="group" aria-label="Minemap">
                  <a class="btn btn-default" href="/minemap?search=type:host"><i class="fa fa-table"></i> Minemap</a>
               </div>
               
               <ul class="list-group">
                  <li class="list-group-item">&nbsp;</li>
                  <li class="list-group-item"><span class="badge">{{h['nb_elts']}}</span>Hosts</li>
                  <li class="list-group-item"><span class="badge">{{nGroups}}</span>Groups</li>
               </ul>
            </section>
         </li>
      %end
    
      %even='alt'
      %for group in hostgroups:
         %if group.has('level')and group.level != level:
         %continue
         %end
         
         %hosts = app.search_hosts_and_services('type:host hg:'+group.get_name(), user, hosts_only=True)
         %h = helper.get_synthesis(hosts)['hosts']
         %if even =='':
           %even='alt'
         %else:
           %even=''
         %end

         %nHosts=h['nb_elts']
         %nGroups=len(group.get_hostgroup_members())
         %# Filter empty groups ?
         %#if nHosts > 0 or nGroups > 0:
         <li class="group list-group-item clearfix {{'alert-danger' if h['nb_elts'] == h['nb_down'] and h['nb_elts'] != 0 else ''}} {{even}}">
            <section class="left">
               <h3>
                  <a role="menuitem" href="/all?search=type:host hg:{{group.get_name()}}"><i class="fa fa-angle-double-down"></i>
                     {{group.alias if group.alias != '' else group.get_name()}} {{!helper.get_business_impact_text(h['bi'])}}</h3>
                  </a>
               <div>
                  %for state in 'up', 'unreachable', 'down', 'pending':
                  <span class="{{'font-' + state if h['nb_' + state] > 0 else 'font-greyed'}}">
                    %label = "%s <i>(%s%%)</i>" % (h['nb_' + state], h['pct_' + state])
                    {{!helper.get_fa_icon_state_and_label(cls='host', state=state, label=label)}}
                  </span>
                  %end
               </div>
               <div>
                  %for state in 'unknown', 'ack', 'downtime':
                  <span class="{{'font-' + state if h['nb_' + state] > 0 else 'font-greyed'}}">
                    %label = "%s <i>(%s%%)</i>" % (h['nb_' + state], h['pct_' + state])
                    {{!helper.get_fa_icon_state_and_label(cls='host', state=state, label=label)}}
                  </span>
                  %end
               </div>
            </section>
          
            <section class="right">
               <div class="btn-group btn-group-justified" role="group" aria-label="Minemap">
                  <a class="btn btn-default" href="/minemap?search=type:host hg:{{group.get_name()}}"><i class="fa fa-table"></i> Minemap</a>
               </div>
               
               <ul class="list-group">
                  <li class="list-group-item">
                  %if nGroups > 0:
                  <a class="text-left" role="menuitem" href="hosts-groups?level={{int(level+1)}}&parent={{group.get_name()}}"><i class="fa fa-level-down"></i>
                  Down
                  </a>
                  %else:
                  &nbsp;
                  %end
                  
                  %if group.has('level') and group.level > 0:
                  <a class="text-right" role="menuitem" href="hosts-groups?level={{int(level-1)}}"><i class="fa fa-level-up"></i>
                  Up
                  </a>
                  %else:
                  &nbsp;
                  %end
                  </li>
                  <li class="list-group-item"><span class="badge">{{h['nb_elts']}}</span>Hosts</li>
                  <li class="list-group-item"><span class="badge">{{nGroups}}</span>Groups</li>
               </ul>
<!--
               <div class="dropdown form-group text-right">
                  <button type="button" class="btn btn-default btn-xs dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
                     Views <span class="caret"></span>
                  </button>
                  <ul class="dropdown-menu" role="menu" aria-labelledby="group_actions">
                     <li role="presentation"><a role="menuitem" href="/all?search=type:host hg:{{group.get_name()}}"><i class="fa fa-angle-double-down"></i> Details</a></li>
                     <li role="presentation"><a role="menuitem" href="/minemap?search=type:host hg:{{group.get_name()}}"><i class="fa fa-table"></i> Minemap</a></li>
                  </ul>
               </div>
-->
            </section>
         </li>
         %#end
      %end
   </ul>
</div>
