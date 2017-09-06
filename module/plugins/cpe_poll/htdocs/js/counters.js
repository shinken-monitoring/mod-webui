/*Copyright (C) 2009-2015 :
     Mohier Frederic, frederic.mohier@gmail.com

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


// When we show the counters view tab, we lazy load the view ...
$(window).ready(function(){
   $('a[href="#counters"]').on('shown.bs.tab', function (e) {
      console.debug('Show counters tab ...');
      // First we get the full name of the object from div data
      var hostname = $('#inner_counters').attr('data-elt-name');
      // hostname = 'auchan-0007';
      var entityId = $('#inner_counters').attr('data-elt-entity');
      // entityId = '859';
      console.debug('Show counters tab for host: ', hostname, ' in entity: ', entityId);
      
      if (entityId == -1) return;
      
      $('#inner_counters').empty();
      var table = $('<table />').addClass('table-condensed').addClass('table-bordered').appendTo("#inner_counters");
      var tr = $('<thead />').appendTo(table);
      $('<th />').html('Counter').appendTo(tr);
      $('<th />').html('Cumulated value').appendTo(tr);
      $('<th />').html('Daily value').appendTo(tr);
      
      $('<tbody />').css({fontSize: "x-small"}).appendTo(table);

      var tr;
      $.each(dc.main_counters, function(id, counter) {
         console.debug('Get counter: ', id, counter);
         if (! counter || (counter.active != undefined && ! counter.active)) return;

        // Get counter ...
        var counterId = id;
        wsCall('kiosks.getCounters', {
          counters: counterId,
          entitiesList: entityId,
          test: "Fred",
          hostsFilter: hostname,
          start_date: moment().format('YYYY-MM-DD'),
          end_date: moment().format('YYYY-MM-DD'),
        }).done(function(data) {
          if (debugJs) console.debug('Main counter received (counter, data): ', counterId, data);
          if (! data.countersSerie || ! data.countersSerie[counterId]) return;

          var counterObject = { 
            value_all: (data.countersSerie[counterId].eternal) ? data.countersSerie[counterId].eternal : 0, 
            value_daily: (data.countersSerie[counterId].data[0][1]) ? data.countersSerie[counterId].data[0][1] : 0 };
          if (debugJs) console.debug('Counter object: ', counterObject);
          
          var counter = dc.main_counters[counterId];
          if (! counter) return;
          
          // Update counter configuration ...
          counter.unit = (data.countersSerie[counterId].unit) ? data.countersSerie[counterId].unit : '';
          counter.ratio = 1;
          counter.decimals = (data.countersSerie[counterId].decimals) ? data.countersSerie[counterId].decimals : 0;
          counter.name = (data.countersSerie[counterId].label) ? data.countersSerie[counterId].label : counter.name;
          if (debugJs) console.debug('Counter configuration: ', counter);
          
          var decimal = (counter.decimals) ? counter.decimals : 0;
          var ratio = (counter.ratio) ? counter.ratio : 1;
          var unit = (counter.unit) ? ' ' + counter.unit : '';
          
          tr = $('<tr />').appendTo("#inner_counters table tbody");
          $('<td />').html(counter.name).appendTo(tr);
          
          if (counter.eternal) {
            $('<td />').html($.number(counterObject.value_all * ratio, decimal, ',', '.') + unit).appendTo(tr);
          }
          if (counter.daily) {
            $('<td />').html($.number(counterObject.value_daily * ratio, decimal, ',', '.') + unit).appendTo(tr);
          }
        });
      });
      // Display counters ...
      getCountersQueue('eltCounters', false, entityId, hostname, function() {
         console.debug('Got all host counters for map display.');
         $('#inner_counters div.alert').hide();
      });
   })

   // And for each already active on boot, show them directly!
   $('.counters_pane.active').each(function(index, elt ) {
      // First we get the full name of the object from div data
      var hostname = $('#inner_counters').attr('data-elt-name');
      var entityId = $('#inner_counters').attr('data-elt-entity');
      console.debug('Show counters tab for host: ', hostname, ' in entity: ', entityId);
      // Get timeline tab content ...
      // $('#inner_counters').load('/logs/inner/'+hostname);
   });
});
