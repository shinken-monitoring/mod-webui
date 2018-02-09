/* Copyright (C) 2009-2015:

   */

'use strict';
var timeline;


function copyToClipboard(elem) {
	  // create hidden text element, if it doesn't already exist
    var targetId = "_hiddenCopyText_";
    var isInput = elem.tagName === "INPUT" || elem.tagName === "TEXTAREA";
    var origSelectionStart, origSelectionEnd;
    if (isInput) {
        // can just use the original source element for the selection and copy
        target = elem;
        origSelectionStart = elem.selectionStart;
        origSelectionEnd = elem.selectionEnd;
    } else {
        // must use a temporary form element for the selection and copy
        target = document.getElementById(targetId);
        if (!target) {
            var target = document.createElement("textarea");
            target.style.position = "absolute";
            target.style.left = "-9999px";
            target.style.top = "0";
            target.id = targetId;
            document.body.appendChild(target);
        }
        target.textContent = elem.textContent;
    }

    var currentFocus = document.activeElement;
    target.focus();
    target.setSelectionRange(0, target.value.length);

    var succeed;
    try {
    	  succeed = document.execCommand("copy");
    } catch(e) {
        succeed = false;
    }

    if (currentFocus && typeof currentFocus.focus === "function") {
        currentFocus.focus();
    }

    if (isInput) {
        elem.setSelectionRange(origSelectionStart, origSelectionEnd);
    } else {
        target.textContent = "";
    }
    return succeed;
}

var Krill = {

  // label=valUOM;warn;crit;min;max
  PERFDATA_PATTERN: /([^=]+)=([\d\.\-]+)([\w%]*);?([\d\.\-:~@]+)?;?([\d\.\-:~@]+)?;?([\d\.\-]+)?;?([\d\.\-]+)?\s*/,

  parsePerfdata: function(perfdata) {
    var parsed = [];

    if (!perfdata)
        return [];

    // Clean up perfdata
    perfdata = perfdata.replace('/\s*=\s*/', '=');

    var perfdataMatches = perfdata.match(new RegExp(this.PERFDATA_PATTERN.source, "g"));

    // Check for empty perfdata
    if (perfdataMatches == null)
        return [];

    for (var i = 0; i < perfdataMatches.length; i++) {

      var tmpPerfdataMatches = perfdataMatches[i].match(this.PERFDATA_PATTERN);

      parsed.push([
        tmpPerfdataMatches[1], // label
        tmpPerfdataMatches[2], // value
        tmpPerfdataMatches[3], // UOM
        tmpPerfdataMatches[4], // warn
        tmpPerfdataMatches[5], // crit
        tmpPerfdataMatches[6], // min
        tmpPerfdataMatches[7], // max
      ]);

    }
    return parsed
  }
}

//$.fn.dataTable.ext.errMode = 'none';

function derive(value, value_last, check_time, check_time_last){
    var t_delta = check_time - check_time_last;
		var d_delta = 0;

    if (t_delta == 0) {
			return 0;
		}

    if (value < value_last) {
        d_delta = 4294967295 - value_last + value;
    } else {
        d_delta = value - value_last;
		}

    var value = d_delta / t_delta;

    return value;
}

var ICON_OK       = '<span class="fa-stack" title="service is OK"><i class="fa fa-circle fa-stack-2x font-ok"></i><i class="fa fa-arrow-up fa-stack-1x fa-inverse"></i></span>';
var ICON_WARNING  = '<span class="fa-stack" title="service is WARNING"><i class="fa fa-circle fa-stack-2x font-warning"></i><i class="fa fa-exclamation fa-stack-1x fa-inverse"></i></span>';
var ICON_CRITICAL = '<span class="fa-stack" "=""><i class="fa fa-circle fa-stack-2x font-critical"></i><i class="fa fa-arrow-down fa-stack-1x fa-inverse"></i></span>';
var ICON_UNKONWN  = '<span class="fa-stack" title="service is UNKNOWN"><i class="fa fa-circle fa-stack-2x font-unknown"></i><i class="fa fa-question fa-stack-1x fa-inverse"></i></span>';

var COLOR_OK        = '#8BC34A';
var COLOR_WARNING   = '#FAA732';
var COLOR_CRITICAL  = '#FF7043';
var COLOR_UNKONWN   = '#49AFCD';

function getHTMLState(val) {
	if(val == 0) {
		return ICON_OK;
	} else if ( val == 1 ) {
		return ICON_WARNING;
	} else if ( val == 2 ) {
		return ICON_CRITICAL;
	} else if ( val == 3 ) {
		return ICON_UNKONWN;
	}

}

function getColorState(val) {
	if(val == 0) {
		return COLOR_OK;
	} else if ( val == 1 ) {
		return COLOR_WARNING;
	} else if ( val == 2 ) {
		return COLOR_CRITICAL;
	} else if ( val == 3 ) {
		return COLOR_UNKONWN;
	}

}



/*
 * Clean graphite raw data for using with Google Charts
 */
function cleanData(element, index, array) {
    var aux = element[1];
    element[1] = element[0];
    element[0] = new Date(aux * 1000);
}


/*
 * Returns an array with the alert logs of the ice/host combination ordered by time
 */
function getServiceAlerts(logs, hostname, service_name, min_date) {
    if (logs === null)
        return null;
    var alerts;
    if (service_name == hostname) // Is a host
        alerts = logs.filter(function(e){
            return new Date(e.timestamp * 1000) >= min_date && e.type === "HOST ALERT" && e.host === hostname;
        });
    else // Is a service
        alerts = logs.filter(function(e){
            return new Date(e.timestamp * 1000) >= min_date && e.type === "SERVICE ALERT" && e.host === hostname && e.service === service_name;
        });
    // Order by date
    alerts.sort(function(a, b){
        return a.timestamp - b.timestamp;
    });

    return alerts;
}

/*
 * Translate a service state id as it's stored in mongo-logs to the actual state name
 */
function serviceStateIdToStr(state_id) {
    var ids = ['OK','WARNING','CRITICAL','UNKNOWN'];
    return ids[state_id];
}

/*
 * Translate a host state id as it's stored in mongo-logs to the actual state name
 */
function hostStateIdToStr(state_id) {
    var ids = ['UP','DOWN','UNREACHABLE','UNKNOWN'];
    return ids[state_id];
}

/*
 * Iterates every SERVICE/HOST ALERT since min_date to generate rows for a timeline for this service/host state
 */
function generateTimelineServiceRows(logs, hostname, service, min_date, max_date) {
    var alerts = getServiceAlerts(logs, hostname, service.name, min_date);
    var start_time = min_date;
    if(alerts === null || alerts.length === 0) {  // No logged SERVICE/HOST alerts found. Use current state data.
        return [{
            group: service.name,
            content: '',
            start: new Date(service.last_state_change * 1000),
            end: max_date,
            className: labelToColor(service.state),
            type: 'background'
        }];
    }
    var stateIdToStr;
    if (hostname === service.name) // Is a host
        stateIdToStr = hostStateIdToStr;
    else // Is a service
        stateIdToStr = serviceStateIdToStr;


    var state = "UNKNOWN";  // State is UNKNOWN until we find any ALERT
    var rows = [];
    var end_time;
    var new_state;
    alerts.forEach(function(element, index, array) {
        end_time = new Date(element.timestamp * 1000);
        new_state = stateIdToStr(element.state);
        if (state !== new_state) { // If we find a new state, add a row for the last state
            rows.push({
                group: service.name,
                content: '',
                start: start_time,
                end: end_time,
                className: labelToColor(state),
                type: 'background'
            });
            start_time = end_time;
            state = new_state;
        }
    });
    rows.push({ // Add a row for the current state in this host
        group: service.name,
        content: '',
        start: start_time,
        end: max_date,
        className: labelToColor(state),
        type: 'background'
    });
    return rows;
}

/*
 * Get the color associated with this state for styling the timeline
 */
function labelToColor(label) {
    if (label == 'UP' || label == 'OK')
        return 'green';
    if (label == 'WARNING')
        return 'orange';
    if (label == 'CRITICAL' || label == 'UNREACHABLE' || label == 'DOWN')
        return 'red';
    return 'blue'; // UNKNOWN
}



//@jgomez
function createTimeline(min_date, max_date) {
    var container = document.getElementById('timeline');
    var groups = [];
    groups.push({id: cpe.name, content: '<span id="status2">'+getHTMLState(cpe.state_id)+'</span>' + '<a href="'+cpe.url+'">'+cpe.name+'</a>'});
    services.forEach(function(service) {
        groups.push({id: service.name, content: getHTMLState(service.state_id) + '<a href="'+service.url+'">'+service.name+'</a>'});
    });
    //groups.push({id: 'iplease', content: 'iplease'});
    var options = {
        start: new Date(new Date().setDate(max_date.getDate() - 1)),
        end: max_date,
        min: min_date,
        max: new Date(new Date().setDate(max_date.getDate() /* + 1 */ )), //@jgomez
        zoomMin: 1000 * 60 * 60, // 30 min
        stack: false
    };
    timeline = new vis.Timeline(container,[],groups, options);
}

/*
 * Draws a timeline for this host state and its service. Also adds a point item
 * with the current state
 */
function drawTimeline(logs, min_date, max_date) {
    var items = [];
    var groups = [];
    // Current status
    items = items.concat(generateTimelineServiceRows(logs, cpe_name, cpe, min_date, max_date));
    items.push({
        group: cpe.name,
        content: '',
        start: max_date,
        className: 'point-'+labelToColor(cpe.state),
        type: 'point'
    });
    services.forEach(function(service) {
        items = items.concat(generateTimelineServiceRows(logs, cpe_name, service, min_date, max_date));
        items.push({
            group: service.name,
            content: '',
            start: max_date,
            className: 'point-'+labelToColor(service.state),
            type: 'point'
        });
    });
    timeline.itemsData.add(items);
}

/*
 * Draws a graphic for every metric in this host using data from Graphite
 */
function drawDashboard() {
    cpe_graphs.forEach(function (graph){
        var graphite_uri='http://'+window.location.hostname+':4288/render/?';
        graph.metrics.forEach(function (metric){
            graphite_uri+='target='+metric.graphite_name+'&';
        });
        graphite_uri+='from=-7d&format=json&jsonp=?';

        $.getJSON(graphite_uri, function(result) {
            var data = new google.visualization.DataTable();
            data.addColumn('datetime', 'Time');
            graph.metrics.forEach(function (metric) {
                data.addColumn('number', metric.name);
            });
            var nrows = 0;

            if (typeof (result[0]) != "undefined" && typeof (result[0].datapoints) != "undefined") {
	            result[0].datapoints.forEach(function (point, point_index) {
	                // Check none of the targets is null for this timestamp
	                var valid = result.every(function (e) {
	                    return e.datapoints[point_index] != "undefined"; //0
	                });

	                if (!valid)
	                    return;
	                // Add row to DataTable
	                data.addRow();
	                data.setCell(nrows, 0, new Date(point[1]*1000));
	                result.forEach(function(target, target_index) {
											if  (typeof target.datapoints[point_index] !== "undefined") {
	                    	data.setCell(nrows, target_index+1, target.datapoints[point_index][0]);
										  }
	                });
	                nrows += 1;
	            });
					  }
            var options = {
                //title: result[0].target,
                legend: { position: 'top' },
                vAxis: {
                    title: graph.uom,
                    minValue: 0,
                    format: 'short'
                },
                height: 400,
                width: 600,
                chartArea: {
                    width: '80%'
                }
            };
            var dashboard = new google.visualization.Dashboard(document.getElementById(graph.title+'_dashboard'));
            var rangeFilter = new google.visualization.ControlWrapper({
                controlType: 'ChartRangeFilter',
                containerId: graph.title+'_control',
                options: {
                    filterColumnLabel: 'Time',
                    ui: {
                        chartOptions: {
                            height: 50,
                            width: 600,
                            chartArea: {
                                width: '80%'
                            }
                        }
                    }
                }
            });

            var chart = new google.visualization.ChartWrapper({
                'chartType': 'LineChart',
                'containerId': graph.title+'_chart',
                'options': options
            });
            dashboard.bind(rangeFilter, chart);
            dashboard.draw(data);
        });
    });

}

function getStateIcon(state, state_type, type) {
    var ICON_WARNING = "<i class=\"fa fa-exclamation-circle fa-2x font-warning\"></i>";
    var ICON_OK = "<i class=\"fa fa-check-circle fa-2x font-ok\"></i>";
    var ICON_UNKNOWN = "<i class=\"fa fa-question-circle fa-2x font-unknown\"></i>";
    var ICON_CRITICAL ="<i class=\"fa fa-times-circle fa-2x font-critical\"></i>";

    if (type == 'SERVICE FLAPPING ALERT' || type == 'HOST FLAPPING ALERT') {
        if (state_type == 'STARTED')    // START FLAPPING
            return ICON_WARNING;
        // STOP FLAPPING
        return ICON_OK;
    }
    else if (type == 'HOST ALERT') {
        if (state === 0) {   // UP
            return ICON_OK;
        }
        else if (state == 3) {  // UNKNOWN
            return ICON_UNKNOWN;
        }
        // DOWN / UNREACHABLE
        return ICON_CRITICAL;
    }
    else {
        if (state === 0) {   // OK
            return ICON_OK;
        }
        else if (state == 1) {   // WARNING
            return ICON_WARNING;
        }
        else if (state == 2) {  // CRITICAL
            return ICON_CRITICAL;
        }
        // UNKNOWN
        return ICON_UNKNOWN;

    }
}

function drawLogsTable(logs) {
    $('#inner_history').DataTable( {
        data: logs,
        columns: [
            { data: 'state',
              render: function ( data, type, row ) {
                return getStateIcon(data, row.state_type, row.type);
              }
            },
            { data: 'timestamp',
              render: function ( data, type, row ) {
                var date = new Date(data * 1000);
                return date.toLocaleString();
              }
            },
            { data: 'service' },
            { data: 'message' }
        ],
        order: [[0, 'desc']],
        responsive: true
    } );
}

function drawEventsTable(events) {
    $('#inner_events').DataTable( {
        data: events,
        columns: [
            { data: 'timestamp',
              render: function ( data, type, row ) {
                var date = new Date(data * 1000);
                return date.toLocaleString();
              }
            },
            { data: 'source' },
            { data: 'data',
              render: function ( data, type, row ) {
                return JSON.stringify(data);
              }
            }
        ],
        order: [[0, 'desc']],
        responsive: true
    } );
}

/*
 * Check this CPE's hostevents for DHCP leases and draw them in the timeline
 */
function addLeasesTimeline(events, min_date) {
    if(!events) {return}

    events = events.filter(function(e) { // Show only ipleases
        return e.source == 'iplease'
    });
    events.forEach(function(e) {
        e.data.ends = new Date(e.data.ends.replace("/", " ")); // Date is in format YYYY-MM-DD/hh:mm:ss
        e.data.starts = new Date(e.data.starts.replace("/", " ")); // Date is in format YYYY-MM-DD/hh:mm:ss
    });
    events = events.filter(function(e) { // Show only ipleases valid in the last X days
        return e.data.ends > min_date;  // min_date is a Date object
    });
    events.sort(function(a,b) {
        if (a.data.leased_address > b.data.leased_address)
            return 1;
        if (a.data.leased_address < b.data.leased_address)
            return -1;
        return a.data.starts - b.data.starts;
    });

    var leases = [];
    events.forEach(function(lease, index, array){
        var event_end;
        if (index + 1 >= array.length || array[index + 1].data.leased_address != lease.data.leased_address && array[index + 1].data.starts < lease.data.ends)
            event_end = lease.data.ends;
        else
            event_end = array[index + 1].data.starts;
        leases.push({
            start: lease.data.starts,
            end: event_end,
            content: '<a href="http://'+ proxy_prefix + lease.data.leased_address+'.'+proxy_sufix+'" target="_blank">'+lease.data.leased_address+'</a>',
            type: 'range',
            group: 'dhcp',
            subgroup: lease.data.leased_address    // To avoid overlapping. See https://github.com/almende/vis/issues/620
        });
    });

    timeline.itemsData.add(leases);

}

/*
 * Function called when the page is loaded and on each page refresh ...
 */
function on_page_refresh() {
    var max_date = new Date();
    var min_date = new Date(new Date().setDate(max_date.getDate() - 15));
    createTimeline(min_date, max_date);
    // Get host logs
    $.getJSON(window.location.origin + '/logs/host/'+cpe_name, function(result) {
        drawLogsTable(result);
        drawTimeline(result, min_date, max_date);
    });

    // Get host events
    $.getJSON(window.location.origin+'/events/host/'+cpe_name, function(result) {
        drawEventsTable(result);
        addLeasesTimeline(result, min_date);
    });

    google.charts.load('current', {'packages':['corechart', 'controls']});
    google.charts.setOnLoadCallback(drawDashboard);

    // Buttons tooltips
    //$('button').tooltip();

    // Buttons as switches
    //$('input.switch').bootstrapSwitch();

    // CPE Action buttons

    $('#btn-reboot').click(function(e) {
        $.getJSON('/cpe_poll/reboot/'+cpe_name, function(data){
		raise_message_ok('Host reboot ordered, result: ' + data.result)
	});
    });

    $('#btn-factrestore').click(function(e) {
      	$.getJSON('/cpe_poll/factory/'+cpe_name, function(data){
		raise_message_ok('Factory reset ordered result: ' + data.result)
	});
    });

    $('#btn-unprovision').click(function(e) {
      	$.getJSON('/cpe_poll/unprovision/'+cpe_name, function(data){
		raise_message_ok('Unprovision ordered, result: ' + data.result)
	});
    });

    $('#btn-tr069').click(function (e) {
        launch('/action/SCHEDULE_FORCED_SVC_CHECK/'+cpe_name+'/tr069/$NOW$', 'Forced TR069 check');
    });





}







function generateTable(rowsData, titles, type, _class) {
    var $table = $("<table>").addClass(_class);
    var $tbody = $("<tbody>").appendTo($table);


    if (type == 2) {//vertical table
        if (rowsData.length !== titles.length) {
            console.error('rows and data rows count doesent match');
            return false;
        }
        titles.forEach(function (title, index) {
            var $tr = $("<tr>");
            $("<th>").html(title).appendTo($tr);
            var rows = rowsData[index];
            rows.forEach(function (html) {
                $td = $("<td>");
                if( title.indexOf("freq") < 0) {
                  //$td.css('background-color', '#5bb75b')
                  $td.css('background-color', '#49afcd')
                  $td.css('color', 'white');
                } else {
                  html = html / 1000000;
                }
                $td.css('width', '42px')
                $td.css('height', '42px')
                $td.css('vertical-align', 'middle')
                $td.css('text-align', 'center')
                $td.css('font-family', 'Courier')

                $td.html(html).appendTo($tr);
            });
            $tr.appendTo($tbody);
        });

    } else if (type == 1) {//horsantal table
        var valid = true;
        rowsData.forEach(function (row) {
            if (!row) {
                valid = false;
                return;
            }

            if (row.length !== titles.length) {
                valid = false;
                return;
            }
        });

        if (!valid) {
            console.error('rows and data rows count doesent match');
            //return false;
        }

        var $tr = $("<tr>");
        titles.forEach(function (title, index) {
            $("<th>").html(title).appendTo($tr);
        });
        $tr.appendTo($tbody);

        rowsData.forEach(function (row, index) {
            var $tr = $("<tr>");
            row.forEach(function (html) {
                $("<td>").html(html).appendTo($tr);
            });
            $tr.appendTo($tbody);
        });
      } else if (type == 3) {//horsantal table

          try {
            rowsData = transpose(rowsData);
          } catch(err) {
            console.log(rowsData)
          }

          var $tr = $("<tr>");
          titles.forEach(function (title, index) {
              $("<th>").html(title).appendTo($tr);
          });
          $tr.appendTo($tbody);

          rowsData.forEach(function (row, index) {
              var $tr = $("<tr>");
              row.forEach(function (html) {
                  $("<td>").html(html).appendTo($tr);
              });
              $tr.appendTo($tbody);
          });
      }

    return $table;
}


function transpose(matrix) {
    return zeroFill(getMatrixWidth(matrix)).map(function(r, i) {
        return zeroFill(matrix.length).map(function(c, j) {
            return matrix[j][i];
        });
    });
}

function getMatrixWidth(matrix) {
    return matrix.reduce(function (result, row) {
        return Math.max(result, row.length);
    }, 0);
}

function zeroFill(n) {
    return new Array(n+1).join('0').split('').map(Number);
}

function generatePerfTable(titles, rows) {
  var tb;
  try {
    tb = generateTable(rows, titles, 3, 'table table-bordered');
  } catch (e) {
    tb = Array()
  }
  return tb;
}

function parsePerfdataTable(metric) {
  var tmp = {};
  var max = 0
  for (var i = 0; i < metric.length; i++) {

    var regex = /([a-z]+)(\d+)/g;
    var m = regex.exec(metric[i][0])
    if(m) {
      var key = m[1]
      var index = m[2] - 1
      var value = metric[i][1]

      max = Math.max(max, index)

      if(typeof tmp[key] === "undefined") {
        tmp[key] = []
      }

      while(tmp[key].length < max) {
        tmp[key].push('')
      }

      //console.log( max + ":" + key + "[" + index + "]=" + value )
      tmp[key][index] = value
    }
  }

  return tmp
}

on_page_refresh();
