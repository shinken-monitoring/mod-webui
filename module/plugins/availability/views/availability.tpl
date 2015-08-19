%import json
%import time

%#date_format='%Y-%m-%d %H:%M:%S'
%date_format='%H:%M:%S'
%states = ['Up', 'down', 'unreachable', 'unknown', 'unchecked']

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
        <th>Service</th>
        <th>Day</th>
        <th>First check</th>
        <th>Last check</th>
        <th>Downtime</th>
        <th> ... </th>
      </tr>
    </thead>
    <tbody style="font-size:x-small;">
      %for log in records:
      <tr>
        <td>
          <a href="/host/{{log['hostname']}}">{{log['hostname']}}</a>
        </td>
        <td>{{log['service']}}</td>
        <td>{{log['day']}}</td>

        <td><span class="moment-date" data-timestamp="{{log['first_check_timestamp']}}" data-format="calendar()">{{log['first_check_timestamp']}}</span> {{!app.helper.get_fa_icon_state_and_label(cls='host', state=states[log['first_check_state']])}}</td>

        <td><span class="moment-date" data-timestamp="{{log['last_check_timestamp']}}" data-format="calendar()">{{log['last_check_timestamp']}}</span> {{!app.helper.get_fa_icon_state_and_label(cls='host', state=states[log['last_check_state']])}}</td>

        <td>{{! app.helper.get_on_off(bool(log['is_downtime']=='1'), 'Is in downtime period?')}}</td>

        %include("_availability_bar.tpl", log=log)
      </tr>
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
