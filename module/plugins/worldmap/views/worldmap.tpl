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
         <h3>No hosts to locate on map.</h3>
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

%include("_worldmap")
