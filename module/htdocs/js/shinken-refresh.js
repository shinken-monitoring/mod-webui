/*Copyright (C) 2009-2011 :
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


/* By default, we set the page to reload each period defined in WebUI configuration */
var refresh_timeout = app_refresh_period;
var nb_refresh_try = 0;
var refresh_stopped = false;

var refresh_logs=false;

function postpone_refresh(){
   // If we are not in our first try, warn the user
   if (nb_refresh_try > 0){
      $.meow({
         message: 'The UI backend is not available.',
         icon: '/static/images/ui_notifications/ko.png'
      });
   }
   nb_refresh_try += 1;
   /* Ok, we are now for a new loop before retrying... */
   reinit_refresh();
}

function do_refresh(){
   if (refresh_logs) console.debug("Refreshing: ", document.URL);
   
   $('#header_loading').addClass('fa-spin');
   $.get(document.URL, {}, function(data) {
      var $response = $('<div />').html(data);
      $('#page-content').html($response.find('#page-content').html());
      $('#hosts-overall-state').html($response.find('#hosts-overall-state').html());
      $('#services-overall-state').html($response.find('#services-overall-state').html());
      $('#header_loading').removeClass('fa-spin');
   
      // Look at the hash part of the URI. If it match a nav name, go for it
      if (location.hash.length > 0) {
         if (refresh_logs) console.debug('Displaying tab: ', location.hash)
         $('.nav-tabs li a[href="' + location.hash + '"]').trigger('click');
      } else {
         if (refresh_logs) console.debug('Displaying first tab')
         $('.nav-tabs li a:first').trigger('click');
      }
   }, 'html');
}

/* We will try to see if the UI is not in restating mode, and so
   don't have enough data to refresh the page as it should. (force login) */
function check_for_data(){
   $.ajax({
      "url": '/gotfirstdata?callback=?',
      "dataType": "jsonp",
      "success": function (response) {
         if (response.status == 200 && response.text == '1') {
            if (! refresh_stopped) {
               // Go Refresh
               do_refresh();
            }

            reinit_refresh();
         } else {
            postpone_refresh();
        }
      }
      ,
      "error": postpone_refresh
   });
}


/* Each second, we check for timeout and restart page */
function check_refresh(){
   if (refresh_timeout < 0){
      // We will first check if the backend is available or not. It's useless to refresh
      // if the backend is reloading, because it will prompt for login, when wait a little bit
      // will make the data available.
      check_for_data();
   }
   refresh_timeout = refresh_timeout - 1;
}


function toggle_refresh() {
    if (refresh_stopped) {
        start_refresh();
    } else {
        stop_refresh();
    }
}

/* Someone ask us to start the refresh so the page will reload */
function start_refresh(){
   $('#header_loading').removeClass('font-greyed');
   refresh_stopped = false;
}


/* Someone ask us to stop the refresh so the user will have time to
   do some things like ask actions or something like that */
function stop_refresh(){
   $('#header_loading').addClass('font-greyed');
   refresh_stopped = true;
}


/* Someone ask us to reinit the refresh so the user will have time to
   do some things like ask actions or something like that */
function reinit_refresh(){
   if (refresh_logs) console.debug("Refresh restart: ", app_refresh_period);
   refresh_timeout = app_refresh_period;
}

/* We will check timeout each 1s */
$(document).ready(function(){
   setInterval("check_refresh();", 1000);
});
