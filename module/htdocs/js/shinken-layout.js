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
      window.setTimeout(function() {
         $.ajax({
            url: filename,
            dataType: "script",
            error: function () {
               console.error('Shinken script error, not loaded: ', filename);
            }
         });
      }, 100);
   } else if (filetype=="css") {
      if (layout_logs) console.debug('Loading Css file: ', filename);
      if (!$('link[href="' + filename + '"]').length)
         $('head').append('<link rel="stylesheet" type="text/css" href="' + filename + '">');
   }
}


/**
 * Display the layout modal form
 */
function display_modal(inner_url) {
   if (layout_logs) console.debug('Displaying modal: ', inner_url);
   disable_refresh();
   $('#modal').modal({
      keyboard: true,
      show: true,
      backdrop: 'static',
      remote: inner_url
   });
}

function headerPopovers() {
  // Topbar hosts popover
   $('#hosts-states-popover').popover({
      placement: 'bottom',
      container: 'body',
      trigger: 'manual',
      animation: false,
      template: '<div class="popover img-popover"><div class="arrow"></div><div class="popover-inner"><h3 class="popover-title"></h3><div class="popover-content"><p></p></div></div></div>',
      content: function() {
         return $('#hosts-states-popover-content').html();
      }
   }).on("mouseenter", function () {
      var _this = this;
      $(this).popover("show");
      $(this).siblings(".popover").on("mouseleave", function () {
          $(_this).popover('hide');
      });
   }).on("mouseleave", function () {
      var _this = this;
      setTimeout(function () {
          if (!$(".popover:hover").length) {
              $(_this).popover("hide");
          }
      }, 100);
   });

  // Topbar services popover
   $('#services-states-popover').popover({
      placement: 'bottom',
      container: 'body',
      trigger: 'manual',
      animation: false,
      template: '<div class="popover img-popover"><div class="arrow"></div><div class="popover-inner"><h3 class="popover-title"></h3><div class="popover-content"><p></p></div></div></div>',
      content: function() {
         return $('#services-states-popover-content').html();
      }
   }).on("mouseenter", function () {
      var _this = this;
      $(this).popover("show");
      $(this).siblings(".popover").on("mouseleave", function () {
          $(_this).popover('hide');
      });
   }).on("mouseleave", function () {
      var _this = this;
      setTimeout(function () {
          if (!$(".popover:hover").length) {
              $(_this).popover("hide");
          }
      }, 100);
   });
}


$(document).ready(function(){
   // When modal box is hidden ...
   $('#modal').on('hidden.bs.modal', function () {
      // Show sidebar menu ...
      $('.sidebar').show();

      // Clean modal box content ...
      $(this).removeData('bs.modal');
   });

   // When modal box is displayed ...
   $('#modal').on('shown.bs.modal', function () {
      // Hide sidebar menu ...
      $('.sidebar').hide();
   });

   // Sidebar menu
   $('#sidebar-menu').metisMenu();


  // Sound
  if ($(".js-toggle-sound-alert").length) {
    // Set alerting sound icon ...
    if (! sessionStorage.getItem("sound_play")) {
      // Default is to play ...
      sessionStorage.setItem("sound_play", 1);
    }

    // Toggle sound ...
    if (sessionStorage.getItem("sound_play") == '1') {
      $('#sound_alerting i.fa-ban').addClass('hidden');
    } else {
      $('#sound_alerting i.fa-ban').removeClass('hidden');
    }
    $('.js-toggle-sound-alert').on('click', function (e, data) {
      if (sessionStorage.getItem("sound_play") == '1') {
        sessionStorage.setItem("sound_play", "0");
        $('#sound_alerting i.fa-ban').removeClass('hidden');
      } else {
        playAlertSound();
        $('#sound_alerting i.fa-ban').addClass('hidden');
      }
    });
  }

  headerPopovers();
});
