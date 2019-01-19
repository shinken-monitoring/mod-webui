%setdefault('debug', False)

%rebase("layout", title='Hosts groups overview')

%user = app.get_user()
%helper = app.helper
%h = app.datamgr.get_hosts_synthesis(user=user)

%hide_empty = (getattr(app.modconf, 'plugin.hostgroups.hide_empty', '0') == '1')

<div id="hostsgroups">
   <!-- Progress bar -->
   <div class="panel panel-default">
      <div class="panel-body">
         <div class="pull-left col-sm-2 hidden-sm hidden-xs text-center">
            {{h['nb_elts']}} hosts
         </div>
         <div class="progress" style="margin-bottom: 0px;">
            <div title="{{h['nb_up']}} hosts Up" class="progress-bar progress-bar-success quickinfo" role="progressbar"
               data-toggle="tooltip" data-placement="bottom"
               style="width: {{h['pct_up']}}%;">{{h['pct_up']}}% Up</div>

            <div title="{{h['nb_down']}} hosts Down" class="progress-bar progress-bar-danger quickinfo" role="progressbar"
               data-toggle="tooltip" data-placement="bottom"
               style="width: {{h['pct_down']}}%;">{{h['pct_down']}}% Down</div>

            <div title="{{h['nb_unreachable']}} hosts Unreachable" class="progress-bar progress-bar-warning quickinfo" role="progressbar"
               data-toggle="tooltip" data-placement="bottom"
               style="width: {{h['pct_unreachable']}}%;">{{h['pct_unreachable']}}% Unreachable</div>

            <div title="{{h['nb_pending']}} hosts Pending" class="progress-bar progress-bar-info quickinfo" role="progressbar"
               data-toggle="tooltip" data-placement="bottom"
               style="width: {{h['pct_pending']}}%;">{{h['pct_pending']}}% Pending</div>

            <div title="{{h['nb_unknown']}} hosts Unknown" class="progress-bar progress-bar-info quickinfo" role="progressbar"
               data-toggle="tooltip" data-placement="bottom"
               style="width: {{h['pct_unknown']}}%;">{{h['pct_unknown']}}% Unknown</div>
         </div>
      </div>
   </div>

   <!-- Groups list -->
   <ul id="groups" class="list-group">
      %if debug:
         %hosts = app.datamgr.search_hosts_and_services('type:host', user)
         <div>Hosts and their groups (only hosts in groups):<ul>
            %for host in hosts:
            %if host.get_groupnames():
            <li>
            Host: <strong>{{host.get_name()}}</strong> is member of:  {{host.get_groupnames()}}
            </li>
            %end
            %end
         </ul></div>
      %end

      %even='alt'
      %if level==0:
         <li class="all_groups list-group-item clearfix {{even}} {{'alert-danger' if h['nb_elts'] == h['nb_down'] and h['nb_elts'] != 0 else ''}}">
            <h3>
               <a role="menuitem" href="/all?search=type:host">
                  All hosts {{!helper.get_business_impact_text(h['bi'])}}
               </a>

               <span class="btn-group pull-right">
                  <a href="{{app.get_url("HostsGroupsDashboard")}}" class="btn btn-small switcher quickinfo pull-right" data-original-title='List'> <i class="fas fa-align-justify"></i> </a>
               </span>
            </h3>
            <section class="col-md-8 col-sm-6 col-xs-6">
               <div>
                  %for state in 'up', 'unreachable', 'down', 'pending':
                  %if h['nb_' + state] > 0:
                  <a role="menuitem" href="/all?search=type:host is:{{state}}">
                  %end
                  <span class="{{'font-' + state if h['nb_' + state] > 0 else 'font-greyed'}}">
                    %label = "%s <i>(%s%%)</i>" % (h['nb_' + state], h['pct_' + state])
                    {{!helper.get_fa_icon_state_and_label(cls='host', state=state, label=label)}}
                  </span>
                  %if h['nb_' + state] > 0:
                  </a>
                  %end
                  %end
               </div>
               <div>
                  %for state in 'unknown', 'ack', 'downtime':
                  %if h['nb_' + state] > 0:
                  <a role="menuitem" href="/all?search=type:host is:{{state}}">
                  %end
                  <span class="{{'font-' + state if h['nb_' + state] > 0 else 'font-greyed'}}">
                    %label = "%s <i>(%s%%)</i>" % (h['nb_' + state], h['pct_' + state])
                    {{!helper.get_fa_icon_state_and_label(cls='host', state=state, label=label)}}
                  </span>
                  %if h['nb_' + state] > 0:
                  </a>
                  %end
                  %end
               </div>
            </section>


            <section class="col-md-4 col-sm-6 col-xs-6">
               <section class="col-sm-12 col-xs-12">
               </section>

               <section class="col-sm-12 col-xs-12">
                  <div class="btn-group btn-group-justified" role="group" aria-label="Minemap" title="View minemap for all hosts">
                     <a class="btn btn-default" href="/minemap?search=type:host"><i class="fas fa-table"></i> <span class="hidden-xs">Minemap</span></a>
                  </div>

                  <div class="btn-group btn-group-justified" role="group" aria-label="Elements" title="View elements for all hosts">
                     <a class="btn btn-default" href="/all?search=type:host"><i class="fas fa-server"></i> <span class="hidden-xs">Elements</span></a>
                  </div>

                  <ul class="list-group">
                     <li class="list-group-item">
                        {{!'<span class="badge">%s</span>Hosts' % (h['nb_elts']) if h['nb_elts'] else '<small><em>No members</em></small>'}}
                     </li>
                     <li class="list-group-item">
                        {{!'<span class="badge">%s</span>Groups' % (len(hostgroups)) if hostgroups else '<small><em>No sub-groups</em></small>'}}
                     </li>
                  </ul>
               </section>
            </section>
         </li>
      %end

      %even='alt'
      %for group in hostgroups:
         %if group.has('level') and group.level != level:
         %continue
         %end

         %hosts = app.datamgr.search_hosts_and_services('type:host hg:"'+group.get_name()+'"', user)
         %h = app.datamgr.get_hosts_synthesis(hosts, user=user)
         %sub_groups = group.hostgroup_members
         %sub_groups = [] if (sub_groups and not sub_groups[0]) else sub_groups

         %if not hosts and hide_empty:
         %continue
         %end

         %if even =='':
           %even='alt'
         %else:
           %even=''
         %end

         %if not hosts:
         %# Empty group: no hosts
         <li class=" list-group-item clearfix {{even}}">
            <h3>
               %if sub_groups:
               <a class="btn btn-default btn-xs" href="hosts-groups?level={{int(level+1)}}&parent={{group.get_name()}}" title="View contained groups"><i class="fas fa-angle-double-down"></i></a>
               %end

               %if group.has('level') and group.level > 0:
               <a class="btn btn-default btn-xs" href="hosts-groups?level={{int(level-1)}}" title="View parent group"><i class="fas fa-angle-double-up"></i></a>
               %end

               <span>
                  {{group.alias if group.alias != '' else group.get_name()}} {{!helper.get_business_impact_text(h['bi'])}}
               </span>
               <small><em>No members</em></small>
            </h3>
         </li>
         %continue
         %end

         %if debug:
         <div>Group <strong>{{group.get_name()}}</strong>:<ul>
            %for host in hosts:
            <li>
            Host: <strong>{{host.get_name()}}</strong> is a known member
            </li>
            %end
         </ul></div>
         %end

         %#if hosts or sub_groups:
         <li class=" list-group-item clearfix {{'alert-danger' if h['nb_elts'] == h['nb_down'] and h['nb_elts'] else ''}} {{even}}">
            <h3>
               %if sub_groups:
               <a class="btn btn-default btn-xs" href="hosts-groups?level={{int(level+1)}}&parent={{group.get_name()}}" title="View contained groups"><i class="fas fa-angle-double-down"></i></a>
               %end

               %if group.has('level') and group.level > 0:
               <a class="btn btn-default btn-xs" href="hosts-groups?level={{int(level-1)}}" title="View parent group"><i class="fas fa-angle-double-up"></i></a>
               %end

               <a role="menuitem" href="/all?search=type:host hg:{{'"%s"' % group.get_name()}}">
                  {{group.alias if group.alias != '' else group.get_name()}} {{!helper.get_business_impact_text(h['bi'])}}
               </a>
            </h3>
            <section class="col-md-8 col-sm-6 col-xs-6">
               <div>
                  %for state in 'up', 'unreachable', 'down', 'pending':
                  %if h['nb_' + state] > 0:
                  <a role="menuitem" href="/all?search=type:host hg:{{'"%s"' % group.get_name()}} is:{{state}}">
                  %end
                  <span class="{{'font-' + state if h['nb_' + state] > 0 else 'font-greyed'}}">
                    %label = "%s <i>(%s%%)</i>" % (h['nb_' + state], h['pct_' + state])
                    {{!helper.get_fa_icon_state_and_label(cls='host', state=state, label=label)}}
                  </span>
                  %if h['nb_' + state] > 0:
                  </a>
                  %end
                  %end
               </div>
               <div>
                  %for state in 'unknown', 'ack', 'downtime':
                  %if h['nb_' + state] > 0:
                  <a role="menuitem" href="/all?search=type:host hg:{{'"%s"' % group.get_name()}} is:{{state}}">
                  %end
                  <span class="{{'font-' + state if h['nb_' + state] > 0 else 'font-greyed'}}">
                    %label = "%s <i>(%s%%)</i>" % (h['nb_' + state], h['pct_' + state])
                    {{!helper.get_fa_icon_state_and_label(cls='host', state=state, label=label)}}
                  </span>
                  %if h['nb_' + state] > 0:
                  </a>
                  %end
                  %end
               </div>
            </section>

            <section class="col-md-4 col-sm-6 col-xs-6">
               <section class="col-sm-12 col-xs-12">
                  %if group.notes_url:
                  <ul class="list-group">
                     <li class="list-group-item">
                        <strong>Notes:</strong>
                     </li>
                     %for note_url in group.notes_url:
                     <li class="list-group-item">
                        <button class="btn btn-default btn-xs">{{! note_url}}</button>
                     </li>
                     %end
                  </ul>
                  %end
               </section>

               <section class="col-sm-12 col-xs-12">
                  <div class="btn-group btn-group-justified" role="group" aria-label="Minemap" title="View minemap for this group">
                     <a class="btn btn-default" href="/minemap?search=type:host hg:{{'"%s"' % group.get_name()}}"><i class="fas fa-table"></i> <span class="hidden-xs">Minemap</span></a>
                  </div>

                  <div class="btn-group btn-group-justified" role="group" aria-label="Elements" title="View elements for this group">
                     <a class="btn btn-default" href="/all?search=type:host hg:{{'"%s"' % group.get_name()}}"><i class="fas fa-server"></i> <span class="hidden-xs">Elements</span></a>
                  </div>

                  <ul class="list-group">
                     <li class="list-group-item">
                        {{!'<span class="badge">%s</span>Hosts' % (h['nb_elts']) if h['nb_elts'] else '<small><em>No members</em></small>'}}
                     </li>
                     <li class="list-group-item">
                        {{!'<span class="badge">%s</span>Groups' % (len(sub_groups)) if len(sub_groups) else '<small><em>No sub-groups</em></small>'}}
                     </li>
                  </ul>
               </section>
            </section>
         </li>
         %#end
      %end
   </ul>
</div>
