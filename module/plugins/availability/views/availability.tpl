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

        <td>{{time.strftime(date_format, time.localtime(log['first_check_timestamp']))}} {{!app.helper.get_fa_icon_state_and_label(cls='host', state=states[log['first_check_state']])}}</td>

        <td>{{time.strftime(date_format, time.localtime(log['last_check_timestamp']))}} {{!app.helper.get_fa_icon_state_and_label(cls='host', state=states[log['last_check_state']])}}</td>

        <td>{{! app.helper.get_on_off(bool(log['is_downtime']=='1'), 'Is in downtime period?')}}</td>

        %include("_availability_bar.tpl", log=log)
      </tr>
      %end
    </tbody>
  </table>
%end
