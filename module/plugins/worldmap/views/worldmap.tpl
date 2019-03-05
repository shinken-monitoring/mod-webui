%# No default refresh for this page
%rebase("layout", css=['worldmap/css/worldmap.css', 'worldmap/css/leaflet.css', 'worldmap/css/MarkerCluster.css', 'worldmap/css/MarkerCluster.Default.css', 'worldmap/css/leaflet.label.css'], title='Worldmap', refresh=False)

   %if not hosts:
   <div class="text-center">
      <h3>We couldn't find any hosts to locate on a map.</h3>
   </div>
   <hr/>
   <div>
      <p><strong>1. </strong>If you used a filter in the widget, change the filter to try a new search query.</p>
      <p><strong>2. </strong>Only the hosts having GPS coordinates may be located on the map. If you do not have any, add hosts GPS coordinates in the configuration file: </p>
      <code>
      <p># GPS</p>
      <p>_GPS                 48.858674, 2.293858</p>
      </code>
      <p>or</p>
      <code>
      <p># Latitude / longitude</p>
      <p>_LOC_LAT             48.858674</p>
      <p>_LOC_LNG             2.293858</p>
      </code>
   </div>
%else:
   <!-- HTML map container -->
   <div class="map_container">
     <div id="{{mapId}}" class="osm">
       <div class="alert alert-info">
          <a href="#" class="alert-link">Loading map ...</a>
       </div>
     </div>
   </div>
%end

%include("_worldmap")
