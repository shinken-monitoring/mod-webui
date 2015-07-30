%import json

<script type="text/javascript">
   // Initial start/stop for downtime, do not consider seconds ...
   var downtime_start = moment().seconds(0);
   // Set default downtime period as two days
   var downtime_stop = moment().seconds(0).add('days', 2);
  
   var helpdesk_configuration = {{! json.dumps(app.helpdesk_module.get_ui_helpdesk_configuration())}};
   var types = {{! json.dumps(types)}};
   console.debug(types)
   var categories = {{! json.dumps(categories)}};
   console.debug(categories)
   var templates = {{! json.dumps(templates)}};
   console.debug(templates)

   // Form submission ...
   $( 'form' ).submit(function(event) {
      event.preventDefault();

      var parameters = {
           'method':          'kiosks.createTicket'
         , 'itemtype':        '{{itemtype}}'
         , 'item':            {{items_id}}
         , 'entity':          {{entities_id}}
         , 'ticket_title':    $('#ticket_title').val()
         , 'ticket_content':  $('#ticket_content').val()
         , 'ticket_category': $("#ticket_category option:selected").val()
         , 'ticket_type':     $("input[name='ticket_type']:checked").val()
      };
      $('#ticket_hidden_fields input').each(function(index, field) {
         parameters[$(field).attr('name')] = $(field).val();
      });
      console.debug('Ticket creation parameters: ', parameters);

      $.ajax({
         url: '/helpdesk/ticket/create/{{name}}',
         dataType: "jsonp",
         method: "GET",
         data: parameters
      })
      .done(function( data, textStatus, jqXHR ) {
         console.debug('Done: ', url, data, textStatus, jqXHR);
         if (data.status==200) {
            raise_message_ok(data.message);
            console.log('Ticket: ', data.ticket)
         } else {
            raise_message_ko(data.message);
         }
      })
      .fail(function( jqXHR, textStatus, errorThrown ) {
         console.error('Done: ', url, jqXHR, textStatus, errorThrown);
         raise_message_ko(textStatus);
      });

      // Schedule a downtime ...
      if ($('#ticket_downtime').prop("checked")) {
         // Launch downtime request
         do_schedule_downtime("{{name}}", downtime_start.format('X'), downtime_stop.format('X'), '{{user.get_name()}}', $('#ticket_title').val());
      }
      
      start_refresh();
      $('#modal').modal('hide');
   });

   // Ticket downtime changed
   $( "#ticket_downtime" ).on( "change", function (event) {
      console.debug('ticket_downtime, change: ', $('#ticket_downtime').prop("checked"));
      
      if ($('#ticket_downtime').prop("checked")) {
         $("#dtr_downtime").prop("disabled", false);
      } else {
         $("#dtr_downtime").prop("disabled", true);
      }
   });

   // Notification type changed
   $( "#ticket_type_request" ).on( "change", function (event) {
      $('#ticket_type_request').prop("checked", true);

      $('#ticket_category').empty().append($("<option />").val('').text("Select a ticket category"));
      var counter=0;
      $.each(categories, function(key,value) {
         if (value['is_request']=='1') {
            $('#ticket_category').append($("<option />").attr('template_id', value.id_template_request).val(value.id).text(value.completename));
            counter++;
         }
      });
      if (counter == 0) {
         $('#ticket_category').empty().append($("<option />").val('').text("No category defined"));
         
         $('form input[type="submit"]').prop("disabled", true);
      } else {
         $('form input[type="submit"]').prop("disabled", false);
      }
      //$('#ticket_category').selectmenu("refresh", true);
      $('label[for="ticket_content"]').html('Description of the demand');
   });
   $( "#ticket_type_incident" ).on( "change", function (event) {
      $('#ticket_type_incident').prop("checked", true);

      $('#ticket_category').empty().append($("<option />").val('').text("Select a ticket category"));
      var counter=0;
      $.each(categories, function(key,value) {
         if (value['is_incident']=='1') {
            $('#ticket_category').append($("<option />").attr('template_id', value.id_template_incident).val(value.id).text(value.name));
            counter++;
         }
      });
      if (counter == 0) {
         $('#ticket_category').empty().append($("<option />").val('').text("No category defined"));
         
         $('form input[type="submit"]').prop("disabled", true);
      } else {
         $('form input[type="submit"]').prop("disabled", false);
      }
      //$('#ticket_category').selectmenu("refresh", true);
      $('label[for="ticket_content"]').html('Description of the incident');
   });
   
   // Category changed
   $( "#ticket_category" ).on( "change", function (event) {
      event.stopPropagation();
     
      var category_id = $("#ticket_category option:selected").val();
      var template_id = $("#ticket_category option:selected").attr('template_id');
     
      $.each(helpdesk_configuration['templates'], function(index,template) {
         if (template['id']==template_id) {
            $('#ticket_hidden_fields').empty();
            $.each(template, function(key,value) {
               if (key=='id' || key=='template_type') return;
           
               if (key=='name') {
                  $("#ticket_title").val(template['name']);
               } else if (key=='content') {
                  $("#ticket_content").val(template['content']);
               } else {
                  $('#ticket_hidden_fields').append($('<input type="hidden" name="'+key+'"/>').val(value));
               }
            });
         }
      });
   });

   $('#modal').on('shown.bs.modal', function () {
      // Set up date range picker ...
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
      $('#dtr_downtime').val(downtime_start.format('YYYY-MM-DD HH:mm') + ' to ' +  downtime_stop.format('YYYY-MM-DD HH:mm'));
    
      // Update dates on apply button ...
      $('#dtr_downtime').on('apply.daterangepicker', function(ev, picker) {
         downtime_start = picker.startDate; downtime_stop = picker.endDate;
      });
      
      // Ticket type
      $( "#ticket_type_request" ).trigger('change');
      
      // Schedule downtime
      $( "#ticket_downtime" ).trigger('change');
   });
</script>

<div class="modal-dialog">
   <div class="modal-content">
      <div class="modal-header">
         <a class="close" data-dismiss="modal">×</a>
         <h3>Create a ticket for {{name}}</h3>
      </div>

      <div class="modal-body">
         <form name="input_form" role="form">
            <!-- Hidden fields -->
            <input type="hidden" name="element_name" value="{{name}}"> 
            <input type="hidden" name="entities_id" value="{{entities_id}}"> 
            <input type="hidden" name="itemtype" value="{{itemtype}}"> 
            <input type="hidden" name="items_id" value="{{items_id}}"> 
            
            <div class="form-group">
               <label>Downtime</label>
               <div class="input-group">
                  <label class="radio-inline" for="ticket_downtime">
                     <input type="checkbox" name="ticket_downtime" id="ticket_downtime" value="1"> Schedule a downtime? 
                  </label>
               </div>

               <label class="sr-only" for="dtr_downtime">Downtime date range</label>
               <div class="input-group">
                  <span class="input-group-addon"><i class="fa fa-calendar"></i></span>
                  <input type="text" name="dtr_downtime" id="dtr_downtime" class="form-control" />
               </div>
            </div>
            
            <hr/>
            <div class="form-group">
               <!-- Ticket type -->
               <label for="ticket_type">Ticket type</label>
               <div class="input-group">
                  <label class="radio-inline">
                     <input type="radio" name="ticket_type" id="ticket_type_request" value="1"> Request 
                  </label>
                  <label class="radio-inline">
                     <input type="radio" name="ticket_type" id="ticket_type_incident" value="2"> Incident 
                  </label>
               </div>
            </div>

            <div class="form-group">
               <!-- Ticket category -->
               <label for="ticket_category">Ticket category</label>
               <select id="ticket_category" name="ticket_category" class="form-control">
                  <option>1</option>
                  <option>2</option>
                  <option>3</option>
                  <option>4</option>
                  <option>5</option>
               </select>
            </div>

            <div class="form-group">
               <label for="ticket_title">Ticket title</label>
               <input id="ticket_title" name="ticket_title" type="text" required class="form-control" placeholder="Title">
            </div>
            
            <div class="form-group">
               <label for="ticket_content">Ticket description</label>
               <textarea id="ticket_content" name="ticket_content" class="form-control" rows="5" placeholder="Ticket description">Problem/demand detailed description made by {{user.get_name()}}</textarea>
            </div>
           
            <input type="submit" class="btn btn-primary btn-lg btn-block" value="Submit" />
         </form>
      </div>
   </div>
</div>


