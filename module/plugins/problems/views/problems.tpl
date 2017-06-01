%import time
%helper = app.helper
%datamgr = app.datamgr
%search_string = app.get_search_string()

%rebase("layout", title=title, js=['problems/js/problems.js'], css=['problems/css/problems.css'], navi=navi, page="/all", elts_per_page=elts_per_page)

<script type="text/javascript">
   var actions_enabled = {{'true' if app.can_action() else 'false'}};
</script>

<script type="text/javascript">
   // Borrowed from gabriel-gm and alvaro-montoro on StackOverflow:
   // http://stackoverflow.com/a/30905277/1420832
   function copyToClipboard(element) {
     var $temp = $("<input>");
     $("body").append($temp);
     $temp.val($(element).text()).select();
     document.execCommand("copy");
     $temp.remove();
   }
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
   %for business_impact, bi_pbs in groupby(pbs, key=lambda x: x.business_impact):
      %# Sort problems, hosts first, then orders by state_id and by host
      %bi_pbs = sorted(sorted(sorted(bi_pbs, key=lambda x: x.host_name), key=lambda x: x.state_id, reverse=True), key=lambda x: x.__class__.my_type)
      %hosts = groupby(bi_pbs, key=lambda x: x.host_name)
   <div class="panel panel-default">
   <div class="panel-body">
      <button type="button" class="btn btn-default btn-xs pull-left" data-type="business-impact" data-business-impact="{{business_impact}}" data-state="off">Select all</button>

      <i class="pull-right small">{{len(list(bi_pbs))}} elements</i>
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
         %for host_name, host_pbs in hosts:
         %for i, pb in enumerate(host_pbs):

            %# Host information ...
            <tr data-toggle="collapse" data-target="#details-{{helper.get_html_id(pb)}}" class="accordion-toggle">
               <td>
                  <input type="checkbox" class="input-sm" value="" id="selector-{{helper.get_html_id(pb)}}" data-type="problem" data-business-impact="{{business_impact}}" data-item="{{pb.get_full_name()}}">
               </td>
               <td title="{{pb.get_name()}} - {{pb.output}} - Since {{helper.print_duration(pb.last_state_change)}} - Last check: {{helper.print_duration(pb.last_chk)}}" class="align-center">
                  {{!helper.get_fa_icon_state(pb, useTitle=False)}}
               </td>
               <td>
                  %if i == 0:
                     %title = ''
                     %if pb.__class__.my_type == 'service':
                        %groups = pb.host.hostgroups
                        %#groups = sorted(pb.host.hostgroups, key=lambda x:x.level, reverse=True)
                        %group = groups[0] if groups else None
                        %title = 'Member of %s' % (group.alias if group.alias else group.get_name()) if group else ''
                     %else:
                        %if pb.alias and pb.alias != pb.get_name():
                            %title = 'Aka %s' % pb.alias
                        %end
                        %groups = pb.hostgroups
                        %#groups = sorted(pb.hostgroups, key=lambda x:x.level, reverse=True)
                        %group = groups[0] if groups else None
                        %title = title + ((' - ' if title else '') + 'Member of %s' % (group.alias if group.alias else group.get_name()) if group else '')
                     %end
                     <a id="hostname" href="/host/{{pb.host_name}}" title="{{title}}">
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
                     <button class="btn-copy" onclick="copyToClipboard('#hostname')">
                        <svg aria-hidden="true" height="16" version="1.1" viewBox="0 0 14 16" width="14">
                           <path d="M2 13h4v1H2v-1zm5-6H2v1h5V7zm2 3V8l-3 3 3 3v-2h5v-2H9zM4.5 9H2v1h2.5V9zM2 12h2.5v-1H2v1zm9 1h1v2c-.02.28-.11.52-.3.7-.19.18-.42.28-.7.3H1c-.55 0-1-.45-1-1V4c0-.55.45-1 1-1h3c0-1.11.89-2 2-2 1.11 0 2 .89 2 2h3c.55 0 1 .45 1 1v5h-1V6H1v9h10v-2zM2 5h8c0-.55-.45-1-1-1H8c-.55 0-1-.45-1-1s-.45-1-1-1-1 .45-1 1-.45 1-1 1H3c-.55 0-1 .45-1 1z">
                        </svg>
                     </button>
                  %end
               </td>
               <td>
                  %if pb.__class__.my_type == 'service':
                  {{!helper.get_link(pb, short=True)}}
                  %end
                  %# Impacts
                  %if len(pb.impacts) > 0:
                  <button class="btn btn-danger btn-xs"><i class="fa fa-plus"></i> {{ len(pb.impacts) }} impacts</button>
                  %end
               </td>
               <td class="font-{{pb.state.lower()}}"><strong><small>{{ pb.state }}</small></strong></td>
               <td title="Since {{time.strftime("%d %b %Y %H:%M:%S", time.localtime(pb.last_state_change))}}">
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
                           data-trigger="hover" data-placement="left">
                           {{!helper.get_perfometer(pb)}}
                        </a>
                     %end
                  </div>
                  %end
                  <div class="ellipsis output">
                     {{!helper.strip_html_output(pb.output) if app.allow_html_output else pb.output}}
                     %if pb.long_output:
                     <div class="long-output">
                        {{!helper.strip_html_output(pb.long_output) if app.allow_html_output else pb.long_output}}
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
                                 <button class="btn btn-default btn-xs"
                                       data-type="action" action="event-handler"
                                       data-toggle="tooltip" data-placement="bottom" title="Try to fix (launch event handler)"
                                       data-element="{{helper.get_uri_name(pb)}}"
                                       >
                                    <i class="fa fa-magic"></i><span class="hidden-sm hidden-xs"> Try to fix</span>
                                 </button>
                                 %end
                                 <button class="btn btn-default btn-xs"
                                       data-type="action" action="recheck"
                                       data-toggle="tooltip" data-placement="bottom" title="Launch the check command"
                                       data-element="{{helper.get_uri_name(pb)}}"
                                       >
                                    <i class="fa fa-refresh"></i><span class="hidden-sm hidden-xs"> Refresh</span>
                                 </button>
                                 <button class="btn btn-default btn-xs"
                                       data-type="action" action="check-result"
                                       data-toggle="tooltip" data-placement="bottom" title="Submit a check result"
                                       data-element="{{helper.get_uri_name(pb)}}"
                                       data-user="{{user}}"
                                       >
                                    <i class="fa fa-share"></i><span class="hidden-sm hidden-xs"> Submit check result</span>
                                 </button>
                                 %if pb.state != pb.ok_up and not pb.problem_has_been_acknowledged:
                                 <button class="btn btn-default btn-xs"
                                       data-type="action" action="add-acknowledge"
                                       data-toggle="tooltip" data-placement="bottom" title="Acknowledge this problem"
                                       data-element="{{helper.get_uri_name(pb)}}"
                                       >
                                    <i class="fa fa-check"></i><span class="hidden-sm hidden-xs"> Acknowledge</span>
                                 </button>
                                 %end
                                 <button class="btn btn-default btn-xs"
                                       data-type="action" action="schedule-downtime"
                                       data-toggle="tooltip" data-placement="bottom" title="Schedule a downtime for this problem"
                                       data-element="{{helper.get_uri_name(pb)}}"
                                       >
                                  <i class="fa fa-ambulance"></i><span class="hidden-sm hidden-xs"> Downtime</span>
                                 </button>
                                 <button class="btn btn-default btn-xs"
                                       data-type="action" action="ignore-checks"
                                       data-toggle="tooltip" data-placement="bottom" title="Ignore checks for the service (disable checks, notifications, event handlers and force Ok)"
                                       data-element="{{helper.get_uri_name(pb)}}"
                                       data-user="{{user}}"
                                       >
                                    <i class="fa fa-eraser"></i><span class="hidden-sm hidden-xs"> Remove</span>
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
                              <h4>{{ len(pb.impacts) }} impacts</h4>
                              <table class="table table-condensed" style="table-layout:fixed;width:100%;">
                                 %for i in helper.get_impacts_sorted(pb):
                                 %if i.state_id != 0:
                                 <tr>
                                    <td align=center>
                                       {{!helper.get_fa_icon_state(i)}}
                                    </td>
                                    <td>{{!helper.get_link(i, short=True)}}</td>
                                    <td align="center" class="font-{{i.state.lower()}}"><strong>{{ i.state }}</strong></td>
                                    <td align="center">{{!helper.print_duration(i.last_state_change, just_duration=True, x_elts=2)}}</td>
                                    <td class="row hidden-sm hidden-xs">
                                       <div class="ellipsis output">
                                          {{!helper.strip_html_output(i.output) if app.allow_html_output else i.output}}
                                          %if i.long_output:
                                          <div class="long-output">
                                             {{!helper.strip_html_output(i.long_output) if app.allow_html_output else i.long_output}}
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

         %# End for i, pb in enumerate(host_pbs):
         %end
         %end
         </tbody>
      </table>
   %#end panel-body
   </div>
   </div>

   %# Close problems div ...
   %end
 </div>

 <script>
   $('a[href="/problems"]').addClass('active');
 </script>
