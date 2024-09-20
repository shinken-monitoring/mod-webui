%import urllib
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
       <tr class="js-select-elt" data-item="{{helper.get_uri_name(pb)}}" data-link="{{ urllib.quote(helper.get_link_dest(pb)) }}">
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
                   <span class="hidden-xs"><strong>{{ pb.state }}</strong><br></span>
                   <!--<span title="Since {{time.strftime("%d %b %Y %H:%M:%S", time.localtime(pb.last_state_change))}}">-->
                     %if pb.state_type == 'HARD':
                     <span class="hidden-xs">{{!helper.print_duration(pb.last_state_change, just_duration=True, x_elts=2)}}</span>
                     <span class="visible-xs">{{!helper.print_duration(pb.last_state_change, just_duration=True, x_elts=1)}}</span>
                     %else:
                     <small><span class="hidden-xs">attempt </span>{{pb.attempt}}/{{pb.max_check_attempts}}</small>
                     <!--soft state-->
                     %end
                   <!--</span>-->
                 </small>
               </div>
           </td>
           <td class="text-muted">
             %if pb.problem_has_been_acknowledged:
             <i class="fas fa-check" title="{{ helper.get_acknowledge_comment(pb) }}"></i><br>
             %end
             %if pb.in_scheduled_downtime:
             <i class="far fa-clock" title="{{ helper.get_downtime_comments(pb)[-1] }}"></i><br>
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
           <!-- LG only, host on it's own column -->
           <td class="hidden-sm hidden-xs hidden-md">
              %if pb.host_name != previous_pb_host_name:
              %include("_elt_button.tpl", elt=pb_host)
              %end
           </td>
           <!-- MD/LG service column -->
           <td class="hidden-sm hidden-xs">
             <!-- MD only, host in service column -->
             <span class="hidden-lg">
               %include("_elt_button.tpl", elt=pb_host)
               %if pb.__class__.my_type == 'service':
               /
               %end
             </span>
              %if pb.__class__.my_type == 'service':
              %include("_elt_button.tpl", elt=pb, short=True)
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
              <div class="pull-right hidden-xs">
                 {{!helper.get_perfdata_pies(pb)}}&nbsp;
                 %if app.graphs_module.is_available():
                 %if pb.perf_data:
                 <span
                   data-toggle="popover-elt-graphs"
                   data-title="{{ pb.get_full_name() }}" data-html="true"
                   data-trigger="hover" data-placement="left"
                   data-item="{{pb.get_full_name()}}">
                   <i class="fas fa-chart-line"></i>
                 </span>
                 %end
                 %end
              </div>
              <div class="ellipsis output">
              <!--<div class="ellipsis output" style='font-family: "Liberation Mono", "Lucida Console", Courier, monospace; color=#7f7f7f; font-size:0.917em;'>-->
                <!-- SM only, host and service in output column -->
                <div class="hidden-md hidden-lg">
                  %include("_elt_button.tpl", elt=pb_host)
                  %if pb.__class__.my_type == 'service':
                  / 
                  %include("_elt_button.tpl", elt=pb)
                  %end
                  %if len(pb.impacts) > 0:
                  <span class="label label-danger" title="This service has impacts">+ {{ len(pb.impacts) }}</span>
                  %end
                </div>

                 <!--<br>-->

                <samp style="font-size:0.95em;">{{! pb.output}}</samp>
                 %if pb.long_output:
                 <div class="long-output">
                   {{! pb.long_output.replace('\n', '<br>')}}
                 </div>
                 %end
              </div>
           </td>
        </tr>
        <!--<tr class="hiddenRow">-->
           <!--<td colspan="8">-->
              <!--<div class="accordion-body collapse" id="details-{{helper.get_html_id(pb)}}">-->
                <!--%include("_problems_eltdetail.tpl")-->
              <!--</div>-->
           <!--</td>-->
        <!--</tr>-->

     %previous_pb_host_name=pb.host_name
     %end
     </tbody>
  </table>
<!--</div>-->
</div>
