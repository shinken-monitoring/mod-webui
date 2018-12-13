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


$('body').on('#display-impacts', 'click', function() {
    save_user_preference('display_impacts', $('#display-impacts').is(':checked'));
    location.reload();
});

// Text ellipsis in tables ...
$('body').on('show.bs.collapse', '.collapse', function () {
    // Close other stuff that my be expanded
    $('.collapse').collapse('hide');
    $(this).closest('tr').prev().find('.output').removeClass("ellipsis", {duration:200});
});

$('body').on('hide.bs.collapse', '.collapse', function () {
    $(this).closest('tr').prev().find('.output').addClass("ellipsis", {duration:200});
});

// Business impact selection buttons
$('body').on('click', '.js-select-all', function (e) {
   if ($(this).data('state')=='off') {
      if (problems_logs) console.log('Select all elements ...', $(this).data('business-impact'));

      // Add elements to selection
      $('input[type=checkbox][data-type="problem"][data-business-impact="'+$(this).data('business-impact')+'"]').each(function() {
         add_element($(this).data('item'));
      })
      $(this).data('original-label', $(this).html());
      $(this).html('Unselect all').data('state', 'on');
   } else {
      if (problems_logs) console.log('Unselect all elements ...', $(this).data('business-impact'));

      // Remove elements from selection
      $('input[type=checkbox][data-type="problem"][data-business-impact="'+$(this).data('business-impact')+'"]').each(function() {
         remove_element($(this).data('item'));
      })
      $(this).html($(this).data('original-label')).data('state', 'off');
   }

});

// Problems element check boxes
$('body').on('click', 'input[type=checkbox][data-type="problem"]', function (e) {
   e.stopPropagation();

   if (problems_logs) console.log('Clicked: ', $(this).data('item'))
   // Add/remove element from selection
   add_remove_elements($(this).data('item'));
});

$('body').on('click', '.js-select-elt', function(e) {
    document.onselectstart = function() {
        return false;
    }
    if (e.ctrlKey) {
        e.stopPropagation();
        if (problems_logs) console.log('CTRL-Clicked: ', $(this).data('item'))
        $(this).focus(); // This is used to avoid text selection
        add_remove_elements($(this).data('item'));
    }
    if (e.shiftKey) {
        e.stopPropagation();
        if (problems_logs) console.log('Shift-Clicked: ', $(this).data('item'))
        $(this).focus(); // This is used to avoid text selection
        if ($(this).closest('table').find('tr.selected').length == 0) {
            add_remove_elements($(this).data('item'));
        } else {
            //$(this).closest('table').children('tr:first').hide();
            //$(this).closest('.js-select-elt').addClass('success')
            var first = $(this).closest('table').find('tr.selected:first');
            if ($(this).prevAll().filter($(first)).length !== 0) {
                $(this).prevUntil(first, 'tr.js-select-elt').andSelf().not('.selected').each(function(i, e) {
                    add_remove_elements($(e).data('item'));
                });
            } else {
                $(this).nextUntil(first, 'tr.js-select-elt').andSelf().not('.selected').each(function(i, e) {
                    add_remove_elements($(e).data('item'));
                });
            }
        }
    }
});

function bootstrap_accordion_bookmark (selector) {
    if (selector == undefined) {
        selector = "";
    }

    $(document).ready(function() {
        if (location.hash) {
            $(location.hash).collapse('show');

            // Check if elt is visible, or scroll to it
            var docViewTop = $(window).scrollTop();
            var docViewBottom = docViewTop + $(window).height();
            var elt = $('tr[data-target="' + location.hash + '"]')
            if (elt.length) {
                var elemTop = elt.offset().top;

                if  ((elemTop < docViewTop) || (elemTop > docViewBottom)) {
                    $('html,body').animate({
                        scrollTop: elemTop - $(window).height() /5
                    });
                }
            }
        }
    });

    var update_location = function (event) {
        document.location.hash = this.id;
    }

    var reset_location = function (event) {
        document.location.hash = "";
    }

    $('body').on('show.bs.collapse', '.collapse', update_location);
    $('body').on('hide.bs.collapse', '.collapse', reset_location);
}


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

   bootstrap_accordion_bookmark();

   // Graphs popover
   $('[data-toggle="popover-elt-graphs"]').popover({
      html: true,
      content: function() {
          $.ajax({url: '/graphs/' + $(this).data('item'),
                  dataType: 'html',
                  elt: $(this),
                  success: function(response) {
                      this.elt.data('bs.popover').options.content = response;
                      this.elt.popover('show');
                  }
          });
          return "<div>Loading…</div>";
      },
      template: '<div class="popover img-popover"><div class="arrow"></div><div class="popover-inner"><h3 class="popover-title"></h3><div style="width: 620px;" class="popover-content"><p></p></div></div></div>',
   });
}

$('a[href="/problems"]').addClass('active');

$("#nav-actions").insertAfter("#nav-filters");

// First page loading ...
on_page_refresh();

