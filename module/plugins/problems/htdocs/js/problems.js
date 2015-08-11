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

var problems_logs=false;


function add_remove_elements(name){
   if (selected_elements.indexOf(name) != -1) {
      remove_element(name);
   } else {
      add_element(name);
   }
}

// Adding an element in the selected elements list
function add_element(name){
   // Force to check the checkbox
   $('td input[type=checkbox][data-item="'+name+'"]').prop("checked", true);
   
   if (problems_logs) console.log('Select element: ', name)
   selected_elements.push(name);

   if (selected_elements.length > 0) {
      show_actions();
      
      // Stop page refresh
      stop_refresh();
   }
}

// Removing an element from the selected elements list
function remove_element(name){
   // Force to uncheck the checkbox
   $('td input[type=checkbox][data-item="'+name+'"]').prop("checked", false);
   
   if (problems_logs) console.log('Unselect element: ', name)
   selected_elements.splice($.inArray(name, selected_elements),1);

   if (selected_elements.length == 0){
      hide_actions();

      // Restart page refresh timer
      start_refresh();
   }
}

// Flush selected elements list
function flush_selected_elements(){
   /* We must copy the list so we can parse it in a clean way
   without fearing some bugs */
   var cpy = $.extend({}, selected_elements);
   $.each(cpy, function(idx, name) {
      remove_element(name)
   });
}


// Text ellipsis in tables ...
$('body').on('show.bs.collapse', '.collapse', function () {
    $(this).closest('tr').prev().find('.output').removeClass("ellipsis", {duration:200});
});

$('body').on('hide.bs.collapse', '.collapse', function () {
    $(this).closest('tr').prev().find('.output').addClass("ellipsis", {duration:200});
});

// :DEBUG:maethor:150811: This can make things very buggy if the output is long.
//$('body').on('mouseenter', '.ellipsis', function () {
   //var $this = $(this);
   //if (this.offsetWidth < this.scrollWidth && !$this.attr('title')) {
      //$this.tooltip({
         //title: $this.text(),
         //placement: "bottom"
      //});
      //$this.tooltip('show');
   //}
//});

// Business impact selection buttons
$('body').on('click', 'button[data-type="business-impact"]', function (e) {
   if ($(this).data('state')=='off') {
      if (problems_logs) console.log('Select all elements ...', $(this).data('business-impact'));

      // Remove elements from selection
      $('input[type=checkbox][data-type="problem"][data-business-impact="'+$(this).data('business-impact')+'"]').each(function() {
         remove_element($(this).data('item'));
      })
      // Add elements to selection
      $('input[type=checkbox][data-type="problem"][data-business-impact="'+$(this).data('business-impact')+'"]').each(function() {
         add_element($(this).data('item'));
      })
      $(this).html("Unselect all elements").data('state', 'on');
   } else {
      if (problems_logs) console.log('Unselect all elements ...', $(this).data('business-impact'));
         
      // Remove elements from selection
      $('input[type=checkbox][data-type="problem"][data-business-impact="'+$(this).data('business-impact')+'"]').each(function() {
         remove_element($(this).data('item'));
      })
      $(this).html("Select all elements").data('state', 'off');
   }
   
});

// Problems element check boxes
$('body').on('click', 'input[type=checkbox][data-type="problem"]', function (e) {
   e.stopPropagation();
   
   if (problems_logs) console.log('Clicked: ', $(this).data('item'))
   // Add/remove element from selection
   add_remove_elements($(this).data('item'));
});

function on_page_refresh(){
   if (problems_logs) console.log('Problems page - on_page_refresh')
      
   // If actions are not allowed, disable the button 'select all' and the checkboxes
   if ("actions_enabled" in window && !actions_enabled) {
      // Get actions buttons bar ... to hide it!
      $('[data-type="actions"]').hide();
      
      // Get all selection buttons ...
      $('button[data-type="business-impact"]').each(function(){
         // ... then disable and hide button
         $(this).prop("disabled", true).hide();
      });
      
      // Get all elements ...
      $('input[type=checkbox]').each(function(){
         // ... then disable and hide checkbox
         $(this).prop("disabled", true).hide();
      });
   }
   
   // Graphs popover
   $('[data-toggle="popover"]').popover({
      html: true,
      template: '<div class="popover img-popover"><div class="arrow"></div><div class="popover-inner"><h3 class="popover-title"></h3><div class="popover-content"><p></p></div></div></div>',
   });

}

// First page loading ...
on_page_refresh();
