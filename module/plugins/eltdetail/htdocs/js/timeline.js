/*Copyright (C) 2009-2011 :
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


// When we show the timeline view tab, we lazy load the view ...
$(window).ready(function(){
	$('#tab_to_timeline').on('shown.bs.tab', function (e) {
		// First we get the full name of the object from div data
		var hostname = $('#inner_timeline').attr('data-elt-name');
		// Get timeline tab content ...
		$('#inner_timeline').load('/timeline/inner/'+hostname);
	})

	// And for each already active on boot, show them directly!
	$('.timeline_pane.active').each(function(index, elt ) {
		// First we get the full name of the object from div data
		var hostname = $('#inner_timeline').attr('data-elt-name');
		// Get timeline tab content ...
		$('#inner_timeline').load('/timeline/inner/'+hostname);
	});
});
