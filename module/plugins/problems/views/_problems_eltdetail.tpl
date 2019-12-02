<div class="pb_detail-content">
  %some_doc = pb.notes or pb.notes_url or pb.action_url or pb.customs and ('_IMPACT' in pb.customs or '_DETAILLEDESC' in pb.customs or '_FIXACTIONS' in pb.customs)
  <div class="row pb_detail-top">

     %if app.can_action():
     <div class="col-md-12 pb_detail-action-buttons pull-right">
     <div class="pull-right">
       <button class="btn btn-lg btn-ico btn-action js-recheck"
         title="Recheck"
         data-element="{{helper.get_uri_name(pb)}}">
         <i class="fas fa-sync"></i>
       </button>
       %if pb.state != pb.ok_up and not pb.problem_has_been_acknowledged:
       <button class="btn btn-lg btn-ico btn-action js-add-acknowledge"
         title="Acknowledge this problem"
         data-element="{{helper.get_uri_name(pb)}}">
         <i class="fas fa-check"></i>
       </button>
       %end
       <div class="dropdown" style="display: inline;">
         <button class="btn btn-lg btn-ico btn-action dropdown-toggle" type="button" id="dropdown-downtime-{{ helper.get_html_id(pb) }}" data-toggle="dropdown"
           title="Schedule a downtime for this element"
           data-element="{{helper.get_uri_name(pb)}}">
           <i class="far fa-clock"></i>
         </button>
         <ul class="dropdown-menu dropdown-menu-right" aria-labelledby="dropdown-downtime-{{ helper.get_html_id(pb) }}" style="margin-top: 15px;">
           <li class="dropdown-header">Set a downtime for…</li>
           <li role="separator" class="divider"></li>
           <li><a href="#" class="js-schedule-downtime" data-element="{{helper.get_uri_name(pb)}}" data-duration="60">1 hour</a></li>
           <li><a href="#" class="js-schedule-downtime" data-element="{{helper.get_uri_name(pb)}}" data-duration="180">3 hours</a></li>
           <li><a href="#" class="js-schedule-downtime" data-element="{{helper.get_uri_name(pb)}}" data-duration="720">12 hours</a></li>
           <li><a href="#" class="js-schedule-downtime" data-element="{{helper.get_uri_name(pb)}}" data-duration="1440">24 hours</a></li>
           <li><a href="#" class="js-schedule-downtime" data-element="{{helper.get_uri_name(pb)}}" data-duration="2160">3 days</a></li>
           <li><a href="#" class="js-schedule-downtime" data-element="{{helper.get_uri_name(pb)}}" data-duration="5040">7 days</a></li>
           <li><a href="#" class="js-schedule-downtime" data-element="{{helper.get_uri_name(pb)}}" data-duration="21600">30 days</a></li>
           <li role="separator" class="divider"></li>
           <li><a href="#" class="js-schedule-downtime" data-element="{{helper.get_uri_name(pb)}}">Custom timeperiod</a></li>
         </ul>
       </div>
       %if pb.event_handler_enabled and pb.event_handler:
       <button class="btn btn-ico btn-action js-try-to-fix"
         title="Try to fix (launch event handler)"
         data-element="{{helper.get_uri_name(pb)}}">
         <i class="fas fa-magic"></i>
       </button>
       %end
       <button class="btn btn-lg btn-ico btn-action js-submit-ok"
         title="Submit a check result"
         data-element="{{helper.get_uri_name(pb)}}">
         <i class="fas fa-share"></i>
       </button>

       <a class="btn btn-lg btn-ico btn-action" href="{{!helper.get_link_dest(pb)}}" title="Element details"><i class="fas fa-search"></i></a>
       %if app.graphs_module.is_available() and pb.perf_data:
       <a class="btn btn-lg btn-ico btn-action" href="{{!helper.get_link_dest(pb)}}#graphs" title="Element graphs"><i class="fas fa-chart-line"></i></a>
       %end
       %if app.logs_module.is_available():
       <a class="btn btn-lg btn-ico btn-action" href="{{!helper.get_link_dest(pb)}}#history" title="Element history"><i class="fas fa-list"></i></a>
       %end
       %if app.helpdesk_module.is_available():
       <a class="btn btn-lg btn-ico btn-action" href="{{!helper.get_link_dest(pb)}}#helpdesk title="Element helpdesk"><i class="fas fa-ambulance"></i></a>
       %end
     </div>
     </div>
     <div class="clearfix">
     </div>
     %end
  </div>

  <div class="row pb_detail-bottom">
     %if some_doc:
     <div class="pb_detail-bottom-left {{'col-md-6 col-md-push-6' if some_doc else 'col-md-12' }}">
        <h4 class="page-header"><i class="fas fa-question-circle"></i> Documentation</h4>
        %if pb.notes:
        <p>{{! pb.notes}}</p>
        %end

        %if pb.notes_url:
        <ul class="list-inline">
        %for note in helper.get_element_notes_url(pb, icon="external-link-square", css='class="btn btn-info btn-xs"'):
          <li>{{! note}}</li>
        %end
        </ul>
        %end

        %if pb.action_url:
        <ul class="list-inline">
        %for action in helper.get_element_actions_url(pb, title="", icon="cogs", css='class="btn btn-warning btn-xs"'):
          <li>{{! action}}</li>
        %end
        </ul>
        %end

        %if pb.customs and ('_IMPACT' in pb.customs or '_DETAILLEDESC' in pb.customs or '_FIXACTIONS' in pb.customs):
        <dl class="dl-horizontal">
        %if '_DETAILLEDESC' in pb.customs:
        <dt style="width: 80px;">Description </dt><dd style="margin-left: 100px;"> {{ pb.customs['_DETAILLEDESC'] }}</dd>
        %end
        %if '_IMPACT' in pb.customs:
        <dt style="width: 80px;">Impact </dt><dd style="margin-left: 100px;"> {{ pb.customs['_IMPACT'] }}</dd>
        %end
        %if '_FIXACTIONS' in pb.customs:
        <dt style="width: 80px;">How to fix </dt><dd style="margin-left: 100px;"> {{ pb.customs['_FIXACTIONS'] }}</dd>
        %end
        </dl>
        %end
     </div>
     %end

     <div class="pb_detail-bottom-right {{'col-md-6 col-md-pull-6' if some_doc else 'col-md-12' }}">
        %if pb.perf_data:
        <h4 class="page-header"><i class="fas fa-chart-line"></i> Performance data</h4>
        <div>
          {{!helper.get_perfdata_table(pb)}}
        </div>
        %end

        %if len(pb.impacts) > 0:
        <h4 class="page-header">
          <div class="pull-right"><small><input type="checkbox" id="display-impacts" {{ "checked" if display_impacts else '' }}> Display impacts in main table</small></div>
          <i class="fas fa-exclamation-circle"></i> {{ len(pb.impacts) }} impacts
        </h4>
        %include("_problems_table.tpl", pbs=pb.impacts)
        %end

        <h4 class="page-header" title="Only the last 60 days comments"><i class="fas fa-comment"></i> Recent comments</h4>
        %# We just need < 60 days comments
        %import datetime
        %import time
        %since = int(time.mktime((datetime.datetime.now() - datetime.timedelta(days = 60)).timetuple()))
        %include("_eltdetail_comment_table.tpl", elt=pb, comments=[ c for c in pb.comments if c.entry_time > since])

        %if pb.downtimes:
        <h4 class="page-header"><i class="far fa-clock"></i></i> Downtimes</h4>
        %include("_eltdetail_downtime_table.tpl", downtimes=pb.downtimes)
        %end
     </div>
  </div>
</div>
