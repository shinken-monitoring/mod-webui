<div class="eltdetail-content">
  <div class="eltdetail-action-buttons">
  %if app.can_action():
    <button class="btn btn-lg btn-ico btn-action js-recheck"
      title="Recheck"
      data-element="{{helper.get_uri_name(pb)}}"
      >
      <i class="fa fa-refresh"></i>
    </button>
    %if pb.state != pb.ok_up and not pb.problem_has_been_acknowledged:
    <button class="btn btn-lg btn-ico btn-action js-add-acknowledge"
      title="Acknowledge this problem"
      data-element="{{helper.get_uri_name(pb)}}"
      >
      <i class="fa fa-check"></i>
    </button>
    %end
    <div class="dropdown" style="display: inline;">
      <button class="btn btn-lg btn-ico btn-action dropdown-toggle" type="button" id="dropdown-downtime-{{ helper.get_html_id(pb) }}" data-toggle="dropdown"
        title="Schedule a downtime for this element"
        data-element="{{helper.get_uri_name(pb)}}"
        >
        <i class="fa fa-clock-o"></i>
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
      data-element="{{helper.get_uri_name(pb)}}"
      >
      <i class="fa fa-magic"></i>
    </button>
    %end
    <button class="btn btn-lg btn-ico btn-action js-submit-ok"
      title="Submit a check result"
      data-element="{{helper.get_uri_name(pb)}}"
      >
      <i class="fa fa-share"></i>
    </button>
    <div class="dropdown" style="display: inline;">
      <button class="btn btn-lg btn-ico btn-action dropdown-toggle" type="button" id="dropdown-others-{{ helper.get_html_id(pb) }}" data-toggle="dropdown"
        >
        <i class="fa fa-ellipsis-v"></i>
      </button>
      <ul class="dropdown-menu dropdown-menu-right" aria-labelledby="dropdown-others-{{ helper.get_html_id(pb) }}" style="margin-top: 15px;">
        <li><a href="{{!helper.get_link_dest(pb)}}"><i class="fa fa-search"></i> Details</a></li>
        %if app.graphs_module.is_available() and pb.perf_data:
        <li><a href="{{!helper.get_link_dest(pb)}}#graphs"><i class="fa fa-line-chart"></i> Graphs</a></li>
        %end
        %if app.logs_module.is_available():
        <li><a href="{{!helper.get_link_dest(pb)}}#history"><i class="fa fa-th-list"></i>&nbsp;&nbsp;History</a></li>
        %end
        %if app.helpdesk_module.is_available():
        <li><a href="{{!helper.get_link_dest(pb)}}#helpdesk">Helpdesk</a></li>
        %end
      </ul>
    </div>
  %end
</div>

  %if pb.notes or pb.notes_url:
  <blockquote style="font-size: 14px;">
    {{ pb.notes }}<br>
    <a href="{{ pb.notes_url }}" target="_blank"><i class="fa fa-external-link"></i> {{ pb.notes_url }}</a>
  </blockquote>
  %end

  %if pb.perf_data:
  <h4 class="page-header">Performance data</h4>
  <div>
    {{!helper.get_perfdata_table(pb)}}
  </div>
  %end

  %if len(pb.impacts) > 0:
  <h4 class="page-header">
    <div class="pull-right"><small><input type="checkbox" id="display-impacts" {{ "checked" if display_impacts else '' }}> Display impacts in main table</small></div>
    <i class="fa fa-exclamation-circle"></i> {{ len(pb.impacts) }} impacts
  </h4>
  %include("_problems_table.tpl", pbs=pb.impacts)
  %end

  <h4 class="page-header"><i class="fa fa-comment-o"></i> Recent comments</h4>
  %# We just need < 60 days comments
  %import datetime
  %import time
  %since = int(time.mktime((datetime.datetime.now() - datetime.timedelta(days = 60)).timetuple()))
  %include("_eltdetail_comment_table.tpl", elt=pb, comments=[ c for c in pb.comments if c.entry_time > since])

  %if pb.downtimes:
  <h4 class="page-header">Downtimes</h4>
  %include("_eltdetail_downtime_table.tpl", downtimes=pb.downtimes)
  %end

  <!--<h4 class="page-header">Graphs</h4>-->
  <!--%include("_eltdetail_comment_table.tpl", comments=pb.comments)-->

</div>
