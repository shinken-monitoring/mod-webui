%import time
%import re
%import ast
%import json
%from shinken.misc.perfdata import PerfDatas
%now = int(time.time())

%# If got no element, bailout
%if not cpe:
%rebase("layout", title='Invalid element name')

Invalid element name

%else:

%helper = app.helper

%from shinken.macroresolver import MacroResolver

%# Main variables
%cpe_type = cpe.__class__.my_type
%cpe_host = cpe if cpe_type=='host' else cpe.host
%cpe_name = cpe.host_name if cpe_type=='host' else cpe.host.host_name+'/'+cpe.service_description
%cpe_display_name = cpe_host.display_name if cpe_type=='host' else cpe_service.display_name+' on '+cpe_host.display_name
%cpe_metrics = PerfDatas(cpe.perf_data)
%cpe_graphs = helper.get_graphs_for_cpe(cpe_host.address, cpe.customs['_TECH']);
%# Replace MACROS in display name ...
%if hasattr(cpe, 'get_data_for_checks'):
    %cpe_display_name = MacroResolver().resolve_simple_macros_in_string(cpe_display_name, cpe.get_data_for_checks())
%end

%business_rule = False
%if cpe.get_check_command().startswith('bp_rule'):
%business_rule = True
%end

%breadcrumb = [ ['All '+cpe_type.title()+'s', '/'+cpe_type+'s-groups'], [cpe_host.display_name, '/host/'+cpe_host.host_name] ]
%title = cpe_type.title()+' detail: ' + cpe_display_name

%js=['cpe/js/bootstrap-switch.min.js', 'cpe/js/datatables.min.js', 'cpe/js/google-charts.min.js', 'cpe/js/vis.min.js', 'cpe/js/cpe.js']
%css=['cpe/css/bootstrap-switch.min.css', 'cpe/css/datatables.min.css', 'cpe/css/vis.min.css', 'cpe/css/cpe.css']
%rebase("layout", js=js, css=css, breadcrumb=breadcrumb, title=title)

<script>
var cpe = {
    name: '{{cpe_host.address}}',
    state: '{{cpe_host.state}}',
    last_state_change: '{{cpe_host.last_state_change}}'
};
var cpe_name = '{{cpe_name}}';
var cpe_graphs = JSON.parse('{{!json.dumps(cpe_graphs)}}');
var services = [];
%for service in cpe.services:
  services.push({
    name: '{{service.display_name}}',
    state: '{{service.state}}',
    last_state_change: '{{service.last_state_change}}'
  });
  %for metric in PerfDatas(service.perf_data):
    cpe_metrics.push({
      'name': '{{cpe_name}}.{{service.display_name}}.{{metric.name}}',
      'uom': '{{metric.uom}}',
      'value': {{metric.value}}
    })
  %end
%end
</script>

<div id="element" class="row container-fluid">

            <div class="col-md-12 panel panel-default">
	        <div class="panel-heading clearfix">
                    <h2 class="panel-title pull-left">{{cpe_display_name}}</h2>
                    <div class="btn-group pull-right" role="group">
                        %if cpe.customs['_TECH'] != 'wimax':
                        <button id="btn-reboot" type="button" class="btn btn-default">Reboot</button>
                        %if cpe.customs['_TECH'] == 'gpon':
                        <button id="btn-factrestore" type="button" class="btn btn-default">Factory restore</button>
                        <button id="btn-unprovision" type="button" class="btn btn-default">Unprovision</button>
                        <button id="btn-tr069" type="button" class="btn btn-default">Force TR069</button>
                        %end
                    </div>
                </div>
                <div class="panel-body">
                <div class="col-sm-6">
                <dl class="dl-horizontal">
	            <dt>Serial Number</dt>
                    <dd>{{cpe.customs['_SN']}}</dd>
                    %if cpe.customs['_DSN']:
                    <dt>DSN</dt>
                    <dd>{{cpe.customs['_DSN']}}</dd>
                    %end
                    <dt>MAC Address</dt>
                    <dd>{{cpe.customs['_MAC']}}</dd>
                    %if cpe.customs['_MTAMAC']:
                    <dt>MTA MAC</dt>
                    <dd>{{cpe.customs['_MTAMAC']}}</dd>
                    %end
                    <dt>CPE IP Address</dt>
	            <dd>{{cpe.cpe_address}}</dd>
                </dl>
                <dl id="more-info" class="dl-horizontal collapse">
	            <dt>Registration host</dt>
	            <dd>{{cpe.cpe_registration_host}}</dd>
	            <dt>Registration ID</dt>
	            <dd>{{cpe.cpe_registration_id}}</dd>
                    <dt>Registration state</dt>
	            <dd>{{cpe.cpe_registration_state}}</dd>
	            <dt>Registration tags</dt>
	            <dd>{{cpe.cpe_registration_tags}}</dd>
	            <dt>Configuration URL</dt>
	            <dd>{{cpe.cpe_connection_request_url}}</dd>
                    %if cpe.cpe_ipleases:
                    %try:
                    %cpe_ipleases = ast.literal_eval(cpe.cpe_ipleases) or {'foo': 'bar'}
                    %for ip,lease in cpe_ipleases.iteritems():
                    <dt>{{ip}}</dt>
                    <dd>{{lease}}</dd>
                    %end
                    %except Exception, exc:
                    <dt>{{cpe.cpe_ipleases}}</dt>
                    <dd>{{exc}}</dd>
                    %end
                    %else:
                    <dt>IP Leases</dt>
                    <dd>N/A</dd>
                    %end
                </dl>
                <button class="btn btn-default btn-xs center-block" data-toggle="collapse" data-target="#more-info">More</button>
                </div>
                <dl class="col-sm-6 dl-horizontal">
                    <dt>Name</dt>
                    <dd>{{cpe.customs['_CUSTOMER_NAME']}}</dd>
	            <dt>Surname</dt>
	            <dd>{{cpe.customs['_CUSTOMER_SURNAME']}}</dd>
	            <dt>Address</dt>
	            <dd>{{cpe.customs['_CUSTOMER_ADDRESS']}}</dd>
	            <dt>City</dt>
	            <dd>{{cpe.customs['_CUSTOMER_CITY']}}</dd>

                </dl>
            </div>
            </div>
</div>
<div class="row container-fluid">
    <div class="col-md-6 panel panel-default">
        <div class="panel-heading"><h4 class="panel-title">Timeline</h4></div>
        <div class="panel-body">
        <div id="timeline"></div>
        </div>
    </div>
    <div class="col-md-6 panel panel-default">
        <div class="panel-heading"><h4 class="panel-title">Current status</h4></div>
        <div class="panel-body">
                <a href="/all?search={{cpe.host_name}}">
                {{! helper.get_fa_icon_state(obj=cpe, label='title')}}
                </a>
                    <!-- Show our own services  -->
                <div>
                    {{!helper.print_aggregation_tree(helper.get_host_service_aggregation_tree(cpe, app), helper.get_html_id(cpe), show_output=True)}}
                </div>
        </div>
    </div>

</div>
<div class="row container-fluid">
    %for graph in cpe_graphs:
    <div class="col-md-6">
        <div class="panel panel-default">
            <div class="panel-heading"><h4 class="panel-title">{{graph['title']}}</h4></div>
            <div class="panel-body">
                <div id="{{graph['title']}}_dashboard">
                    <div id="{{graph['title']}}_chart" class="dashboard-chart"></div>
                    <div id="{{graph['title']}}_control" class="dashboard-control"></div>
                </div>
            </div>
        </div>
    </div>
    %end
</div>
<div class="row container-fluid">
    %if app.logs_module.is_available():
    <div class="panel panel-default">
        <div class="panel-heading"><h4 class="panel-title">Log History</h4></div>
        <div class="panel-body">
            <table id="inner_history" class="table" data-element='{{cpe.get_full_name()}}'>
                <thead>
                    <tr>
                        <th>State</th>
                        <th>Time</th>
                        <th>Service</th>
                        <th>Message</th>
                    </tr>
                </thead>
            </table>
        </div>
    </div>
    <div class="panel panel-default">
        <div class="panel-heading"><h4 class="panel-title">Event History</h4></div>
        <div class="panel-body">
            <table id="inner_events" class="table" data-element='{{cpe.get_full_name()}}'>
                <thead>
                    <tr>
                        <th>Time</th>
                        <th>Source</th>
                        <th>Message</th>
                    </tr>
                </thead>
            </table>
        </div>
    </div>
    %end
</div>
%#End of the element exist or not case
%end
