/*Copyright (C) 2009-2014 :
     Gabes Jean, naparuba@gmail.com
     Gerhard Lausser, Gerhard.Lausser@consol.de
     Gregory Starck, g.starck@gmail.com
     Hartmut Goebel, h.goebel@goebel-consult.de
     Andreas Karfusehr, andreas@karfusehr.de

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


// Utility function
function capitalize (text) {
    return text.charAt(0).toUpperCase() + text.slice(1).toLowerCase();
}


/* ************************************* Message raise part ******************* */
function raise_message_ok(text){
	$.meow({
		message: text,
		icon: '/static/images/ui_notifications/ok.png',
		onTimeout: function () {
			// Reload the page
			// window.location.href = window.location.protocol + "//" + window.location.host + window.location.pathname + '?' + params.join('&');
			window.location.href = window.location.protocol + "//" + window.location.host + window.location.pathname+window.location.hash;
		}
	});
}


function raise_message_error(text){
	$.meow({
		message: text,
		icon: '/static/images/ui_notifications/ko.png',
		onTimeout: function () {
			// Reload the page
			// window.location.href = window.location.protocol + "//" + window.location.host + window.location.pathname + '?' + params.join('&');
			window.location.href = window.location.protocol + "//" + window.location.host + window.location.pathname+window.location.hash;
		}
	});
}


/* React to an action return of the /action page. Look at status
 to see if it's ok or not */
function react(response){
	if (response.status == 200){
		raise_message_ok(response.text);
	}else{
		raise_message_error(response.text);
	}
}

function manage_error(response){
	raise_message_error(response.responseText);
}


/* ************************************* Launch the request ******************* */
function launch(url, response_message){
	// this code will send a data object via a GET request and alert the retrieved data.
	// $.jsonp({
		// "url": url+'?response_text='+response_message+'&callback=?',
		// "success": react,
		// "error": manage_error
	// });
	$.ajax({
		"url": url+'?response_text='+response_message+'&callback=?',
    "dataType": "jsonp",
		"success": react,
		"error": manage_error
	});
}


/* ************************************* Commands ******************* */

function get_elements(name){
	var elts = name.split('/');
	var elt = {
		type : 'UNKNOWN',
		namevalue : 'NOVALUE'
	};
	if (elts.length == 1){
		// 1 element means HOST
		elt.type = 'HOST';
		elt.type_long = 'HOST';
		elt.namevalue = elts[0];
		elt.nameslash = elts[0];
  } else { 
		// 2 means Service
		elt.type = 'SVC';
		elt.type_long = 'SERVICE';
		elt.namevalue = elts[0]+';'+elts[1];
		elt.nameslash = elts[0]+'/'+elts[1];
    
		// And now for all elements, change the / into a $SLASH$ macro
		for(var i=2; i<elts.length; i++){
			elt.namevalue = elt.namevalue+ '$SLASH$'+ elts[i];
			elt.nameslash = elt.nameslash+ '$SLASH$'+ elts[i];
		}
	}
	return elt
}

/* The command that will launch an event handler */
function try_to_fix(name) {
	var elts = get_elements(name);
	var url = '/action/LAUNCH_'+elts.type+'_EVENT_HANDLER/'+elts.namevalue;
	// We can launch it :)
	launch(url, capitalize(elts.type)+': '+name+', event handler activated');
}



function do_acknowledge(name, text, user){
	var elts = get_elements(name);
	var url = '/action/ACKNOWLEDGE_'+elts.type+'_PROBLEM/'+elts.nameslash+'/1/0/1/'+user+'/'+text;
	launch(url, capitalize(elts.type)+': '+name+', acknowledged');
}


function do_remove(name, text, user){
    var elts = get_elements(name);
    
    /* A Remove is in fact some several commands :
       DISABLE_SVC_CHECK
       DISABLE_PASSIVE_SVC_CHECKS
       DISABLE_SVC_NOTIFICATIONS
       DISABLE_SVC_EVENT_HANDLER
       PROCESS_SERVICE_CHECK_RESULT
     */

    disable_notifications(elts);
    disable_event_handlers(elts);
    submit_check(name, 0, text);
    // WARNING : Disable passive checks make the set not push, 
    // so we only disable active checks
    disable_checks(elts, false);
    
    // And later after (10s), we push a full disable, so passive too
    setTimeout(function(){disable_checks(elts, true);}, 10000);
}



//# SCHEDULE_HOST_DOWNTIME;<host_name>;<start_time>;<end_time>;<fixed>;<trigger_id>;<duration>;<author>;<comment>
function do_schedule_downtime(name, start_time, end_time, user, comment){
    var elts = get_elements(name);
    var url = '/action/SCHEDULE_'+elts.type+'_DOWNTIME/'+elts.nameslash+'/'+start_time+'/'+end_time+'/1/0/0/'+user+'/'+comment;
    launch(url, capitalize(elts.type)+': '+name+', downtime scheduled');
}

function submit_check(name, return_code, output){
    var elts = get_elements(name);
    var url = '/action/PROCESS_'+elts.type_long+'_CHECK_RESULT/'+elts.nameslash+'/'+return_code+'/'+output;
    // We can launch it :)
    launch(url, capitalize(elts.type)+': '+name+', check result submitted');
}




/* The command that will launch an event handler */
function recheck_now(name) {
    var elts = get_elements(name);
    var now = '$NOW$';
    var url = '/action/SCHEDULE_FORCED_'+elts.type+'_CHECK/'+elts.nameslash+'/'+now;
    // We can launch it :)
    launch(url, capitalize(elts.type)+': '+name+', check forced');
}


/* For some commands, it's a toggle/un-toggle way */

/* We may do the active AND passive in the same way, 
and the services in the same time */
function toggle_checks(name, b){
	//alert('toggle_active_checks::'+hname+b);
	var elts = get_elements(name);
	// Inverse the active check or not for the element
	if(b){ // go disable
		disable_checks(elts, true);
	}else{ // Go enable, passive too
		enable_checks(elts, true);
	}
}


function toggle_active_checks(name, b){
	var elts = get_elements(name);
	// Inverse the active check or not for the element
	if (b){ // go disable
		disable_checks(elts, false);
	} else { // Go enable, passive too
		enable_checks(elts, false);
	}
}


function toggle_passive_checks(name, b){
	var elts = get_elements(name);
	// Inverse the active check or not for the element
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



function toggle_notifications(name, b){
	var elts = get_elements(name);
	//alert('toggle_active_checks::'+hname+b);
	// Inverse the active check or not for the element
	if(b){ // go disable
		disable_notifications(elts);
	}else{ // Go enable
		enable_notifications(elts);
	}
}

function disable_notifications(elts){
    var url = '/action/DISABLE_'+elts.type+'_NOTIFICATIONS/'+elts.nameslash;
    launch(url, capitalize(elts.type)+', notifications disabled');
}

function enable_notifications(elts){
    var url = '/action/ENABLE_'+elts.type+'_NOTIFICATIONS/'+elts.nameslash;
    launch(url, capitalize(elts.type)+', notifications enabled');
}



function toggle_event_handlers(name, b){
	var elts = get_elements(name);
	//alert('toggle_active_checks::'+hname+b);
	// Inverse the active check or not for the element
	if(b){ // go disable
		disable_event_handlers(elts);
	}else{ // Go enable
		enable_event_handlers(elts);
	}
}

function enable_event_handlers(elts){
	var url = '/action/ENABLE_'+elts.type+'_EVENT_HANDLER/'+elts.nameslash;
	launch(url, capitalize(elts.type)+', event handler enabled');
}

function disable_event_handlers(elts){
	var url = '/action/DISABLE_'+elts.type+'_EVENT_HANDLER/'+elts.nameslash;
	launch(url, capitalize(elts.type)+', event handler disabled');
}

function toggle_flap_detection(name, b){
	var elts = get_elements(name);
	//alert('toggle_flap::'+name+b);
	// Inverse the active check or not for the element
	if(b){ //go disable
		var url = '/action/DISABLE_'+elts.type+'_FLAP_DETECTION/'+elts.nameslash;
		launch(url, capitalize(elts.type)+', flap detection disabled');
	}else{ // Go enable
		var url = '/action/ENABLE_'+elts.type+'_FLAP_DETECTION/'+elts.nameslash;
		launch(url, capitalize(elts.type)+', flap detection enabled');
	}
}



/* The command that will add a persistent comment */
function add_comment(name, user, comment){
    var elts = get_elements(name);
    var url = '/action/ADD_'+elts.type+'_COMMENT/'+elts.nameslash+'/1/'+user+'/'+comment;
    // We can launch it :)
    launch(url, capitalize(elts.type)+', comment added');
}


/* The command that will delete a comment */
function delete_comment(name, i) {
    var elts = get_elements(name);
    var url = '/action/DEL_'+elts.type+'_COMMENT/'+i;
    // We can launch it :)
    launch(url, capitalize(elts.type)+', comment deleted');
}


/* The command that will delete all comments */
function delete_all_comments(name) {
    var elts = get_elements(name);
    var url = '/action/DEL_ALL_'+elts.type+'_COMMENTS/'+elts.nameslash;
    // We can launch it :)
    launch(url, capitalize(elts.type)+', all comments deleted');
}


/* The command that will delete a downtime */
function delete_downtime(name, i) {
    var elts = get_elements(name);
    var url = '/action/DEL_'+elts.type+'_DOWNTIME/'+i;
    // We can launch it :)
    launch(url, capitalize(elts.type)+', downtime deleted');
}


/* The command that will delete all downtimes */
function delete_all_downtimes(name) {
    var elts = get_elements(name);
    var url = '/action/DEL_ALL_'+elts.type+'_DOWNTIMES/'+elts.nameslash;
    // We can launch it :)
    launch(url, capitalize(elts.type)+', all downtimes deleted');
}
