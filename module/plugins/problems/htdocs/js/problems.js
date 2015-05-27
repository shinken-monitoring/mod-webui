/*Copyright (C) 2009-2011 :
     Gabes Jean, naparuba@gmail.com
     Gerhard Lausser, Gerhard.Lausser@consol.de
     Gregory Starck, g.starck@gmail.com
     Hartmut Goebel, h.goebel@goebel-consult.de

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
  Look for Shift key up and down
*/
var is_shift_pressed = false;
function shift_pressed(){
  is_shift_pressed = true;
}

function shift_released(){
  is_shift_pressed = false;
}

$(document).bind('keydown', 'shift', shift_pressed);
$(document).bind('keyup', 'shift', shift_released);

/*
  If we keep the shift pushed and hovering over selections, it
  select the elements. Easier for massive selection :)
*/
function hovering_selection(name){
  if (is_shift_pressed) {
    add_element(name);
  }
}


/*
  Tool bar related code
*/
function hide_toolbar(){
  $('#toolbar').hide();
  $('#hide_toolbar_btn').hide();
  $('#show_toolbar_btn').show();
  
  $('#problems').addClass('col-lg-12 col-md-12 col-sm-12');
  $('#problems').removeClass('col-lg-9 col-md-8 col-sm-8');

  save_toolbar('hide');
}

function show_toolbar(){
  $('#toolbar').show();
  $('#hide_toolbar_btn').show();
  $('#show_toolbar_btn').hide();
  
  $('#problems').addClass('col-lg-9 col-md-8 col-sm-8');
  $('#problems').removeClass('col-lg-12 col-md-12 col-sm-12');

  save_toolbar('show');
}

function save_toolbar(toolbar){
  $.post("/user/save_pref", { 'key' : 'toolbar', 'value' : toolbar});
}



// The user asks to show the hidden problems 
function show_hidden_problems(cls){
  $('.hide_for_'+cls).show();
  // And hide the vvv button
  $('.show_for_'+cls).hide();
}



function toggle_select_buttons(){
   $('#select_all_btn').toggle();
   $('#unselect_all_btn').toggle();
}

function show_unselect_all_button(){
   $('#select_all_btn').hide();
   $('#unselect_all_btn').show();
}

function show_select_all_button(){
   $('#unselect_all_btn').hide();
   $('#select_all_btn').show();
}

// Expand all collapsed block
function expand_all_block(){
   $('#accordion .collapse').collapse('show');
   $('#expand_all').hide();
   $('#collapse_all').show();
}
 
// Collapse all block
function collapse_all_block(){
   $('#accordion .in').collapse('hide');
   $('#collapse_all').hide();
   $('#expand_all').show();
}


// When we select all, add all in the selected list,
// and hide the select all button, and swap it with
// unselect all one
function select_all_problems(){
   // Maybe the actions are not allwoed. If so, don't act
   if (!actions_enabled){return;}

   toggle_select_buttons();

   // we will get all elements by looking at .details and get their ids
   $('.detail').each(function(){
      add_element($(this).attr('id'));
   });
}

// guess what? unselect is the total oposite...
function unselect_all_problems(){
   toggle_select_buttons();
   /*$('#unselect_all_btn').hide();
   $('#select_all_btn').show();*/
   flush_selected_elements();
}


/* We keep an array of all selected elements */
var selected_elements = [];

function add_remove_elements(name){
   // Maybe the actions are not allowed. If so, don't act
   if (!actions_enabled) {return;}

   if (selected_elements.indexOf(name) != -1) {
      remove_element(name);
   } else {
      add_element(name);
   }

   //$('#details-'+name).collapse('hide'); // :DEBUG:maethor:150526: Doesn't work
}


/* function when we add an element*/
function add_element(name){
   selected_elements.push(name);

   // Show the 'tick' image of the selector
   $('#selector-'+name).show();

   show_toolbar();
   $('#actions').show();
   show_unselect_all_button();

   // Restart page refresh timer
   reinit_refresh();
}

/* And of course when we remove it... */
function remove_element(name){
   selected_elements.splice($.inArray(name, selected_elements),1);

   if (selected_elements.length == 0){
      $('#actions').hide();
      show_select_all_button();
   }
   // And hide the tick image
   $('#selector-'+name).hide();
}


/* Flush selected elements, so clean the list
but also untick them in the UI */
function flush_selected_elements(){
   /* We must copy the list so we can parse it in a clean way
   without fearing some bugs */
   var cpy = $.extend({}, selected_elements);
   $.each(cpy, function(idx, name) {
      remove_element(name)
      //selected_elements.splice($.inArray(name, selected_elements),1);
   });
}


/* Jquery need simple id, so no / or space. So we get in the #id
the data-raw-obj-name to get the unchanged name*/
function unid_name(name){
  return $('#'+name).attr('data-raw-obj-name');
}

/* Now actions buttons : */
function recheck_now_one(name){
   recheck_now(name);
}
function recheck_now_all(){
   $.each(selected_elements,function(idx, name){
      recheck_now(unid_name(name));
   });
   flush_selected_elements();
}


function submit_check_ok_one(name, user){
   submit_check(name, '0', 'Forced OK from WebUI by '+user);
}
function submit_check_ok_all(user){
   $.each(selected_elements, function(idx, name){
      submit_check(unid_name(name), '0', 'Forced OK from WebUI by '+user);
   });
   flush_selected_elements();
}


/* Now actions buttons : */
function try_to_fix_one(name){
   try_to_fix(name);
}
function try_to_fix_all(){
   $.each(selected_elements, function(idx, name){
      try_to_fix(unid_name(name));
   });
   flush_selected_elements();
}


function acknowledge_one(name, user){
   do_acknowledge(name, 'Acknowledged from WebUI by '+user, user);
}
function acknowledge_all(user){
   $.each(selected_elements, function(idx, name){
      do_acknowledge(unid_name(name), 'Acknowledged from WebUI by '+user, user);
   });
   flush_selected_elements();
}


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
      do_schedule_downtime(unid_name(name), downtime_start.format('X'), downtime_stop.format('X'), user, 'Downtime scheduled from WebUI by '+user);
   });
   flush_selected_elements();
}


function remove_one(name, user){
   do_remove(name, 'Removed from WebUI by '+user, user);
}
function remove_all(user){
   $.each(selected_elements, function(idx, name){
      do_remove(unid_name(name), 'Removed from WebUI by '+user, user);
   });
   flush_selected_elements();
}

// On page loaded ... 
$(document).ready(function(){
   // At start we hide the toolbar
   hide_toolbar();

   // ... we hide the unselect all and collapse all buttons
   $('#unselect_all_btn').hide();
   $('#collapse_all').hide()

   // If actions are not allowed, disable the button 'select all'
   if ("actions_enabled" in window && !actions_enabled) {
      $('#select_all_btn').addClass('disabled');
      // And put in low opacity the 'selectors'
      $('.tick').css({'opacity' : 0.4});
   }

   // ... we hide the selected images.
   $('.img_tick').hide();
   $('#actions').hide();
});
