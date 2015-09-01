<script>
   // Google API not yet loaded ... except if window.google still exists!
   var mapsApiLoaded=window.google;
   var mapsApiLoading=window.google;
   // Set true to activate javascript console logs
   var debugMaps=false;
   if (debugMaps && !window.console) {
      alert('Your web browser does not have any console object ... you should stop using IE ;-) !');
   }

   var map_{{mapId}};
   var infoWindow_{{mapId}};

   // Images dir
   var imagesDir="/static/worldmap/img/";

   // Default camera position/zoom ...
   var defLat={{params['default_lat']}};
   var defLng={{params['default_lng']}};
   var defaultZoom={{params['default_zoom']}};

   // Markers ...
   var allMarkers_{{mapId}} = [];

   //------------------------------------------------------------------------------
   // Sequentially load necessary scripts to create map with markers
   //------------------------------------------------------------------------------
   loadScripts = function(scripts, complete) {
      var loadScript = function(src) {
         if (! src) return;
         if (debugMaps) console.log('Loading script: ', src);
         $.getScript(src, function( data, textStatus, jqxhr ) {
            next = scripts.shift();
            if (next) {
               loadScript(next);
            } else if (typeof complete == 'function') {
               complete();
            }
         });
      };
      if (scripts.length) {
         loadScript(scripts.shift());
      } else if (typeof complete == 'function') {
         complete();
      }
   }

   //------------------------------------------------------------------------------
   // Create a marker on specified position for specified host/state with IW content
   //------------------------------------------------------------------------------
   // position : GPS coordinates
   // name : host name
   // state : host state
   // content : infoWindow content
   // iconBase : icone name base
   //------------------------------------------------------------------------------
   markerCreate_{{mapId}} = function(name, state, content, position, iconBase, title) {
      if (debugMaps) console.log("-> marker creation for "+name+", state : "+state);
      if (iconBase == undefined) iconBase='host';

      var iconUrl=imagesDir+'/'+iconBase+"-"+state+".png";
      if (state == '') iconUrl=imagesDir+'/'+iconBase+".png";

      var markerImage = new google.maps.MarkerImage(
         iconUrl,
         new google.maps.Size(32,32),
         new google.maps.Point(0,0),
         new google.maps.Point(16,32)
      );

      try {
         /* Marker with label ...
         */
         var marker = new MarkerWithLabel({
            map: map_{{mapId}},
            position: position,
            icon: new google.maps.MarkerImage(
              iconUrl,
              new google.maps.Size(32,32),
              new google.maps.Point(0,0),
              new google.maps.Point(16,16)
            ),
            raiseOnDrag: false, draggable: true,
            title: title,
            hoststate: state,
            hostname: name,
            iw_content: content,

            // Half the CSS width to get a centered label ...
            labelAnchor: new google.maps.Point(50, -20),
            labelClass: "labels",
            labelContent: name,
            labelStyle: {opacity: 0.8},
            labelInBackground: true
         });
      } catch (e) {
         console.error('markerCreate, exception : '+e.message);
      }

      return marker;
   }

   //------------------------------------------------------------------------------
   // Map initialization
   //------------------------------------------------------------------------------
   //------------------------------------------------------------------------------
   mapInit_{{mapId}} = function() {
      if (debugMaps) console.log('mapInit_{{mapId}} ...');
      if (mapsApiLoading) {
         mapsApiLoaded=true;
      }
      if (! mapsApiLoaded) {
         console.error('Google Maps API not loaded. Call mapLoad function ...');
         return;
      }

      var scripts = [];
      // Group markers inside of clusters depending upon map zoom level
      if (! window.MarkerClusterer) scripts.push("/static/worldmap/js/markerclusterer.js");
      // Allow labels for map markers 
      if (! window.MarkerWithLabel) scripts.push("/static/worldmap/js/markerwithlabel.js");
      // "Spiderify" close markers : https://github.com/jawj/OverlappingMarkerSpiderfier
      if (! window.OverlappingMarkerSpiderfier) scripts.push("/static/worldmap/js/oms.min.js");
      loadScripts(scripts, function() {
         if (debugMaps) console.log('Scripts loaded !')

         if ("{{params['layer']}}"=='OSM') {
            // Define OSM map type pointing at the OpenStreetMap tile server
            map_{{mapId}} = new google.maps.Map(document.getElementById('{{mapId}}'), {
               center: new google.maps.LatLng (defLat, defLng),
               zoom: defaultZoom,
               mapTypeId: "OSM",
               mapTypeControl: false,
               streetViewControl: false
            });

            map_{{mapId}}.mapTypes.set("OSM", new google.maps.ImageMapType({
               getTileUrl: function(coord, zoom) {
                  return "http://tile.openstreetmap.org/" + zoom + "/" + coord.x + "/" + coord.y + ".png";
               },
               tileSize: new google.maps.Size(256, 256),
               name: "OpenStreetMap",
               maxZoom: 18
            }));
         } else {
            map_{{mapId}} = new google.maps.Map(document.getElementById('{{mapId}}'), {
               center: new google.maps.LatLng (defLat, defLng),
               zoom: defaultZoom,
               mapTypeId: google.maps.MapTypeId.ROADMAP,
               panControl: true,
               zoomControl: true,
               mapTypeControl: false,
               scaleControl: true,
               streetViewControl: false
            });
         }
         if (debugMaps) console.log('Map object ({{mapId}}): ', map_{{mapId}})

         var bounds = new google.maps.LatLngBounds();
         infoWindow_{{mapId}} = new google.maps.InfoWindow;

         %# For all hosts ...
         %for h in hosts:

         try {
            // Create a marker for all hosts having GPS coordinates ...
            if (debugMaps) console.log("host {{h.get_name()}} is {{h.state}}. GPS is {{h.customs.get('_LOC_LAT')}} / {{h.customs.get('_LOC_LNG')}} :");
            var gpsLocation = new google.maps.LatLng( {{float(h.customs.get('_LOC_LAT'))}} , {{float(h.customs.get('_LOC_LNG'))}} );

            var hostAcknowledged = false;
            %if h.is_problem and h.problem_has_been_acknowledged:
            hostAcknowledged = true;
            %end
            var hostGlobalState = 0;
            var hostState = "{{h.state}}";
            switch(hostState.toUpperCase()) {
               case "UP":
                  hostGlobalState=0;
                  break;
               case "DOWN":
                  hostGlobalState=2;
                  if (hostAcknowledged) hostGlobalState=3;
                  break;
               default:
                  hostGlobalState=1;
                  if (hostAcknowledged) hostGlobalState=3;
                  break;
            }
            if (debugMaps) console.log('-> host global state : '+hostGlobalState);

            var markerInfoWindowContent = [
               '<div class="map-infoView" id="iw-{{h.get_name()}}">',
               '{{!app.helper.get_fa_icon_state(h)}}',
               '<span class="map-hostname"><a href="/host/{{h.get_name()}}">{{h.get_name()}}</a> {{!app.helper.get_business_impact_text(h.business_impact)}} is {{h.state}}.</span>',
               %if h.in_scheduled_downtime:
               '<div><i class="fa fa-ambulance"></i> Currently in scheduled downtime.</div>',
               %end
               %if h.is_problem:
               %if h.problem_has_been_acknowledged:
               '<div><i class="fa fa-check"></i> Host problem has been acknowledged.</div>',
               %else:
               '<div><i class="fa fa-check"></i> Host problem should be acknowledged.</div>',
               %end
               %end
               '<hr/>',
               %if h.services:
               '<ul class="map-services">',
               %for s in h.services:
                  %#if s.get_name() in params['map_servicesHide']:
                  %#continue
                  %#end
                  '<li>',
                  '{{!app.helper.get_fa_icon_state(s)}}',
                  '<a href="/service/{{h.get_name()}}/{{s.get_name()}}">{{s.get_name()}}</a> {{!app.helper.get_business_impact_text(s.business_impact)}} is {{s.state}}.',
                  '</li>',
               %end
               '</ul>',
               %end
               '</div>'
            ].join('');

            var ok=0, warning=0, pending=0, unknown=0, ko=0, ack=0;
            %if h.services:
               %for s in h.services:
                  %if s.problem_has_been_acknowledged:
                  ack++;
                  %end
                  switch("{{s.state}}".toUpperCase()) {
                     case "OK":
                        ok++;
                        break;
                     case "PENDING":
                        pending++;
                        break;
                     case "WARNING":
                        warning++;
                        break;
                     case "CRITICAL":
                        ko++;
                        break;
                     case "UNKNOWN":
                     default:
                        unknown++;
                        break;
                  }
               %end
               %for s in h.services:
                  %if s.business_impact in params['services_level']:
                     var serviceAcknowledged = false;
                     %if s.problem_has_been_acknowledged:
                     serviceAcknowledged = true;
                     %end
                     var serviceState = "{{s.state}}";
                     switch(serviceState.toUpperCase()) {
                        case "OK":
                           break;
                        case "PENDING":
                           if (hostGlobalState < 1) if (serviceAcknowledged) hostGlobalState=3; else hostGlobalState=1;
                           break;
                        case "WARNING":
                           if (hostGlobalState < 1) if (serviceAcknowledged) hostGlobalState=3; else hostGlobalState=1;
                           break;
                        case "CRITICAL":
                           if (hostGlobalState < 2) if (serviceAcknowledged) hostGlobalState=3; else hostGlobalState=2;
                           break;
                        case "UNKNOWN":
                        default:
                           if (hostGlobalState < 1) if (serviceAcknowledged) hostGlobalState=3; else hostGlobalState=1;
                           break;
                     }
                     // if (debugMaps) console.log('-> host global state : '+hostGlobalState);
                  %end
               %end
            %end
            var title = ' '+ok+' ok, '+warning+' warning, '+ko+' critical, '+pending+' pending, '+unknown+' unknown ('+ack+' acknowledged)'
            var markerState = "UNKNOWN";
            switch(hostGlobalState) {
               case 0:
                  markerState = "OK";
                  break;
               case 2:
                  markerState = "KO";
                  break;
               case 3:
                  markerState = "ACK";
                  break;
               default:
                  markerState = "WARNING";
                  break;
            }

            // Create marker and append to markers list ...
            allMarkers_{{mapId}}.push(markerCreate_{{mapId}}('{{h.get_name()}}', markerState, markerInfoWindowContent, gpsLocation, 'mark-host-monitored', title));
            bounds.extend(gpsLocation);
            if (debugMaps) console.log('-> marker created at '+gpsLocation+'.');
         } catch (e) {
            if (debugMaps) console.error('mapInit_{{mapId}}, exception : '+e.message);
         }

         %end
         %# End all hosts ...

         map_{{mapId}}.fitBounds(bounds);
         var mcOptions = {
            zoomOnClick: true, showText: true, averageCenter: true, gridSize: 40, minimumClusterSize: 2, maxZoom: 18,
            styles: [
               { height: 50, width: 50, url: imagesDir+"/cluster-OK.png" },
               { height: 60, width: 60, url: imagesDir+"/cluster-WARNING.png" },
               { height: 60, width: 60, url: imagesDir+"/cluster-KO.png" }
            ]
            ,
            calculator: function(markers, numStyles) {
               // Manage markers in the cluster ...
               if (debugMaps) console.log("marker, count : "+markers.length);
               if (debugMaps) console.log(markers);
               var ok=0, warning=0, ko=0, ack=0;
               var clusterIndex = 1;
               for (i=0; i < markers.length; i++) {
                  var currentMarker = markers[i];
                  if (debugMaps) console.log("marker, "+currentMarker.hostname+" state is : "+currentMarker.hoststate);
                  // if (debugMaps) console.log(currentMarker);
                  switch(currentMarker.hoststate.toUpperCase()) {
                     case "OK":
                        ok++;
                        break;
                     case "ACK":
                        ack++;
                        break;
                     case "WARNING":
                        warning++;
                        if (clusterIndex < 2) clusterIndex=2;
                        break;
                     case "KO":
                        ko++;
                        if (clusterIndex < 3) clusterIndex=3;
                        break;
                  }
               }

               if (debugMaps) console.log("marker, index : "+clusterIndex);
               return {text: markers.length, index: clusterIndex, title: ''+ok+' ok, '+warning+' warning, '+ko+' critical, ('+ack+' acknowledged)'};
            }
         };
         var markerCluster = new MarkerClusterer(map_{{mapId}}, allMarkers_{{mapId}}, mcOptions);

         // Configuration
         var nearbyDistance = 40;
         var circleFootSeparation = 50;
         var spiralFootSeparation = 50;
         var spiralLengthFactor = 20;

         var oms = new OverlappingMarkerSpiderfier(map_{{mapId}}, {
            markersWontMove: true,
            markersWontHide: true,
            keepSpiderfied: true,
            nearbyDistance: nearbyDistance,
            circleFootSeparation: circleFootSeparation,
            spiralFootSeparation: spiralFootSeparation,
            spiralLengthFactor: spiralLengthFactor
         });
         oms.addListener('click', function(marker) {
            if (debugMaps) console.log('click marker for host : '+marker.hostname);
            infoWindow_{{mapId}}.setContent(marker.iw_content);
            infoWindow_{{mapId}}.open(map_{{mapId}}, marker);
         });
         oms.addListener('spiderfy', function(markers) {
            if (debugMaps) console.log('spiderfy ...');
            infoWindow_{{mapId}}.close();
         });
         oms.addListener('unspiderfy', function(markers) {
            if (debugMaps) console.log('unspiderfy ...');
         });

         for (i=0; i < allMarkers_{{mapId}}.length; i++) {
            oms.addMarker(allMarkers_{{mapId}}[i]);
         }
      });
   };

   //<!-- Ok go initialize the map with all elements when it's loaded -->
   $(document).ready(function (){
      // Uncomment to activate javascript console logs ...
      debugMaps=false; 

      // Introduce a small timeout to avoid several parallel loading ...
      var random = Math.floor((Math.random() * 1000));
      if (debugMaps) console.log('Random loading time: ', random)
      window.setTimeout(function() {
         if (window.google) {
            if (debugMaps) console.debug("Google maps already loaded ...");
            mapInit_{{mapId}}();
        } else {
            $.getScript("https://maps.googleapis.com/maps/api/js?sensor=false&callback=mapInit_{{mapId}}", function() {
               mapsApiLoaded=true;
               if (debugMaps) console.log("Google maps API loaded ...");
            });
        }
      }, random);
   });
</script>
