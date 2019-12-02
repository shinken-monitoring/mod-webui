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

      if (data && typeof callback !== 'undefined' && $.isFunction(callback)) {
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

      if (value && typeof callback !== 'undefined' && $.isFunction(callback)) {
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

      if (value && typeof callback !== 'undefined' && $.isFunction(callback)) {
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
   if (elt.type == 'SVC') {
       elt.type = 'SERVICE';
   }
   var url = '/action/PROCESS_'+elt.type+'_CHECK_RESULT/'+elt.name+'/'+return_code+'/'+output;
   // We can launch it :)
   launch(url, elt.type+': '+name+', check result submitted');
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
      var url = '/action/ENABLE_' + elt.type + '_CHECK/' + elt.name;
      launch(url, 'Active checks enabled');
   } else {
      var url = '/action/DISABLE_' + elt.type + '_CHECK/' + elt.name;
      launch(url, 'Active checks disabled');
   }
}
function toggle_passive_checks(name, b){
   var elt = get_element(name);

   if (actions_logs) console.debug("Toggle passive checks for: ", name, ", currently: ", b)

   if (b) {
      var url = '/action/ENABLE_PASSIVE_' + elt.type + '_CHECKS/' + elt.name;
      launch(url, 'Passive checks enabled');
   } else {
      var url = '/action/DISABLE_PASSIVE_' + elt.type + '_CHECKS/' + elt.name;
      launch(url, 'Passive checks disabled');
   }
}
function toggle_host_checks(name, b){
   var elt = get_element(name);

   if (elt.type == 'HOST') {
      if (actions_logs) console.debug("Toggle host checks for: ", name, ", currently: ", b);

      if (b) {
          var url = '/action/ENABLE_HOST_SVC_CHECKS/' + elt.name;
          launch(url, 'Host services checks enabled');
      } else {
          var url = '/action/DISABLE_HOST_SVC_CHECKS/' + elt.name;
          launch(url, 'Host services checks disabled');
      }
   }
}


/*
 * Enable/disable all notifications
 */
function toggle_all_notifications(b){
   if (actions_logs) console.debug("Toggle all notifications, currently: ", b)

   if (b) {
      var url = '/action/ENABLE_NOTIFICATIONS'
      launch(url, 'All notifications enabled');
   } else {
      var url = '/action/DISABLE_NOTIFICATIONS';
      launch(url, 'All notifications disabled');
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
      var url = '/action/ENABLE_'+elt.type+'_NOTIFICATIONS/'+elt.name;
      launch(url, elt.type+', notifications enabled');
   } else { // Go enable
      var url = '/action/DISABLE_'+elt.type+'_NOTIFICATIONS/'+elt.name;
      launch(url, elt.type+', notifications disabled');
   }
}


/*
 * Enable/disable host/service event handler
 */
function toggle_event_handlers(name, b){
   var elt = get_element(name);
   // Inverse the event handler or not for the element
   if (b) { // go disable
      var url = '/action/ENABLE_'+elt.type+'_EVENT_HANDLER/'+elt.name;
      launch(url, elt.type+', event handler enabled');
   } else { // Go enable
      var url = '/action/DISABLE_'+elt.type+'_EVENT_HANDLER/'+elt.name;
      launch(url, elt.type+', event handler disabled');
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
      var url = '/action/ENABLE_'+elt.type+'_FLAP_DETECTION/'+elt.name;
      launch(url, elt.type+', flapping detection enabled');
   } else {
      var url = '/action/DISABLE_'+elt.type+'_FLAP_DETECTION/'+elt.name;
      launch(url, elt.type+', flapping detection disabled');
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

function submit_comment_form(id){
    var user = $('#user_' + id).val();
    var name = $('#name_' + id).val();
    var comment = $('#comment_' + id).val();

    add_comment(name, user, comment);
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

var selected_elements = [];

function display_nav_actions() {
    $('#nav-filters').addClass('hidden');
    $('#nav-actions').removeClass('hidden');
    $('.navbar-inverse').addClass('navbar-inverse-2');
}

function hide_nav_actions() {
    $('#nav-actions').addClass('hidden');
    $('#nav-filters').removeClass('hidden');
    $('.navbar-inverse').removeClass('navbar-inverse-2');
}

function add_remove_elements(name){
   if (selected_elements.indexOf(name) != -1) {
      remove_element(name);
   } else {
      add_element(name);
   }
}

// Adding an element in the selected elements list
function add_element(name){
   // Force to check the checkbox
   $('td input[type=checkbox][data-item="'+name+'"]').prop("checked", true);

   $('td input[type=checkbox][data-item="'+name+'"]').closest('tr').addClass('selected');

   if (problems_logs) console.log('Select element: ', name)

   selected_elements.push(name);

   $('#js-nb-selected-elts').html(selected_elements.length);

   if (selected_elements.length > 0) {
      display_nav_actions();

      // Stop page refresh
      disable_refresh();
   }
}

// Removing an element from the selected elements list
function remove_element(name){
   // Force to uncheck the checkbox
   $('td input[type=checkbox][data-item="'+name+'"]').prop("checked", false);

   $('td input[type=checkbox][data-item="'+name+'"]').closest('tr').removeClass('selected');

   if (problems_logs) console.log('Unselect element: ', name)
   selected_elements.splice($.inArray(name, selected_elements),1);

   $('#js-nb-selected-elts').html(selected_elements.length);

   if (selected_elements.length == 0){
      hide_nav_actions();

      // Restart page refresh timer
      enable_refresh();
   }
}

// Flush selected elements list
function flush_selected_elements(){
   /* We must copy the list so we can parse it in a clean way
   without fearing some bugs */
   var cpy = $.extend({}, selected_elements);
   $.each(cpy, function(idx, name) {
      remove_element(name)
   });
}


function get_action_element(btn) {
    var elt = btn.data('element');
    if (! elt) {
        if (selected_elements.length == 1) {
            elt = selected_elements[0];
        }
    }

    return elt;
}

$("body").on("click", ".js-delete-comment", function () {
    var elt = $(this).data('element');
    var comment = $(this).data('comment');

    var strconfirm = confirm("Are you sure you want to delete this comment?");

    if (strconfirm == true) {
        delete_comment(elt, comment);
    }
});

$("body").on("click", ".js-schedule-downtime", function () {
    var elt = get_action_element($(this));

    var duration = $(this).data('duration');
    if (duration) {
        var downtime_start = moment().seconds(0).format('X');
        var downtime_stop = moment().seconds(0).add('minutes', duration).format('X');
        var comment = $(this).text() + " downtime scheduled from WebUI by " + user;
        if (elt) {
            do_schedule_downtime(elt, downtime_start, downtime_stop, g_user_name, comment, shinken_downtime_fixed, shinken_downtime_trigger, shinken_downtime_duration);
        } else {
            $.each(selected_elements, function(idx, name){
                do_schedule_downtime(name, downtime_start, downtime_stop, g_user_name, comment, shinken_downtime_fixed, shinken_downtime_trigger, shinken_downtime_duration);
            });
        }
    } else {
        if (elt) {
            display_modal("/forms/downtime/add/"+elt);
        } else {
            // :TODO:maethor:171008:
            alert("Sadly, you cannot define a custom timeperiod on multiple elements at once. This is not implemented yet.");
        }
    }

    flush_selected_elements();
});

$("body").on("click", ".js-delete-downtime", function () {
    var elt = $(this).data('element');
    var downtime = $(this).data('downtime');
    //display_modal("/forms/downtime/delete/"+elt+"?downtime="+downtime);

    var strconfirm = confirm("Are you sure you want to delete this downtime?");

    if (strconfirm == true) {
        delete_downtime(elt, downtime);
        add_comment(elt, g_user_name, "Dowtime "+ downtime + " for " + elt + " deleted by " + user);
    }
});

$("body").on("click", ".js-delete-all-downtimes", function () {
    var elt = get_action_element($(this));

    if (elt) {
        display_modal("/forms/downtime/delete_all/"+elt);
    } else {
        $.each(selected_elements, function(idx, name){
            delete_all_downtimes(name);
        });
    }

    flush_selected_elements();
});

$("body").on("click", ".js-add-acknowledge", function () {
    var elt = get_action_element($(this));

    if (elt) {
        display_modal("/forms/acknowledge/add/"+elt);
    } else {
        $.each(selected_elements, function(idx, name){
            do_acknowledge(name, 'Acknowledged by '+user, g_user_name, default_ack_sticky, default_ack_notify, default_ack_persistent);
        });
    }

    flush_selected_elements();
});

$("body").on("click", ".js-remove-acknowledge", function () {
    var elt = get_action_element($(this));

    if (elt) {
        display_modal("/forms/acknowledge/remove/"+elt);
    } else {
        $.each(selected_elements, function(idx, name){
            delete_acknowledge(name);
        });
    }

    flush_selected_elements();
});

$("body").on("click", ".js-recheck", function () {
    var elt = get_action_element($(this));

    if (elt) {
        recheck_now(elt);
    } else {
        $.each(selected_elements, function(idx, name){
            recheck_now(name);
        });
    }

    flush_selected_elements();
});

$("body").on("click", ".js-submit-ok", function () {
    var elt = get_action_element($(this));

    if (elt) {
        display_modal("/forms/submit_check/"+elt);
    } else {
        $.each(selected_elements, function(idx, name){
            submit_check(name, '0', 'Forced OK/UP by '+user);
        });
    }

    flush_selected_elements();
});

$("body").on("click", ".js-try-to-fix", function () {
    var elt = get_action_element($(this));

    if (elt) {
        try_to_fix(elt);
    } else {
        $.each(selected_elements, function(idx, name){
            try_to_fix(name);
        });
    }

    flush_selected_elements();
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
