%user = app.get_user()
<script type="text/javascript">
   // Initial start/stop for downtime, do not consider seconds ...
   var downtime_start = moment().seconds(0);
   // Set default downtime period as two days
   var downtime_stop = moment().seconds(0).add('hours', "{{ default_downtime_hours }}");

   function submit_local_form(){
      // Launch downtime request and bailout this modal view
     do_schedule_downtime("{{name}}", downtime_start.format('X'), downtime_stop.format('X'), '{{user.get_username()}}', $('#reason').val(), '{{app.shinken_downtime_fixed}}', '{{app.shinken_downtime_trigger}}', '{{app.shinken_downtime_duration}}');

      %if elt.__class__.my_type=='host':
      if ($('#dwn_services').is(":checked")) {
      %for service in elt.services:
         do_schedule_downtime("{{name}}/{{service.get_name()}}", downtime_start.format('X'), downtime_stop.format('X'), '{{user.get_username()}}', $('#reason').val(), '{{app.shinken_downtime_fixed}}', '{{app.shinken_downtime_trigger}}', '{{app.shinken_downtime_duration}}');
      %end
      }
      %end

      enable_refresh();
      $('#modal').modal('hide');
   }


   $('#modal').on('shown.bs.modal', function () {
      $("#dtr_downtime").daterangepicker({
         ranges: {
            '1 hour':       [moment(), moment().add(1, 'hours')],
            '3 days':       [moment(), moment().add(3, 'days').hour(8).minutes(0)],
            '7 days':       [moment(), moment().add(7, 'days').hour(8).minutes(0)],
            '30 days':      [moment(), moment().add(30, 'days').hour(8).minutes(0)],
            'Today 9am':    [moment(), moment().hour(9)],
            'Today 14pm':   [moment(), moment().hour(14)],
            'Tomorrow 8am': [moment(), moment().add(1, 'days').hour(8).minutes(0)],
            'Next Monday 8am':     [moment(), moment().add(7, 'days').startOf('week').hours(8).minutes(0)],
            'First of next month': [moment(), moment().add(1, 'month').startOf('month').hours(8).minutes(0)],
            'First of next year':  [moment(), moment().add(1, 'year').startOf('year').hours(8).minutes(0)],
         },
         locale: {
           format: 'YYYY-MM-DD HH:mm',
           separator: '   to   ',
         },
         minDate: moment(),
         //dateLimit: moment(),
         startDate: moment(),
         endDate: moment().add(1, 'days'),
         timePicker: true,
         timePickerIncrement: 10,
         timePicker24Hour: true,
         showDropdowns: false,
         showWeekNumbers: false,
         alwaysShowCalendars: true,
         opens: 'right',
         buttonClasses: 'btn',
         applyButtonClasses: 'btn-primary',
         },

         function(start, end, label) {
            downtime_start = start; downtime_stop = end;
         }
      );

      // Default date range is one hour from now ...
      $('#dtr_downtime').val(downtime_start.format('YYYY-MM-DD HH:mm') + '   to   ' +  downtime_stop.format('YYYY-MM-DD HH:mm'));

      // Update dates on apply button ...
      $('#dtr_downtime').on('apply.daterangepicker', function(ev, picker) {
         downtime_start = picker.startDate; downtime_stop = picker.endDate;
      });
   });
</script>

<div class="modal-header">
   <a class="close" data-dismiss="modal">×</a>
   <h3>Schedule a downtime for {{name}}</h3>
</div>

<div class="modal-body">
   <form name="input_form" role="form">
      %if elt.__class__.my_type=='host':
      <div class="checkbox">
        <label>
          <input name="dwn_services" id="dwn_services" type="checkbox" checked="checked"> Apply the same downtime on all the services of this host</input>
        </label>
      </div>
      %end

      <div class="form-group">
         <input name="shinken_downtime_fixed" id="shinken_downtime_fixed" type="hidden" value="{{app.shinken_downtime_fixed}}">
         <input name="shinken_downtime_trigger" id="shinken_downtime_trigger" type="hidden" value="{{app.shinken_downtime_trigger}}">
         <input name="shinken_downtime_duration" id="shinken_downtime_duration" type="hidden" value="{{app.shinken_downtime_duration}}">
      </div>

      <div class="form-group">
         <div class="input-group" title="Downtime range">
            <span class="input-group-addon"><i class="fas fa-calendar"></i></span>
            <input type="text" name="dtr_downtime" id="dtr_downtime" class="form-control" />
         </div>
      </div>

      <div class="form-group">
         <textarea name="reason" title="Downtime message" id="reason" class="form-control" rows="5" placeholder="Downtime comment…">Downtime scheduled by {{user.get_name()}}</textarea>
      </div>

      <a href="javascript:submit_local_form();" class="btn btn-primary btn-lg btn-block"> <i class="fas fa-save"></i> Submit</a>
   </form>
</div>
