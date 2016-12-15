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

  function Host(name, state, iconState, businessImpact, lat, lng, isProblem, isAcknowledged, scheduledDowntime, services) {
    this.name = name;
    this.state = state;
    this.iconState = iconState;
    this.businessImpact = businessImpact;
    this.lat = lat;
    this.lng = lng;
    this.isProblem = isProblem;
    this.isAcknowledged = isAcknowledged;
    this.scheduledDowntime = scheduledDowntime;
    this.services = services;

    this.infoContent = hostInfoContent;
    this.location = gpsLocation;
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
    scripts.push('/static/worldmap/js/leaflet.markercluster.js');
    scripts.push('/static/worldmap/js/Leaflet.Icon.Glyph.js');
    scripts.push('/static/worldmap/js/leaflet.label.js');
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
      for (var i = 0; i < hosts.length; i++) {
        var h = hosts[i];
        bounds.extend(h.location());
        allMarkers_{{mapId}}.push(markerCreate_{{mapId}}(h));
      }

      // Zoom
      map_{{mapId}}.fitBounds(bounds);

      // Build marker cluster
      var markerCluster = L.markerClusterGroup({
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
