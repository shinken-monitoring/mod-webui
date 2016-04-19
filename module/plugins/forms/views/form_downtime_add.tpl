<script type="text/javascript">
   // Initial start/stop for downtime, do not consider seconds ...
   var downtime_start = moment().seconds(0);
   // Set default downtime period as two days
   var downtime_stop = moment().seconds(0).add('hours', "{{ default_downtime_hours }}");

   function submit_local_form(){
      // Launch downtime request and bailout this modal view
      %if elt.__class__.my_type=='contact':
        do_schedule_downtime("{{name}}", downtime_start.format('X'), downtime_stop.format('X'), '{{user.get_name()}}', $('#reason').val(), 'contact', '{{app.shinken_downtime_fixed}}', '{{app.shinken_downtime_trigger}}', '{{app.shinken_downtime_duration}}');
      %else:
        do_schedule_downtime("{{name}}", downtime_start.format('X'), downtime_stop.format('X'), '{{user.get_name()}}', $('#reason').val(), undefined, '{{app.shinken_downtime_fixed}}', '{{app.shinken_downtime_trigger}}', '{{app.shinken_downtime_duration}}');
      %end

      %if elt.__class__.my_type=='host':
      if ($('#dwn_services').is(":checked")) {
      %for service in elt.services:
         do_schedule_downtime("{{name}}/{{service.get_name()}}", downtime_start.format('X'), downtime_stop.format('X'), '{{user.get_name()}}', $('#reason').val(), undefined, '{{app.shinken_downtime_fixed}}', '{{app.shinken_downtime_trigger}}', '{{app.shinken_downtime_duration}}');
      %end
      }
      %end

      start_refresh();
      $('#modal').modal('hide');
   }


   $('#modal').on('shown.bs.modal', function () {
      $("#dtr_downtime").daterangepicker({
         ranges: {
            '2 hours':       [moment(), moment().add('hours', 2)],
            '8 hours':       [moment(), moment().add('hours', 8)],
            '1 day':         [moment(), moment().add('days', 1)],
            '2 days':        [moment(), moment().add('days', 2)],
            '1 week':        [moment(), moment().add('days', 7)],
            '1 month':       [moment(), moment().add('month', 1)],
         },
         format: 'YYYY-MM-DD HH:mm',
         separator: '   to   ',
         minDate: moment(),
         //dateLimit: moment(),
         startDate: moment(),
         endDate: moment().add('days', 2),
         timePicker: true,
         timePickerIncrement: 1,
         timePicker12Hour: false,
         showDropdowns: false,
         showWeekNumbers: false,
         opens: 'right',
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
      <div class="form-group">
         <input name="dwn_services" id="dwn_services" type="checkbox" checked="checked">Same downtime period for all services of the host?</input>
      </div>
      %end

      <div class="form-group">
         <input name="shinken_downtime_fixed" id="shinken_downtime_fixed" type="hidden" value="{{app.shinken_downtime_fixed}}">
         <input name="shinken_downtime_trigger" id="shinken_downtime_trigger" type="hidden" value="{{app.shinken_downtime_trigger}}">
         <input name="shinken_downtime_duration" id="shinken_downtime_duration" type="hidden" value="{{app.shinken_downtime_duration}}">
      </div>

      <div class="form-group">
         <label for="dtr_downtime">Downtime date range</label>
         <div class="input-group">
            <span class="input-group-addon"><i class="fa fa-calendar"></i></span>
            <input type="text" name="dtr_downtime" id="dtr_downtime" class="form-control" />
         </div>
      </div>

      <div class="form-group">
         <textarea name="reason" id="reason" class="form-control" rows="5" placeholder="Downtime comment…">Downtime scheduled from WebUI by {{user.get_name()}}</textarea>
      </div>

      <a href="javascript:submit_local_form();" class="btn btn-primary btn-lg btn-block"> <i class="fa fa-save"></i> Submit</a>
   </form>
</div>
