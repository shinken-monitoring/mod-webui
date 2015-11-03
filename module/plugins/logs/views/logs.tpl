%rebase("layout", css=['logs/css/logs.css','logs/css/sliding_navigation.css','logs/css/bootstrap-multiselect.css'], js=['logs/js/bootstrap-multiselect.js'], title='System logs')

%from shinken.bin import VERSION
%helper = app.helper
%import time
%import datetime

%date_format='%Y-%m-%d %H:%M:%S'

%today = datetime.datetime.now()
%today_beginning = datetime.datetime(today.year, today.month, today.day,0,0,0,0)
%today_beginning_time = int(time.mktime(today_beginning.timetuple()))
%today_end = datetime.datetime(today.year, today.month, today.day,23,59,59,999)
%today_end_time = int(time.mktime(today_end.timetuple()))

%yesterday = datetime.datetime.now() - datetime.timedelta(days = 1)
%yesterday_beginning = datetime.datetime(yesterday.year, yesterday.month, yesterday.day,0,0,0,0)
%yesterday_beginning_time = int(time.mktime(yesterday_beginning.timetuple()))
%yesterday_end = datetime.datetime(yesterday.year, yesterday.month, yesterday.day,23,59,59,999)
%yesterday_end_time = int(time.mktime(yesterday_end.timetuple()))

%thisweek = datetime.datetime.now() - datetime.timedelta(days = 7)
%thisweek_beginning = datetime.datetime(thisweek.year, thisweek.month, thisweek.day,0,0,0,0)
%thisweek_beginning_time = int(time.mktime(thisweek_beginning.timetuple()))
%thisweek_end = thisweek_beginning + datetime.timedelta(days = 7)
%thisweek_end_time = int(time.mktime(thisweek_end.timetuple()))

%lastweek = datetime.datetime.now() - datetime.timedelta(days = 14)
%lastweek_beginning = datetime.datetime(lastweek.year, lastweek.month, lastweek.day,0,0,0,0)
%lastweek_beginning_time = int(time.mktime(lastweek_beginning.timetuple()))
%lastweek_end = lastweek_beginning + datetime.timedelta(days = 7)
%lastweek_end_time = int(time.mktime(lastweek_end.timetuple()))

%thismonth = datetime.datetime.now() - datetime.timedelta(days = 31)
%thismonth_beginning = datetime.datetime(thismonth.year, thismonth.month, thismonth.day,0,0,0,0)
%thismonth_beginning_time = int(time.mktime(thismonth_beginning.timetuple()))
%thismonth_end = thismonth_beginning + datetime.timedelta(days = 31)
%thismonth_end_time = int(time.mktime(thismonth_end.timetuple()))

<!-- Logs parameters -->
<ul class="sliding-navigation drop-shadow" id="parameters">
  <li class="sliding-element"><h3>Parameters</h3></li>
  %if len(params['logs_hosts']) > 0:
  <li class="sliding-element">
    <a href="/logs/hosts_list" data-toggle="modal" data-target="#modal"><i class="fa fa-gear"></i> Hosts filter: {{len(params['logs_hosts'])}}
    <ul>
    %for log_host in params['logs_hosts']:
      <li class="sliding-element">{{log_host}}</li>
    %end
    </ul>
    </a>
  </li>
  %end
  %if len(params['logs_services']) > 0:
  <li class="sliding-element">
    <a href="/logs/services_list" data-toggle="modal" data-target="#modal"><i class="fa fa-gear"></i> Services filter: 
    <ul>
    %for log_service in params['logs_services']:
      <li class="sliding-element">{{log_service}}</li>
    %end
    </ul>
    </a>
  </li>
  %end
  %if len(params['logs_type']) > 0:
  <li class="sliding-element">
    <a href="/logs/logs_type_list" data-toggle="modal" data-target="#modal"><i class="fa fa-gear"></i> Logs type filter: 
    <ul>
    %for log_type in params['logs_type']:
      <li class="sliding-element">{{log_type}}</li>
    %end
    </ul>
    </a>
  </li>
  %end
</ul>
<script type="text/javascript">
  $(document).ready(function() {
    $('.multiselect').multiselect();
  });

  function getHostsList(url){
    // this code will send a data object via a GET request and alert the retrieved data.
    $.jsonp({
      "url": url+'?callback=?',
      "success": function (response){
        if (response.status == 200) {
          alert(response.text);
        }else{
          alert(response.text);
        }
      },
      "error": function (response) {
        alert('Error !');
      }
    });
  }
</script>

   <script type="text/javascript">
      // Initial start/stop range ...
      var range_start = moment.unix({{range_start}}, 'YYYY-MM-DD');
      // Set default downtime period as two days
      var range_end = moment.unix({{range_end}}, 'YYYY-MM-DD');
   </script>

   <div class="row row-fluid">
     <div class="col-md-6">
       <form class="form-inline pull-left" role="form" method="get" action="/logs">
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

  %if hasattr(records,"__iter__"):
      <table class="table table-condensed">
         <colgroup>
            <col style="width: 10%" />
            <col style="width: 90%" />
         </colgroup>
         <thead>
            <tr>
               <th colspan="2"><em>{{message}}</em></th>
            </tr>
         </thead>
         <tbody style="font-size:x-small;">
            %for log in records:
            <tr>
               <td>{{time.strftime(date_format, time.localtime(log['timestamp']))}}</td>
               <td>{{log['message']}}</td>
            </tr>
            %end
         </tbody>
      </table>
   %else:
      No logs found
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
   </script>

</div>
