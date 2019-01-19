%setdefault('debug', False)

%user = app.get_user()
%rebase("layout", title='Services groups overview')

%helper = app.helper
%s = app.datamgr.get_services_synthesis(user=user)

%hide_empty = (getattr(app.modconf, 'plugin.servicegroups.hide_empty', '0') == '1')

<div id="servicesgroups">
   <!-- Progress bar -->
   <div class="panel panel-default">
      <div class="panel-body">
         <div class="pull-left col-sm-2 hidden-sm hidden-xs text-center">
            {{s['nb_elts']}} services
         </div>
         <div class="progress" style="margin-bottom: 0px;">
            <div title="{{s['nb_ok']}} services Ok" class="progress-bar progress-bar-success quickinfo" role="progressbar"
               data-toggle="tooltip" data-placement="bottom"
               style="width: {{s['pct_ok']}}%;">{{s['pct_ok']}}% Ok</div>

            <div title="{{s['nb_critical']}} services Critical" class="progress-bar progress-bar-danger quickinfo" role="progressbar"
               data-toggle="tooltip" data-placement="bottom"
               style="width: {{s['pct_critical']}}%;">{{s['pct_critical']}}% Critical</div>

            <div title="{{s['nb_warning']}} services  Warning" class="progress-bar progress-bar-warning quickinfo" role="progressbar"
               data-toggle="tooltip" data-placement="bottom"
               style="width: {{s['pct_warning']}}%;">{{s['pct_warning']}}% Warning</div>

            <div title="{{s['nb_pending']}} services Pending" class="progress-bar progress-bar-info quickinfo" role="progressbar"
               data-toggle="tooltip" data-placement="bottom"
               style="width: {{s['pct_pending']}}%;">{{s['pct_pending']}}% Pending</div>

            <div title="{{s['nb_unknown']}} services Unknown" class="progress-bar progress-bar-info quickinfo" role="progressbar"
               data-toggle="tooltip" data-placement="bottom"
               style="width: {{s['pct_unknown']}}%;">{{s['pct_unknown']}}% Unknown</div>
         </div>
      </div>
   </div>

   <!-- Groups list -->
   <ul id="groups" class="list-group">
      %if debug:
         %services = app.datamgr.search_hosts_and_services('type:service', user)
         <div>Services and their groups (only services in groups):<ul>
            %for service in services:
            %if service.get_groupnames():
            <li>
            Service: <strong>{{service.get_name()}}</strong> is member of: {{service.get_groupnames()}}
            </li>
            %end
            %end
         </ul></div>
      %end

      %even='alt'
      %if level==0:
         <li class="all_groups list-group-item clearfix {{even}} {{'alert-danger' if s['nb_elts'] == s['nb_critical'] and s['nb_elts'] != 0 else ''}}">
            <h3>
               <a role="menuitem" href="/all?search=type:service">
                  All services {{!helper.get_business_impact_text(s['bi'])}}
               </a>
            </h3>
            <section class="col-md-8 col-sm-6 col-xs-6">
               <div>
                  %for state in 'ok', 'warning', 'critical', 'pending':
                  %if s['nb_' + state] > 0:
                  <a role="menuitem" href="/all?search=type:service is:{{state}}">
                  %end
                  <span class="{{'font-' + state if s['nb_' + state] > 0 else 'font-greyed'}}">
                    %label = "%s <i>(%s%%)</i>" % (s['nb_' + state], s['pct_' + state])
                    {{!helper.get_fa_icon_state_and_label(cls='service', state=state, label=label)}}
                  </span>
                  %if s['nb_' + state] > 0:
                  </a>
                  %end
                  %end
               </div>
               <div>
                  %for state in 'unknown', 'ack', 'downtime':
                  %if s['nb_' + state] > 0:
                  <a role="menuitem" href="/all?search=type:service is:{{state}}">
                  %end
                  <span class="{{'font-' + state if s['nb_' + state] > 0 else 'font-greyed'}}">
                    %label = "%s <i>(%s%%)</i>" % (s['nb_' + state], s['pct_' + state])
                    {{!helper.get_fa_icon_state_and_label(cls='service', state=state, label=label)}}
                  </span>
                  %if s['nb_' + state] > 0:
                  </a>
                  %end
                  %end
               </div>
            </section>

            <section class="col-md-4 col-sm-6 col-xs-6">
               <section class="col-sm-12 col-xs-12">
               </section>

               <section class="col-sm-12 col-xs-12">
                  <div class="btn-group btn-group-justified" role="group" aria-label="Minemap" title="View minemap for all services">
                     <a class="btn btn-default" href="/minemap?search=type:service"><i class="fas fa-table"></i> <span class="hidden-xs">Minemap</span></a>
                  </div>

                  <div class="btn-group btn-group-justified" role="group" aria-label="Elements" title="View elements for all services">
                     <a class="btn btn-default" href="/all?search=type:service"><i class="fas fa-hdd"></i> <span class="hidden-xs">Elements</span></a>
                  </div>

                  <ul class="list-group">
                     <li class="list-group-item">
                        {{!'<span class="badge">%s</span>Services' % (s['nb_elts']) if s['nb_elts'] else '<small><em>No members</em></small>'}}
                     </li>
                     <li class="list-group-item">
                        {{!'<span class="badge">%s</span>Groups' % (len(servicegroups)) if servicegroups else '<small><em>No sub-groups</em></small>'}}
                     </li>
                  </ul>
               </section>
            </section>
         </li>
      %end

      %even='alt'
      %for group in servicegroups:
         %if group.has('level') and group.level != level:
         %continue
         %end

         %services = app.datamgr.search_hosts_and_services('type:service sg:"'+group.get_name()+'"', user)
         %s = app.datamgr.get_services_synthesis(services, user=user)
         %sub_groups = group.servicegroup_members
         %sub_groups = [] if (sub_groups and not sub_groups[0]) else sub_groups

         %if not services and hide_empty:
         %continue
         %end

         %if even =='':
           %even='alt'
         %else:
           %even=''
         %end

         %if not services:
         %# Empty group: no service
         <li class=" list-group-item clearfix {{even}}">
            <h3>
               %if sub_groups:
               <a class="btn btn-default btn-xs" href="services-groups?level={{int(level+1)}}&parent={{group.get_name()}}" title="View contained groups"><i class="fas fa-angle-double-down"></i></a>
               %end

               %if group.has('level') and group.level > 0:
               <a class="btn btn-default btn-xs" href="services-groups?level={{int(level-1)}}" title="View parent group"><i class="fas fa-angle-double-up"></i></a>
               %end

               <span>
                  {{group.alias if group.alias != '' else group.get_name()}} {{!helper.get_business_impact_text(s['bi'])}}
               </span>
               <small><em>No members</em></small>
            </h3>
         </li>
         %continue
         %end

         %if debug:
         <div>Group <strong>{{group.get_name()}}</strong>:<ul>
            %for service in services:
            <li>
            Service: <strong>{{service.get_name()}}</strong> is a known member
            </li>
            %end
         </ul></div>
         %end

         %#if services or sub_groups:
         <li class="group list-group-item clearfix {{'alert-danger' if s['nb_elts'] == s['nb_critical'] and s['nb_elts'] != 0 else ''}} {{even}}">
            <h3>
               %if sub_groups:
               <a class="btn btn-default btn-xs" href="services-groups?level={{int(level+1)}}&parent={{group.get_name()}}" title="View contained groups"><i class="fas fa-angle-double-down"></i></a>
               %end

               %if group.has('level') and group.level > 0:
               <a class="btn btn-default btn-xs" href="services-groups?level={{int(level-1)}}" title="View parent group"><i class="fas fa-angle-double-up"></i></a>
               %end

               <a role="menuitem" href="/all?search=type:service sg:{{'"%s"' % group.get_name()}}">
                  {{group.alias if group.alias != '' else group.get_name()}} {{!helper.get_business_impact_text(s['bi'])}}
               </a>
            </h3>
            <section class="col-md-8 col-sm-6 col-xs-6">
               <div>
                  %for state in 'ok', 'warning', 'critical', 'pending':
                  %if s['nb_' + state] > 0:
                  <a role="menuitem" href="/all?search=type:service sg:{{'"%s"' % group.get_name()}} is:{{state}}">
                  %end
                  <span class="{{'font-' + state if s['nb_' + state] > 0 else 'font-greyed'}}">
                    %label = "%s <i>(%s%%)</i>" % (s['nb_' + state], s['pct_' + state])
                    {{!helper.get_fa_icon_state_and_label(cls='service', state=state, label=label)}}
                  </span>
                  %if s['nb_' + state] > 0:
                  </a>
                  %end
                  %end
               </div>
               <div>
                  %for state in 'unknown', 'ack', 'downtime':
                  %if s['nb_' + state] > 0:
                  <a role="menuitem" href="/all?search=type:service sg:{{'"%s"' % group.get_name()}} is:{{state}}">
                  %end
                  <span class="{{'font-' + state if s['nb_' + state] > 0 else 'font-greyed'}}">
                    %label = "%s <i>(%s%%)</i>" % (s['nb_' + state], s['pct_' + state])
                    {{!helper.get_fa_icon_state_and_label(cls='service', state=state, label=label)}}
                  </span>
                  %if s['nb_' + state] > 0:
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
                     <a class="btn btn-default" href="/minemap?search=type:service sg:{{'"%s"' % group.get_name()}}"><i class="fas fa-table"></i> <span class="hidden-xs">Minemap</span></a>
                  </div>

                  <div class="btn-group btn-group-justified" role="group" aria-label="Elements" title="View elements for this group">
                     <a class="btn btn-default" href="/all?search=type:service sg:{{'"%s"' % group.get_name()}}"><i class="fas fa-hdd"></i> <span class="hidden-xs">Elements</span></a>
                  </div>

                  <ul class="list-group">
                     <li class="list-group-item">
                        {{!'<span class="badge">%s</span>Services' % (s['nb_elts']) if s['nb_elts'] else '<small><em>No members</em></small>'}}
                     </li>
                     <li class="list-group-item">
                        {{!'<span class="badge">%s</span>Groups' % (len(sub_groups)) if sub_groups else '<small><em>No sub-groups</em></small>'}}
                     </li>
                  </ul>
               </section>
            </section>
         </li>
         %#end
      %end
   </ul>
</div>
