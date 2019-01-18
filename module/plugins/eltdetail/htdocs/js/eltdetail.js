/* Copyright (C) 2009-2015:
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

var eltdetail_logs=false;

// @mohierf@: really need this global ?
var elt_name = '{{elt.get_full_name()}}';


/*
 * Function called when the page is loaded and on each page refresh ...
 */
function on_page_refresh() {
   // Elements popover
//   $('[data-toggle="popover"]').popover();

   $('[data-toggle="popover"]').popover({
      trigger: 'manual',
      animation: false,

      template: '<div class="popover popover-large"><div class="arrow"></div><div class="popover-inner"><h3 class="popover-title"></h3><div class="popover-content"><p></p></div></div></div>'
   }).on("mouseenter", function () {
      var _this = this;
      $(this).popover("show");
      $(this).siblings(".popover").on("mouseleave", function () {
          $(_this).popover('hide');
      });
   }).on("mouseleave", function () {
      var _this = this;
      setTimeout(function () {
          if (!$(_this).siblings(".popover").is(":hover")) {
              $(_this).popover("hide");
          }
      }, 100);
   });

   /*
    * Impacts view
    */
   // When toggle list is activated ...
   $('#impacts a.toggle-list').on('click', function () {
      var state = $(this).data('state');
      var target = $(this).data('target');

      if (state=='expanded') {
         $('#impacts ul[name="'+target+'"]').hide();
         $(this).data('state', 'collapsed')
         $(this).children('i').removeClass('fa-minus').addClass('fa-plus');
      } else {
         $('#impacts ul[name="'+target+'"]').show();
         $(this).data('state', 'expanded')
         $(this).children('i').removeClass('fa-plus').addClass('fa-minus');
      }
   });

   /*
    * Custom views
    */
   $('.cv_pane').on('shown.bs.tab', function (e) {
      show_custom_view($(this));
   })

   // Show each active custom view
   $('.cv_pane.active').each(function(index, elt) {
      show_custom_view($(elt));
   });

   // Fullscreen management
   $('button[action="fullscreen-request"]').click(function() {
      var elt = $(this).data('element');
      screenfull.request($('#'+elt)[0]);
   });


   /*
    * Commands buttons
    */
   // Toggles ...
   $('.js-toggle-parameter').on('change', function (e, data) {
      var elt = $(this).data('element');
      var value = $(this).is(':checked');
      var func = $(this).data('action')
      if (eltdetail_logs) console.debug(func, " for: ", elt, ", to make it ", value);

      window[func](elt, value);
   });

   /*
    * Availability
    */
   $('a[data-toggle="tab"][href="#availability"]').on('shown.bs.tab', function (e) {
      // First we get the full name of the object from div data
      var element = $('#inner_availability').data('element');

      // Loading indicator ...
      $("#inner_availability").html('<i class="fas fa-spinner fa-spin fa-3x"></i> Loading availability data ...');

      $("#inner_availability").load('/availability/inner/'+encodeURIComponent(element), function(response, status, xhr) {
         if (status == "error") {
            $('#inner_availability').html('<div class="alert alert-danger">Sorry but there was an error: ' + xhr.status + ' ' + xhr.statusText+'</div>');
         }
      });
   })


   /*
    * Helpdesk
    */
   $('a[data-toggle="tab"][href="#helpdesk"]').on('shown.bs.tab', function (e) {
      // First we get the full name of the object from div data
      var element = $('#inner_helpdesk').data('element');

      // Loading indicator ...
      $("#inner_helpdesk").html('<i class="fas fa-spinner fa-spin fa-3x"></i> Loading helpdesk data ...');

      $("#inner_helpdesk").load('/helpdesk/tickets/'+encodeURIComponent(element), function(response, status, xhr) {
         if (status == "error") {
            $('#inner_helpdesk').html('<div class="alert alert-danger">Sorry but there was an error: ' + xhr.status + ' ' + xhr.statusText+'</div>');
         }
      });
   })


   /*
    * Graphs
    */
   // Change graph
   $('a[data-type="graph"]').click(function (e) {
      current_graph=$(this).data('period');

      // Update graphs
      $("#real_graphs").html( html_graphes[current_graph] );

      // Update active period selected
      $('#graph_periods li').removeClass('active');
      $(this).parent('li').addClass('active');
   });

   // Restore previously selected tab
   bootstrap_tab_bookmark();
}


/*
 * Host/service aggregation toggle image button action
 */
function toggleAggregationElt(e) {
    var toc = document.getElementById('aggregation-node-'+e);
    var imgLink = document.getElementById('aggregation-toggle-img-'+e);

    img_src = '/static/images/';

    if (toc && toc.style.display == 'none') {
        toc.style.display = 'block';
        if (imgLink != null){
            imgLink.src = img_src+'reduce.png';
        }
    } else {
        toc.style.display = 'none';
        if (imgLink != null){
            imgLink.src = img_src+'expand.png';
        }
    }
}


/* The business rules toggle buttons*/
function toggleBusinessElt(e) {
    //alert('Toggle'+e);
    var toc = document.getElementById('business-parents-'+e);
    var imgLink = document.getElementById('business-parents-img-'+e);

    img_src = '/static/images/';

    if (toc && toc.style.display == 'none') {
   toc.style.display = 'block';
   if (imgLink != null){
       imgLink.src = img_src+'reduce.png';
   }
    } else {
   toc.style.display = 'none';
   if (imgLink != null){
       imgLink.src = img_src+'expand.png';
   }
    }
}


/* Not very nice ... should be better to request smaller/bigger image to Graphite!
 @TODO: request adapted size images to Graphite.
// On window resize ... resizes graphs.
$(window).bind('resize', function () {
   var img_width = $("#real_graphs").width();

   $.each($('#real_graphs img'), function (index, value) {
      $(this).css("width", img_width);
   });
});
*/

on_page_refresh();
