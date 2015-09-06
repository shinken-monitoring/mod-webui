%rebase("layout", title='All timeperiods (%d time periods)' % len(timeperiods))

%import time
%import operator

<div id="timeperiods">
   <table class="table table-condensed">
      <colgroup>
         <col style="width: 20%" />
         <col style="width: 60%" />
      </colgroup>
      <tbody style="font-size:x-small;">
      %for timeperiod in timeperiods:
         <tr>
            <td>
               <h3>{{timeperiod.timeperiod_name}}</h3>
            </td>
         </tr>
         <tr>
            <table class="table table-condensed">
              <colgroup>
                <col style="width: 20%" />
                <col style="width: 60%" />
              </colgroup>
              <thead>
                <tr>
                  <th colspan="2"></td>
                </tr>
              </thead>
              <tbody style="font-size:x-small;">
                %if hasattr(timeperiod, 'alias'):
                <tr>
                  <td><strong>Alias:</strong></td>
                  <td>{{timeperiod.alias}}</td>
                </tr>
                %end
                <tr>
                  <td><strong>Valid:</strong></td>
                  <td><span class="{{'glyphicon glyphicon-ok font-green' if timeperiod.is_correct() else 'glyphicon glyphicon-remove font-red'}}"></span></td>
                </tr>
                %if len(timeperiod.dateranges) > 0:
                <tr>
                  <td colspan="2"><strong>Periods:</strong></td>
                </tr>
                %for dr in sorted(timeperiod.dateranges, key=operator.methodcaller("get_start_and_end_time")):
                %(dr_start, dr_end) = dr.get_start_and_end_time()
                %dr_start = time.strftime("%d %b %Y", time.localtime(dr_start))
                %dr_end = time.strftime("%d %b %Y", time.localtime(dr_end))
                <tr>
                  <td></td>
                  <td>
                    From: <strong>{{dr_start}}</strong> to:<strong>{{dr_end}}</strong>
                    %if len(dr.timeranges) > 0:
                    &nbsp;(
                    %idx=0
                    %for timerange in dr.timeranges:
                    %hr_start = ("%02d:%02d" % (timerange.hstart, timerange.mstart))
                    %hr_end = ("%02d:%02d" % (timerange.hend, timerange.mend))
                    <strong>{{hr_start}}-{{hr_end}}&nbsp;</strong>
                    %', ' if idx == 0 else ''
                    %idx = idx+1
                    %end
                    )
                    %end
                  </td>
                </tr>
                %end
                %end
                <tr>
                  <td><strong>Active:</strong></td>
                  <td><span class="{{'glyphicon glyphicon-ok font-green' if timeperiod.is_time_valid(int(time.time())) else 'glyphicon glyphicon-remove font-red'}}"></span></td>
                </tr>
              </tbody>
            </table>
         </tr>
      %end
      </tbody>
   </table>
</div>
