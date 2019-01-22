%rebase("layout", css=['groups/css/groups-overview.css'], title='Hosts groups dashboard')

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
      %even='alt'
      %if level==0:
         <li class="all_groups list-group-item clearfix {{even}} {{'alert-danger' if h['nb_elts'] == h['nb_down'] and h['nb_elts'] != 0 else ''}}">
            <section class="left">
               <h3>
                  <a role="menuitem" href="/all?search=type:host"><i class="fas fa-angle-double-down"></i>
                     All hosts {{!helper.get_business_impact_text(h['bi'])}}
                  </a>

                  <span class="btn-group pull-right">
                     <a href="{{app.get_url("HostsGroups")}}" class="btn btn-small switcher quickinfo pull-right" data-original-title='List'> <i class="fas fa-align-justify"></i> </a>
                  </span>
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
         %h = app.datamgr.get_hosts_synthesis(elts=hosts, user=user)
         %if not hosts and hide_empty:
         %continue
         %end

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
               <a href="hosts-groups?level={{int(group.level)}}"><i class="fas fa-sitemap"></i>&nbsp;{{group.level}}</a>
            </div>

            %html=''
            %for state in 'down', 'unreachable', 'up', 'pending', 'unknown', 'ack', 'downtime':
              %if h['nb_' + state]:
              %html += helper.get_fa_icon_state_and_label(cls='host', state=state, label=h['nb_' + state])
              %end
            %end
            <div class="col-sm-6 text-center btn popover-dismiss"
                  data-html="true" data-toggle="popover" data-trigger="hover" data-placement="bottom"
                  data-title="Hosts status"
                  data-content='{{!html}}' >
               <i class="fas fa-server"></i>&nbsp;{{h['nb_elts']}}
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
$(document).ready(function(){
   // Tooltips
   $('[data-toggle="tooltip"]').tooltip();

   // Popovers
   $('div[data-toggle="popover"]').popover({
      placement: 'bottom',
      container: 'body',
      trigger: 'manual',
      animation: false,
      template: '<div class="popover img-popover"><div class="arrow"></div><div class="popover-inner"><h3 class="popover-title"></h3><div class="popover-content"><p></p></div></div></div>'
   }).on("mouseenter", function () {
      var _this = this;
      $(this).popover("show");
      $(this).siblings(".popover").on("mouseleave", function () {
          $(_this).popover('hide');
      });
   }).on("mouseleave", function () {
      var _this = this;
      setTimeout(function () {
          if (!$(".popover:hover").length) {
              $(_this).popover("hide");
          }
      }, 100);
   });
});
</script>
