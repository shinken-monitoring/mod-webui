/*Copyright (C) 2009-2011 :
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


/* By default, we set the page to reload each period defined in WebUI configuration */
var refresh_timeout = app_refresh_period;
var nb_refresh_try = 0;
var refresh_stopped = false;


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
   $.get(document.URL, {}, function(data) {
      var $response = $('<div />').html(data);
      $('#page-content').html($response.find('#page-content').html());
      $('#hosts-overall-state').html($response.find('#hosts-overall-state').html());
      $('#services-overall-state').html($response.find('#services-overall-state').html());
   
      // Display active tab ...
      // var hash = location.hash
        // , hashPieces = hash.split('?')
        // , activeTab = $('[href=' + hashPieces[0] + ']');
      // activeTab && activeTab.tab('show');
   }, 'html');
}

/* React to an action return of the /action page. Look at status
 to see if it's ok or not */
function check_gotfirstdata_result(response){
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


/* We will try to see if the UI is not in restating mode, and so
   don't have enough data to refresh the page as it should. (force login) */
function check_for_data(){
   $.ajax({
      "url": '/gotfirstdata?callback=?',
      "dataType": "jsonp",
      "success": check_gotfirstdata_result,
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


/* Someone ask us to start the refresh so the page will reload */
function start_refresh(){
   refresh_stopped = false;
}


/* Someone ask us to stop the refresh so the user will have time to
   do some things like ask actions or something like that */
function stop_refresh(){
   refresh_stopped = true;
}


/* Someone ask us to reinit the refresh so the user will have time to
   do some things like ask actions or something like that */
function reinit_refresh(){
   refresh_timeout = app_refresh_period;
}

/* We will check timeout each 1s */
$(document).ready(function(){
   setInterval("check_refresh();", 1000);
   
   // Every link that changes hash ...
   $("a[href^=#]").on("click",function(e){
      // console.log('New hash: ', e.target.hash, ', url before was: ', document.URL)
   });
});

try {
   var hash = location.hash
     , hashPieces = hash.split('?')
     , activeTab = $('[href=' + hashPieces[0] + ']');
   activeTab && activeTab.tab('show');
} catch(e) {
   
}
