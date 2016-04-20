%setdefault('debug', False)

%rebase("layout", title='Hosts groups overview')

%helper = app.helper
%h = app.datamgr.get_hosts_synthesis()


<div id="hostsgroups">
   <!-- Progress bar -->
   <div class="panel panel-default">
      <div class="panel-body">
         <div class="pull-left col-sm-2">
            <span class="pull-right">Total hosts: {{h['nb_elts']}}</span>
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
         %nHosts=h['nb_elts']
         %nGroups=len(hostgroups)
         <li class="all_groups list-group-item clearfix {{even}} {{'alert-danger' if h['nb_elts'] == h['nb_down'] and h['nb_elts'] != 0 else ''}}">
            <h3>
               <a role="menuitem" href="/all?search=type:host">
                  All hosts {{!helper.get_business_impact_text(h['bi'])}}
               </a>
            </h3>
            <section class="col-md-8 col-sm-6 col-xs-6">
               <div>
                  %for state in 'up', 'unreachable', 'down', 'pending':
                  %if h['nb_' + state]>0:
                  <a role="menuitem" href="/all?search=type:host is:{{state}}">
                  %end
                  <span class="{{'font-' + state if h['nb_' + state] > 0 else 'font-greyed'}}">
                    %label = "%s <i>(%s%%)</i>" % (h['nb_' + state], h['pct_' + state])
                    {{!helper.get_fa_icon_state_and_label(cls='host', state=state, label=label)}}
                  </span>
                  %if h['nb_' + state]>0:
                  </a>
                  %end
                  %end
               </div>
               <div>
                  %for state in 'unknown', 'ack', 'downtime':
                  %if h['nb_' + state]>0:
                  <a role="menuitem" href="/all?search=type:host is:{{state}}">
                  %end
                  <span class="{{'font-' + state if h['nb_' + state] > 0 else 'font-greyed'}}">
                    %label = "%s <i>(%s%%)</i>" % (h['nb_' + state], h['pct_' + state])
                    {{!helper.get_fa_icon_state_and_label(cls='host', state=state, label=label)}}
                  </span>
                  %if h['nb_' + state]>0:
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
                     <a class="btn btn-default" href="/minemap?search=type:host"><i class="fa fa-table"></i> <span class="hidden-xs">Minemap</span></a>
                  </div>

                  <div class="btn-group btn-group-justified" role="group" aria-label="Resources" title="View resources for all hosts">
                     <a class="btn btn-default" href="/all?search=type:host"><i class="fa fa-ambulance"></i> <span class="hidden-xs">Resources</span></a>
                  </div>

                  <ul class="list-group">
                     <li class="list-group-item">
                        {{!'<span class="badge">%s</span>Hosts' % (h['nb_elts']) if h['nb_elts'] else '<small><em>No members</em></small>'}}
                     </li>
                     <li class="list-group-item">
                        {{!'<span class="badge">%s</span>Groups' % (nGroups) if nGroups else '<small><em>No sub-groups</em></small>'}}
                     </li>
                  </ul>
               </section>
            </section>
         </li>
      %end

      %even='alt'
      %for group in hostgroups:
         %if group.has('level')and group.level != level:
         %continue
         %end

         %hosts = app.datamgr.search_hosts_and_services('type:host hg:"'+group.get_name()+'"', user)
         %h = app.datamgr.get_hosts_synthesis(hosts)
         %if debug:
         <div>Group <strong>{{group.get_name()}}</strong>:<ul>
            %for host in hosts:
            <li>
            Host: <strong>{{host.get_name()}}</strong> is a known member
            </li>
            %end
         </ul></div>
         %end

         %if even =='':
           %even='alt'
         %else:
           %even=''
         %end

         %nHosts=h['nb_elts']
         %nGroups=len(group.get_hostgroup_members())
         %# Filter empty groups ?
         %#if nHosts > 0 or nGroups > 0:
         <li class=" list-group-item clearfix {{'alert-danger' if h['nb_elts'] == h['nb_down'] and h['nb_elts'] != 0 else ''}} {{even}}">
            <h3>
               %if nGroups > 0:
               <a class="btn btn-default btn-xs" href="hosts-groups?level={{int(level+1)}}&parent={{group.get_name()}}" title="View contained groups"><i class="fa fa-angle-double-down"></i></a>
               %end

               %if group.has('level') and group.level > 0:
               <a class="btn btn-default btn-xs" href="hosts-groups?level={{int(level-1)}}" title="View parent group"><i class="fa fa-angle-double-up"></i></a>
               %end

               <a role="menuitem" href="/all?search=type:host hg:{{'"%s"' % group.get_name()}}">
                  {{group.alias if group.alias != '' else group.get_name()}} {{!helper.get_business_impact_text(h['bi'])}}
               </a>
            </h3>
            <section class="col-md-8 col-sm-6 col-xs-6">
               <div>
                  %for state in 'up', 'unreachable', 'down', 'pending':
                  %if h['nb_' + state]>0:
                  <a role="menuitem" href="/all?search=type:host hg:'{{'"%s"' % group.get_name()}}' is:{{state}}">
                  %end
                  <span class="{{'font-' + state if h['nb_' + state] > 0 else 'font-greyed'}}">
                    %label = "%s <i>(%s%%)</i>" % (h['nb_' + state], h['pct_' + state])
                    {{!helper.get_fa_icon_state_and_label(cls='host', state=state, label=label)}}
                  </span>
                  %if h['nb_' + state]>0:
                  </a>
                  %end
                  %end
               </div>
               <div>
                  %for state in 'unknown', 'ack', 'downtime':
                  %if h['nb_' + state]>0:
                  <a role="menuitem" href="/all?search=type:host hg:{{'"%s"' % group.get_name()}} is:{{state}}">
                  %end
                  <span class="{{'font-' + state if h['nb_' + state] > 0 else 'font-greyed'}}">
                    %label = "%s <i>(%s%%)</i>" % (h['nb_' + state], h['pct_' + state])
                    {{!helper.get_fa_icon_state_and_label(cls='host', state=state, label=label)}}
                  </span>
                  %if h['nb_' + state]>0:
                  </a>
                  %end
                  %end
               </div>
            </section>

            <section class="col-md-4 col-sm-6 col-xs-6">
               <section class="col-sm-12 col-xs-12">
                  %notes = helper.get_element_notes_url(group, default_title="Comment", default_icon="comment", popover=True)
                  %if len(notes):
                  <ul class="list-group">
                     <li class="list-group-item">
                        <strong>Notes:</strong>
                     </li>
                     %for note_url in notes:
                     <li class="list-group-item">
                        <button class="btn btn-default btn-xs">{{! note_url}}</button>
                     </li>
                     %end
                  </ul>
                  %end
               </section>

               <section class="col-sm-12 col-xs-12">
                  <div class="btn-group btn-group-justified" role="group" aria-label="Minemap" title="View minemap for this group">
                     <a class="btn btn-default" href="/minemap?search=type:host hg:{{'"%s"' % group.get_name()}}"><i class="fa fa-table"></i> <span class="hidden-xs">Minemap</span></a>
                  </div>

                  <div class="btn-group btn-group-justified" role="group" aria-label="Resources" title="View resources for this group">
                     <a class="btn btn-default" href="/all?search=type:host hg:{{'"%s"' % group.get_name()}}"><i class="fa fa-ambulance"></i> <span class="hidden-xs">Resources</span></a>
                  </div>

                  <ul class="list-group">
                     <li class="list-group-item">
                        {{!'<span class="badge">%s</span>Hosts' % (h['nb_elts']) if h['nb_elts'] else '<small><em>No members</em></small>'}}
                     </li>
                     <li class="list-group-item">
                        {{!'<span class="badge">%s</span>Groups' % (nGroups) if nGroups else '<small><em>No sub-groups</em></small>'}}
                     </li>
                  </ul>
               </section>
            </section>
         </li>
         %#end
      %end
   </ul>
</div>

<script type="text/javascript">
   // Elements popover
   $('[data-toggle="popover"]').popover();

   $('[data-toggle="popover medium"]').popover({
      trigger: "hover",
      placement: 'bottom',
      toggle : "popover",
      viewport: {
         selector: 'body',
         padding: 10
      },

      template: '<div class="popover popover-medium"><div class="arrow"></div><div class="popover-inner"><h3 class="popover-title"></h3><div class="popover-content"><p></p></div></div></div>',
   });
</script>
