%import time
%import re
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
%cpe_service = cpe if cpe_type=='service' else None
%cpe_name = cpe.host_name if cpe_type=='host' else cpe.host.host_name+'/'+cpe.service_description
%cpe_display_name = cpe_host.display_name if cpe_type=='host' else cpe_service.display_name+' on '+cpe_host.display_name
%cpe_metrics = PerfDatas(cpe.perf_data)

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
%if cpe_service:
%breadcrumb += [[cpe_service.display_name, '/service/'+cpe_name] ]
%end

%js=['availability/js/justgage.js', 'availability/js/raphael-2.1.4.min.js', 'cv_host/js/flot/jquery.flot.min.js', 'cv_host/js/flot/jquery.flot.tickrotor.js', 'cv_host/js/flot/jquery.flot.resize.min.js', 'cv_host/js/flot/jquery.flot.pie.min.js', 'cv_host/js/flot/jquery.flot.categories.min.js', 'cv_host/js/flot/jquery.flot.time.min.js', 'cv_host/js/flot/jquery.flot.stack.min.js', 'cv_host/js/flot/jquery.flot.valuelabels.js',  'cpe/js/jquery.color.js', 'cpe/js/bootstrap-switch.min.js', 'cpe/js/custom_views.js', 'cpe/js/google-charts.min.js', 'cpe/js/cpe.js']
%css=['cpe/css/bootstrap-switch.min.css', 'cpe/css/datatables.min.css', 'cv_host/css/cv_host.css', 'cpe/css/cpe.css']
%rebase("layout", js=js, css=css, breadcrumb=breadcrumb, title=title)

<script>
var cpe_name = '{{cpe_host.address}}';
var cpe_metrics = [];
%for metric in cpe_metrics:
cpe_metrics.push({
  'name': '{{cpe_name}}.__HOST__.{{metric.name}}',
  'uom': '{{metric.uom}}',
  'value': {{metric.value}}
})
%end
%for service in cpe.services:
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

   %groups = cpe_service.servicegroups if cpe_service else cpe_host.hostgroups
   %groups = sorted(groups, key=lambda x:x.level)
   %tags = cpe_service.get_service_tags() if cpe_service else cpe_host.get_host_tags()


   <!-- Second row : host/service overview ... -->
    <div class="panel panel-default">
        <div class="panel-heading fitted-header cursor" data-toggle="collapse" data-parent="#Overview" href="#collapseOverview">
            <h4 class="panel-title"><span class="caret"></span>{{cpe_display_name}} {{!helper.get_business_impact_text(cpe.business_impact)}}</h4>
        </div>

        <div id="collapseOverview" class="panel-body panel-collapse collapse in">
            <div class="panel panel-default">
	        <div class="panel-heading"><h2 class="panel-title">CPE Info</h2></div>
            <div class="panel-body">
                <dl class="col-sm-6 dl-horizontal">
                    <dt>CPE alias</dt>
           	    <dd>{{cpe_host.address}}</dd>
            	    <dt>Model</dt>
                    <dd>{{cpe.customs['_CPE_MODEL']}}</dd>
	            <dt>Serial Number</dt>
                    <dd>{{cpe.customs['_SN']}}</dd>
                    <dt>MAC Address</dt>
                    <dd>{{cpe.customs['_MAC']}}</dd>
                    <dt>CPE IP Address</dt>
	            <dd>{{cpe.cpe_address}}</dd>
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
                    <dt>Leased IP {{ip}}</dt>
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
            </div>
        </div>
        <div class="panel panel-default">
            <div class="panel-heading"><h2 class="panel-title">Customer info</h2></div>
            <div class="panel-body">
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
</div>
<div class="row container-fluid">
    <div class="panel panel-default">
        <div class="panel-heading"><h4 class="panel-title">Current status</h4></div>
        <div class="panel-body">
            <div class="col-lg-6">
                %displayed_services=False
                <a href="/all?search={{cpe.host_name}}">
                {{! helper.get_fa_icon_state(obj=cpe, label='title')}}
                </a>
                <!-- Show our father dependencies if we got some -->
                %if cpe.parent_dependencies:
                <h4>Root cause:</h4>
                {{!helper.print_business_rules(app.datamgr.get_business_parents(user, cpe), source_problems=cpe.source_problems)}}
                %end

                <!-- If we are an host and not a problem, show our services -->
                %if cpe_type=='host' and not cpe.is_problem:
                %if cpe.services:
                %displayed_services=True
                <h4>Services:</h4>
                <div class="services-tree">
                  {{!helper.print_aggregation_tree(helper.get_host_service_aggregation_tree(cpe, app), helper.get_html_id(cpe), expanded=False, max_sons=3)}}
                </div>
                %elif not cpe.parent_dependencies:
                <h4>No services!</h4>
                %end
                %end #of the only host part

                <!-- If we are a root problem and got real impacts, show them! -->
                %if cpe.is_problem and cpe.impacts:
                <h4>My impacts:</h4>
                <div class='host-services'>
                    %s = ""
                    <ul>
                        %for svc in helper.get_impacts_sorted(cpe):
                            %s += "<li>"
                            %s += helper.get_fa_icon_state(svc)
                            %s += helper.get_link(svc, short=True)
                            %s += "(" + helper.get_business_impact_text(svc.business_impact) + ")"
                            %s += """ is <span class="font-%s"><strong>%s</strong></span>""" % (svc.state.lower(), svc.state)
                            %s += " since %s" % helper.print_duration(svc.last_state_change, just_duration=True, x_cpes=2)
                            %s += "</li>"
                        %end
                        {{!s}}
                    </ul>
                </div>
                %# end of the 'is problem' if
                %end
            </div>
                %if cpe_type=='host':
                    <div class="col-lg-6">
                        %if not displayed_services:
                        <!-- Show our own services  -->
                        <h4>My services:</h4>
                        <div>
                          {{!helper.print_aggregation_tree(helper.get_host_service_aggregation_tree(cpe, app), helper.get_html_id(cpe))}}
                        </div>
                        %end
                     </div>
                %end
            </div>
        </div>
    </div>


    <div class="panel panel-default">
        <div class="panel-heading"><h4 class="panel-title">CPE actions</h4></div>
        <div class="panel-body">
            <div class="btn-group" role="group">
                <button id="btn-reboot" type="button" class="btn btn-default">Reboot</button>
                %if cpe.customs['_TECH'] == 'gpon':
                <button id="btn-factrestore" type="button" class="btn btn-default">Factory restore</button>
                <button id="btn-unprovision" type="button" class="btn btn-default">Unprovision</button>
                %end
            </div>
        </div>
    </div>

</div>
<div class="row container-fluid">
    %for metric in cpe_metrics:
    <div class="col-md-6">
        <div class="panel panel-default">
            <div class="panel-heading"><h4 class="panel-title">{{metric.name}}</h4></div>
            <div class="panel-body">
                <div id="{{cpe_name}}.__HOST__.{{metric.name}}_dashboard">
                    <div id="{{cpe_name}}.__HOST__.{{metric.name}}_chart" class="dashboard-chart"></div>
                    <div id="{{cpe_name}}.__HOST__.{{metric.name}}_control" class="dashboard-control"></div>
                </div>
            </div>
        </div>
    </div>
    %end
    %for service in cpe.services:
        %service_perf = PerfDatas(service.perf_data)
        %if service_perf:
        <h2>{{service.display_name}}</h2>
        %for metric in service_perf:
        <div class="col-md-6">
            <div class="panel panel-default">
                <div class="panel-heading"><h4 class="panel-title">{{metric.name}}</h4></div>
                <div class="panel-body">
                    <div id="{{cpe_name}}.{{service.display_name}}.{{metric.name}}_dashboard">
                        <div id="{{cpe_name}}.{{service.display_name}}.{{metric.name}}_chart" class="dashboard-chart"></div>
                        <div id="{{cpe_name}}.{{service.display_name}}.{{metric.name}}_control" class="dashboard-control"></div>
                    </div>
                </div>
            </div>
        </div>
        %end
        %end
    %end
    </div>
</div>
<div class="row container-fluid">
    %if app.logs_module.is_available():
    <div class="panel panel-default">
        <div class="panel-heading"><h4 class="panel-title">Log History</h4></div>
        <div class="panel-body">
            <div id="inner_history" data-element='{{cpe.get_full_name()}}'></div>
        </div>
    </div>
    <div class="panel panel-default">
        <div class="panel-heading"><h4 class="panel-title">Event History</h4></div>
        <div class="panel-body">
            <div id="inner_events" data-element='{{cpe.get_full_name()}}'></div>
        </div>
    </div>
    %end
</div>
%#End of the element exist or not case
%end
