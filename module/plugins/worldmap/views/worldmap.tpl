%rebase layout globals(), css=['worldmap/css/worldmap.css'], title='Worldmap', refresh=True

<!-- HTML map container -->
<div class="map_container">
	<div id="map">
		<div class="alert alert-info">
			<a href="#" class="alert-link">Loading map ...</a>
		</div>
	</div>
</div>

<script>
	// Google API not yet loaded ...
	var apiLoaded=false;
	var apiLoading=false;
	// Set true to activate javascript console logs
	var debugJs=false;

	var map;
	var infoWindow;
	
	// Images dir
	var imagesDir="/static/worldmap/img/";

	// Default camera position/zoom ...
	var defLat={{params['default_Lat']}};
	var defLng={{params['default_Lng']}};
	var defaultZoom={{params['default_zoom']}};

	// Markers ...
	var allMarkers = [];

	//------------------------------------------------------------------------------
	// Create a marker on specified position for specified host/state with IW content
	//------------------------------------------------------------------------------
	// point : GPS coordinates
	// name : host name
	// state : host state
	// content : infoWindow content
	//------------------------------------------------------------------------------
	markerCreate = function(name, state, content, position, iconBase) {
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
			/* Standard Google maps marker */
			var marker = new google.maps.Marker({
				map: map, 
				position: position,
				icon: markerImage, 
				raiseOnDrag: false, draggable: true,
				title: name,
				hoststate: state,
				hostname: name,
				iw_content: content
			});

			/* Marker with label ...
			var marker = new MarkerWithLabel({
				map: map, 
				position: position,
				icon: markerImage, 
				raiseOnDrag: false, draggable: true,
				title: name,
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
			*/
			
			// Register Custom "dragend" Event
			google.maps.event.addListener(marker, 'dragend', function() {
				// Center the map at given point
				map.panTo(marker.getPosition());
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
					
					map = new google.maps.Map(document.getElementById('map'),{
						center: new google.maps.LatLng (defLat, defLng),
						zoom: defaultZoom,
						mapTypeId: google.maps.MapTypeId.ROADMAP
					});

					var bounds = new google.maps.LatLngBounds();
					infoWindow = new google.maps.InfoWindow;
					
					%# For all hosts ...
					%for h in hosts:
					
					try {
						// Creating a marker for all hosts having GPS coordinates ...
						if (debugJs) console.log("host {{h.get_name()}} is {{h.state}}. GPS is {{h.customs.get('_LOC_LAT')}} / {{h.customs.get('_LOC_LNG')}} :");
						var gpsLocation = new google.maps.LatLng( {{float(h.customs.get('_LOC_LAT', params['default_Lat']))}} , {{float(h.customs.get('_LOC_LNG', params['default_Lng']))}} );
						//gpsLocation = new google.maps.LatLng( {{h.customs.get('_LOC_LAT', params['default_Lat'])}} , {{h.customs.get('_LOC_LNG', params['default_Lng'])}} );
						//gpsLocation = new google.maps.LatLng( defLat , defLng );
						
						var hostGlobalState = 0;
						var hostState = "{{h.state}}";
						switch(hostState.toUpperCase()) {
							case "UP":
								hostGlobalState=0;
								break;
							case "DOWN":
								hostGlobalState=2;
								break;
							default:
								hostGlobalState=1;
								break;
						}
						if (debugJs) console.log('-> host global state : '+hostGlobalState);

						var markerInfoWindowContent = [
							'<div class="map-infoView" id="iw-{{h.get_name()}}">',
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
										break;
									case "UNKNOWN":
									case "PENDING":
									case "WARNING":
										if (hostGlobalState < 1) hostGlobalState=1;
										break;
									case "CRITICAL":
										if (hostGlobalState < 2) hostGlobalState=2;
										break;
								}
								//if (debugJs) console.log('-> host global state : '+hostGlobalState);
							%end
						%end
						
						var markerState = "UNKNOWN";
						switch(hostGlobalState) {
							case 0:
								markerState = "OK";
								break;
							case 2:
								markerState = "KO";
								break;
							default:
								markerState = "WARNING";
								break;
						}
						
						// Create marker and append to markers list ...
						allMarkers.push(markerCreate('{{h.get_name()}}', markerState, markerInfoWindowContent, gpsLocation, 'host'));
						bounds.extend(gpsLocation);
						if (debugJs) console.log('-> marker created at '+gpsLocation+'.');
					} catch (e) {
						if (debugJs) console.error('markerCreate, exception : '+e.message);
					}
						
					%end
					%# End all hosts ...
					
					map.fitBounds(bounds);

					var mcOptions = {
						zoomOnClick: true, showText: true, averageCenter: true, gridSize: 40, maxZoom: 20, 
						styles: [
							{ height: 53, width: 53, url: imagesDir+"m1.png" },
							{ height: 56, width: 56, url: imagesDir+"m2.png" },
							{ height: 66, width: 66, url: imagesDir+"m3.png" },
							{ height: 78, width: 78, url: imagesDir+"m4.png" },
							{ height: 90, width: 90, url: imagesDir+"m5.png" }
						]
					};
					
					var mcOptions = {
						zoomOnClick: true, showText: true, averageCenter: true, gridSize: 10, minimumClusterSize: 2, maxZoom: 18,
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
							var clusterIndex = 1;
							for (i=0; i < markers.length; i++) {
								var currentMarker = markers[i];
								if (debugJs) console.log("marker, "+currentMarker.hostname+" state is : "+currentMarker.hoststate);
								// if (debugJs) console.log(currentMarker);
								switch(currentMarker.hoststate.toUpperCase()) {
									case "OK":
										break;
									case "WARNING":
										if (clusterIndex < 2) clusterIndex=2;
										break;
									case "KO":
										if (clusterIndex < 3) clusterIndex=3;
										break;
								}
							}

							if (debugJs) console.log("marker, index : "+clusterIndex);
							return {text: markers.length, index: clusterIndex};
						}
					};
					var markerCluster = new MarkerClusterer(map, allMarkers, mcOptions);

					var oms = new OverlappingMarkerSpiderfier(map, {
						markersWontMove: true, 
						markersWontHide: true,
						keepSpiderfied: true,
						nearbyDistance: 10,
						circleFootSeparation: 50,
						spiralFootSeparation: 50,
						spiralLengthFactor: 20
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
		$.getScript("https://maps.googleapis.com/maps/api/js?sensor=false&callback=mapInit", function() {
			apiLoaded=true;
			if (debugJs) console.log("Google maps API loaded ...");
		});
	});
</script>
