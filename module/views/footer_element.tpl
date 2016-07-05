%from shinken.bin import VERSION
%setdefault('elt', None)
%setdefault('user', None)

%username = 'anonymous'
%if user is not None:
%if hasattr(user, 'alias') and user.alias != 'none':
%username = user.alias
%else:
%username = user.get_name()
%end
%end


<!-- Footer -->
<footer>
   <nav class="navbar navbar-default navbar-fixed-bottom">
      <div class="container-fluid">
         <!-- Actions bar:
         - enabled when elt is defined ...
         - enabled when problems are selected
         -->
         %if app.can_action():
         <nav id="actions" class="navbar navbar-default navbar-element dropup" role="navigation" style="display:none;">
            <button type="button" class="btn btn-default dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
               <span class="caret"></span>
               <span class="fa fa-bolt"></span>
               <span>Execute an action</span>
            </button>
            <ul class="dropdown-menu" role="menu" aria-labelledby="Actions bar menu">
               %if elt:
                  %elt_type = elt.__class__.my_type
                  <li> <a href="#" action="add-comment" title="Add a comment for this {{elt_type}}"
                     data-element="{{helper.get_uri_name(elt)}}" >
                     <i class="fa fa-plus"></i> Add a comment
                  </a> </li>
                  %if elt.is_problem and elt.event_handler_enabled and elt.event_handler:
                  <li> <a href="#" action="event-handler" title="Try to fix the current problem for this {{elt_type}}"
                     data-element="{{helper.get_uri_name(elt)}}" >
                     <i class="fa fa-magic"></i> Try to fix
                  </a> </li>
                  %end
                  <li> <a href="#" action="recheck" title="Launch the defined check command for this {{elt_type}}"
                     data-element="{{helper.get_uri_name(elt)}}" >
                     <i class="fa fa-refresh"></i> Recheck
                  </a> </li>
                  %if (elt.passive_checks_enabled):
                  <li> <a href="#" action="check-result" title="Set this {{elt_type}} as ok"
                     data-element="{{helper.get_uri_name(elt)}}" >
                     <i class="fa fa-share"></i> Submit check result
                  </a> </li>
                  %end
                  %if elt.state != elt.ok_up and not elt.problem_has_been_acknowledged:
                  <li> <a href="#" action="add-acknowledge" title="Acknowledge this {{elt_type}} problem"
                     data-element="{{helper.get_uri_name(elt)}}" >
                     <i class="fa fa-check"></i> Acknowledge
                  </a> </li>
                  %end
                  %if elt.problem_has_been_acknowledged:
                  <li> <a href="#" action="remove-acknowledge" title="Remove the acknowledge for this {{elt_type}} problem"
                     data-element="{{helper.get_uri_name(elt)}}" >
                     <i class="fa fa-check"></i> Unacknowledge
                  </a> </li>
                  %end
                  <li> <a href="#" action="schedule-downtime" title="Schedule a downtime for this {{elt_type}}"
                     data-element="{{helper.get_uri_name(elt)}}" >
                     <i class="fa fa-ambulance"></i> Schedule a downtime
                  </a> </li>
                  %if elt_type=='host' and app.helpdesk_module.is_available():
                  <li> <a href="#" action="create-ticket" title="Create a ticket for this {{elt_type}}"
                     data-element="{{helper.get_uri_name(elt)}}" >
                     <i class="fa fa-medkit"></i> Create a ticket
                  </a> </li>
                  %end
               %else:
                  <li> <a href="#" action="event-handler" title="Try to fix the selected problems">
                     <i class="fa fa-magic"></i> Try to fix
                  </a> </li>
                  <li> <a href="#" action="recheck" title="Launch the check command for selected problems">
                     <i class="fa fa-refresh"></i> Recheck
                  </a> </li>
                  <li> <a href="#" action="check-result" title="Set the selected problems as OK/UP">
                     <i class="fa fa-share"></i> Set Ok
                  </a> </li>
                  <li> <a href="#" action="add-acknowledge" title="Acknowledge the selected problems">
                     <i class="fa fa-check"></i> Acknowledge
                  </a> </li>
                  <li> <a href="#" action="schedule-downtime" title="Schedule a one day downtime for the selected problems">
                     <i class="fa fa-ambulance"></i> Schedule a downtime
                  </a> </li>
                  <li> <a href="#" action="ignore-checks" title="Remove the selected problems from the problems list">
                     <i class="fa fa-eraser"></i> Uncheck
                  </a> </li>
               %end
            </ul>
         </nav>
         %end

         <!-- Dashboard actions bar:
         - enabled when elt is defined ...
         - enabled when problems are selected
         -->
         <nav id="dashboard-actions" class="navbar navbar-default navbar-dashboard dropup" role="navigation" style="display:none;">
            <button type="button" class="btn btn-default dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
               <span class="caret"></span>
               <span class="fa fa-leaf"></span>
               <span>Add a new widget</span>
            </button>

                  <ul class="dropdown-menu" role="menu" aria-labelledby="Widgets bar menu">
                      %for w in app.get_widgets_for('dashboard'):
                         <li>
                            <a href="#"
                               class="dashboard-widget"
                               data-widget-title="
                                  <button href='#' role='button'
                                      action='add-widget'
                                      data-widget='{{w['widget_name']}}'
                                      data-wuri='{{w['base_uri']}}'
                                      class='btn btn-sm btn-success'>
                                      <span class='fa fa-plus'></span>
                                      Add this widget to your dashboard
                                  </button>"
                               data-widget-description='{{!w["widget_desc"]}} <hr/> <div class="center-block"><img class="text-center" src="{{w["widget_picture"]}}"/></div>'
                               >
                               <span class="fa fa-plus"></span> {{w['widget_name']}}
                            </a>
                         </li>
                      %end
                  </ul>
         </nav>

         <!-- Page footer -->
         <div>
            <img src="/static/images/default_company_xxs.png" alt="Shinken Logo"/>
            <small><em class="text-muted">
               Shinken {{VERSION}} &mdash; Web User Interface {{app.app_version}}, &copy;2011-2016
            </em></small>
         </div>
      </div>
   </nav>
</footer>

<script>
   /* We keep an array of all selected elements */
   var selected_elements = [];
   var eltdetail_logs=false;

   // Add a comment
   $('body').on("click", '[action="add-comment"]', function () {
      var elt = $(this).data('element');
      if (! elt) {
         if (eltdetail_logs) console.error("Unavailable add a comment for a list of problems!")
      } else {
         if (eltdetail_logs) console.debug("Add a comment for: ", elt)
         display_modal("/forms/comment/add/"+elt);
      }
   });

   // Delete a comment
   $('body').on("click", '[action="delete-comment"]', function () {
      var elt = $(this).data('element');
      var comment = $(this).data('comment');
      if (! elt) {
         if (eltdetail_logs) console.error("Unavailable delete a comment for a list of problems!")
      } else {
         if (eltdetail_logs) console.debug("Delete comment '"+comment+"' for: ", elt)

         display_modal("/forms/comment/delete/"+elt+"?comment="+comment);
      }
   });

   // Delete all comments
   $('body').on("click", '[action="delete-comments"]', function () {
      var elt = $(this).data('element');
      if (! elt) {
         if (eltdetail_logs) console.error("Unavailable delete all comments for a list of problems!")
      } else {
         if (eltdetail_logs) console.debug("Delete all comments for: ", elt)

         display_modal("/forms/comment/delete_all/"+elt);
      }
   });

   // Schedule a downtime ...
   $('body').on("click", '[action="schedule-downtime"]', function () {
      var elt = $(this).data('element');
      var user = '{{username}}';
      if (! elt) {
         if (selected_elements.length == 1) {
            var elt = selected_elements[0];
            if (eltdetail_logs) console.debug("Schedule a downtime for: ", elt)

            display_modal("/forms/downtime/add/"+elt);
         } else {
            // Default downtime scheduling...
            // Initial start/stop for downtime, do not consider seconds ...
            var downtime_start = moment().seconds(0);
            var downtime_stop = moment().seconds(0).add('day', 1);

            $.each(selected_elements, function(idx, name){
               if (eltdetail_logs) console.debug("Schedule a downtime for: ", name)
               do_schedule_downtime(name, downtime_start.format('X'), downtime_stop.format('X'), user, 'One day downtime scheduled by '+user, undefined, '{{app.shinken_downtime_fixed}}', '{{app.shinken_downtime_trigger}}', '{{app.shinken_downtime_duration}}');
            });
         }
         flush_selected_elements();
      } else {
         if (eltdetail_logs) console.debug("Schedule a downtime for: ", elt)

         display_modal("/forms/downtime/add/"+elt);
      }
   });

   // Delete a downtime
   $('body').on("click", '[action="delete-downtime"]', function () {
      var elt = $(this).data('element');
      var downtime = $(this).data('downtime');
      if (! elt) {
         if (eltdetail_logs) console.error("Unavailable delete a downtime for a list of problems!")
      } else {
         if (eltdetail_logs) console.debug("Delete downtime '"+downtime+"' for: ", elt)

         display_modal("/forms/downtime/delete/"+elt+"?downtime="+downtime);
      }
   });

   // Delete all downtimes
   $('body').on("click", '[action="delete-downtimes"]', function () {
      var elt = $(this).data('element');
      if (! elt) {
         if (eltdetail_logs) console.error("Unavailable delete all downtimes for a list of problems!")
      } else {
         if (eltdetail_logs) console.debug("Delete all downtimes for: ", elt)

         display_modal("/forms/downtime/delete_all/"+elt);
      }
   });

   // Add an acknowledge
   $('body').on("click", '[action="add-acknowledge"]', function () {
      var elt = $(this).data('element');
      var user = '{{username}}';
      if (! elt) {
         $.each(selected_elements, function(idx, name){
            if (eltdetail_logs) console.debug("Add acknowledge for: ", name)
            do_acknowledge(name, 'Acknowledged by '+user, user, '{{app.default_ack_sticky}}', '{{app.default_ack_notify}}', '{{app.default_ack_persistent}}');
         });
         flush_selected_elements();
      } else {
         if (eltdetail_logs) console.debug("Button - add an acknowledge for: ", elt)

         display_modal("/forms/acknowledge/add/"+elt);
      }
   });

   // Delete an acknowledge
   $('body').on("click", '[action="remove-acknowledge"]', function () {
      var elt = $(this).data('element');
      if (! elt) {
         if (eltdetail_logs) console.error("Unavailable delete acknowledge for a list of problems!")
      } else {
         if (eltdetail_logs) console.debug("Delete an acknowledge for: ", elt)

         display_modal("/forms/acknowledge/remove/"+elt);
      }
   });

   // Recheck
   $('body').on("click", '[action="recheck"]', function () {
      var elt = $(this).data('element');
      if (! elt) {
         $.each(selected_elements, function(idx, name){
            if (eltdetail_logs) console.debug("Recheck for: ", name)
            recheck_now(name);
         });
         flush_selected_elements();
      } else {
         if (eltdetail_logs) console.debug("Recheck for: ", elt)
         recheck_now(elt);
      }
   });

   // Check result
   $('body').on("click", '[action="check-result"]', function () {
      var elt = $(this).data('element');
      var user = '{{username}}';
      if (! elt) {
         $.each(selected_elements, function(idx, name){
            if (eltdetail_logs) console.debug("Submit check for: ", name)
            submit_check(name, '0', 'Forced OK/UP by '+user);
         });
         flush_selected_elements();
      } else {
         if (eltdetail_logs) console.debug("Submit a check result for: ", elt)

         display_modal("/forms/submit_check/"+elt);
      }
   });

   // Event handler
   $('body').on("click", '[action="event-handler"]', function () {
      var elt = $(this).data('element');
      if (! elt) {
         $.each(selected_elements, function(idx, name){
            if (eltdetail_logs) console.debug("Try to fix for: ", name)
            try_to_fix(name);
         });
         flush_selected_elements();
      } else {
         if (eltdetail_logs) console.debug("Try to fix: ", elt)

         try_to_fix(elt);
      }
   });

   // Ignore checks
   $('body').on("click", '[action="ignore-checks"]', function () {
      var elt = $(this).data('element');
      var user = '{{username}}';
      if (! elt) {
         $.each(selected_elements, function(idx, name){
            if (eltdetail_logs) console.debug("Remove for: ", name)
            do_remove(name, 'Removed by '+user, user);
         });
         flush_selected_elements();
      } else {
         if (problems_logs) console.debug("Remove for: ", elt)

         do_remove(elt, 'Removed by '+user, user);
      }
   });

   // Create a ticket ...
   $('body').on("click", '[action="create-ticket"]', function () {
      var elt = $(this).data('element');
      var user = '{{username}}';
      if (elt) {
         if (eltdetail_logs) console.debug("Create a ticket for: ", elt)
         display_modal("/helpdesk/ticket/add/"+elt);
      }
   });

   // Create a ticket follow-up...
   $('body').on("click", '[action="create-ticket-followup"]', function () {
      var elt = $(this).data('element');
      var user = '{{username}}';
      var ticket = $(this).data('ticket');
      var status = $(this).data('status');
      if (elt) {
         if (eltdetail_logs) console.debug("Create a ticket follow-up for: ", elt, 'ticket #', ticket)
         display_modal("/helpdesk/ticket_followup/add/"+elt+'?ticket='+ticket+'&status='+status);
      }
   });

   // Add a widget
   $('body').on("click", '[action="add-widget"]', function () {
      AddNewWidget($(this).data('wuri'), null, 'widget-place-1');
   });

   $('body').on("click", '.dashboard-widget', function () {
      // Display modal dialog box
      $('#modal .modal-title').html($(this).data('widget-title'));
      $('#modal .modal-body').html($(this).data('widget-description'));
      $('#modal').modal({
         keyboard: true,
         show: true,
         backdrop: 'static'
      });
   });

</script>
