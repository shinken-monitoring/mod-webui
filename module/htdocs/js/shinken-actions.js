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

// Utility function
function capitalize (text) {
   return text.charAt(0).toUpperCase() + text.slice(1).toLowerCase();
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
function get_elements(name){
   var elts = name.split('/');
   var elt = {
      type : 'UNKNOWN',
      namevalue : 'NOVALUE'
   };
   if (elts.length == 1){
      // 1 element means HOST
      elt.type = 'HOST';
      elt.namevalue = elts[0];
      elt.nameslash = elts[0];
   } else { 
      // 2 means Service
      elt.type = 'SVC';
      elt.namevalue = elts[0]+';'+elts[1];
      elt.nameslash = elts[0]+'/'+elts[1];
    
      // And now for all elements, change the / into a $SLASH$ macro
      for (var i=2; i<elts.length; i++){
         elt.namevalue = elt.namevalue+ '$SLASH$'+ elts[i];
         elt.nameslash = elt.nameslash+ '$SLASH$'+ elts[i];
      }
   }
   return elt
}

/*
 * Event handlers
 */
/* The command that will launch an event handler */
function try_to_fix(name) {
   var elts = get_elements(name);
   var url = '/action/LAUNCH_'+elts.type+'_EVENT_HANDLER/'+elts.namevalue;
   // We can launch it :)
   launch(url, capitalize(elts.type)+': '+name+', event handler activated');
}



/*
 * Remove an element from WebUI
 */
function do_remove(name, text, user){
  var elts = get_elements(name);
  
  /* A Remove is in fact some several commands :
     DISABLE_SVC_NOTIFICATIONS
     DISABLE_SVC_EVENT_HANDLER
     PROCESS_SERVICE_CHECK_RESULT
     DISABLE_SVC_CHECK
     DISABLE_PASSIVE_SVC_CHECKS
   */

   disable_notifications(elts);
   disable_event_handlers(elts);
   add_comment(name, user, text);
   submit_check(name, 0, text);
   // WARNING : Disable passive checks make the set not push, 
   // so we only disable active checks
   disable_checks(elts, false);

   // And later after (10s), we push a full disable, so passive too
   setTimeout(function(){
      disable_checks(elts, true);
   }, 10000);
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
   var elts = get_elements(name);
   var url = '/action/PROCESS_';
   if (elts.type == 'HOST'){
      url += 'HOST_CHECK_RESULT/'+elts.nameslash+'/'+return_code+'/'+output;
   } else {
      url += 'SERVICE_CHECK_RESULT/'+elts.nameslash+'/'+return_code+'/'+output;
   }
   // We can launch it :)
   launch(url, capitalize(elts.type)+': '+name+', check result submitted');
}


/*
 * Changes the value of a custom host variable.
 */
function change_custom_var(name, custom_var, value){
   var elts = get_elements(name);
   var url = '/action/CHANGE_CUSTOM_';
   if (elts.type == 'HOST'){
      url += 'HOST_VAR/'+elts.nameslash+'/'+custom_var+'/'+value;
   } else {
      url += 'SVC_VAR/'+elts.nameslash+'/'+custom_var+'/'+value;
   }
   // We can launch it :)
   launch(url, capitalize(elts.type)+': '+name+', custom variable changed');
}


/* 
 * Launch the check_command
 */
function recheck_now(name) {
   var elts = get_elements(name);
   var now = '$NOW$';
   var url = '/action/SCHEDULE_FORCED_'+elts.type+'_CHECK/'+elts.nameslash+'/'+now;
   // We can launch it :)
   launch(url, capitalize(elts.type)+': '+name+', check forced');
}


/*
 * Enable/disable host/service checks
 * See #226
 */
function toggle_active_checks(name, b){
   if (actions_logs) console.debug("Toggle active checks for: ", name, ", currently: ", b)

   var elts = get_elements(name);
   // Inverse the active check or not for the element
   if (b) { // go disable
      disable_checks(elts, false);
   } else { // Go enable, passive too
      enable_checks(elts, false);
   }
}
function toggle_passive_checks(name, b){
   if (actions_logs) console.debug("Toggle passive checks for: ", name, ", currently: ", b)

   var elts = get_elements(name);
   // Inverse the passive check or not for the element
   if (b) {
      disable_checks(elts, true);
   } else {
      enable_checks(elts, true);
   }
}
function enable_checks(elts, passive_too){
   var url = '/action/ENABLE_'+elts.type+'_CHECK/'+elts.nameslash;
   launch(url, 'Active checks enabled');
   if (passive_too){
      var url = '/action/ENABLE_PASSIVE_'+elts.type+'_CHECKS/'+elts.nameslash;
      launch(url, 'Passive checks enabled');
   }
   // Enable host services only if it's an host ;)
   if (elts.type == 'HOST'){
      var url = '/action/ENABLE_HOST_SVC_CHECKS/'+elts.nameslash;
      launch(url, 'Host services checks enabled');
   }
}
function disable_checks(elts, passive_too){
   var url = '/action/DISABLE_'+elts.type+'_CHECK/'+elts.nameslash;
   launch(url, 'Active checks disabled');
   if (passive_too){
      var url = '/action/DISABLE_PASSIVE_'+elts.type+'_CHECKS/'+elts.nameslash;
      launch(url, 'Passive checks disabled');
   }
   // Disable host services only if it's an host ;)
   if (elts.type == 'HOST'){
      var url = '/action/DISABLE_HOST_SVC_CHECKS/'+elts.nameslash;
      launch(url, 'Host services checks disabled');
   }
}


/*
 * Enable/disable host/service notifications
 */
function toggle_notifications(name, b){
   if (actions_logs) console.debug("Toggle notifications for: ", name, ", currently: ", b)

   var elts = get_elements(name);
   // Inverse the active check or not for the element
   if (b) { // go disable
      var url = '/action/DISABLE_'+elts.type+'_NOTIFICATIONS/'+elts.nameslash;
      launch(url, capitalize(elts.type)+', notifications disabled');
   } else { // Go enable
      var url = '/action/ENABLE_'+elts.type+'_NOTIFICATIONS/'+elts.nameslash;
      launch(url, capitalize(elts.type)+', notifications enabled');
   }
}
function disable_notifications(elts){
   var url = '/action/DISABLE_'+elts.type+'_NOTIFICATIONS/'+elts.nameslash;
   launch(url, capitalize(elts.type)+', notifications disabled');
}


/*
 * Enable/disable host/service event handler
 */
function toggle_event_handlers(name, b){
   var elts = get_elements(name);
   // Inverse the event handler or not for the element
   if (b) { // go disable
      var url = '/action/DISABLE_'+elts.type+'_EVENT_HANDLER/'+elts.nameslash;
      launch(url, capitalize(elts.type)+', event handler disabled');
   } else { // Go enable
      var url = '/action/ENABLE_'+elts.type+'_EVENT_HANDLER/'+elts.nameslash;
      launch(url, capitalize(elts.type)+', event handler enabled');
   }
}
function disable_event_handlers(elts){
   var url = '/action/DISABLE_'+elts.type+'_EVENT_HANDLER/'+elts.nameslash;
   launch(url, capitalize(elts.type)+', event handler disabled');
}


/*
 * Enable/disable host/service flapping detection
 */
function toggle_flap_detection(name, b){
   if (actions_logs) console.debug("Toggle flapping detection for: ", name, ", currently: ", b)

   var elts = get_elements(name);
   // Inverse the flap detection for the element
   if (b) { //go disable
      var url = '/action/DISABLE_'+elts.type+'_FLAP_DETECTION/'+elts.nameslash;
      launch(url, capitalize(elts.type)+', flapping detection disabled');
   } else {
      var url = '/action/ENABLE_'+elts.type+'_FLAP_DETECTION/'+elts.nameslash;
      launch(url, capitalize(elts.type)+', flapping detection enabled');
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
   var elts = get_elements(name);
   var url = '/action/ADD_'+elts.type+'_COMMENT/'+elts.nameslash+'/'+shinken_comment_persistent+'/'+user+'/'+comment;
   // We can launch it :)
   launch(url, capitalize(elts.type)+': '+name+', comment added');
}


/* The command that will delete a comment */
function delete_comment(name, i) {
   var elts = get_elements(name);
   var url = '/action/DEL_'+elts.type+'_COMMENT/'+i;
   // We can launch it :)
   launch(url, capitalize(elts.type)+': '+name+', comment deleted');
}


/* The command that will delete all comments */
function delete_all_comments(name) {
   var elts = get_elements(name);
   var url = '/action/DEL_ALL_'+elts.type+'_COMMENTS/'+elts.nameslash;
   // We can launch it :)
   launch(url, capitalize(elts.type)+': '+name+', all comments deleted');
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
var shinken_downtime_fixed='1';
var shinken_downtime_trigger='0';
var shinken_downtime_duration='0';
function do_schedule_downtime(name, start_time, end_time, user, comment){
   var elts = get_elements(name);
   var url = '/action/SCHEDULE_'+elts.type+'_DOWNTIME/'+elts.nameslash+'/'+start_time+'/'+end_time+'/'+shinken_downtime_fixed+'/'+shinken_downtime_trigger+'/'+shinken_downtime_duration+'/'+user+'/'+comment;
   launch(url, capitalize(elts.type)+': '+name+', downtime scheduled');
}

/* The command that will delete a downtime */
function delete_downtime(name, i) {
   var elts = get_elements(name);
   var url = '/action/DEL_'+elts.type+'_DOWNTIME/'+i;
   // We can launch it :)
   launch(url, capitalize(elts.type)+': '+name+', downtime deleted');
}

/* The command that will delete all downtimes */
function delete_all_downtimes(name) {
   var elts = get_elements(name);
   var url = '/action/DEL_ALL_'+elts.type+'_DOWNTIMES/'+elts.nameslash;
   // We can launch it :)
   launch(url, capitalize(elts.type)+': '+name+', all downtimes deleted');
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
 acknowledgement will survive across restarts of the Nagios process. 
 If not, the comment will be deleted the next time Nagios restarts.
*/
var shinken_acknowledge_sticky='2';
var shinken_acknowledge_notify='1';
var shinken_acknowledge_persistent='1';
function do_acknowledge(name, text, user){
   var elts = get_elements(name);
   var url = '/action/ACKNOWLEDGE_'+elts.type+'_PROBLEM/'+elts.nameslash+'/'+shinken_acknowledge_sticky+'/'+shinken_acknowledge_notify+'/'+shinken_acknowledge_persistent+'/'+user+'/'+text;
   launch(url, capitalize(elts.type)+': '+name+', acknowledged');
}

/* The command that will delete an acknowledge */
function delete_acknowledge(name) {
   var elts = get_elements(name);
   var url = '/action/REMOVE_'+elts.type+'_ACKNOWLEDGEMENT/'+name;
   // We can launch it :)
   launch(url, capitalize(elts.type)+': '+name+', acknowledge deleted');
}
