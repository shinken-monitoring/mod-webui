<script>
  // Set true to activate javascript console logs
  var debugMaps = false;
  if (debugMaps && !window.console) {
    alert('Your web browser does not have any console object ... you should stop using IE ;-) !');
  }

  var servicesLevel = {{ params['services_level'] }};

  %# List hosts and their services
    var hosts = [
      %for h in hosts:
      new Host(
        '{{ h.get_name() }}', '{{ h.state }}',
        '{{ !app.helper.get_fa_icon_state(h) }}',
        '{{ h.business_impact }}',
        '{{ !app.helper.get_business_impact_text(h.business_impact) }}',
        {{ float(h.customs.get('_LOC_LAT')) }}, {{ float(h.customs.get('_LOC_LNG')) }},
        {{ str(h.is_problem).lower() }}, {{ str(h.is_problem).lower() }} && {{ str(h.problem_has_been_acknowledged).lower() }},
        {{ str(h.in_scheduled_downtime).lower() }},
        [
          %for s in h.services:
          new Service(
            '{{ s.get_name() }}', '{{ s.state }}',
            '{{ !app.helper.get_fa_icon_state(s) }}',
            '{{ !app.helper.get_business_impact_text(s.business_impact) }}',
            {{ str(s.problem_has_been_acknowledged).lower() }},
            '{{ h.get_name() }}'
          ),
          %end
        ],
        [
          %for p in h.parent_dependencies:
          [{{float(p.customs.get('_LOC_LAT'))}}, {{float(p.customs.get('_LOC_LNG'))}}],
          %end
        ]
      ),
      %end
    ]


  function hostInfoContent() {
    var text = '<div class="map-infoView" id="iw-' + this.name + '">' + this.iconState + ' <span class="map-hostname"><a href="/host/' + this.name + '">' + this.name + '</a> ' + this.businessImpact + ' is ' + this.state + '.</span>';
    if (this.scheduledDowntime) {
      text += '<div><i class="fa fa-ambulance"></i> Currently in scheduled downtime.</div>';
    }
    if (this.isProblem) {
      text += '<div><i class="fa fa-check"></i> ';
      if (this.isAcknowledged) {
        text += 'Host problem has been acknowledged.';
      } else {
        text += 'Host problem should be acknowledged.';
      }
      text += '</div>';
    }
    text += '<hr/>';
    if (this.services.length > 0) {
      text += '<ul class="map-services">';
      for (var i = 0; i < this.services.length; i++) {
        text += this.services[i].infoContent();
      }
      text += '</ul>';
    }
    text += '</div>';
    return text;
  }

  function gpsLocation() {
    return L.latLng(this.lat, this.lng);
  }

  function parentsGpsLocations() {
    // console.log('TFLK parentsGpsLocations')
    locations = [];
    for (var i = 0; i < this.parents.length; i++) {
      // console.log('TFLK parentsGpsLocations parent' + this.parents[i][0])
      var loc = L.latLng(this.parents[i][0], this.parents[i][1]);
      locations.push(loc);
    }
    return locations;
  }

  function markerIcon() {
    return imagesDir + '/glyph-marker-icon-' + this.hostState().toLowerCase() + '.png';
  }

  function hostState() {
    var hs = 'OK';
    switch (this.state.toUpperCase()) {
      case 'UP':
        break;
      case 'DOWN':
        if (this.isAcknowledged) {
          hs = 'ACK';
        } else {
          hs = 'KO';
        }
        break;
      default:
        if (this.isAcknowledged) {
          hs = 'ACK';
        } else {
          hs = 'WARNING';
        }
    }
    for (var i = 0; i < this.services.length; i++) {
      var s = this.services[i];
      if ($.inArray(s.businessImpact, servicesLevel)) {
        switch (s.state.toUpperCase()) {
          case 'OK':
            break;
          case 'CRITICAL':
            if (hs == 'OK' || hs == 'WARNING' || hs == 'ACK') {
              if (s.isAcknowledged) {
                hs = 'ACK';
              } else {
                hs = 'KO';
              }
            }
            break;
          default:
            if (hs == 'OK' || hs == 'ACK') {
              if (s.isAcknowledged) {
                hs = 'ACK';
              } else {
                hs = 'WARNING';
              }
            }
        }
      }
    }

    return hs;
  }

  function Host(name, state, iconState, businessImpactNumber, businessImpact, lat, lng, isProblem, isAcknowledged, scheduledDowntime, services, parents) {
    this.name = name;
    this.state = state;
    this.iconState = iconState;
    this.businessImpactNumber = businessImpactNumber;
    this.businessImpact = businessImpact;
    this.lat = lat;
    this.lng = lng;
    this.isProblem = isProblem;
    this.isAcknowledged = isAcknowledged;
    this.scheduledDowntime = scheduledDowntime;
    this.services = services;
    this.parents = parents;

    this.infoContent = hostInfoContent;
    this.location = gpsLocation;
    this.parentLocations = parentsGpsLocations
    this.markerIcon = markerIcon;
    this.hostState = hostState;
  }

  function serviceInfoContent() {
    return '<li>' + this.iconState + ' <a href="/service/' + this.hostName + '/' + this.name + '">' + this.name + '</a> ' + this.businessImpact + ' is ' + this.state + '.</li>';
  }

  function Service(name, state, iconState, businessImpact, isAcknowledged, hostName) {
    this.name = name;
    this.state = state;
    this.iconState = iconState;
    this.businessImpact = businessImpact;
    this.isAcknowledged = isAcknowledged;
    this.hostName = hostName;

    this.infoContent = serviceInfoContent;
  }

  function Arrow(firstPoint, secondPoint) {
    var arrowIcon = L.icon({
      iconUrl: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAAAXNSR0IArs4c6QAAAAlwSFlzAAALEwAACxMBAJqcGAAAAVlpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IlhNUCBDb3JlIDUuNC4wIj4KICAgPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4KICAgICAgPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIKICAgICAgICAgICAgeG1sbnM6dGlmZj0iaHR0cDovL25zLmFkb2JlLmNvbS90aWZmLzEuMC8iPgogICAgICAgICA8dGlmZjpPcmllbnRhdGlvbj4xPC90aWZmOk9yaWVudGF0aW9uPgogICAgICA8L3JkZjpEZXNjcmlwdGlvbj4KICAgPC9yZGY6UkRGPgo8L3g6eG1wbWV0YT4KTMInWQAAAdpJREFUOBGFVDtOA0EMnewGCS7ACeAYUIISEtpAxRGgRaLlFijiFkCAlgqJDokT0CAqJD7ZxLznsScT2GR35IzXnzdvbG9CWPZIKOhuS3u3lLKroWZbllbvyxIB9gB5TIGZL9kaFQltxoDdDsB8dTTPfI0YKUBCy3VA3SQ4Ke/cHrKYZFuoSFihD0AdBZtmv1L2NM9iFmIkR3YyYEYKJeUYO4XrPovVpqX3WmXGbs8ACDIx8Vrua24jy6x7APDa/UDnpSnUufJaLmFp3UNCzq5KcFJWBkjQvrHUafh/23p23wbgDAnktgaWM3bdjAVr52C+T9QSr+4d/8NyvrO3Buj1ciDfCeW+nGWa3YAh9bnrNbBzUDL35SwVowBYge9ibEU9sb1Se3wRbBMT6iTAzlaqhxBziKH2Gbt+OjN2kx3lMJOVL+q00Zd3PLHM2R3biV/KAV8edha7JUGeKNTNRh/ZfkL4xFy/KU7z2uW1oc4GHSJ1DbIK/QAyguTsfBLi/yXhEXAN8fWOD22Iv61t+uoe+LYQfQF5S1lSXmksDAMaCyleIGdgsjkHwhqz2FG0k8kvYQM5p5BnAx608HKOgNdpmF6iQh8aHOeS9atgi511lDofSlKE4ggh679ecGIXq+UAsgAAAABJRU5ErkJggg==',
      iconSize: [20, 20],
      iconAnchor: [10, 10],
      popupAnchor: [-3, -76],
    });

    var diffLat = secondPoint.lat-firstPoint.lat, angle;
    var diffLng = secondPoint.lng-firstPoint.lng;
    var slope = diffLat/diffLng;
    // console.log('TFLK diffs:' + diffLat + ' / ' + diffLng);
    // console.log('TFLK slope:' + slope);
    // console.log('TFLK atan:' + Math.atan(slope));
    if (diffLng == 0){
      if (diffLat>=0){
        angle = Math.PI/2;
      }else{
        angle = -Math.PI/2;
      }
    }else if(diffLng > 0){
      angle = Math.atan(slope);

    }else{
      // var angle=Math.atan(slope);
      // rad2deg -> angle * (180/Math.PI)
      angle = Math.atan(slope)-Math.PI;
    }
    var midPoint = new L.latLng((firstPoint.lat+secondPoint.lat)/2, (firstPoint.lng+secondPoint.lng)/2);
    // console.log('TFLK arrow:' + firstPoint + secondPoint + angle + '->' + (angle * (180/Math.PI)));
    return L.marker(midPoint, {icon: arrowIcon, rotationAngle: 90-(angle * (180/Math.PI))});
  }

  var map_{{mapId}};
  var infoWindow_{{mapId}};

  // Images dir
  var imagesDir = "/static/worldmap/img/";

  //------------------------------------------------------------------------------
  // Sequentially load necessary scripts to create map with markers
  // ------------------------------------------------------------------------------
  loadScripts = function(scripts, complete) {
    var loadScript = function(src) {
      if (!src)
        return;
      if (debugMaps)
        console.log('Loading script: ', src);
      $.getScript(src, function(data, textStatus, jqxhr) {
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

  // ------------------------------------------------------------------------------
  // Create a marker on specified position for specified host/state with IW content
  // ------------------------------------------------------------------------------
  markerCreate_{{mapId}} = function(host) {
    if (debugMaps)
      console.log("-> marker creation for " + host.name + ", state : " + host.hostState());

    var icon = L.icon.glyph({iconUrl: host.markerIcon(), prefix: 'fa', glyph: 'server'});

    var m = L.marker(host.location(), {icon: icon}).bindLabel(host.name, {
      noHide: true,
      direction: 'center',
      offset: [0, 0]
    }).bindPopup(host.infoContent()).openPopup();
    m.state = host.hostState();
    return m;
  }

  // ------------------------------------------------------------------------------
  // Map initialization
  // ------------------------------------------------------------------------------
  // ------------------------------------------------------------------------------
  mapInit_{{mapId}} = function() {
    if (debugMaps)
      console.log('mapInit_{{mapId}} ...');

    var scripts = [];
    scripts.push('/static/worldmap/js/leaflet.js');
    scripts.push('/static/worldmap/js/leaflet.markercluster.js');
    scripts.push('/static/worldmap/js/Leaflet.Icon.Glyph.js');
    scripts.push('/static/worldmap/js/leaflet.label.js');
    scripts.push('/static/worldmap/js/leaflet.rotatedMarker.js');
    loadScripts(scripts, function() {
      if (debugMaps)
        console.log('Scripts loaded !')

      map_{{mapId}} = L.map('{{mapId}}');
      L.tileLayer('https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png', {attribution: '&copy; <a href="http://osm.org/copyright">OpenStreetMap</a> contributors, &copy; <a href="http://cartodb.com/attributions">CartoDB</a>'}).addTo(map_{{mapId}});
      var bounds = new L.LatLngBounds();

      if (debugMaps)
        console.log('Map object ({{mapId}}): ', map_{{mapId}})

        // Markers ...
      var allMarkers_{{mapId}} = [];
      // var arrow_latlngs = [], arrow_latlng;
      for (var i = 0; i < hosts.length; i++) {
        var h = hosts[i];
        bounds.extend(h.location());
        allMarkers_{{mapId}}.push(markerCreate_{{mapId}}(h));
        // console.log('TFLK')
        var parentLocations = h.parentLocations();
        for (var j = 0; j < parentLocations.length; j++) {
          // console.log('TFLK j' + j)
          var loc = parentLocations[j];
          var line = new L.Polyline(
            [h.location(), loc],{
              weight: h.businessImpactNumber,
              color: '#00ff00',
            }
          );
          allMarkers_{{mapId}}.push(line);
          // console.log('TFLK arrow_latlngs1' + arrow_latlngs);
          // arrow_latlng = Math.floor(loc.lat*10000) + '/' + Math.floor(loc.lng*10000);
            // var arrow = Arrow(h.location(), loc);
          allMarkers_{{mapId}}.push(Arrow(h.location(), loc));
          // if (arrow_latlngs.indexOf(arrow_latlng) == -1) {
          //   arrow_latlngs.push(arrow_latlng);
          //   console.log('TFLK arrow_latlngs2:' + arrow_latlngs.indexOf(arrow_latlng) + '-' + arrow_latlngs);
          //   var arrow = Arrow(h.location(), loc);
          //   allMarkers_{{mapId}}.push(arrow);
          // }
        }
      }

      // Zoom
      map_{{mapId}}.fitBounds(bounds);

      // Build marker cluster
      var markerCluster = L.markerClusterGroup({
        maxClusterRadius: 25,
        //spiderfyDistanceMultiplier: 3,
        //removeOutsideVisibleBounds: false,
        iconCreateFunction: function(cluster) {
          // Manage markers in the cluster ...
          var markers = cluster.getAllChildMarkers();
          if (debugMaps)
            console.log("marker, count : " + markers.length);
          var clusterState = "ok";
          for (var i = 0; i < markers.length; i++) {
            var currentMarker = markers[i];
            if (debugMaps) {
              console.log("marker, " + currentMarker.hostname + " state is: " + currentMarker.state);
            }
            switch (currentMarker.state) {
              case "WARNING":
                if (clusterState != "ko")
                  clusterState = "warning";
                break;
              case "KO":
                clusterState = "ko";
                break;
            }
          }
          return L.divIcon({
            html: '<div><span>' + markers.length + '</span></div>',
            className: 'marker-cluster marker-cluster-' + clusterState,
            iconSize: new L.Point(60, 60)
          });
        }
      });
      markerCluster.addLayers(allMarkers_{{mapId}});
      map_{{mapId}}.addLayer(markerCluster);
    });
  };

  //<!-- Ok go initialize the map with all elements when it's loaded -->
  $(document).ready(function() {
    $.getScript("https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.0.0-rc.1/leaflet.js").done(function() {
      if (debugMaps)
        console.log("Leafletjs API loaded ...");
      mapInit_{{mapId}}();
    });
  });
</script>
