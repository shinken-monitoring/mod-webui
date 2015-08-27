%import json
%import time

%# Specific content for breadcrumb
%rebase("layout", title='Availability for all hosts', breadcrumb=[ ['All hosts', '/minemap'] ])

%states = ['Up', 'down', 'unreachable', 'unknown', 'unchecked']

<div id="availability">
  <div class="row row-fluid">
    <div class="col-md-6">
      <!--<div class="btn-group pull-left">-->
        <!--<button type="button" class="btn btn-default dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">-->
          <!--Period <span class="caret"></span>-->
          <!--</button>-->
        <!--<ul class="dropdown-menu">-->
          <!--<li><a href="#">Today</a></li>-->
          <!--<li><a href="#">Yesterday</a></li>-->
          <!--<li><a href="#">This week</a></li>-->
          <!--<li><a href="#">Last week</a></li>-->
          <!--<li><a href="#">This month</a></li>-->
          <!--<li><a href="#">Last month</a></li>-->
          <!--<li><a href="#">This year</a></li>-->
          <!--<li><a href="#">Last year</a></li>-->
          <!--</ul>-->
        <!--</div>-->
      <!--<p>{{range_start}} - {{range_end}}</p>-->
      <form class="form-inline pull-left" role="form" method="get" action="/availability">
        <div class="form-group">
          <div class="input-group">
            <span class="input-group-addon"><i class="fa fa-calendar"></i></span>
            <input type="text" class="form-control" id="dtr_downtime" placeholder="..." />
          </div>
          <input type="hidden" id="range_start" name="range_start" />
          <input type="hidden" id="range_end" name="range_end" />
        </div>
        <button type="submit" class="btn btn-default btn-primary">Submit</button>
      </form>
    </div>
  </div>

  %if not records:
    <center>
      <h3>No availability records found.</h3>
      You should install the <strong>mongo-logs</strong> Shinken module to collect hosts availability data.
    </center>
  %else:
    <table class="table table-condensed">
      <thead>
        <tr>
          <th>Hostname</th>
          <th>First check</th>
          <th>Last check</th>
          <!--<th>Downtime</th>-->
          <th> ... </th>
        </tr>
      </thead>
      <tbody style="font-size:x-small;">
        %for log in records:
        %if log is not None:
        <tr>
          <td>
            <a href="/host/{{log['hostname']}}">{{log['hostname']}}</a>
          </td>

          <td><span class="moment-date" data-timestamp="{{log['first_check_timestamp']}}" data-format="calendar()">{{log['first_check_timestamp']}}</span> {{!app.helper.get_fa_icon_state_and_label(cls='host', state=states[log['first_check_state']])}}</td>

          <td><span class="moment-date" data-timestamp="{{log['last_check_timestamp']}}" data-format="calendar()">{{log['last_check_timestamp']}}</span> {{!app.helper.get_fa_icon_state_and_label(cls='host', state=states[log['last_check_state']])}}</td>

          <!--<td>{{! app.helper.get_on_off(bool(log['is_downtime']=='1'), 'Is in downtime period?')}}</td>-->

          %include("_availability_bar.tpl", log=log)
        </tr>
        %end
        %end
      </tbody>
    </table>
  %end

  <script type="text/javascript">
    function moment_render_date(elem) {
        $(elem).text(eval('moment.unix("' + $(elem).data('timestamp') + '").' + $(elem).data('format') + ';'));
        $(elem).removeClass('moment-date').show();
    }
    function moment_render_duration(elem) {
        $(elem).attr('title', eval('moment.duration(' + $(elem).data('duration') + ', "seconds").humanize();'));
        $(elem).removeClass('moment-duration').show();
    }
    function moment_render_all() {
      $('.moment-date').each(function() {
        moment_render_date(this);
      })
      $('.moment-duration').each(function() {
        moment_render_duration(this);
      })
    }
    $(document).ready(function() {
      moment_render_all();
    });
  </script>
   
  <script type="text/javascript">
    // Initial start/stop range ...
    var range_start = moment.unix({{range_start}}, 'YYYY-MM-DD');
    // Set default downtime period as two days
    var range_end = moment.unix({{range_end}}, 'YYYY-MM-DD');

    $("#dtr_downtime").daterangepicker({
       ranges: {
          '1 day':         [moment().add('days', -1), moment()],
          '2 days':        [moment().add('days', -2), moment()],
          '1 week':        [moment().add('days', -7), moment()],
          '1 month':       [moment().add('month', -1), moment()]
       },
       format: 'YYYY-MM-DD',
       separator: ' to ',
       maxDate: moment(),
       startDate: range_start,
       endDate: range_end,
       timePicker: false,
       timePickerIncrement: 1,
       timePicker12Hour: false,
       showDropdowns: false,
       showWeekNumbers: false,
       opens: 'right',
       },
       
       function(start, end, label) {
          range_start = start; range_end = end;
       }
    );

    // Set default date range values
    $('#dtr_downtime').val(range_start.format('YYYY-MM-DD') + ' to ' +  range_end.format('YYYY-MM-DD'));
    $('#range_start').val(range_start.format('X'));
    $('#range_end').val(range_end.format('X'));

    // Update dates on apply button ...
    $('#dtr_downtime').on('apply.daterangepicker', function(ev, picker) {
       range_start = picker.startDate; range_end = picker.endDate;
       console.log(range_start, range_end)
       $('#range_start').val(range_start.unix());
       $('#range_end').val(range_end.unix());
    });
  </script>
</div>
