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

var eltdetail_logs=false;

google.charts.load('current', {'packages':['corechart', 'controls','timeline']});
google.charts.setOnLoadCallback(drawDashboard);
drawTimeline();

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
function getServiceAlerts(hostname, service_name, min_date) {
    if (logs === null)
        return null;
    if (service_name == "host") 
        alerts = logs.filter(function(e){
            return new Date(e.timestamp * 1000) >= min_date && e.type === "HOST ALERT" && e.host === hostname;
        });
    else
        alerts = logs.filter(function(e){
            return new Date(e.timestamp * 1000) >= min_date && e.type === "SERVICE ALERT" && e.host === hostname && e.service === service_name;
        });

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
 * Translate an state id as it's stored in mongo-logs to the actual state name
 */
function stateIdToStr(state_id) {
    ids = ['OK','WARNING','CRITICAL','UNKNOWN'];
    return ids[state_id];
}

/*
 * Iterates every SERVICE/HOST ALERT since min_date to generate rows for a timeline for this service/host state
 */
function generateTimelineServiceRows(hostname, service, min_date, max_date) {
    alerts = getServiceAlerts(hostname, service.name, min_date);
    start_time = min_date;
    if(alerts === null || alerts.lenght === 0) {  // No logged SERVICE/HOST alerts found. Use current state data.
        return [{
            group: service.name,
            content: '',
            start: new Date(service.last_state_change * 1000),
            end: max_date,
            className: labelToColor(service.state)
        }];
    }

    state = "UNKNOWN";  // State is UNKNOWN until we find any ALERT
    rows = [];
    alerts.forEach(function(element, index, array) {
        end_time = new Date(element.timestamp * 1000);
        new_state = stateIdToStr(element.state);
        if (state !== new_state) {
            rows.push({
                group: service.name,
                content: '',
                start: start_time,
                end: end_time,
                className: labelToColor(state)
            });
            start_time = end_time;
            state = new_state;
        }
    });
    rows.push({
        group: service.name,
        content: '',
        start: start_time,
        end: max_date,
        className: labelToColor(state)
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
    if (label == 'CRITICAL' || label == 'UNREACHABLE')
        return 'red';
    return 'blue';
}

/*
 * Draws a timeline for this host state and its service
 */
function drawTimeline() {
    var container = document.getElementById('timeline');
    var items = [];
    var groups = [];
    var now = new Date();
    var min_date = new Date(new Date().setDate(now.getDate() - 7));
    items = items.concat(generateTimelineServiceRows(cpe_name, cpe, min_date, now));
    groups.push({id: cpe.name, content: cpe.name});
    services.forEach(function(service) {
        items = items.concat(generateTimelineServiceRows(cpe_name, service, min_date, now));
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
                //explorer: { 
                //    actions: ['dragToZoom', 'rightClickToReset'],
                //    axis: 'horizontal'
                //}
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


/*
 * Function called when the page is loaded and on each page refresh ...
 */
function on_page_refresh() {
    var element = $('#inner_history').data('element');

    // Log History
    $("#inner_history").html('<i class="fa fa-spinner fa-spin fa-3x"></i> Loading history data ...');
    $("#inner_history").load('/logs/inner/'+encodeURIComponent(element), function(response, status, xhr) {
        if (status == "error") {
            $('#inner_history').html('<div class="alert alert-danger">Sorry but there was an error: ' + xhr.status + ' ' + xhr.statusText+'</div>');
        }
    });

    // Event History
    $("#inner_events").html('<i class="fa fa-spinner fa-spin fa-3x"></i> Loading history data ...');
    $("#inner_events").load('/events/inner/'+encodeURIComponent(element), function(response, status, xhr) {
        if (status == "error") {
            $('#events_history').html('<div class="alert alert-danger">Sorry but there was an error: ' + xhr.status + ' ' + xhr.statusText+'</div>');
        }
    });

    // Buttons tooltips
    $('button').tooltip();

    // Buttons as switches
    $('input.switch').bootstrapSwitch();

    // Elements popover
    //   $('[data-toggle="popover"]').popover();

    $('[data-toggle="popover"]').popover({
        trigger: "hover",
        container: "body",
        placement: 'bottom',
        toggle : "popover",

        template: '<div class="popover popover-large"><div class="arrow"></div><div class="popover-inner"><h3 class="popover-title"></h3><div class="popover-content"><p></p></div></div></div>'
    });


    $('#btn-reboot').click(function (e) {
        launch('/action/REBOOT_HOST/'+cpe_name+'/', 'Host reboot ordered');
    });

    $('#btn-factrestore').click(function (e) {
        launch('/action/RESTORE_FACTORY_HOST/'+cpe_name+'/', 'Factory reset ordered');
    });

    $('#btn-unprovision').click(function (e) {
        launch('/action/UNPROVISION_HOST/'+cpe_name+'/', 'Unprovision ordered');
    });


    /*
     * Impacts view
     */
    // When toggle list is activated ...
    $('#impacts a.toggle-list').on('click', function () {
        var state = $(this).data('state');
        var target = $(this).data('target');

        if (state=='expanded') {
            $('#impacts ul[name="'+target+'"]').hide();
            $(this).data('state', 'collapsed');
            $(this).children('i').removeClass('fa-minus').addClass('fa-plus');
        } else {
            $('#impacts ul[name="'+target+'"]').show();
            $(this).data('state', 'expanded');
            $(this).children('i').removeClass('fa-plus').addClass('fa-minus');
        }
    });


    // Fullscreen management
    $('button[action="fullscreen-request"]').click(function() {
        var elt = $(this).data('element');
        screenfull.request($('#'+elt)[0]);
    });


    /*
     * Timeline
     */
    $('a[data-toggle="tab"][href="#timeline"]').on('shown.bs.tab', function (e) {
        // First we get the full name of the object from div data
        var element = $('#inner_timeline').data('element');
        // Get timeline tab content ...
        $('#inner_timeline').load('/timeline/inner/'+encodeURIComponent(element));

    });

}


on_page_refresh();
