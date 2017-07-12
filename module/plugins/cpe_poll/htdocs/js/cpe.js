/* Copyright (C) 2009-2015:
   Gabes Jean, naparuba@gmail.com
   Gerhard Lausser, Gerhard.Lausser@consol.de
   Gregory Starck, g.starck@gmail.com
   Hartmut Goebel, h.goebel@goebel-consult.de
   Andreas Karfusehr, andreas@karfusehr.de
   Frederic Mohier, frederic.mohier@gmail.com

   This file is part of Shinken.

   Shinken is free software: you can redistribute it and/or modify
   it under the terms of the GNU Affero General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   Shinken is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU Affero General Public License for more details.

   You should have received a copy of the GNU Affero General Public License
   along with Shinken.  If not, see <http://www.gnu.org/licenses/>.
   */
'use strict';
var timeline;

/*
 * Clean graphite raw data for using with Google Charts
 */
function cleanData(element, index, array) {
    var aux = element[1];
    element[1] = element[0];
    element[0] = new Date(aux * 1000);
}


/*
 * Returns an array with the alert logs of the service/host combination ordered by time
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

function createTimeline(min_date, max_date) {
    var container = document.getElementById('timeline');
    var groups = [];
    groups.push({id: cpe.name, content: cpe.name});
    services.forEach(function(service) {
        groups.push({id: service.name, content: service.name});
    });
    //groups.push({id: 'iplease', content: 'iplease'});
    var options = {
        start: new Date(new Date().setDate(max_date.getDate() - 3)),
        end: max_date,
        min: min_date,
        max: new Date(new Date().setDate(max_date.getDate() + 1)),
        zoomMin: 1000 * 60 * 30, // 30 min
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
            result[0].datapoints.forEach(function (point, point_index) {
                // Check none of the targets is null for this timestamp
                var valid = result.every(function (e) {
                    return e.datapoints[point_index][0] !== null;
                });
                if (!valid)
                    return;
                // Add row to DataTable
                data.addRow();
                data.setCell(nrows, 0, new Date(point[1]*1000));
                result.forEach(function(target, target_index) {
                    data.setCell(nrows, target_index+1, target.datapoints[point_index][0]);
                });
                nrows += 1;
            });
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
            content: lease.data.leased_address,
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
    var min_date = new Date(new Date().setDate(max_date.getDate() - 7));
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
    $('#btn-reboot').click(function (e) {
        launch('/action/REBOOT_HOST/'+cpe_name, 'Host reboot ordered');
    });

    $('#btn-factrestore').click(function (e) {
        launch('/action/RESTORE_FACTORY_HOST/'+cpe_name, 'Factory reset ordered');
    });

    $('#btn-unprovision').click(function (e) {
        launch('/action/UNPROVISION_HOST/'+cpe_name, 'Unprovision ordered');
    });

    $('#btn-tr069').click(function (e) {
        launch('/action/SCHEDULE_FORCED_SVC_CHECK/'+cpe_name+'/tr069/$NOW$', 'Forced TR069 check');
    });
    
    //launch('/action/CPE_POLLING_HOST/'+cpe_name+'/tr069/$NOW$', 'Cpe Polling');
    
    

}

on_page_refresh();
