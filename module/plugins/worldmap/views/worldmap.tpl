<script type="text/javascript" src="http://maps.google.com/maps/api/js?sensor=false"></script>

%rebase layout globals(), js=['worldmap/js/XXX.js'], css=['worldmap/css/worldmap.css'], title='Worldmap', refresh=True

<!-- HTML map container -->
<div class="map_container row">
  <div id="map" class="col-lg-12">
  	<div class="alert alert-info">
		<a href="#" class="alert-link">Map loading</a>
	</div>
  </div>
</div>

<script>
	// Google API not yet loaded ...
	var apiLoaded=false;
	var apiLoading=false;
	// Set true to activate javascript console logs
	var debugJs=true;

	var map;
	var infoWindow;
	
	// Images dir
	var urlImages="/static/worldmap/img/";

	// Markers ...
	var allMarkers = [];

	// France / Romans is default camera position
	var defLat=45.054485;
	var defLng=5.081413;
	var defaultZoom=16;
	var currentZoom=defaultZoom;

	// Markers ...
	var allMarkers = [];
	// Content of infoWindow ...
	var infoWindowsArray = [];

	//------------------------------------------------------------------------------
	// Google maps API loading if needed, and map creation ...
	//------------------------------------------------------------------------------
	// If google maps API is not already loaded, call this function which will, at
	// end, call mapInit ...
	//------------------------------------------------------------------------------
	mapLoad = function() {
		if (debugJs) console.log('mapLoad');

		if (! apiLoaded) {
			apiLoading=true;
			var script = document.createElement("script");
			script.type = "text/javascript";
			script.src = "http://maps.googleapis.com/maps/api/js?sensor=false&callback=mapInit";
			document.body.appendChild(script);
		} else {
			mapInit();
		}
	}

	//------------------------------------------------------------------------------
	// Create a marker on specified position for specified host/state with IW content
	//------------------------------------------------------------------------------
	initPoint = function(point, name, state, content) {
		if (debugJs) console.log("markerCreate for "+name+", state : "+state);

		var iconUrl=urlImages+"point-"+state+".png";
		if (debugJs) console.log("markerCreate, icon URL : "+iconUrl);

		var image = new google.maps.MarkerImage(iconUrl, new google.maps.Size(32,32), new google.maps.Point(0,0), new google.maps.Point(16,32));

		// Manage markers on the same position ...
		for (i=0; i < allMarkers.length; i++) {
			var existingMarker = allMarkers[i];
			var pos = existingMarker.getPosition();

			// if a marker already exists in the same position as this marker
			if (point.equals(pos)) {
				if (debugJs) console.log("markerCreate, same position ...");
				
				//update the position of the coincident marker by applying a small multipler to its coordinates
				var newLat = point.lat() + (Math.random() -.10) / 20000;
				var newLng = point.lng() + (Math.random() -.10) / 20000;
				point = new google.maps.LatLng(newLat,newLng);
				if (debugJs) console.log("markerCreate, new position is : "+point);
			}
		}

		try {
/* Standard Google maps marker
			var marker = new google.maps.Marker({
				map: map, position: point, raiseOnDrag: false,
				icon: image, 
				animation: google.maps.Animation.DROP,
				title: name
			});
*/
			// Marker with label ...
			var marker = new MarkerWithLabel({
				map: map, position: point,
				icon: image, 
				raiseOnDrag: false, draggable: true,
				title: name,

				// Half the CSS width to get a centered label ...
				labelAnchor: new google.maps.Point(50, 10),
				labelClass: "labels",
				labelContent: name,
				labelStyle: {opacity: 0.50}
			});
			if (debugJs) console.log("markerCreate 2 : "+iconUrl);

			// Register Custom "click" Event
			google.maps.event.addListener(marker, 'click', function () {
				infoWindow.setContent(content);
				infoWindow.open(map, marker);
				
				return true;
			});
			
			// Register Custom "dragend" Event
			google.maps.event.addListener(marker, 'dragend', function() {
				// Get the Current position, where the pointer was dropped
				var point = marker.getPosition();
				// Center the map at given point
				map.panTo(point);
				// To be defined ... should be interesting to change customs variables ... to be done.
				if (debugJs) console.log("Host new position is : "+point.lat()+", "+point.lng());
				alert("Host "+name+" new position is : "+point.lat()+", "+point.lng()+" ... should be stored in host custom variables ... to be done !");
			});
		} catch (e) {
			if (debugJs) console.error('markerCreate, exception : '+e.message);
		}
		
		return marker;
	}
	
	mapInit = function() {
		if (debugJs) console.log('mapInit ...');
		if (apiLoading) {
			apiLoaded=true;
		}
		if (! apiLoaded) {
			console.error('Google Maps API not loaded. Call mapLoad function ...');
			return;
		}
		
		$.getScript(debugJs ? "/static/worldmap/js/markerclusterer.js" : "/static/worldmap/js/markerclusterer_packed.js", function( data, textStatus, jqxhr ) {
			if (debugJs) console.log('Google marker clusterer API loaded ...');
			$.getScript(debugJs ? "/static/worldmap/js/markerwithlabel.js" : "/static/worldmap/js/markerwithlabel_packed.js", function( data, textStatus, jqxhr ) {
				if (debugJs) console.log('Google labeled marker API loaded ...');
				
				map = new google.maps.Map(document.getElementById('map'),{
					center: new google.maps.LatLng (defLat, defLng),
					zoom: defaultZoom,
					mapTypeId: google.maps.MapTypeId.ROADMAP
				});

				var bounds = new google.maps.LatLngBounds();
				infoWindow = new google.maps.InfoWindow;
				
				var hostGlobalState = 0;

				// Creating a marker for all hosts having GPS coordinates ...
				%for h in hosts:
//%_ref = {'OK':0, 'UP':0, 'DOWN':3, 'UNREACHABLE':1, 'UNKNOWN':1, 'CRITICAL':3, 'WARNING':2, 'PENDING' :1}

					if (debugJs) console.log("host {{h.get_name()}} is {{h.state}}. GPS is {{h.customs.get('_LOC_LAT')}} / {{h.customs.get('_LOC_LNG')}}");
					try {
						var gpsLocation = new google.maps.LatLng( {{float(h.customs.get('_LOC_LAT'))}} , {{float(h.customs.get('_LOC_LNG'))}} )
						if (debugJs) console.log('host {{h.get_name()}} : '+gpsLocation);
						
						var hostState = "{{h.state}}";
						switch(hostState.toUpperCase()) {
							case "UP":
								hostGlobalState=0;
								break;
							case "DOWN":
								hostGlobalState=3;
								break;
							case "UNREACHABLE":
								hostGlobalState=1;
								break;
							case "UNKNOWN":
								hostGlobalState=1;
								break;
						}
						if (debugJs) console.log('-> host global state : '+hostGlobalState);

						var markerInfoWindowContent = [
							'<div id="iw-{{app.helper.get_html_id(h)}}">',
							'<img class="map-iconHostState map-host-{{h.state}} map-host-{{h.state_type}}" src="{{app.helper.get_icon_state(h)}}" />',
							'<span class="map-hostname"><a href="/host/{{h.get_name()}}">{{h.get_name()}}</a> is {{h.state}}.</span>',
							'<hr/>',
							%if h.services:
							'<ul class="map-servicesList">',
							%for s in h.services:
								'<li><span class="map-service map-service-{{s.state}} map-service-{{s.state_type}}"></span><a href="/service/{{h.get_name()}}/{{s.get_name()}}">{{s.get_name()}}</a> is {{s.state}}.</li>',
							%end
							'</ul>',
							%end
							'</div>'
						].join('');
						%if h.services:
							%for s in h.services:
								var serviceState = "{{s.state}}";
								switch(serviceState.toUpperCase()) {
									case "OK":
									case "UNKNOWN":
									case "PENDING":
										break;
									case "WARNING":
										if (hostGlobalState < 1) hostGlobalState=1;
										break;
									case "CRITICAL":
										if (hostGlobalState < 2) hostGlobalState=2;
										break;
								}
								if (debugJs) console.log('-> host global state : '+hostGlobalState);
							%end
						%end
						// Create a marker ...
		//				allMarkers.push(markerCreate(gpsLocation, host, infoViewContent, iconBase));
		//				bounds.extend(gpsLocation);
						var markerState = "UNKNOWN";
						switch(hostGlobalState) {
							case 0:
								markerState = "UP";
								break;
							case 1:
								markerState = "UNKNOWN";
								break;
							case 2:
								markerState = "UNREACHABLE";
								break;
							case 3:
								markerState = "DOWN";
								break;
						}
						allMarkers.push(initPoint(gpsLocation, '{{h.get_name()}}', markerState, markerInfoWindowContent));
					
						bounds.extend(gpsLocation);
					} catch (e) {
						if (debugJs) console.log('-> host {{h.get_name()}} does not have valid GPS.');
					}
				%end
				map.fitBounds(bounds);
				
				var mcOptions = {
					zoomOnClick: true, showText: true, averageCenter: true, gridSize: 40, maxZoom: 20, 
					styles: [
						{ height: 53, width: 53, url: urlImages+"m1.png" },
						{ height: 56, width: 56, url: urlImages+"m2.png" },
						{ height: 66, width: 66, url: urlImages+"m3.png" },
						{ height: 78, width: 78, url: urlImages+"m4.png" },
						{ height: 90, width: 90, url: urlImages+"m5.png" }
					]
				};
				var markerCluster = new MarkerClusterer(map, allMarkers, mcOptions);
			});
		});
	};

	//<!-- Ok go initialize the map with all elements when it's loaded -->
	$(document).ready(mapLoad);
</script>
