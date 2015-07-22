%# No default refresh for this page
%rebase("layout", css=['worldmap/css/worldmap.css'], title='Worldmap', refresh=False)

<!-- HTML map container -->
<div class="map_container">
   %if not hosts:
      <center>
         %if search_string:
         <h3>Bummer, we couldn't find anything.</h3>
         Use the filters or the bookmarks to find what you are looking for, or try a new search query.
         %else:
         <h3>No host or service.</h3>
         %end
      </center>
   %else:
      <div id="map">
         <div class="alert alert-info">
            <a href="#" class="alert-link">Loading map ...</a>
         </div>
      </div>
   %end
</div>

<script>
   // Google API not yet loaded ...
   var apiLoaded=false;
   var apiLoading=false;
   // Set true to activate javascript console logs
   var debugJs=false;
   if (debugJs && !window.console) {
      alert('Your web browser does not have any console object ... you should stop using IE ;-) !');
   }

   var map;
   var infoWindow;
   
   // Images dir
   var imagesDir="/static/worldmap/img/";

   // Default camera position/zoom ...
   var defLat={{params['default_Lat']}};
   var defLng={{params['default_Lng']}};
   var defaultZoom={{params['default_zoom']}};

   // Default map layer ...
   var mapLayer='{{params['layer']}}';

   // Markers ...
   var allMarkers = [];

   //------------------------------------------------------------------------------
   // Create a marker on specified position for specified host/state with IW content
   //------------------------------------------------------------------------------
   // position : GPS coordinates
   // name : host name
   // state : host state
   // content : infoWindow content
   // iconBase : icone name base
   //------------------------------------------------------------------------------
   markerCreate = function(name, state, content, position, iconBase, title) {
      if (debugJs) console.log("-> marker creation for "+name+", state : "+state);
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
            map: map, 
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
   mapInit = function() {
      if (debugJs) console.log('mapInit ...');
      if (apiLoading) {
         apiLoaded=true;
      }
      if (! apiLoaded) {
         console.error('Google Maps API not loaded. Call mapLoad function ...');
         return;
      }
      
      // "Spiderify" close markers : https://github.com/jawj/OverlappingMarkerSpiderfier
      $.getScript("/static/worldmap/js/oms.min.js", function( data, textStatus, jqxhr ) {
         if (debugJs) console.log('Spiderify API loaded ...');
         $.getScript(debugJs ? "/static/worldmap/js/markerclusterer.js" : "/static/worldmap/js/markerclusterer_packed.js", function( data, textStatus, jqxhr ) {
            if (debugJs) console.log('Google marker clusterer API loaded ...');
            $.getScript(debugJs ? "/static/worldmap/js/markerwithlabel.js" : "/static/worldmap/js/markerwithlabel_packed.js", function( data, textStatus, jqxhr ) {
               if (debugJs) console.log('Google labeled marker API loaded ...');
               
               if (mapLayer=='OSM') {
                  // Define OSM map type pointing at the OpenStreetMap tile server
                  map = new google.maps.Map(document.getElementById('map'),{
                     center: new google.maps.LatLng (defLat, defLng),
                     zoom: defaultZoom,
                     mapTypeId: "OSM",
                     mapTypeControl: false,
                     streetViewControl: false
                  });

                  map.mapTypes.set("OSM", new google.maps.ImageMapType({
                     getTileUrl: function(coord, zoom) {
                        return "http://tile.openstreetmap.org/" + zoom + "/" + coord.x + "/" + coord.y + ".png";
                     },
                     tileSize: new google.maps.Size(256, 256),
                     name: "OpenStreetMap",
                     maxZoom: 18
                  }));
               } else {
                  map = new google.maps.Map(document.getElementById('map'),{
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
          
               var bounds = new google.maps.LatLngBounds();
               infoWindow = new google.maps.InfoWindow;
               
               %# For all hosts ...
               %for h in hosts:
               
               try {
                  // Create a marker for all hosts having GPS coordinates ...
                  if (debugJs) console.log("host {{h.get_name()}} is {{h.state}}. GPS is {{h.customs.get('_LOC_LAT')}} / {{h.customs.get('_LOC_LNG')}} :");
                  var gpsLocation = new google.maps.LatLng( {{float(h.customs.get('_LOC_LAT', params['default_Lat']))}} , {{float(h.customs.get('_LOC_LNG', params['default_Lng']))}} );
                  
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
                  if (debugJs) console.log('-> host global state : '+hostGlobalState);

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
                        '<a href="/service/{{h.get_name()}}/{{s.get_name()}}">{{s.get_name()}} {{s.get_name()}}</a> {{!app.helper.get_business_impact_text(s.business_impact)}} is {{s.state}}.',
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
                           if (debugJs) console.log('-> host global state : '+hostGlobalState);
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
                  allMarkers.push(markerCreate('{{h.get_name()}}', markerState, markerInfoWindowContent, gpsLocation, 'mark-host-monitored', title));
                  bounds.extend(gpsLocation);
                  if (debugJs) console.log('-> marker created at '+gpsLocation+'.');
               } catch (e) {
                  if (debugJs) console.error('mapInit, exception : '+e.message);
               }
                  
               %end
               %# End all hosts ...
               
               map.fitBounds(bounds);

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
                     if (debugJs) console.log("marker, count : "+markers.length);
                     if (debugJs) console.log(markers);
                     var ok=0, warning=0, ko=0, ack=0;
                     var clusterIndex = 1;
                     for (i=0; i < markers.length; i++) {
                        var currentMarker = markers[i];
                        if (debugJs) console.log("marker, "+currentMarker.hostname+" state is : "+currentMarker.hoststate);
                        // if (debugJs) console.log(currentMarker);
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

                     if (debugJs) console.log("marker, index : "+clusterIndex);
                     return {text: markers.length, index: clusterIndex, title: ''+ok+' ok, '+warning+' warning, '+ko+' critical, ('+ack+' acknowledged)'};
                  }
               };
               var markerCluster = new MarkerClusterer(map, allMarkers, mcOptions);

               // Configuration
               var nearbyDistance = 40;
               var circleFootSeparation = 50;
               var spiralFootSeparation = 50;
               var spiralLengthFactor = 20;

               var oms = new OverlappingMarkerSpiderfier(map, {
                  markersWontMove: true, 
                  markersWontHide: true,
                  keepSpiderfied: true,
                  nearbyDistance: nearbyDistance,
                  circleFootSeparation: circleFootSeparation,
                  spiralFootSeparation: spiralFootSeparation,
                  spiralLengthFactor: spiralLengthFactor
               });
               oms.addListener('click', function(marker) {
                  if (debugJs) console.log('click marker for host : '+marker.hostname);
                  infoWindow.setContent(marker.iw_content);
                  infoWindow.open(map, marker);
               });
               oms.addListener('spiderfy', function(markers) {
                  if (debugJs) console.log('spiderfy ...');
                  infoWindow.close();
               });
               oms.addListener('unspiderfy', function(markers) {
                  if (debugJs) console.log('unspiderfy ...');
               });
               
               for (i=0; i < allMarkers.length; i++) {
                  oms.addMarker(allMarkers[i]);
               }
            });
         });
      });
   };

   //<!-- Ok go initialize the map with all elements when it's loaded -->
   $(document).ready(function (){
      // Uncomment to activate javascript console logs ...
      // debugJs=true; 
      $.getScript("http://maps.googleapis.com/maps/api/js?sensor=false&callback=mapInit", function() {
         apiLoaded=true;
         if (debugJs) console.log("Google maps API loaded ...");
      });
   });
</script>
