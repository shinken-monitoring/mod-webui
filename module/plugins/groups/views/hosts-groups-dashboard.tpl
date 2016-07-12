%rebase("layout", css=['groups/css/groups-overview.css'], title='Hosts groups dashboard')

%helper = app.helper
%h = app.datamgr.get_hosts_synthesis(user=user)


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
                  %for state in 'up', 'unreachable', 'down', 'pending', 'unknown', 'ack', 'downtime':
                  <span class="{{'font-' + state if h['nb_' + state] > 0 else 'font-greyed'}}">
                    %label = "%s <i>(%s%%)</i>" % (h['nb_' + state], h['pct_' + state])
                    {{!helper.get_fa_icon_state_and_label(cls='host', state=state, label=label)}}
                  </span>
                  %end
               </div>
            </section>
         </li>
      %end
   </ul>

   %bg_colors=['', 'danger', 'warning', 'info']
   <table class="table table-bordered">
      <colgroup>
         <col class="col-sm-2"></col>
         <col class="col-sm-2"></col>
         <col class="col-sm-2"></col>
         <col class="col-sm-2"></col>
         <col class="col-sm-2"></col>
         <col class="col-sm-2"></col>
      </colgroup>
      <thead><tr>
      </tr></thead>

      <tbody>
      %i=0
      %for group in hostgroups:
         %hosts = app.datamgr.search_hosts_and_services('type:host hg:'+group.get_name(), user)
         %h = app.datamgr.get_hosts_synthesis(user=user)
         %nHosts=h['nb_elts']
         %nGroups=len(group.get_hostgroup_members())
         %if (i % 6)==0:
         <tr data-row="{{i}}">
         %end
         %worst_state = 3
         %if hosts:
         %worst_state = max(host.state_id for host in hosts)
         %end
         <td data-column="{{i%6}}" data-worst-state="{{worst_state}}" class="{{bg_colors[worst_state]}}">
            <div>
            <div class="col-sm-6 text-center btn">
               <a href="hosts-groups?level={{int(group.level)}}"><i class="fa fa-sitemap"></i>&nbsp;{{group.level}}</a>
            </div>

            %html=''
            %for state in 'down', 'unreachable', 'up', 'pending', 'unknown', 'ack', 'downtime':
              %html += helper.get_fa_icon_state_and_label(cls='host', state=state, label=h['nb_' + state])
            %end
            <div class="col-sm-6 text-center btn popover-dismiss"
                  data-html="true" data-toggle="popover" data-trigger="hover" data-placement="bottom"
                  data-title="Hosts status"
                  data-content='{{!html}}' >
               <i class="fa fa-server"></i>&nbsp;{{h['nb_elts']}}
            </div>

            <h5 class="ellipsis" style="display:inline-block">
               <a role="menuitem" href="/all?search=type:host hg:{{group.get_name()}}">
               </small>{{group.alias if group.alias != '' else group.get_name()}} {{!helper.get_business_impact_text(h['bi'])}}</small>
               </a>
            </h5>
            </div>
         </td>
         %if (i % 6)==5:
         </tr>
         %end
         %i=i+1
      %end
      </tbody>
   </table>
</div>


<script type="text/javascript">
   // Tooltips
   $('[data-toggle="tooltip"]').tooltip();
</script>
