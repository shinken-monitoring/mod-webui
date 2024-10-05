%import time

<!-- Debug: {{ app.request.url }} -->
%if events:
  %for daterange, _events in app.helper.group_by_daterange(sorted(events, key=lambda x: x['time'], reverse=True), key=lambda x: x['time']).items():

  %if _events:
  <h4 class="daterange-title">{{ daterange }}</h4>
  <table class="table table-condensed">
    <tbody style='font-size: small;'>
      <!--<tr class="event-level0"><td width="180px" class="text-right">2024-08-29 10:04:05</td><td><i class="fas fa-bookmark">&nbsp;</i>Test 0</td></tr>-->
      <!--<tr class="event-level1"><td width="180px" class="text-right">2024-08-29 10:04:05</td><td><i class="fas fa-bookmark">&nbsp;</i>Test 1</td></tr>-->
      <!--<tr class="event-level2"><td width="180px" class="text-right">2024-08-29 10:04:05</td><td><i class="fas fa-bookmark">&nbsp;</i>Test 2</td></tr>-->
      <!--<tr class="event-level3"><td width="180px" class="text-right">2024-08-29 10:04:05</td><td><i class="fas fa-bookmark">&nbsp;</i>Test 3</td></tr>-->
      <!--<tr class="event-level4"><td width="180px" class="text-right">2024-08-29 10:04:05</td><td><i class="fas fa-code">&nbsp;</i>Test 4</td></tr>-->
      <!--<tr class="event-level5"><td width="180px" class="text-right">2024-08-29 10:04:05</td><td><i class="fas fa-git">&nbsp;</i>Test 5</td></tr>-->
    %for e in _events:
      <tr class="event-level{{ e['level'] }}">
        <!--<td width="180px" class="text-right">{{ time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(e['time'])) }}</td>-->
        <td>
          {{ time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(e['time'])) }}&nbsp;&nbsp;
          %if 'source' in e and e['source'].lower() == 'git':
          <i class="fas fa-code" title="From Git"></i>
          %elif 'source' in e and e['source'].lower() == 'asis':
          <i class="fas fa-list" title="From Asis"></i>
          %elif 'source' in e and e['source'].lower() == 'shinken':
          %if e['log']['state'] == 2:
          <i class="fas fa-history font-critical" title="From Shinken history"></i>
          %elif e['log']['state'] == 1:
          <i class="fas fa-history font-warning" title="From Shinken history"></i>
          %elif e['log']['state'] == 3:
          <i class="fas fa-history font-unknown" title="From Shinken history"></i>
          %else:
          <i class="fas fa-history" title="From Shinken history"></i>
          %end
          %else:
          <i class="fas fa-minus"></i>
          %end
          &nbsp;&nbsp;
          {{ e['message'] }}
        </td>
      </tr>
    %end
    </tbody>
  </table>
  %end
  %end
%else:
<div class="text-center text-muted">
  <em><small>No event with level >= {{ level }} on this period.</small></em>
</div>
%end
