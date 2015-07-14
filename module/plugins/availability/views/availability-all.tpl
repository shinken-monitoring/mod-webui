%import json
%import time

%#date_format='%Y-%m-%d %H:%M:%S'
%date_format='%H:%M:%S'
%states = ['Up', 'down', 'unreachable', 'unknown', 'unchecked']

%# Specific content for breadrumb
%rebase("layout", title='Availability for all hosts', refresh=True, breadcrumb=[ ['All hosts', '/minemap'] ])


<div id="availability">
   <script type="text/javascript">
      // Initial start/stop range ...
      var range_start = moment.unix({{range_start}}, 'YYYY-MM-DD');
      // Set default downtime period as two days
      var range_end = moment.unix({{range_end}}, 'YYYY-MM-DD');
   </script>

   <div class="row row-fluid">
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
               %t_0=int(log['daily_0'])
               %t_1=int(log['daily_1'])
               %t_2=int(log['daily_2'])
               %t_3=int(log['daily_3'])
               %t_4=int(log['daily_4'])
               
               <tr>
                  <td>
                  %h = app.get_host(log['hostname'])
                  <a href="/host/{{h.get_name()}}">
                     {{!app.helper.get_fa_icon_state(h)}}&nbsp;{{h.get_name()}}
                  </a>
                  </td>
                  <td>{{log['service']}}</td>
                  <td>{{log['day']}}</td>
                  
                  <td>{{time.strftime(date_format, time.localtime(log['first_check_timestamp']))}} {{!app.helper.get_fa_icon_state_and_label(cls='host', state=states[log['first_check_state']])}}</td>
                  
                  <td>{{time.strftime(date_format, time.localtime(log['last_check_timestamp']))}} {{!app.helper.get_fa_icon_state_and_label(cls='host', state=states[log['last_check_state']])}}</td>
                  
                  <td>{{! app.helper.get_on_off(bool(log['is_downtime']=='1'), 'Is in downtime period?')}}</td>
                  
                  %p_0=round(100.0 * t_0 / 86400, 2)
                  %p_1=round(100.0 * t_1 / 86400, 2)
                  %p_2=round(100.0 * t_2 / 86400, 2)
                  %p_3=round(100.0 * t_3 / 86400, 2)
                  %p_4=round(100.0 * t_4 / 86400, 2)
                  <td>
                     <div class="progress" style="margin-bottom: 5px;">
                        <div title="{{t_0}} seconds Up" class="progress-bar progress-bar-success " role="progressbar" 
                           aria-valuenow="{{p_0}}" aria-valuemin="0" aria-valuemax="100" 
                           data-toggle="tooltip" data-placement="bottom" 
                           style="width: {{p_0}}%;">{{p_0}}% Up</div>

                        <div title="{{t_1}} seconds Down" class="progress-bar progress-bar-danger " role="progressbar" 
                           aria-valuenow="{{p_1}}" aria-valuemin="0" aria-valuemax="100" 
                           data-toggle="tooltip" data-placement="bottom" 
                           style="width: {{p_1}}%;">{{p_1}}% Down</div>

                        <div title="{{t_2}} seconds Unreachable" class="progress-bar progress-bar-warning " role="progressbar" 
                           aria-valuenow="{{p_2}}" aria-valuemin="0" aria-valuemax="100" 
                           data-toggle="tooltip" data-placement="bottom" 
                           style="width: {{p_2}}%;">{{p_2}}% Unreachable</div>

                        <div title="{{t_3}} seconds Unknown" class="progress-bar progress-bar-info " role="progressbar" 
                           aria-valuenow="{{p_3}}" aria-valuemin="0" aria-valuemax="100" 
                           data-toggle="tooltip" data-placement="bottom" 
                           style="width: {{p_3}}%;">{{p_3}}% Unknown</div>

                        <div title="{{t_4}} seconds Unchecked" class="progress-bar " role="progressbar" 
                           aria-valuenow="{{p_4}}" aria-valuemin="0" aria-valuemax="100" 
                           data-toggle="tooltip" data-placement="bottom" 
                           style="width: {{p_4}}%;">{{p_4}}% Unchecked</div>
                     </div>
                     %if t_4 != 86400:
                     %p_0=round(100.0 * t_0 / (86400-t_4), 2)
                     %p_1=round(100.0 * t_1 / (86400-t_4), 2)
                     %p_2=round(100.0 * t_2 / (86400-t_4), 2)
                     %p_3=round(100.0 * t_3 / (86400-t_4), 2)
                     <div class="progress" style="margin-bottom: 0px;">
                        <div title="{{t_0}} seconds Up" class="progress-bar progress-bar-success " role="progressbar" 
                           aria-valuenow="{{p_0}}" aria-valuemin="0" aria-valuemax="100" 
                           data-toggle="tooltip" data-placement="bottom" 
                           style="width: {{p_0}}%;">{{p_0}}% Up</div>

                        <div title="{{t_1}} seconds Down" class="progress-bar progress-bar-danger " role="progressbar" 
                           aria-valuenow="{{p_1}}" aria-valuemin="0" aria-valuemax="100" 
                           data-toggle="tooltip" data-placement="bottom" 
                           style="width: {{p_1}}%;">{{p_1}}% Down</div>

                        <div title="{{t_2}} seconds Unreachable" class="progress-bar progress-bar-warning " role="progressbar" 
                           aria-valuenow="{{p_2}}" aria-valuemin="0" aria-valuemax="100" 
                           data-toggle="tooltip" data-placement="bottom" 
                           style="width: {{p_2}}%;">{{p_2}}% Unreachable</div>

                        <div title="{{t_3}} seconds Pending" class="progress-bar progress-bar-info " role="progressbar" 
                           aria-valuenow="{{p_3}}" aria-valuemin="0" aria-valuemax="100" 
                           data-toggle="tooltip" data-placement="bottom" 
                           style="width: {{p_3}}%;">{{p_3}}% Unknown</div>

                        <div title="{{t_4}} seconds Unknown" class="progress-bar " role="progressbar" 
                           aria-valuenow="{{p_4}}" aria-valuemin="0" aria-valuemax="100" 
                           data-toggle="tooltip" data-placement="bottom" 
                           style="width: {{p_4}}%;">{{p_4}}% Unchecked</div>
                     </div>
                     %end
                  </td>
               </tr>
               <!--
               <tr>
                  <td colspan="6">&nbsp;</td>
                  <td>
                     <div class="progress" style="margin-bottom: 0px;">
                       <div class="progress-bar" role="progressbar" aria-valuenow="60" aria-valuemin="0" aria-valuemax="100" style="min-width: 2em; width: {{p_0+p_1+p_2+p_3}}%;">
                         <span class="sr-only">{{p_0+p_1+p_2+p_3}} %</span>
                       </div>
                     </div>
                  </td>
               </tr>
               -->
            %end
         </tbody>
      </table>
   %end
   
   <script type="text/javascript">
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
    
      // Form submit ...
      /*
      $('button[type="submit"]').on('click', function(ev, picker) {
         console.log('Selected range: ', range_start.format('YYYY-MM-DD'), range_end.format('YYYY-MM-DD'))
         console.log(location.href)
         var url = window.location.href;
         var separator = (url.indexOf('?') > -1) ? "&" : "?";
         var rs = "range_start=" + encodeURIComponent(range_start.format('YYYY-MM-DD'));
         var re = "range_end=" + encodeURIComponent(range_end.format('YYYY-MM-DD'));
         console.log(url + separator + rs + '&' + re)
         window.location = "http://google.fr?test=1"; //url + separator + rs + '&' + re;
      });
      */
   </script>
</div>