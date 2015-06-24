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

/*
 * Function called when the page is loaded and on each page refresh ...
 */
function on_page_refresh() {
   // Buttons tooltips
   $('button').tooltip();

   // Elements popover
   $('[data-toggle="popover"]').popover();

   $('[data-toggle="popover medium"]').popover({ 
      trigger: "hover", 
      placement: 'bottom',
      toggle : "popover",
      viewport: {
         selector: 'body',
         padding: 10
      },
      
      template: '<div class="popover popover-medium"><div class="arrow"></div><div class="popover-inner"><h3 class="popover-title"></h3><div class="popover-content"><p></p></div></div></div>',
   });

   // Buttons as switches
   $('input.switch').bootstrapSwitch();

   /*
    * Custom views 
    */
   $('.cv_pane').on('shown.bs.tab', function (e) {
      show_custom_view($(this));
   })

   // Show each active custom view
   $('.cv_pane.active').each(function(index, elt ) {
      var cvname = $(elt).data('name');
      if (! _already_loaded[cvname]) {
         show_custom_view($(elt));
      } else {
         console.debug('Custom view '+cvname+' already exists !');
      }
   });
   
   
   /*
    * Dependency graph
    */
   $('#tab_to_depgraph').on('shown.bs.tab', function (e) {
      // First we get the full name of the object from div data
      var n = $('#inner_depgraph').attr('data-elt-name');
      // Then we load the inner depgraph page. Easy isn't it? :)
      $('#inner_depgraph').load('/inner/depgraph/'+n);
   });
   
   // Fullscreen management
   $('#supported').text('Supported/allowed: ' + !!screenfull.enabled);
   if (!screenfull.enabled) {
      return false;
   }

   $('#fullscreen-request').click(function() {
      screenfull.request($('#inner_depgraph')[0]);
   });

   // Trigger the onchange() to set the initial values
   screenfull.onchange();

   
   /*
    * Commands buttons
    */
   // Add a comment
   $('button[action="add-comment"]').click(function () {
      display_form("/forms/comment/"+$(this).data('element'));
   });
   
   // Delete a comment
   $('button[action="delete-comment"]').click(function () {
      display_form("/forms/comment_delete/"+$(this).data('element')+"/"+$(this).data('comment'));
   });
   
   // Delete all comments
   $('button[action="delete-comments"]').click(function () {
      display_form("/forms/comment_delete_all/"+$(this).data('element'));
   });
  
   // Change a custom variable
   $('button[action="change-variable"]').click(function () {
      var elt = $(this).data('element');
      var variable = $(this).data('variable');
      var value = $(this).data('value');
      console.debug("Button - set custom variable '"+variable+"'="+value+", for: ", elt)
      
      stop_refresh();
      $('#modal').modal({
         keyboard: true,
         show: true,
         backdrop: 'static',
         remote: "/forms/change_var/"+elt+"?variable="+variable+"&value="+value
      });
   });

   
   
   
   
   
   
   // Schedule a downtime ...
   $('button[name="bt-schedule-downtime"]').click(function () {
      var elt = $(this).data('element');
      console.debug("Button - schedule a downtime, for: ", elt)
      
      // Stop page refresh ...
      stop_refresh();
      // Display modal window ...
      $('#modal').modal({
         keyboard: true,
         show: true,
         backdrop: 'static',
         remote: "/forms/downtime/"+elt
      });
   });
   
   // Delete a downtime ...
   $('button[name="bt-delete-downtimes"]').click(function () {
      var elt = $(this).data('element');
      console.debug("Button - delete a downtime, for: ", elt)
      
      // Stop page refresh ...
      stop_refresh();
      // Display modal window ...
      $('#modal').modal({
         keyboard: true,
         show: true,
         backdrop: 'static',
         remote: "/forms/downtime_delete/"+elt
      });
   });





   
   // Toggles ...
   $('#ck-active-checks').on('switch-change', function (e, data) {
      toggle_active_checks(elt_name, !data.value);
   });
   $('#ck-passive-checks').on('switch-change', function (e, data) {
      toggle_passive_checks(elt_name, !data.value);
   });
   $('#ck-check-freshness').on('switch-change', function (e, data) {
      toggle_freshness_check(elt_name, !data.value);
   });
   $('#ck-notifications').on('switch-change', function (e, data) {
      toggle_notifications(elt_name, !data.value);
   });
   $('#ck-event-handler').on('switch-change', function (e, data) {
      toggle_event_handlers(elt_name, !data.value);
   });
   $('#ck-process-perfdata').on('switch-change', function (e, data) {
      toggle_process_perfdata(elt_name, !data.value);
   });
   $('#ck-flap-detection').on('switch-change', function (e, data) {
      toggle_flap_detection(elt_name, !data.value);
   });
   $('#ck-flap-detection').on('switch-change', function (e, data) {
      toggle_flap_detection(elt_name, !data.value);
   });

   
   /*
    * Graphs
    */
   // This to allow the range to change after the page is loaded.
   get_range();
   
   /* We can't apply Jcrop on ready. Why? Because the images are not yet loaded, and so
      they will have a null size. So how to do it?
      The key is to hook the graph tab. onshow will raise when we active it (and was shown).
   */
   $('#tab_to_graphs').on('shown.bs.tab', function (e) {
      // console.log("Display graph: ", current_graph)
      $('a[data-type="graph"][data-period="'+current_graph+'"]').trigger('click');
   })
   
   // Change graph
   $('a[data-type="graph"]').click(function (e) {
      current_graph=$(this).data('period');
      graphstart=$(this).data('graphstart');
      graphend=$(this).data('graphend');

      // Update graphs
      $("#real_graphs").html( html_graphes[current_graph] );

      // Update active period selected
      $("#graph_periods li.active").removeClass('active');
      $(this).parent('li').addClass('active');
      
      // and call the jcrop javascript
      $('.jcropelt').Jcrop({
         onSelect: update_coords,
         onChange: update_coords
      });
      get_range();
   });
}
