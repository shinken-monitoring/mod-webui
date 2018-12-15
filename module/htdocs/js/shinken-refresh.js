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
var nb_refresh_try = 0;
if (! sessionStorage.getItem("refresh_enabled")) {
   if (refresh_logs) console.debug("Refresh active storage does not exist");
   // Store default value ...
   sessionStorage.setItem("refresh_enabled", app_refresh_period==0 ? '0' : '1');
}

if (refresh_logs) console.debug("Refresh active is ", sessionStorage.getItem("refresh_enabled"));

if (sessionStorage.getItem("refresh_enabled") == '1') {
    enable_refresh();
} else {
    disable_refresh();
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
var processing_refresh = false;
function do_refresh(forced){
   if (processing_refresh) {
      if (refresh_logs) console.debug("Avoid simultaneous refreshes ...");
      return;
   }
   if (refresh_logs) console.debug("Refreshing: ", document.URL);

   // Refresh starting indicator ...
   $('#header_loading').addClass('fa-spin');
   processing_refresh = true;

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
      }

      // Refresh Dashboard currently ...
      if (dashboard_currently) {
         $('#one-eye-overall').html($response.find('#one-eye-overall').html());
         $('#one-eye-icons').html($response.find('#one-eye-icons').html());
         $('#livestate-graphs').html($response.find('#livestate-graphs').html());
      }

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
         on_page_refresh(forced);
      }

      if (typeof display_charts !== 'undefined' && $.isFunction(display_charts)) {
         if (refresh_logs) console.debug('Calling display charts function ...');
         display_charts();
      }

      /*
      // Refresh bindings of actions buttons ...
      if (typeof bind_actions !== 'undefined' && $.isFunction(bind_actions)) {
         if (refresh_logs) console.debug('Calling actions bindings function ...', bind_actions);
         bind_actions();
      }
      */

      tooltips();

      if (typeof headerPopovers !== 'undefined') {
          headerPopovers();
      }

      // Look at the hash part of the URI. If it match a nav name, go for it
      if (location.hash.length > 0) {
         if (refresh_logs) console.debug('Displaying tab: ', location.hash)
         $('.nav-tabs li a[href="' + location.hash + '"]').trigger('click');
      } else {
         if (refresh_logs) console.debug('Displaying first tab')
         $('.nav-tabs li a:first').trigger('click');
      }
   })
   .fail(function( jqXHR, textStatus, errorThrown ) {
      if (refresh_logs) console.error('Done: ', jqXHR, textStatus, errorThrown);
   })
   .always(function() {
      // Refresh is finished
      $('#header_loading').removeClass('fa-spin');
      processing_refresh = false;
   });
}


function check_refresh(){
   // We first test if the backend is available
   $.ajax({
      url: '/gotfirstdata?callback=?',
      dataType: "jsonp",
      method: "GET"
   })
   .done(function( data, textStatus, jqXHR ) {
      if (sessionStorage.getItem("refresh_enabled") == '1') {
         // Go Refresh
         do_refresh();
      }
   })
   .fail(function( jqXHR, textStatus, errorThrown ) {
      if (refresh_logs) console.error('UI backend is not available for refresh, retrying later ...');
      if (nb_refresh_try > 0){
          alertify.log("The Web UI backend is not available", "info", 5000);
      }
      nb_refresh_try += 1;
   });
}


function disable_refresh() {
   if (refresh_logs) console.debug("Stop refresh");
   $('#header_loading').addClass('fa-striked');
   $('#header_loading').parent().data('tooltip', false)
                                .attr('data-original-title', "Enable auto-refresh")
                                .tooltip({html: 'true', placement: 'bottom'});
   //$('#header_loading').parent().prop('title', "Enable auto-refresh");
   sessionStorage.setItem("refresh_enabled", '0');
}


function enable_refresh() {
   if (refresh_logs) console.debug("Stop refresh");
   $('#header_loading').removeClass('fa-striked');
   $('#header_loading').parent().data('tooltip', false)
                                .attr('data-original-title', "Disable auto-refresh")
                                .tooltip({html: 'true', placement: 'bottom'});
   sessionStorage.setItem("refresh_enabled", '1');
}


$(document).ready(function(){
   // Start refresh periodical check ...
   setInterval("check_refresh();", app_refresh_period * 1000);

   // Toggle refresh ...
   $('body').on("click", '.js-toggle-page-refresh', function (e, data) {
      if (sessionStorage.getItem("refresh_enabled") == '1') {
         disable_refresh();
      } else {
         enable_refresh();
      }
      if (refresh_logs) console.debug("Refresh active is ", sessionStorage.getItem("refresh_enabled"));
   });

});
