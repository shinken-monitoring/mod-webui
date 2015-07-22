%import json
%import time

%# Specific content for breadrumb
%rebase("layout", title='Availability for all hosts', breadcrumb=[ ['All hosts', '/minemap'] ])


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

   %include('availability.tpl', records=records)
   
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