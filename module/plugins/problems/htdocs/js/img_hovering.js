/*Copyright (C) 2009-2012 :
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


/* We want to be able to add image hovering in perfdata
   so we need the position of the mouse and make apears a div with
   the image in it */

function create_img(src, alt){
    var img = $("<img/>");

    // If we got problem with the image, bail out the
    // print/ WARNING : BEFORE set src!
    img.onerror = function() {
      img.hide()
    };
    img.attr('src', src);
    img.attr('alt', alt);

    return img;
}

// First we look for the img_hover div and we add it
// the image, and we set it in the good place
function display_hover_img(src, alt){
    var img = create_img(src, alt);

    // We remove the previous image in it
    $('#img_hover').empty().append(img);
    $('#image_panel').show();
}

// when we go out the hover item, we must hide the
// img div, and remove the image in it
function hide_hover_img(){
    $('#image_panel').hide();
}

// When we move, we save our mouse position, both
// absolute and relative
$(document).ready(function(){
/*
  $(document).mousemove(function(e){
    // Absolute position
    mouse_abs_x = e.pageX;
    mouse_abs_y = e.pageY;
    // Now the relative part.
    mouse_rel_x = e.clientX;
    mouse_rel_y = e.clientY;
  });
*/
  $('#image_panel').hide();
});
