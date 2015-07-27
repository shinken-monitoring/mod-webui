/*Copyright (C) 2009-2011 :
     Gabes Jean, naparuba@gmail.com
     Gerhard Lausser, Gerhard.Lausser@consol.de
     Gregory Starck, g.starck@gmail.com
     Hartmut Goebel, h.goebel@goebel-consult.de
     Frédéric Mohier, frederic.mohier@gmail.com

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
   $('#wall-impacts').bxSlider({
     auto: true,
     autoControls: true
   });
   $('#wall-problems').bxSlider({
     auto: true,
     autoControls: true
   });
   $('#wall-last-problems').bxSlider({
     auto: true,
     autoControls: true
   });
}

// First page loading ...
on_page_refresh();
