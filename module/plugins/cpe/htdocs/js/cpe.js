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
        if(a.timestamp > b.timestamp) {
            return 1;
        }
        if(a.timestamp < b.timestamp) {
            return -1;
        }
        return 0;
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

    if (hostname === service.name) // Is a host
        stateIdToStr = hostStateIdToStr;
    else // Is a service
        stateIdToStr = serviceStateIdToStr;


    var state = "UNKNOWN";  // State is UNKNOWN until we find any ALERT
    var rows = [];
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

/*
 * Draws a timeline for this host state and its service
 */
function drawTimeline(logs) {
    var container = document.getElementById('timeline');
    var items = [];
    var groups = [];
    var now = new Date();
    var min_date = new Date(new Date().setDate(now.getDate() - 7));
    items = items.concat(generateTimelineServiceRows(logs, cpe_name, cpe, min_date, now));
    items.push({
        group: cpe.name,
        content: '',
        start: now,
        className: 'point-'+labelToColor(cpe.state),
        type: 'point'
    });
    groups.push({id: cpe.name, content: cpe.name});
    services.forEach(function(service) {
        items = items.concat(generateTimelineServiceRows(logs, cpe_name, service, min_date, now));
        items.push({
            group: service.name,
            content: '',
            start: now,
            className: 'point-'+labelToColor(service.state),
            type: 'point'
        });
        groups.push({id: service.name, content: service.name});
    });
    var data = new vis.DataSet(items);
    var options = {
        min: min_date,
        max: now,
        stack: false
    };
    var timeline = new vis.Timeline(container,data,groups, options);
}

/*
 * Draws a graphic for every metric in this host using data from Graphite
 */
function drawDashboard() {
    cpe_metrics.forEach(function (metric){
        // Get graphite data in JSON
        $.getJSON('http://'+window.location.hostname+':4288/render/?width=588&height=310&_salt=1487262913.012&target='+metric.name+'&from=-7d&format=json&jsonp=?', function(result) {
            var data = result[0].datapoints;
            data = data.filter(function (e) {
                return e[0] !== null;
            });
            data.forEach(cleanData);
            data.unshift([{label: 'Time', id: 'Time', type: 'datetime'},
                {label: metric.name, id: metric.name, type: 'number'}]);
            var dataTable = google.visualization.arrayToDataTable(data);
            var options = {
                //title: result[0].target,
                legend: { position: 'top' },
                vAxis: {
                    title: metric.uom,
                    minValue: 0,
                    format: 'short'
                },
                height: 400,
                width: 600,
                chartArea: {
                    width: '80%'
                }
            };
            var dashboard = new google.visualization.Dashboard(document.getElementById(metric.name+'_dashboard'));
            var rangeFilter = new google.visualization.ControlWrapper({
                controlType: 'ChartRangeFilter',
                containerId: metric.name+'_control',
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
                'containerId': metric.name+'_chart',
                'options': options
            });
            dashboard.bind(rangeFilter, chart);
            dashboard.draw(dataTable);
        });


    });
}

function getStateIcon(state, state_type, type) {
    if (type == 'SERVICE FLAPPING ALERT' || type == 'HOST FLAPPING ALERT') {
        if (state_type == 'STARTED')    // START FLAPPING
            return "<i class=\"fa fa-exclamation-circle fa-2x font-warning\"></i>"
        // STOP FLAPPING
        return "<i class=\"fa fa-check-circle fa-2x font-ok\"></i>"
    }
    else if (type == 'HOST ALERT') {
        if (state == 0) {   // UP
            return "<i class=\"fa fa-check-circle fa-2x font-ok\"></i>"
        }
        else if (state == 3) {  // UNKNOWN
            return "<i class=\"fa fa-question-circle fa-2x font-unknown\"></i>"
        }
        // CRITICAL
        return "<i class=\"fa fa-times-circle fa-2x font-critical\"></i>"
    }
    else {
        if (state == 0) {   // OK
            return "<i class=\"fa fa-check-circle fa-2x font-ok\"></i>"
        }
        else if (state == 1) {   // WARNING
            return "<i class=\"fa fa-exclamation-circle fa-2x font-warning\"></i>"
        }
        else if (state == 2) {  // CRITICAL
            return "<i class=\"fa fa-times-circle fa-2x font-critical\"></i>"
        }
        // UNKNOWN
        return "<i class=\"fa fa-question-circle fa-2x font-unknown\"></i>"

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
        order: [[0, 'desc']]
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
                return JSON.stringify(data)
              }
            }
        ],
        order: [[0, 'desc']]
    } );
}

/*
 * Function called when the page is loaded and on each page refresh ...
 */
function on_page_refresh() {
    var element = $('#inner_history').data('element');

    // Get host logs
    $.getJSON('http://'+window.location.hostname+':4267/logs/host/'+cpe_name, function(result) {
        drawLogsTable(result);
        drawTimeline(result);
    });

    // Get host events
    $.getJSON('http://'+window.location.hostname+':4267/events/host/'+cpe_name, function(result) {
        drawEventsTable(result);
    });

    google.charts.load('current', {'packages':['corechart', 'controls']});
    google.charts.setOnLoadCallback(drawDashboard);

    // Buttons tooltips
    $('button').tooltip();

    // Buttons as switches
    $('input.switch').bootstrapSwitch();

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


    // Fullscreen management
    $('button[action="fullscreen-request"]').click(function() {
        var elt = $(this).data('element');
        screenfull.request($('#'+elt)[0]);
    });

}


on_page_refresh();
