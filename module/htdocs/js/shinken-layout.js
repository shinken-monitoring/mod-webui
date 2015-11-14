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

var layout_logs=false;

/*
 * For IE missing window.console ...
*/
(function () {
    var f = function () {};
    if (!window.console) {
        window.console = {
            log:f, info:f, warn:f, debug:f, error:f
        };
    }
}());

/*
 * To load on run some additional js or css files.
*/
function loadjscssfile(filename, filetype){
   if (filetype=="js") {
      if (layout_logs) console.debug('Loading Js file: ', filename);
      $.ajax({
         url: filename,
         dataType: "script",
         error: function () {
            console.error('Shinken script error, not loaded: ', filename);
         }
      });
   } else if (filetype=="css") {
      if (layout_logs) console.debug('Loading Css file: ', filename);
       if (!$('link[href="' + filename + '"]').length)
           $('head').append('<link rel="stylesheet" type="text/css" href="' + filename + '">');
   }
}


/**
 * Save current user preference value:
 * - key / value
 * - callback function called after data are posted
**/
function save_user_preference(key, value, callback) {

   $.get("/user/save_pref", { 'key' : key, 'value' : value}, function() {
      if (layout_logs) console.debug('User preference saved: ', key, value);
      raise_message_ok("User parameter saved");

      if (typeof callback !== 'undefined' && $.isFunction(callback)) {
         if (layout_logs) console.debug('Calling callback function ...', callback);
         callback();
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
      if (layout_logs) console.debug('Common preference saved: ', key, value);
      raise_message_ok("Common parameter saved");

      if (typeof callback !== 'undefined' && $.isFunction(callback)) {
         if (layout_logs) console.debug('Calling callback function ...', callback);
         callback();
      }
   });
}


/**
 *  Actions bar related code
 */
function hide_actions(){
   if (layout_logs) console.debug('Hiding actions bar');
   $('#actions').hide();
}

function show_actions(){
   if (layout_logs) console.debug('Showing actions bar');
   $('#actions').show();
}


/**
 * Display the layout modal form
 */
function display_modal(inner_url) {
   if (layout_logs) console.debug('Displaying modal: ', inner_url);
   stop_refresh();
   $('#modal').modal({
      keyboard: true,
      show: true,
      backdrop: 'static',
      remote: inner_url
   });
}


$(document).ready(function(){
   // When modal box is hidden ...
   $('#modal').on('hidden.bs.modal', function () {
      // Show sidebar menu ...
      $('.sidebar').show();
      // Show actions bar ...
      $('.actionbar').show();

      // Clean modal box content ...
      $(this).removeData('bs.modal');
   });

   // When modal box is displayed ...
   $('#modal').on('shown.bs.modal', function () {
      // Hide sidebar menu ...
      $('.sidebar').hide();
      // Hide actions bar ...
      $('.actionbar').hide();
   });

   // Sidebar menu
   $('#sidebar-menu').metisMenu();

   // Actions bar menu
   $('#actions-menu').metisMenu();

});
