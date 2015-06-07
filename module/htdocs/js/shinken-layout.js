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

/*
 * To load on run some additional js or css files.
*/
function loadjscssfile(filename, filetype){
  if (filetype=="js"){ //if filename is a external JavaScript file
    $.ajax({
      url: filename,
      dataType: "script",
      error: function () {
        console.error('Shinken script error, not loaded: ', filename);
      }
    });
  } else if (filetype=="css"){ //if filename is an external CSS file
    $('<link>')
      .appendTo('head')
      .attr({type : 'text/css', rel : 'stylesheet'})
      .attr('href', filename);
  }
}
