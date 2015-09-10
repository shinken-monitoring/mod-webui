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


var refresh_logs=false;

/* By default, we set the page to reload each period defined in WebUI configuration */
var refresh_timeout = app_refresh_period;
var nb_refresh_try = 0;
if (! sessionStorage.getItem("refresh_active")) {
   if (refresh_logs) console.debug("Refresh active storage does not exist");
   // Store default value ...
   sessionStorage.setItem("refresh_active", refresh_timeout==0 ? '0' : '1');
}
if (refresh_logs) console.debug("Refresh active is ", sessionStorage.getItem("refresh_active"));
if (sessionStorage.getItem("refresh_active") == '1') {
   $('#header_loading').removeClass('font-greyed');
} else {
   $('#header_loading').addClass('font-greyed');
}
if (refresh_logs) console.debug("Refresh active is ", sessionStorage.getItem("refresh_active"));

function postpone_refresh(){
   // If we are not in our first try, warn the user
   if (nb_refresh_try > 0){
      alertify.log("The Web UI backend is not available", "info", 5000);
   }
   nb_refresh_try += 1;
   
   // Start a new loop before retrying... 
   reinit_refresh();
}

// Play alerting sound ...
function playAlertSound() {
   var audio = document.getElementById('alert-sound');
   var canPlay = audio && !!audio.canPlayType && audio.canPlayType('audio/wav') != "";
   if (canPlay) {
      audio.play();
      sessionStorage.setItem("sound_play", "1");
      $('#sound_alerting i.fa-ban').addClass('hidden');
   }
}

/*
 * This function is called on each refresh of the current page.
 * ----------------------------------------------------------------------------
 *  It is to be noted that this function makes an Ajax call on the current URL
 * to get the new version of the current page. This is the most interesting 
 * strategy for refreshing ... but the drawbacks are that it gets an entire 
 * Html page including <head>, <body> and ... <script> 
 * 
 *  The only elements that are replaced in the current page are :
 * - #page-content
 * - #overall-hosts-states
 * - #overall-services-states
 * => These elements are the real "dynamic" elements in the page ...
 *
 *  Because of the new received Html inclusion method, the embedded scripts  
 * are not executed ... this implies that the necessary scripts for refresh 
 * management are to be included in this function in the always Ajax promise!
 * ---------------------------------------------------------------------------
 */
function do_refresh(){
   if (refresh_logs) console.debug("Refreshing: ", document.URL);
   
   // Refresh starting indicator ...
   $('#header_loading').addClass('fa-spin');
   
   $.ajax({
     url: document.URL,
     method: "get",
     dataType: "html"
   })
   .done(function( html, textStatus, jqXHR ) {
      /* This var declaration includes the response in the document body ... bad luck!
       * ------------------------------------------------------------------------------
       * In fact, each refresh do include all the received Html and then we filter 
       * what we are interested in ... not really efficient and quite buggy !
       */
      var $response = $('<div />').html(html);
      // Refresh current page content ...
      $('#page-content').html($response.find('#page-content').html());
      
      // Refresh header bar hosts/services state ...
      if ($('#overall-hosts-states').length > 0) {
         $('#overall-hosts-states').html($response.find('#overall-hosts-states').html());
         $('#hosts-states-popover-content').html($response.find('#hosts-states-popover-content').html());
         $('#overall-services-states').html($response.find('#overall-services-states').html());
         $('#services-states-popover-content').html($response.find('#services-states-popover-content').html());

         var nb_problems=0;
         nb_problems += parseInt($('#overall-hosts-states a span').html());
         nb_problems += parseInt($('#overall-services-states a span').html());
         if (refresh_logs) console.debug("Hosts/Services problems", nb_problems);
         
         var old_problems = Number(sessionStorage.getItem("how_many_problems_actually"));
         // Sound alerting
         if (sessionStorage.getItem("sound_play") == '1') {
            if (! sessionStorage.getItem("how_many_problems_actually")) {
               // Default is current value ...
               sessionStorage.setItem("how_many_problems_actually", nb_problems);
            }
            if (refresh_logs) console.debug("Dashboard currently - stored problems number:", old_problems);
            if (old_problems < nb_problems) {
               if (refresh_logs) console.debug("Dashboard - play sound!");
               playAlertSound();
            }
         }
         sessionStorage.setItem("how_many_problems_actually", nb_problems);
      }
      
      // Refresh Dashboard currently ...
      if ($('#one-eye-overall').length > 0) {
         $('#one-eye-overall').html($response.find('#one-eye-overall').html());
         $('#one-eye-icons').html($response.find('#one-eye-icons').html());

         var nb_problems=0;
         nb_problems += parseInt($('#one-eye-overall-hosts').data("hosts-problems"));
         nb_problems += parseInt($('#one-eye-overall-services').data("services-problems"));
         if (refresh_logs) console.debug("Dashboard currently - Hosts/Services problems", nb_problems);
         
         var old_problems = Number(sessionStorage.getItem("how_many_problems_actually"));
         // Sound alerting
         if (sessionStorage.getItem("sound_play") == '1') {
            if (! sessionStorage.getItem("how_many_problems_actually")) {
               // Default is current value ...
               sessionStorage.setItem("how_many_problems_actually", nb_problems);
            }
            if (refresh_logs) console.debug("Dashboard currently - stored problems number:", old_problems);
            if (old_problems < nb_problems) {
               if (refresh_logs) console.debug("Dashboard currently - play sound!");
               playAlertSound();
            }
         }
         if (old_problems < nb_problems) {
            var message = (nb_problems - old_problems) + " new " + ((nb_problems - old_problems)==1 ? "problem" : "problems") + " since last "+refresh_timeout+" seconds."
            alertify.log((nb_problems - old_problems) + " new problems since last "+refresh_timeout+" seconds.", "warning", 5000);
         }
         sessionStorage.setItem("how_many_problems_actually", nb_problems);
         if (refresh_logs) console.debug("Dashboard currently - updated stored problems number:", Number(sessionStorage.getItem("how_many_problems_actually")));
      }
      
      /* Because of what is explained in the previous comment ... we must use this 
       * awful hack ! 
       * Hoping this is a temporary solution ... :/P
       * 
       * An idea : only refreshing the values in the popover would be enough!
       */
      // Activate the popover ...
      $('#hosts-states-popover').popover({ 
         placement: 'bottom', 
         animation: true, 
         template: '<div class="popover img-popover"><div class="arrow"></div><div class="popover-inner"><h3 class="popover-title"></h3><div class="popover-content"><p></p></div></div></div>',
         content: function() {
            return $('#hosts-states-popover-content').html();
         }
      });

      // Activate the popover ...
      $('#services-states-popover').popover({ 
         placement: 'bottom', 
         animation: true, 
         template: '<div class="popover img-popover"><div class="arrow"></div><div class="popover-inner"><h3 class="popover-title"></h3><div class="popover-content"><p></p></div></div></div>',
         content: function() {
            return $('#services-states-popover-content').html();
         }
      });
      
      // Clean the DOM after refresh update ...
      $response.remove();
      
/*
      @mohierf: for future refresh implementation ...
      -----------------------------------------------
      // The solution is to not parse received Html with jQuery and extract some parts
      // of the data using regexp ...
      var content = html.match(/<!--begin-page-content--[^>]*>((\r|\n|.)*)<!--end-page-content--/m);
      content = content ? content[1] : 'Refresh for page content failed!';
      var script = content.match(/<script[^>]*>((\r|\n|.)*)<\/script/m);
      script = script ? script[1] : 'Refresh for hosts states failed!';
      var $response = $('<div />').html(content);
      $('#page-content').html($response.find('#page-content').html()).append('<script>'+script+'</script>');
      
      var content = html.match(/<!--begin-hosts-states--[^>]*>((\r|\n|.)*)<!--end-hosts-states--/m);
      content = content ? content[1] : 'Refresh for hosts states failed!';
      var script = content.match(/<script[^>]*>((\r|\n|.)*)<\/script/m);
      script = script ? script[1] : 'Refresh for hosts states failed!';
      var $response = $('<div />').html(content);
      $('#overall-hosts-states').html($response.find('#overall-hosts-states').html()).append('<script>'+script+'</script>');
      
      var content = html.match(/<!--begin-services-states--[^>]*>((\r|\n|.)*)<!--end-services-states--/m);
      content = content ? content[1] : 'Refresh for services states failed!';
      var script = content.match(/<script[^>]*>((\r|\n|.)*)<\/script/m);
      script = script ? script[1] : 'Refresh for hosts states failed!';
      var $response = $('<div />').html(content);
      $('#overall-services-states').html($response.find('#overall-services-states').html()).append('<script>'+script+'</script>');
*/

      // Each plugin may provide its on_page_refresh function that will be called here ...
      if (typeof on_page_refresh !== 'undefined' && $.isFunction(on_page_refresh)) {
         if (refresh_logs) console.debug('Calling page refresh function ...');
         on_page_refresh();
      }

      /*
      // Refresh bindings of actions buttons ...
      if (typeof bind_actions !== 'undefined' && $.isFunction(bind_actions)) {
         if (refresh_logs) console.debug('Calling actions bindings function ...', bind_actions);
         bind_actions();
      }
      */
      
      // Look at the hash part of the URI. If it match a nav name, go for it
      if (location.hash.length > 0) {
         if (refresh_logs) console.debug('Displaying tab: ', location.hash)
         $('.nav-tabs li a[href="' + location.hash + '"]').trigger('click');
      } else {
         if (refresh_logs) console.debug('Displaying first tab')
         $('.nav-tabs li a:first').trigger('click');
      }
      
      $('#header_loading').removeClass('fa-spin');
   })
   .fail(function( jqXHR, textStatus, errorThrown ) {
      if (refresh_logs) console.error('Done: ', jqXHR, textStatus, errorThrown);
   })
   .always(function() {
      // Set refresh icon ...
      if (sessionStorage.getItem("refresh_active") == '1') {
         $('#header_loading').removeClass('font-greyed');
      } else {
         $('#header_loading').addClass('font-greyed');
      }
      if (refresh_logs) console.debug("Refresh active is ", sessionStorage.getItem("refresh_active"));
      
      // Refresh is finished
      $('#header_loading').removeClass('fa-spin');
   });
}

/* We will try to see if the UI is not in restating mode, and so
   don't have enough data to refresh the page as it should ... */
function check_UI_backend(){
   $.ajax({
      url: '/gotfirstdata?callback=?',
      dataType: "jsonp",
      method: "GET"
   })
   .done(function( data, textStatus, jqXHR ) {
      if (sessionStorage.getItem("refresh_active") == '1') {
         // Go Refresh
         do_refresh();
      }

      reinit_refresh();
   })
   .fail(function( jqXHR, textStatus, errorThrown ) {
      if (refresh_logs) console.error('UI backend is not available, retrying later ...');
      postpone_refresh();
   });
}


/* Each second, we check for timeout and restart page */
function check_refresh(){
   if (refresh_timeout < 0){
      // We will first check if the backend is available or not. It's useless to refresh
      // if the backend is reloading, because it will prompt for login, but waiting a little
      // will make the data available.
      check_UI_backend();
   }
   refresh_timeout = refresh_timeout - 1;
}


/* Someone ask us to reinit the refresh so the user will have time to
   do something ... */
function reinit_refresh(){
   if (refresh_logs) console.debug("Refresh period restarted: " + app_refresh_period + " seconds");
   refresh_timeout = app_refresh_period;
}


function stop_refresh() {
   $('#header_loading').addClass('font-greyed');
   sessionStorage.setItem("refresh_active", '0');
}


function start_refresh() {
   $('#header_loading').removeClass('font-greyed');
   sessionStorage.setItem("refresh_active", '1');
}


/* We will check timeout each 1s */
$(document).ready(function(){
   // Start refresh periodical check ...
   setInterval("check_refresh();", 1000);
   
   if (sessionStorage.getItem("refresh_active") == '1') {
      $('#header_loading').removeClass('font-greyed');
   } else {
      $('#header_loading').addClass('font-greyed');
   }

   // Toggle refresh ...
   $('body').on("click", '[action="toggle-page-refresh"]', function (e, data) {
      if (sessionStorage.getItem("refresh_active") == '1') {
         stop_refresh();
      } else {
         start_refresh();
      }
      if (refresh_logs) console.debug("Refresh active is ", sessionStorage.getItem("refresh_active"));
   });

});
