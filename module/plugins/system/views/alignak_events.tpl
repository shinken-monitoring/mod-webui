%rebase("layout", title='Alignak events log', css=['system/css/multiselect.css'], js=['system/js/multiselect.js'], breadcrumb=[ ['Alignak events log', '/alignak/events'] ])

%helper = app.helper

<div class="col-sm-12 panel panel-default">
   <div class="panel-body">
      <div class="row">
         <div style="display: table-cell; vertical-align: middle;" class="text-center">
            <h3 class="panel-title">{{"%d total matching items" % total}}</h3>
         </div>
      </div>

      <div class="row">
         %event_types = { "retention_load", "retention_save", "alert", "notification", "check_result", "webui_comment", "timeperiod_transition", "event_handler", "flapping_start", "flapping_stop", "downtime_start", "downtime_cancelled", "downtime_end", "acknowledge_start", "acknowledge_end" }

         <form class="well form-inline" role="form" method="get" action="/alignak/events">
            <div class="form-group">
               <div class="input-group">
                  <span class="input-group-addon"><i class="fa fa-calendar"></i></span>
                  <input type="text" class="form-control" id="dtr_timerange" placeholder="..." style="width:280px;"/>
               </div>
               <input type="hidden" id="range_start" name="range_start" />
               <input type="hidden" id="range_end" name="range_end" />
            </div>

            <div class="form-group">
               <div class="mod-lg-12">
                  <select id="filter" name="filter" class="form-control multiselect-ui" multiple="multiple">
                  %for s in event_types:
                  <option value="{{s}}" {{'selected="selected"' if s in filters else ''}}>{{s}}</option>
                  %end
                  </select>
               </div>
            </div>

            <div class="form-group">
               <button type="submit" class="btn btn-default btn-primary">Filter</button>
            </div>
         </form>
      </div>

      %if not logs:
         <div class="page-header">
            <h3 class="text-center">No events log found!</h3>
            <h3 class="text-center"><small>Use the date and events filtering to find what you are looking for.</small></h3>
         </div>
      %else:
         <table class="table table-hover table-condensed table-fixed-header">
            <thead>
               <tr>
                  <th></th>
                  <th>Event</th>
                  <th>Host</th>
                  <th>Service</th>
                  <!--<th>User</th>-->
                  <th>Message</th>
               </tr>
            </thead>
            <tbody>
               %for log in logs:
                  <tr>
                     <td title="{{! helper.print_duration(log.get('timestamp', 0), just_duration=True, x_elts=2)}}">{{log.get('date', '')}}</td>
                     <td>{{! helper.get_event_icon(log)}} - {{log.get('type', '')}}</td>
                     <td>{{log.get('host_name', '')}}</td>
                     <td>{{log.get('service_name', '')}}</td>
                     <!--<td>{{log.get('user_name', '')}}</td>-->
                     <td>{{log.get('message', '')}}</td>
                  </tr>
               %end
            </tbody>
         </table>
      %end
   </div>

<script type="text/javascript">
   $(document).ready(function(){
      $('.multiselect-ui').multiselect({
         includeSelectAllOption: true
      });

      // Initial start/stop range ...
      var range_start = moment.unix({{range_start}}, 'YYYY-MM-DD');
      // Set default downtime period as two days
      var range_end = moment.unix({{range_end}}, 'YYYY-MM-DD');

      $("#dtr_timerange").daterangepicker({
            ranges: {
               '1 hour':        [moment().add('hours', -1), moment()],
               '2 hours':       [moment().add('hours', -2), moment()],
               '2 hours':       [moment().add('hours', -4), moment()],
               '8 hours':       [moment().add('hours', -8), moment()],
               '1 day':         [moment().add('days', -1), moment()],
               '2 days':        [moment().add('days', -2), moment()],
               '1 week':        [moment().add('days', -7), moment()],
               '1 month':       [moment().add('month', -1), moment()]
            },
            format: 'YYYY-MM-DD HH:mm',
            separator: ' to ',
            maxDate: moment(),
            startDate: range_start,
            endDate: range_end,
            timePicker: true,
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

      // Default date range is one hour from now ...
      $('#dtr_timerange').val(range_start.format('YYYY-MM-DD HH:mm') + ' to ' +  range_end.format('YYYY-MM-DD HH:mm'));
      $('#range_start').val(range_start.format('X'));
      $('#range_end').val(range_end.format('X'));

      // Update dates on apply button ...
      $('#dtr_timerange').on('apply.daterangepicker', function(ev, picker) {
         range_start = picker.startDate; range_end = picker.endDate;
         console.log(range_start, range_end)
         $('#range_start').val(range_start.unix());
         $('#range_end').val(range_end.unix());
      });
   });
   </script>
</div>
