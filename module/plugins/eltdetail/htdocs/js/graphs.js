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


function get_range() {
    g_s = graphstart;  // Time start and ends
    g_e = graphend;

    g_p = 0; // relative pos for start and end
    g_q = 0;

    // theses offsets are for PNP, with won't work with
    // Graphite from now.
    // TODO
    g_A = 65;
    g_B = 25;
    g_T = 587;

    g_D = g_T - (g_A + g_B); // The pixel range when we remove borders

    g_O = g_e - g_s; // total time printed
}

/*
   { }  <-- User selection.

         s    p             q  e         # s = time start, p = rel pos start, q = rel pos end, e = end time
         |    {             }  |
              x             x2           # x = select start, x2=select end
   [  A  ][       D           ][  B  ]   # A = offset left, D=usefull, B = offset right
   [              T                  ]   # T = Total size of the picture

*/

function update_coords(c)
{
    // variables can be accessed here as
    // c.x, c.y, c.x2, c.y2, c.w, c.h
    // Compute relative positions
    g_p = Math.min(Math.max(g_A, c.x), g_T - g_B) - g_A;
    g_q = Math.min(Math.max(g_A, c.x2), g_T - g_B) - g_A;
};


// We will compute the relative position of the selection
// by removing the borders. This will give us g_rp and g_rq.
// Then we compute the ratio of this selection, and so we apply
// it in the time selection. And we are done.
function graph_zoom(uri){
   //console.log(uri);

   //alert('Relatives'+g_p+' '+g_q);

   // We compute the ratio of the relative position from the inner
   // draw (without the borders)
   var g_rp = g_p / g_D;
   var g_rq = g_q / g_D;

   //alert('Relative ratio: '+g_D+' '+g_rp+' '+g_rq);

   // Now compute the new start and new end we want to border
   var g_ns = parseInt(g_s + g_O*g_rp);
   var g_ne = parseInt(g_s + g_O*g_rq);

   //alert('New time '+g_ns+' '+g_ne);

   // Maybe we just fuck up, if so, bailout
   if(g_ne <= g_ns){
      return;
   }

   // Make the uri and GO!
   var new_uri = uri+'graphstart='+g_ns+'&graphend='+g_ne+'#graphs';
   console.log(new_uri);
   window.location=new_uri;
}
