<script type="text/javascript">
   // Initial start/stop for downtime, do not consider seconds ...
   var downtime_start = moment().seconds(0);
   var downtime_stop = moment().seconds(0).add('hours', 1);
  
   function submit_local_form(){
      // Launch downtime request and bailout this modal view
      do_schedule_downtime("{{name}}", downtime_start.format('X'), downtime_stop.format('X'), '{{user.get_name()}}', $('#reason').val());
      start_refresh();
      $('#modal').modal('hide');
   }


   $(function() {
  
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
         endDate: moment().add('hours', 1),
         timePicker: true,
         timePickerIncrement: 1,
         timePicker12Hour: false,
         showDropdowns: false,
         showWeekNumbers: false,
         opens: 'right',
      },
      
      function(start, end, label) {
         downtime_start = start; downtime_stop = stop;
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

<div class="modal-dialog">
   <div class="modal-content">
      <div class="modal-header">
         <a class="close" data-dismiss="modal">×</a>
         <h3>Schedule downtime for {{name}}</h3>
      </div>

      <div class="modal-body">
         <form name="input_form" role="form">
            <div class="form-group">
               <!--<label for="dtr_downtime">Downtime date range</label>-->
               <div class="input-group">
                  <span class="input-group-addon"><i class="fa fa-calendar"></i></span>
                  <input type="text" name="dtr_downtime" id="dtr_downtime" class="form-control" />
               </div>
            </div>

            <div class="form-group">
              <textarea name="reason" id="reason" class="form-control" rows="5" placeholder="Downtime comment…"></textarea>
            </div>
           
            <a href="javascript:submit_local_form();" class="btn btn-primary btn-lg btn-block"> <i class="fa fa-save"></i> Submit</a>
         </form>
      </div>
   </div>
</div>


