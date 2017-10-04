<div class="eltdetail-content">
  <div class="text-right" style="margin-right: 20px;">
  %if app.can_action():
    %if pb.event_handler_enabled and pb.event_handler:
    <button class="btn btn-ico btn-action js-try-to-fix"
      title="Try to fix (launch event handler)"
      data-element="{{helper.get_uri_name(pb)}}"
      >
      <i class="fa fa-magic"></i>
    </button>
    %end
    <button class="btn btn-ico btn-action js-recheck"
      title="Launch the check command"
      data-element="{{helper.get_uri_name(pb)}}"
      >
      <i class="fa fa-refresh"></i>
    </button>
    <button class="btn btn-ico btn-action js-submit-ok"
      title="Submit a check result"
      data-element="{{helper.get_uri_name(pb)}}"
      >
      <i class="fa fa-share"></i>
    </button>
    %if pb.state != pb.ok_up and not pb.problem_has_been_acknowledged:
    <button class="btn btn-ico btn-action js-add-acknowledge"
      title="Acknowledge this problem"
      data-element="{{helper.get_uri_name(pb)}}"
      >
      <i class="fa fa-check"></i>
    </button>
    %end
    <button class="btn btn-ico btn-action js-schedule-downtime"
      title="Schedule a downtime for this problem"
      data-element="{{helper.get_uri_name(pb)}}"
      >
      <i class="fa fa-ambulance"></i>
    </button>
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
