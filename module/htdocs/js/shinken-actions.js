/*Copyright (C) 2009-2014 :
     Gabes Jean, naparuba@gmail.com
     Gerhard Lausser, Gerhard.Lausser@consol.de
     Gregory Starck, g.starck@gmail.com
     Hartmut Goebel, h.goebel@goebel-consult.de
     Andreas Karfusehr, andreas@karfusehr.de
     Frederic Mohier, frederic.mohier@gmail.com

 This file is part of Shinken.

 Shinken is free software: you can redistribute it and/or modify
 it under the terms of the GNU Affero General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 Shinken is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU Affero General Public License for more details.

 You should have received a copy of the GNU Affero General Public License
 along with Shinken.  If not, see <http://www.gnu.org/licenses/>.
*/

var actions_logs=false;

/**
 * Get current user preference value:
 * - key
 * - callback function called after data are posted
**/
function get_user_preference(key, callback) {

   $.get("/user/get_pref", { 'key' : key }, function( data, textStatus, jqXHR ) {
      if (actions_logs) console.debug('Got: '+key, data, textStatus);

      if (typeof callback !== 'undefined' && $.isFunction(callback)) {
         if (actions_logs) console.debug('Calling callback function ...', callback);
         callback(JSON.parse(data));
      }
   });
}

/**
 * Save current user preference value:
 * - key / value
 * - callback function called after data are posted
**/
function save_user_preference(key, value, callback) {

   $.get("/user/save_pref", { 'key' : key, 'value' : value }, function() {
      if (actions_logs) console.debug('User preference saved: ', key, value);
      // raise_message_ok("User parameter saved");

      if (typeof callback !== 'undefined' && $.isFunction(callback)) {
         if (actions_logs) console.debug('Calling callback function ...', callback);
         callback(JSON.parse(value));
      }
   });
}

/**
 * Save common preference value
 * - key / value
 * - callback function called after data are posted
**/
function save_common_preference(key, value, callback) {

   $.get("/user/save_common_pref", { 'key' : key, 'value' : value}, function() {
      if (actions_logs) console.debug('Common preference saved: ', key, value);
      // raise_message_ok("Common parameter saved");

      if (typeof callback !== 'undefined' && $.isFunction(callback)) {
         if (actions_logs) console.debug('Calling callback function ...', callback);
         callback(JSON.parse(value));
      }
   });
}


/*
 * Launch the request
 */
function launch(url, response_message){
   if (actions_logs) console.debug('Launch external command: ', url);

   $.ajax({
      url: url,
      dataType: "jsonp",
      method: "GET",
      data: { response_text: response_message }
   })
   .done(function( data, textStatus, jqXHR ) {
      if (actions_logs) console.debug('Done: ', url, data, textStatus, jqXHR);
      raise_message_ok(data.text)
   })
   .fail(function( jqXHR, textStatus, errorThrown ) {
      if (actions_logs) console.error('Done: ', url, jqXHR, textStatus, errorThrown);
      raise_message_ko(textStatus);
   })
   .always(function(  ) {
      window.setTimeout(function() {
         // Refresh the current page after a short delay
         do_refresh();
      }, 5000);
   });
}


/*
 * Message raise part
 */
function raise_message_ok(text){
   alertify.log(text, "success", 5000);
}

function raise_message_ko(text){
   alertify.log(text, "error", 5000);
}


/*
 * Get element information
 */
function get_element(name) {
   var parts = name.split('/');
   var elt = {
      type : 'UNKNOWN',
      name : 'NOVALUE'
   };
   if (parts.length == 1){
      // 1 element means HOST
      elt.type = 'HOST';
      elt.name = parts[0];
   } else {
      // 2 means Service
      elt.type = 'SVC';
      elt.name = parts[0]+'/'+parts[1];

      // And now for all elements, change the / into a $SLASH$ macro
      for (var i=2; i<parts.length; i++){
         elt.name = elt.name+ '$SLASH$'+ parts[i];
      }
   }
   return elt
}

/*
 * Event handlers
 */
/* The command that will launch an event handler */
function try_to_fix(name) {
   var elt = get_element(name);
   var url = '/action/LAUNCH_'+elt.type+'_EVENT_HANDLER/'+elt.name;
   // We can launch it :)
   launch(url, elt.type+': '+name+', event handler activated');
}



/*
This is used to submit a passive check result for a particular host.
The "status_code" indicates the state of the host check and should
be one of the following: 0=UP, 1=UNREACHABLE, 2=DOWN.
The "plugin_output" argument contains the text returned from the
host check, along with optional performance data.

This is used to submit a passive check result for a particular service.
The "return_code" field should be one of the following: 0=OK,
1=WARNING, 2=CRITICAL, 3=UNKNOWN.
The "plugin_output" field contains text output from the service
check, along with optional performance data.
*/
function submit_check(name, return_code, output){
   var elt = get_element(name);
   var url = '/action/PROCESS_'+elt.type+'_HOST_CHECK_RESULT/'+elt.name+'/'+return_code+'/'+output;
   // We can launch it :)
   launch(url, elt.type+': '+name+', check result submitted');
}


/*
 * Changes the value of a custom host variable.
 */
function change_custom_var(name, custom_var, value){
   var elt = get_element(name);
   var url = '/action/CHANGE_CUSTOM_'+elt.type+'_VAR/'+elt.name+'/'+custom_var+'/'+value;
   // We can launch it :)
   launch(url, elt.type+': '+name+', custom variable changed');
}


/*
 * Launch the check_command
 */
function recheck_now(name) {
   var elt = get_element(name);
   var now = '$NOW$';
   var url = '/action/SCHEDULE_FORCED_'+elt.type+'_CHECK/'+elt.name+'/'+now;
   // We can launch it :)
   launch(url, elt.type+': '+name+', check forced');
}


/*
 * Enable/disable host/service checks
 * See #226
 */
function toggle_active_checks(name, b){
   var elt = get_element(name);

   if (actions_logs) console.debug("Toggle active checks for: ", name, ", currently: ", b)

   if (b) {
      var url = '/action/DISABLE_' + elt.type + '_CHECK/' + elt.name;
      launch(url, 'Active checks disabled');
   } else {
      var url = '/action/ENABLE_' + elt.type + '_CHECK/' + elt.name;
      launch(url, 'Active checks enabled');
   }
}
function toggle_passive_checks(name, b){
   var elt = get_element(name);

   if (actions_logs) console.debug("Toggle passive checks for: ", name, ", currently: ", b)

   if (b) {
      var url = '/action/DISABLE_PASSIVE_' + elt.type + '_CHECKS/' + elt.name;
      launch(url, 'Passive checks disabled');
   } else {
      var url = '/action/ENABLE_PASSIVE_' + elt.type + '_CHECKS/' + elt.name;
      launch(url, 'Passive checks enabled');
   }
}
function toggle_host_checks(name, b){
   var elt = get_element(name);

   if (elt.type == 'HOST') {
      if (actions_logs) console.debug("Toggle host checks for: ", name, ", currently: ", b);

      if (b) {
          var url = '/action/DISABLE_HOST_SVC_CHECKS/' + elt.name;
          launch(url, 'Host services checks disabled');
      } else {
          var url = '/action/ENABLE_HOST_SVC_CHECKS/' + elt.name;
          launch(url, 'Host services checks enabled');
      }
   }
}


/*
 * Enable/disable all notifications
 */
function toggle_all_notifications(b){
   if (actions_logs) console.debug("Toggle all notifications, currently: ", b)

   if (b) {
      var url = '/action/DISABLE_NOTIFICATIONS';
      launch(url, 'All notifications disabled');
   } else {
      var url = '/action/ENABLE_NOTIFICATIONS'
      launch(url, 'All notifications enabled');
   }
}


/*
 * Enable/disable host/service notifications
 */
function toggle_notifications(name, b){
   if (actions_logs) console.debug("Toggle notifications for: ", name, ", currently: ", b)

   var elt = get_element(name);
   // Inverse the active check or not for the element
   if (b) { // go disable
      var url = '/action/DISABLE_'+elt.type+'_NOTIFICATIONS/'+elt.name;
      launch(url, elt.type+', notifications disabled');
   } else { // Go enable
      var url = '/action/ENABLE_'+elt.type+'_NOTIFICATIONS/'+elt.name;
      launch(url, elt.type+', notifications enabled');
   }
}


/*
 * Enable/disable host/service event handler
 */
function toggle_event_handlers(name, b){
   var elt = get_element(name);
   // Inverse the event handler or not for the element
   if (b) { // go disable
      var url = '/action/DISABLE_'+elt.type+'_EVENT_HANDLER/'+elt.name;
      launch(url, elt.type+', event handler disabled');
   } else { // Go enable
      var url = '/action/ENABLE_'+elt.type+'_EVENT_HANDLER/'+elt.name;
      launch(url, elt.type+', event handler enabled');
   }
}


/*
 * Enable/disable host/service flapping detection
 */
function toggle_flap_detection(name, b){
   if (actions_logs) console.debug("Toggle flapping detection for: ", name, ", currently: ", b)

   var elt = get_element(name);
   // Inverse the flap detection for the element
   if (b) { //go disable
      var url = '/action/DISABLE_'+elt.type+'_FLAP_DETECTION/'+elt.name;
      launch(url, elt.type+', flapping detection disabled');
   } else {
      var url = '/action/ENABLE_'+elt.type+'_FLAP_DETECTION/'+elt.name;
      launch(url, elt.type+', flapping detection enabled');
   }
}


/*
 * Comments
 */
/*
 Adds a comment to a particular host.
 If the "persistent" field is set to zero (0), the comment will be deleted
 the next time Nagios is restarted. Otherwise, the comment will persist
 across program restarts until it is deleted manually.
*/
var shinken_comment_persistent = '1';
/* The command that will add a persistent comment */
function add_comment(name, user, comment){
   var elt = get_element(name);
   var url = '/action/ADD_'+elt.type+'_COMMENT/'+elt.name+'/'+shinken_comment_persistent+'/'+user+'/'+comment;
   // We can launch it :)
   launch(url, elt.type+': '+name+', comment added');
}


/* The command that will delete a comment */
function delete_comment(name, i) {
   var elt = get_element(name);
   var url = '/action/DEL_'+elt.type+'_COMMENT/'+i;
   // We can launch it :)
   launch(url, elt.type+': '+name+', comment deleted');
}


/* The command that will delete all comments */
function delete_all_comments(name) {
   var elt = get_element(name);
   var url = '/action/DEL_ALL_'+elt.type+'_COMMENTS/'+elt.name;
   // We can launch it :)
   launch(url, elt.type+': '+name+', all comments deleted');
}



/*
 * Downtimes
 */
/*
 Schedules downtime for a specified host.
 If the "fixed" argument is set to one (1), downtime will start and end
 at the times specified by the "start" and "end" arguments.
 Otherwise, downtime will begin between the "start" and "end" times and
 last for "duration" seconds.
 The "start" and "end" arguments are specified in time_t format (seconds
 since the UNIX epoch).
 The specified host downtime can be triggered by another downtime entry
 if the "trigger_id" is set to the ID of another scheduled downtime entry.
 Set the "trigger_id" argument to zero (0) if the downtime for the
 specified host should not be triggered by another downtime entry.
*/
function do_schedule_downtime(name, start_time, end_time, user, comment, shinken_downtime_fixed, shinken_downtime_trigger, shinken_downtime_duration){
   var elt = get_element(name);
   var url = '/action/SCHEDULE_'+elt.type+'_DOWNTIME/'+elt.name+'/'+start_time+'/'+end_time+'/'+shinken_downtime_fixed+'/'+shinken_downtime_trigger+'/'+shinken_downtime_duration+'/'+user+'/'+comment;
   launch(url, elt.type+': '+name+', downtime scheduled');
}

/* The command that will delete a downtime */
function delete_downtime(name, i) {
   var elt = get_element(name);
   var url = '/action/DEL_'+elt.type+'_DOWNTIME/'+i;
   // We can launch it :)
   launch(url, elt.type+': '+name+', downtime deleted');
}

/* The command that will delete all downtimes */
function delete_all_downtimes(name) {
   var elt = get_element(name);
   var url = '/action/DEL_ALL_'+elt.type+'_DOWNTIMES/'+elt.name;
   // We can launch it :)
   launch(url, elt.type+': '+name+', all downtimes deleted');
}



/*
 * Acknowledges
 */
/*
Allows you to acknowledge the current problem for the specified host/service.
By acknowledging the current problem, future notifications (for the same host state)
are disabled.

 If the "sticky" option is set to two (2), the acknowledgement will remain until
 the host returns to an UP state. Otherwise the acknowledgement will
 automatically be removed when the host changes state.
 If the "notify" option is set to one (1), a notification will be sent out to
 contacts indicating that the current host problem has been acknowledged.
 If the "persistent" option is set to one (1), the comment associated with the
 acknowledgement will survive across restarts of the Shinken process.
 If not, the comment will be deleted the next time Shinken restarts.
*/
function do_acknowledge(name, text, user, shinken_acknowledge_sticky, shinken_acknowledge_notify, shinken_acknowledge_persistent){
   var elt = get_element(name);
   var url = '/action/ACKNOWLEDGE_'+elt.type+'_PROBLEM/'+elt.name+'/'+shinken_acknowledge_sticky+'/'+shinken_acknowledge_notify+'/'+shinken_acknowledge_persistent+'/'+user+'/'+text;
   launch(url, elt.type+': '+name+', acknowledged');
}

/* The command that will delete an acknowledge */
function delete_acknowledge(name) {
   var elt = get_element(name);
   var url = '/action/REMOVE_'+elt.type+'_ACKNOWLEDGEMENT/'+elt.name;
   // We can launch it :)
   launch(url, elt.type+': '+name+', acknowledge deleted');
}

// Join the method to some html classes
$("body").on("click", ".js-add-comment", function () {
    var elt = $(this).data('element');
    var comment = $(this).data('comment');
    display_modal("/forms/comment/add/" + elt);
});

$("body").on("click", ".js-delete-comment", function () {
    var elt = $(this).data('element');
    var comment = $(this).data('comment');
    display_modal("/forms/comment/delete/"+elt+"?comment="+comment);
});

$("body").on("click", ".js-delete-all-comments", function () {
    var elt = $(this).data('element');
    display_modal("/forms/comment/delete_all/"+elt);
});

$("body").on("click", ".js-schedule-downtime", function () {
    var elt = $(this).data('element');
    display_modal("/forms/downtime/add/"+elt);
});

$("body").on("click", ".js-delete-downtime", function () {
    var elt = $(this).data('element');
    var downtime = $(this).data('downtime');
    display_modal("/forms/downtime/delete/"+elt+"?downtime="+downtime);
});

$("body").on("click", ".js-delete-all-downtimes", function () {
    var elt = $(this).data('element');
    display_modal("/forms/downtime/delete_all/"+elt);
});

$("body").on("click", ".js-add-acknowledge", function () {
    var elt = $(this).data('element');
    display_modal("/forms/acknowledge/add/"+elt);
});

$("body").on("click", ".js-remove-acknowledge", function () {
    var elt = $(this).data('element');
    display_modal("/forms/acknowledge/remove/"+elt);
});

$("body").on("click", ".js-recheck", function () {
    var elt = $(this).data('element');
    recheck_now(elt);
});

$("body").on("click", ".js-submit-ok", function () {
    var elt = $(this).data('element');
    display_modal("/forms/submit_check/"+elt);
});

$("body").on("click", ".js-try-to-fix", function () {
    var elt = $(this).data('element');
    try_to_fix(elt);
});

$("body").on("click", ".js-create-ticket", function () {
    var elt = $(this).data('element');
    display_modal("/helpdesk/ticket/add/"+elt);
});

$("body").on("click", ".js-create-ticket-followup", function () {
    var elt = $(this).data('element');
    var ticket = $(this).data('ticket');
    var status = $(this).data('status');
    display_modal("/helpdesk/ticket_followup/add/"+elt+'?ticket='+ticket+'&status='+status);
});
