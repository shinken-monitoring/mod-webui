/*Copyright (C) 2009-2011 :
     Gabes Jean, naparuba@gmail.com
     Gerhard Lausser, Gerhard.Lausser@consol.de
     Gregory Starck, g.starck@gmail.com
     Hartmut Goebel, h.goebel@goebel-consult.de
     Frederic Mohier, frederic.mohier@gmail.com
     Guillaume Subiron, maethor@subiron.org

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


/*
  Tool bar related code
*/
function hide_toolbar(save){
   $('#toolbar').hide();
   $('#problems').addClass('col-lg-12 col-md-12 col-sm-12');
   $('#problems').removeClass('col-lg-9 col-md-8 col-sm-8');
}

function show_toolbar(save){
   $('#toolbar').show();
   $('#problems').addClass('col-lg-9 col-md-8 col-sm-8');
   $('#problems').removeClass('col-lg-12 col-md-12 col-sm-12');
}



/* We keep an array of all selected elements */
var selected_elements = [];

// When we select all, add all in the selected list,
// and hide the select all button, and swap it with
// unselect all one
function select_all_problems(){
   // Maybe the actions are not allowed?
   if (!actions_enabled){
      return;
   }

   // Get all elements name ...
   $('td input[type=checkbox]').each(function(){
      // ... and add to the selected items list.
      add_element($(this).data('item'));
   });

   $('#select_all_btn').hide();
   $('#unselect_all_btn').show();
}

// Unselect all
function unselect_all_problems(){
   $('#select_all_btn').show();
   $('#unselect_all_btn').hide();
   flush_selected_elements();
}


function add_remove_elements(name){
   // Maybe the actions are not allowed. If so, don't do anything ...
   if (!actions_enabled) {return;}

   if (selected_elements.indexOf(name) != -1) {
      remove_element(name);
   } else {
      add_element(name);
   }
}


/* function when we add an element*/
function add_element(name){
   // Force to check the checkbox
   $('td input[type=checkbox][data-item="'+name+'"]').prop("checked", true);
   
   selected_elements.push(name);

   show_toolbar();
   if (actions_enabled) $('#actions').show();
}

/* And of course when we remove it... */
function remove_element(name){
   // Force to uncheck the checkbox
   $('td input[type=checkbox][data-item="'+name+'"]').prop("checked", false);
   
   selected_elements.splice($.inArray(name, selected_elements),1);

   if (selected_elements.length == 0){
      hide_toolbar();
      if (actions_enabled) $('#actions').hide();
      show_select_all_button();

      // Restart page refresh timer
      reinit_refresh();
   }
}


/* Flush selected elements, so clean the list
but also untick them in the UI */
function flush_selected_elements(){
   /* We must copy the list so we can parse it in a clean way
   without fearing some bugs */
   var cpy = $.extend({}, selected_elements);
   $.each(cpy, function(idx, name) {
      remove_element(name)
   });
}


/* 
 * Actions on the problems page
 */
// Recheck 
function recheck_now_one(name){
   recheck_now(name);
}
function recheck_now_all(){
   $.each(selected_elements,function(idx, name){
      recheck_now(name);
   });
   flush_selected_elements();
}


// Submit check result
function submit_check_ok_one(name, user){
   submit_check(name, '0', 'Forced OK from WebUI by '+user);
}
function submit_check_ok_all(user){
   $.each(selected_elements, function(idx, name){
      submit_check(name, '0', 'Forced OK from WebUI by '+user);
   });
   flush_selected_elements();
}


// Try to fix
function try_to_fix_one(name){
   try_to_fix(name);
}
function try_to_fix_all(){
   $.each(selected_elements, function(idx, name){
      try_to_fix(name);
   });
   flush_selected_elements();
}


// Acknowledge
function acknowledge_one(name, user){
   do_acknowledge(name, 'Acknowledged from WebUI by '+user, user);
}
function acknowledge_all(user){
   $.each(selected_elements, function(idx, name){
      do_acknowledge(name, 'Acknowledged from WebUI by '+user, user);
   });
   flush_selected_elements();
}


// Schedule downtime
function downtime_one(name, user){
   // Initial start/stop for downtime, do not consider seconds ...
   var downtime_start = moment().seconds(0);
   var downtime_stop = moment().seconds(0).add('day', 1);

   do_schedule_downtime(name, downtime_start.format('X'), downtime_stop.format('X'), user, 'Downtime scheduled from WebUI by '+user);
}
function downtime_all(user){
   // Initial start/stop for downtime, do not consider seconds ...
   var downtime_start = moment().seconds(0);
   var downtime_stop = moment().seconds(0).add('day', 1);

   $.each(selected_elements, function(idx, name){
      do_schedule_downtime(name, downtime_start.format('X'), downtime_stop.format('X'), user, 'Downtime scheduled from WebUI by '+user);
   });
   flush_selected_elements();
}


// Remove from Web UI
function remove_one(name, user){
   do_remove(name, 'Removed from WebUI by '+user, user);
}
function remove_all(user){
   $.each(selected_elements, function(idx, name){
      do_remove(name, 'Removed from WebUI by '+user, user);
   });
   flush_selected_elements();
}


// On page loaded ... 
$(document).ready(function(){
   // If actions are not allowed, disable the button 'select all' and the checkboxes
   if ("actions_enabled" in window && !actions_enabled) {
      $('#select_all_btn').addClass('disabled');
      $('[id^=selector').attr('disabled', true);
      
      // Get all elements ...
      $('td input[type=checkbox]').each(function(){
         // ... and disable and hide checkbox
         $(this).prop("disabled", true).hide();
      });
   }

   // Problems element check boxes
   $('td input[type=checkbox]').click(function (e) {
      // Do not expand collapsible container ...
      e.stopPropagation();
      
      // Stop page refresh
      stop_refresh();
      
      // Add/remove element from selection
      add_remove_elements($(this).data('item'));
   });
   
   // Graphs popover
   $('[data-toggle="popover"]').popover({
      html: true,
      template: '<div class="popover img-popover"><div class="arrow"></div><div class="popover-inner"><h3 class="popover-title"></h3><div class="popover-content"><p></p></div></div></div>',
   });

   $('[id^=details-]').on('show.bs.collapse', function () {
       $(this).closest('tr').prev().find('.output').removeClass("ellipsis", {duration:200});
   });

   $('[id^=details-]').on('hide.bs.collapse', function () {
       $(this).closest('tr').prev().find('.output').addClass("ellipsis", {duration:200});
   });
});
