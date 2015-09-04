%rebase("widget", css=['worldmap/css/worldmap.css'])

<!-- HTML map container -->
<div class="map_container_widget">
   %if not hosts:
      <center>
         <h3>We couldn't find any hosts to locate on a map.</h3>
      </center>
      <hr/>
      <p align><strong>1. </strong>If you used a filter in the widget, change the filter to try a new search query.</p>
      <p align><strong>2. </strong>Only the hosts having GPS coordinates may be located on the map. If you do not have any, add hosts GPS coordinates in the configuration file: </p>
      <code>
      <p># GPS</p>
      <p>_LOC_LAT             45.054700</p>
      <p>_LOC_LNG             5.080856</p>
      </code>
   %else:
      <div id="{{mapId}}" class="gMap">
         <div class="alert alert-info">
            <a href="#" class="alert-link">Loading map ...</a>
         </div>
      </div>
   %end
</div>

%include("_worldmap")
