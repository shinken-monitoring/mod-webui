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
   $.ajax({
      url: '/cv/'+hname+'/'+cvname+'?_='+_t,
      method: "get",
      dataType: "html"
   })
   .done(function( html, textStatus, jqXHR ) {
      $("#cv"+cvname+"_"+cvconf+" .panel-body").html(html);

      // Panel container height is updated with the custom view height ...
      $("#cv"+cvname+"_"+cvconf+" .panel-body").each(function() {
         $(this).css('height', $('#cv_'+cvname+"_"+cvconf).height() + "px");
      });
      if (custom_logs) console.debug('Loaded custom view: ', cvname+"_"+cvconf);
   })
   .fail(function( jqXHR, textStatus, errorThrown ) {
      if (custom_logs) console.log('Required view is not available. Trying default view ...');

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

      // Let us try the default view ...
      $.ajax({
         url: '/cv/'+hname+'/replace?_='+_t,
         method: "get",
         dataType: "html"
      })
      .done(function( html, textStatus, jqXHR ) {
         $("#cvhost_replace .panel-body").html(html);

         // Panel container height is updated with the custom view height ...
         $("#cvcvhost_replace .panel-body").each(function() {
            $(this).css('height', $('#cv_'+cvname+"_"+cvconf).height() + "px");
         });
         if (custom_logs) console.debug('Loaded custom view: ', cvname+"_"+cvconf);
      })
      .fail(function( jqXHR, textStatus, errorThrown ) {
         $('#cvhost_replace').html('<div class="alert alert-danger">Sorry but there really was an error: ' + jqXHR.status + ' ' + jqXHR.statusText+'</div>');
      })
      .always(function() {
      });
   })
   .always(function() {
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