%import json

%user = app.get_user()
<script type="text/javascript">
   var helpdesk_configuration = {{! json.dumps(app.helpdesk_module.get_ui_helpdesk_configuration())}};

   // Form submission ...
   $( 'form' ).submit(function(event) {
      event.preventDefault();

      var parameters = {
           'method':          'addTicketFollowup'
         , 'ticket':          '{{ticket}}'
         , 'content':         $('#content').val()
      };
      $('#ticket_hidden_fields input').each(function(index, field) {
         parameters[$(field).attr('name')] = $(field).val();
      });
      parameters['status'] = $("#ticket_status option:selected").attr('status_id');
      parameters['private'] = $('#ticket_downtime').prop("checked");

      $.ajax({
         url: '/helpdesk/ticket_followup/create/{{name}}',
         dataType: "json",
         method: "GET",
         data: parameters
      })
      .done(function( data, textStatus, jqXHR ) {
         console.debug('Done: ', data);
         if (data.status==200) {
            raise_message_ok(data.message);
            //console.log('Ticket: ', data.ticket)
         } else {
            raise_message_ko(data.message);
         }
      })
      .fail(function( jqXHR, textStatus, errorThrown ) {
         console.error('Fail: ', url, jqXHR, textStatus, errorThrown);
         raise_message_ko(textStatus);
      });

      enable_refresh();
      $('#modal').modal('hide');
   });

   // status changed
   $( "#ticket_status" ).on( "change", function (event) {
      event.stopPropagation();

      var status = $("#ticket_status option:selected").val();
      var status_id = $("#ticket_status option:selected").attr('status_id');
   });

   $('#modal').on('shown.bs.modal', function () {
      $('#ticket_status option[status_id="{{status}}"]').prop('selected', true);
   });
</script>

<div class="modal-header">
   <a class="close" data-dismiss="modal">×</a>
   <h3>Add a ticket follow-up to #{{ticket}} for {{name}}</h3>
</div>

<div class="modal-body">
  <form name="input_form" role="form">
    <!-- Hidden fields -->
    <input type="hidden" name="element_name" value="{{name}}">

    <div class="form-group">
       <!-- Ticket status -->
       <!--
           // Tickets status:
           const INCOMING      = 1; // new
           const ASSIGNED      = 2; // assign
           const PLANNED       = 3; // plan
           const WAITING       = 4; // waiting
           const SOLVED        = 5; // solved
           const CLOSED        = 6; // closed
           const ACCEPTED      = 7; // accepted
           const OBSERVED      = 8; // observe
           const EVALUATION    = 9; // evaluation
           const APPROVAL      = 10; // approbation
           const TEST          = 11; // test
           const QUALIFICATION = 12; // qualification
       -->
       <label for="ticket_status">Ticket status</label>
       <select id="ticket_status" name="ticket_status" class="form-control">
          <option status_id="6">Closed</option>
          <option status_id="5">Solved</option>
          <option status_id="4">Waiting</option>
          <option status_id="3">Planned</option>
          <option status_id="2">Assigned</option>
          <option status_id="1">New</option>
       </select>
    </div>

    <div class="form-group">
       <label>Private</label>
       <div class="input-group">
          <label class="radio-inline" for="private_followup">
             <input type="checkbox" name="private_followup" id="private_followup" checked="checked"> Private follow-up?
          </label>
       </div>
    </div>

    <div class="form-group">
       <label for="content">Ticket description</label>
       <textarea id="content" name="content" class="form-control" rows="5" placeholder="Ticket description">Follow-up description made by {{user.get_name()}}</textarea>
    </div>

    <input type="submit" class="btn btn-primary btn-lg btn-block" value="Submit" />
  </form>
</div>
