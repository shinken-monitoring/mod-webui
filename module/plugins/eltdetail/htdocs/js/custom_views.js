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

var custom_logs=false;

// when we show a custom view tab, we lazy load it :D
function show_custom_view(elt){
   var hname = elt.data('element');
   var cvname = elt.data('name');
   var cvconf = elt.data('conf');
   if (custom_logs) console.debug('Request for loading custom view: ', cvname, ' for ', hname, ', configuration: ', cvconf);

   var _t = new Date().getTime();
   $("#cv"+cvname+"_"+cvconf+" .panel-body").load('/cv/'+cvname+'/'+hname+'/'+cvconf+'?_='+_t, function(response, status, xhr) {
      if (status == "error") {
         // Let us try with default host view ... we never know :-)
         // First rename tab ...
         $("#tab-cv-"+cvname+"-"+cvconf)
            .data('name', 'host')
            .data('conf', 'replace')
            .attr('id', 'tab-cv-host-replace')
            .children('a')
            .attr('href', '#cvhost_replace');
         $("#cv"+cvname+"_"+cvconf)
            .data('name', 'host')
            .data('conf', 'replace')
            .attr('id', 'cvhost_replace');
         $("#cvhost_replace .panel-body").load('/cv/host/'+hname+'/replace?_='+_t, function(response, status, xhr) {
            if (status == "error") {
               $('#cvhost_replace').html('<div class="alert alert-danger">Sorry but there really was an error: ' + xhr.status + ' ' + xhr.statusText+'</div>');
            } else {
               // Panel container height is updated with the custom view height ...
               $("#cvhost_replace .panel-body").each(function() {
                  $(this).css('height', $('#cvhost_replace').height() + "px");
               });
               $('#cvhost_replace').prepend('<div class="alert alert-danger">Replacing the custom view \''+cvname+'\' that was not found ... hope it will help anyway :-)</div>');
               if (custom_logs) console.debug('Loaded custom view (after error): ', 'cvhost_replace');
            }
         });
      } else {
         // Panel container height is updated with the custom view height ...
         $("#cv"+cvname+"_"+cvconf+" .panel-body").each(function() {
            $(this).css('height', $('#cv_'+cvname+"_"+cvconf).height() + "px");
         });
         if (custom_logs) console.debug('Loaded custom view: ', cvname+"_"+cvconf);
      }
   });
}

function reload_custom_view(elt){
   var hname = elt.data('element');
   var cvname = elt.data('name');
   var cvconf = elt.data('conf');
   
   // Be sure to remove the panel from already loaded panels, else it won't load
   delete _already_loaded[cvname+cvconf];
   show_custom_view(elt);
}