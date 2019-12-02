%import time
%user = app.get_user()
%helper = app.helper
%datamgr = app.datamgr
%search_string = app.get_search_string()

%rebase("layout", title=title, js=['js/jquery.sparkline.min.js', 'js/shinken-charts.js', 'problems/js/problems.js'], css=['problems/css/problems.css'], navi=navi, page="/all", elts_per_page=elts_per_page)

<script type="text/javascript">
   var actions_enabled = {{'true' if app.can_action() else 'false'}};
</script>

<!-- Problems filtering and display -->
<div id="problems">

   %include("_problems_synthesis.tpl", pbs=pbs, search_string=app.get_search_string())

   %if not pbs:
   <center>
     <div class="page-header">
       %if problems_search:
       <h3>Great! Everything is under control</h3>
       <h3><small>No problems are currently unhandled on your monitored system.</small></h3>
       %else:
       %if search_string:
       <h3>What a bummer! We couldn't find anything.</h3>
       <h3><small>Use the filters, the bookmarks, click on the links above, or try a new search query to find what you are looking for.</small></h3>
       %else:
       <h3>No host or service.</h3>
       %end
       %end
     </div>
   </center>

   %else:

   %from itertools import groupby
   %pbs = sorted(pbs, key=lambda x: x.business_impact, reverse=True)
   %for business_impact, bi_pbs in groupby(helper.sort_elements(pbs), key=lambda x: x.business_impact):
   %bi_pbs = list(bi_pbs)

   <h4 class="table-title">
     <a class="js-select-all" data-business-impact="{{ business_impact }}" data-state="off">
       <span class="original-label">
         <span class="hidden-xs">Business impact: </span>
         {{!helper.get_business_impact_text(business_impact, text=True)}}
       </span>
       <span class="onhover-label">
         <i class="fas fa-check"></i> Select all {{len(bi_pbs)}} elements
       </span>
     </a>
   </h4>

   <div class="panel panel-default">
   <!--<div class="panel-body">-->

      <table class="table table-condensed table-hover problems-table">
        <colgroup>
            <col style="width: 122px;"/>
            <col style="width: 30px;"/>
            <col class="host-column hidden-sm hidden-xs hidden-md"/>
            <col class="service-column hidden-sm hidden-xs"/>
            <col style="width: 100%;"/>
        </colgroup>
         <!--<thead><tr>-->
            <!--<th width="20px"></th>-->
            <!--[><th width="40px"></th><]-->
            <!--<th width="130px">State</th>-->
            <!--<th class="host-column hidden-sm hidden-xs hidden-md">Host</th>-->
            <!--<th class="service-column hidden-sm hidden-xs">Service</th>-->
            <!--[><th class="duration-column">Duration</th><]-->
            <!--<th width="100%">Output</th>-->
         <!--</tr></thead>-->

         <tbody>
         %previous_pb_host_name=None
         %for pb in bi_pbs:
            %if pb.__class__.my_type == 'service':
            %pb_host = pb.host
            %else:
            %pb_host = pb
            %end
            <tr data-toggle="collapse" data-target="#details-{{helper.get_html_id(pb)}}" data-item="{{helper.get_uri_name(pb)}}" class="accordion-toggle js-select-elt collapsed">
             <td title="{{pb.get_name()}} - {{pb.state}}
Since {{helper.print_date(pb.last_state_change, format="%d %b %Y %H:%M:%S")}}

Last check <strong>{{helper.print_duration(pb.last_chk)}}</strong>
Next check <strong>{{helper.print_duration(pb.next_chk)}}</strong>
%if (pb.check_freshness):
(Freshness threshold: {{pb.freshness_threshold}} seconds)
%end
"
                 data-placement="right"
                 data-container="body"
                 class="item-state font-{{pb.state.lower()}} text-center">
                   <div style="display: table-cell; vertical-align: middle; padding-right: 10px;">
                     <input type="checkbox" class="input-sm item-checkbox" value="" id="selector-{{helper.get_html_id(pb)}}" data-type="problem" data-business-impact="{{business_impact}}" data-item="{{helper.get_uri_name(pb)}}">
                     <div class="item-icon">
                       {{!helper.get_fa_icon_state(pb, use_title=False)}}
                     </div>
                   </div>
                   <div style="display: table-cell; vertical-align: middle;">
                     <small>
                       <strong>{{ pb.state }}</strong><br>
                       <!--<span title="Since {{time.strftime("%d %b %Y %H:%M:%S", time.localtime(pb.last_state_change))}}">-->
                         %if pb.state_type == 'HARD':
                         {{!helper.print_duration(pb.last_state_change, just_duration=True, x_elts=2)}}
                         %else:
                         <small>attempt {{pb.attempt}}/{{pb.max_check_attempts}}</small>
                         <!--soft state-->
                         %end
                       <!--</span>-->
                     </small>
                   </div>
               </td>
               <td class="text-muted">
                 %if pb.problem_has_been_acknowledged:
                 <i class="fas fa-check" title="Acknowledged"></i><br>
                 %end
                 %if pb.in_scheduled_downtime:
                 <i class="far fa-clock" title="In scheduled downtime"></i><br>
                 %end
               </td>
               %aka = ''
               %if pb_host.alias and not pb_host.alias.startswith(pb_host.get_name()):
                 %if pb_host.display_name:
                 %aka = 'Aka %s (%s)' % (pb_host.alias.replace(' ', '<br>'), pb_host.get_name())
                 %else:
                 %aka = 'Aka %s' % pb_host.alias.replace(' ', '<br>')
                 %end
               %end
               <td class="hidden-sm hidden-xs hidden-md">
                  %if pb.host_name != previous_pb_host_name:
                     <a href="/host/{{ pb.host_name }}" title="{{!aka}}">
                       {{ pb_host.display_name if pb_host.display_name else pb_host.get_name() }}
                     </a>
                  %end
               </td>
               <td class="hidden-sm hidden-xs">
                 <span class="hidden-lg">
                   <a href="/host/{{ pb.host_name }}" title="{{!aka}}">
                     {{ pb_host.display_name if pb_host.display_name else pb_host.get_name() }}
                   </a>
                   %if pb.__class__.my_type == 'service':
                   /
                   %end
                 </span>
                  %if pb.__class__.my_type == 'service':
                  {{!helper.get_link(pb, short=True)}}
                  %end
                  %if len(pb.impacts) > 0:
                  <span class="label label-danger" title="This {{'service' if pb.__class__.my_type == 'service' else 'host'}} has impacts">+ {{ len(pb.impacts) }}</span>
                  %end
                  <!--:TODO:maethor:170924: -->
                  <!--<div class="pull-right problem-actions">-->
                    <!--<i class="fas fa-plus"></i>-->
                  <!--</div>-->
               </td>
               <td class="row">
                  <div class="pull-right">
                     {{!helper.get_perfdata_pies(pb)}}&nbsp;
                     %if app.graphs_module.is_available():
                     %if pb.perf_data:
                        <a style="text-decoration: none; color: #333;" role="button" tabindex="0" data-toggle="popover-elt-graphs"
                           data-title="{{ pb.get_full_name() }}" data-html="true"
                           data-trigger="hover" data-placement="left"
                           data-item="{{pb.get_full_name()}}"
                           href="{{!helper.get_link_dest(pb)}}#graphs">
                           <i class="fas fa-chart-line"></i>
                        </a>
                     %end
                     %end
                  </div>
                  <div class="ellipsis output">
                  <!--<div class="ellipsis output" style='font-family: "Liberation Mono", "Lucida Console", Courier, monospace; color=#7f7f7f; font-size:0.917em;'>-->
                    <div class="hidden-md hidden-lg">
                      <a href="/host/{{ pb.host_name }}" title="{{!aka}}">
                        {{ pb_host.get_name() if pb_host.display_name == '' else pb_host.display_name }}
                      </a>
                      %if pb.__class__.my_type == 'service':
                      / {{!helper.get_link(pb, short=True)}}
                      %end
                      %if len(pb.impacts) > 0:
                      <span class="label label-danger" title="This service has impacts">+ {{ len(pb.impacts) }}</span>
                      %end
                    </div>

                     <!--<br>-->

                    <samp style="font-size:0.95em;">{{! pb.output}}</samp>
                     %if pb.long_output:
                     <div class="long-output">
                        {{! pb.long_output}}
                     </div>
                     %end
                  </div>
               </td>
            </tr>
            <tr class="hiddenRow">
               <td colspan="8">
                  <div class="accordion-body collapse" id="details-{{helper.get_html_id(pb)}}">
                    %include("_problems_eltdetail.tpl")
                  </div>
               </td>
            </tr>

         %previous_pb_host_name=pb.host_name
         %end
         </tbody>
      </table>
   <!--</div>-->
   </div>

   %end
</div>

%include('_problems_actions-navbar.tpl')
