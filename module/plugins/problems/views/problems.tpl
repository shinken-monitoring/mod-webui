%import time
%helper = app.helper
%datamgr = app.datamgr
%search_string = app.get_search_string()

%rebase("layout", title=title, js=['js/shinken-actions.js', 'problems/js/problems.js', 'problems/js/actions.js'], css=['problems/css/problems.css'], navi=navi, page="/all", elts_per_page=elts_per_page)

<script type="text/javascript">
   var actions_enabled = {{'true' if app.can_action() else 'false'}};
</script>

<!-- Problems filtering and display -->
<div id="problems">

   %include("_problems_synthesis.tpl", pbs=pbs, search_string=app.get_search_string())

   %if not pbs:
   <center>
     <div class="page-header">
       %if search_string:
       <h3>What a bummer! We couldn't find anything.</h3>
       <h3><small>Use the filters, the bookmarks, click on the links above, or try a new search query to find what you are looking for.</small></h3>
       %else:
       <h3>No host or service.</h3>
       %end
     </div>
   </center>

   %else:

   %from itertools import groupby
   %pbs = sorted(pbs, key=lambda x: x.business_impact, reverse=True)
   %for business_impact, bi_pbs in groupby(helper.sort_elements(pbs), key=lambda x: x.business_impact):
   %bi_pbs = list(bi_pbs)
   <div class="panel panel-default">
   <div class="panel-body">
      <button type="button" class="btn btn-default btn-xs pull-left" data-type="business-impact" data-business-impact="{{business_impact}}" data-state="off">Select all</button>

      <i class="pull-right small">{{len(bi_pbs)}} elements</i>
      <h3 class="text-center"><span class="hidden-xs">Business impact: </span>{{!helper.get_business_impact_text(business_impact, text=True)}}</h3>

      <table class="table table-condensed" style="table-layout:fixed; width:100%;">
         <thead><tr>
            <th width="20px"></th>
            <th width="40px"></th>
            <th class="host-column">Host</th>
            <th class="service-column">Service</th>
            <th class="state-column">State</th>
            <th class="duration-column">Duration</th>
            <th class="hidden-sm hidden-xs" width="100%">Output</th>
         </tr></thead>

         <tbody>
         %previous_pb_host_name=None
         %for pb in bi_pbs:
            <tr data-toggle="collapse" data-target="#details-{{helper.get_html_id(pb)}}" class="accordion-toggle">
               <td>
                  <input type="checkbox" class="input-sm" value="" id="selector-{{helper.get_html_id(pb)}}" data-type="problem" data-business-impact="{{business_impact}}" data-item="{{pb.get_full_name()}}">
               </td>
               <td> <a href="/all?search={{pb.host_name}}" title="{{pb.get_name()}} - {{pb.output}} - Since {{helper.print_duration(pb.last_state_change)}} - Last check: {{helper.print_duration(pb.last_chk)}}" class="align-center">
                  {{!helper.get_fa_icon_state(pb, useTitle=False)}}
                  </a>
               </td>
               <td>
                  %if pb.host_name != previous_pb_host_name:
                     %title = ''
                     %if pb.__class__.my_type == 'service':
                        %groups = pb.host.hostgroups
                        %group = groups[0] if groups else None
                        %title = 'Member of %s' % (group.alias if group.alias else group.get_name()) if group else ''
                     %else:
                        %if pb.alias and pb.alias != pb.get_name():
                            %title = 'Aka %s' % pb.alias
                        %end
                        %groups = pb.hostgroups
                        %group = groups[0] if groups else None
                        %title = title + ((' - ' if title else '') + 'Member of %s' % (group.alias if group.alias else group.get_name()) if group else '')
                     %end
                     <a href="/host/{{pb.host_name}}" title="{{title}}">
                     %if pb.__class__.my_type == 'service':
                        %if pb.host:
                        {{pb.host.get_name() if pb.host.display_name == '' else pb.host.display_name}}
                        %else:
                        {{pb.host_name}}
                        %end
                     %else:
                        {{pb.get_name() if pb.display_name == '' else pb.display_name}}
                     %end
                     </a>
                  %end
               </td>
               <td>
                  %if pb.__class__.my_type == 'service':
                  {{!helper.get_link(pb, short=True)}}
                  %end
                  %if len(pb.impacts) > 0:
                  <button class="btn btn-danger btn-xs"><i class="fa fa-plus"></i> {{ len(pb.impacts) }} impacts</button>
                  %end
               </td>
               <td class="font-{{pb.state.lower()}}"><strong><small>{{ pb.state }}</small></strong></td>
               <td title="Since {{time.strftime("%d %b %Y %H:%M:%S", time.localtime(pb.last_state_change))}}">
                 <a href="/cpe/{{pb.host_name}}" target="_blank" title="who is gershom?">
                 {{!helper.print_duration(pb.last_state_change, just_duration=True, x_elts=2)}}
               </td>
               <td class="row hidden-sm hidden-xs">
                  %if app.graphs_module.is_available():
                  <div class="pull-right">
                     %graphs = app.graphs_module.get_graph_uris(pb, duration=12*3600)
                     %if len(graphs) > 0:
                        <a style="text-decoration: none;" role="button" tabindex="0" data-toggle="popover"
                           title="{{ pb.get_full_name() }}" data-html="true"
                           data-content="<img src='{{ graphs[0]['img_src'] }}' width='600px' height='200px'>"
                           data-trigger="hover" data-placement="left"
                           href="{{!helper.get_link_dest(pb)}}#graphs">
                           {{!helper.get_perfometer(pb)}}
                        </a>
                     %end
                  </div>
                  %end
                  <div class="ellipsis output">
                     {{! pb.output}}
                     %if pb.long_output:
                     <div class="long-output">
                        {{! pb.long_output}}
                     </div>
                     %end
                  </div>
               </td>
            </tr>
            <tr>
               <td colspan="8" class="hiddenRow">
                  <div class="accordion-body collapse" id="details-{{helper.get_html_id(pb)}}">
                     <table class="table table-condensed" style="margin:0;">
                       <tr class="hidden-md hidden-lg">
                         <td colspan="3">
                           {{ pb.output }}
                         </td>
                       </tr>
                        <tr>
                           <td align="center" class="visible-lg">Realm {{pb.get_realm()}}</td>
                           %if pb.passive_checks_enabled:
                           <td align="left">
                              <i class="fa fa-arrow-left hidden-xs" title="Passive checks are enabled."></i>
                              %if (pb.check_freshness):
                              <i title="Freshness check is enabled">(Freshness threshold: {{pb.freshness_threshold}} seconds)</i>
                              %end
                           </td>
                           %end
                           %if pb.active_checks_enabled:
                           <td align="left">
                              <i class="fa fa-arrow-right hidden-xs" title="Active checks are enabled."></i>
                              <i>Last check <strong>{{!helper.print_duration(pb.last_chk, just_duration=True, x_elts=2)}} ago</strong>, next check in <strong>{{!helper.print_duration(pb.next_chk, just_duration=True, x_elts=2)}}</strong>, attempt <strong>{{pb.attempt}}/{{pb.max_check_attempts}}</strong></i>
                           </td>
                           %end
                           %if app.can_action():
                           <td align="right">
                              <div class="btn-group" role="group" data-type="actions" aria-label="Actions">
                                 %if pb.event_handler_enabled and pb.event_handler:
                                 <button class="btn btn-default btn-xs js-try-to-fix"
                                       title="Try to fix (launch event handler)"
                                       data-element="{{helper.get_uri_name(pb)}}"
                                       >
                                    <i class="fa fa-magic"></i><span class="hidden-sm hidden-xs"> Try to fix</span>
                                 </button>
                                 %end
                                 <button class="btn btn-default btn-xs js-recheck"
                                       title="Launch the check command"
                                       data-element="{{helper.get_uri_name(pb)}}"
                                       >
                                    <i class="fa fa-refresh"></i><span class="hidden-sm hidden-xs"> Recheck</span>
                                 </button>
                                 <button class="btn btn-default btn-xs js-submit-ok"
                                       title="Submit a check result"
                                       data-element="{{helper.get_uri_name(pb)}}"
                                       >
                                    <i class="fa fa-share"></i><span class="hidden-sm hidden-xs"> Set OK</span>
                                 </button>
                                 %if pb.state != pb.ok_up and not pb.problem_has_been_acknowledged:
                                 <button class="btn btn-default btn-xs js-add-acknowledge"
                                   title="Acknowledge this problem"
                                   data-element="{{helper.get_uri_name(pb)}}"
                                   >
                                   <i class="fa fa-check"></i><span class="hidden-sm hidden-xs"> Acknowledge</span>
                                 </button>
                                 %end
                                 <button class="btn btn-default btn-xs js-schedule-downtime"
                                       title="Schedule a downtime for this problem"
                                       data-element="{{helper.get_uri_name(pb)}}"
                                       >
                                  <i class="fa fa-ambulance"></i><span class="hidden-sm hidden-xs"> Downtime</span>
                                 </button>
                              </div>
                           </td>
                           %end
                        </tr>
                     </table>
                     %if len(pb.impacts) > 0:
                        <div class="col-sm-1"></div>
                        <div class="col-sm-10">
                           <div class="panel panel-default align-center">
                           <div class="panel-body" style="margin-left: 20px;">
                             <div class="pull-right"><input type="checkbox" id="display-impacts" {{ "checked" if display_impacts else '' }}> Display impacts in main table</div>
                              <h4>{{ len(pb.impacts) }} impacts</h4>
                              <table class="table table-condensed" style="table-layout:fixed;width:100%;">
                                %for business_impact, bi_pbs in groupby(helper.sort_elements(pb.impacts), key=lambda x: x.business_impact):
                                <tr class="hidden-sm hidden-xs"><td colspan=5 style="text-align:center;"><strong>Business impact: </strong>{{!helper.get_business_impact_text(business_impact, text=True)}}</td></tr>
                                 %for i in bi_pbs:
                                 <tr>
                                    <td align=center>
                                       {{!helper.get_fa_icon_state(i)}}
                                    </td>
                                    <td>{{!helper.get_link(i, short=True)}}</td>
                                    <td align="center" class="font-{{i.state.lower()}}"><strong>{{ i.state }}</strong></td>
                                    <td align="center">{{!helper.print_duration(i.last_state_change, just_duration=True, x_elts=2)}}</td>
                                    <td class="row hidden-sm hidden-xs">
                                       <div class="ellipsis output">
                                          {{! i.output}}
                                          %if i.long_output:
                                          <div class="long-output">
                                             {{! i.long_output}}
                                          </div>
                                          %end
                                       </div>
                                    </td>
                                 </tr>
                                 %end
                                 %end
                              </table>
                           </div>
                           </div>
                        </div>
                        <div class="col-sm-1"></div>
                  %end
                  </div>
               </td>
            </tr>

         %previous_pb_host_name=pb.host_name
         %end
         </tbody>
      </table>
   </div>
   </div>

   %end
 </div>

 %include("_problems_action-menu.tpl")

 <script>
   // Configuration for actions.js
   var user='{{ user.alias if hasattr(user, "alias") and user.alias != "none" else user.get_name() }}';
   var shinken_downtime_fixed='{{ app.shinken_downtime_fixed}}';
   var shinken_downtime_trigger='{{ app.shinken_downtime_trigger }}';
   var shinken_downtime_duration='{{ app.shinken_downtime_duration }}';
   var default_ack_persistent='{{ app.default_ack_persistent }}';
   var default_ack_notify='{{ app.default_ack_notify }}';
   var default_ack_sticky='{{ app.default_ack_sticky }}';

   $('a[href="/problems"]').addClass('active');

   $('#display-impacts').click(function() {
     save_user_preference('display_impacts', $('#display-impacts').is(':checked'));
     location.reload();
   });
 </script>
