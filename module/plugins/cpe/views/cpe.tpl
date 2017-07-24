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
%cpe_graphs = helper.get_graphs_for_cpe(cpe_host.host_name, cpe.customs.get('_TECH'));

%reboot_available = cpe.cpe_registration_host and cpe.cpe_registration_id
%tr069_available = cpe.cpe_connection_request_url

%# Replace MACROS in display name ...
%if hasattr(cpe, 'get_data_for_checks'):
    %cpe_display_name = MacroResolver().resolve_simple_macros_in_string(cpe_display_name, cpe.get_data_for_checks())
%end

%business_rule = False
%if cpe.get_check_command().startswith('bp_rule'):
%business_rule = True
%end

%breadcrumb = [ ['All '+cpe_type.title()+'s', '/'+cpe_type+'s-groups'], [cpe_host.display_name, '/host/'+cpe_host.host_name] ]
%breadcrumb = []

%title = cpe_type.title()+' detail: ' + cpe_display_name

%js=['cpe/js/bootstrap-switch.min.js', 'cpe/js/datatables.min.js', 'cpe/js/google-charts.min.js', 'cpe/js/vis.min.js', 'cpe/js/cpe.js']
%css=['cpe/css/bootstrap-switch.min.css', 'cpe/css/datatables.min.css', 'cpe/css/vis.min.css', 'cpe/css/cpe.css']
%rebase("layout", js=js, css=css, breadcrumb=breadcrumb, title=title)

<!--<script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>-->

<script src="http://www.flotcharts.org/flot/jquery.flot.js" charset="utf-8"></script>
<script src="/static/cpe/js/plots.js" charset="utf-8"></script>

<script>
%if app.proxy_sufix:
var proxy_sufix = "{{app.proxy_sufix}}";
%else:
var proxy_sufix = "";
%end

%if str(cpe.customs.get('_SN', 'ffffffff').upper())[0:8].decode("hex") ==  'HWTC':
var proxy_prefix = "h";
%else:
var proxy_prefix = "";
%end



var cpe = {
    name: '{{cpe_host.host_name}}',
    state: '{{cpe_host.state}}',
    state_id: '{{cpe_host.state_id}}',
    last_state_change: '{{cpe_host.last_state_change}}',
    url: '/host/{{cpe_host.host_name}}'
};

var cpe_name = '{{cpe_name}}';
var cpe_graphs = JSON.parse('{{!json.dumps(cpe_graphs)}}');
var services = [];
%for service in cpe.services:
  services.push({
    name: '{{service.display_name}}',
    state: '{{service.state}}',
    state_id: '{{service.state_id}}',
    last_state_change: '{{service.last_state_change}}',
    url: '/service/{{cpe_host.host_name}}/{{service.display_name}}'
  });
%end

function notify(msg) {
  // Let's check if the browser supports notifications
  if (!("Notification" in window)) {
    alert("This browser does not support desktop notification");
  }

  // Let's check whether notification permissions have already been granted
  else if (Notification.permission === "granted") {
    // If it's okay let's create a notification
    var notification = new Notification(msg);
  }

  // Otherwise, we need to ask the user for permission
  else if (Notification.permission !== 'denied') {
    Notification.requestPermission(function (permission) {
      if (permission === "granted") {
        var notification = new Notification(msg);
      }
    });
  }
};

function poll_cpe() {
  $.getJSON('/cpe_poll/{{cpe_host.host_name}}', function(data){

        if(data && data.status) {
            data.status = data.status.replace(/\W+/g, '').toUpperCase()
            $('#registration_state').html(data.status)
            $('#upbw').html(humanBytes(data.upbw))
            $('#dnbw').html(humanBytes(data.dnbw))
            $('#dnrx').html(data.dnrx)
            $('#uprx').html(data.uprx)

            d1 = Date.parse(data.uptime)
            d2 = new Date()
            delta = (d2 - d1) / 1000

            $('#uptime').html(toHHMMSS(delta))

            $('#registration_state').html('<span>'+data.status+'</span>');

            if(data.status == "UP" || data.status == "WORKING") {
                $('#registration_state').css('color','#8BC34A');
		            $('#status2').html(getHTMLState(0))
            } else if (data.status == "DOWN")  {
                $('#registration_state').css('color','#FF7043');
		            $('#status2').html(getHTMLState(2))
            } else {
                $('#registration_state').css('color','#FAA732');
                $('#status2').html(getHTMLState(1))
            }

            line = ""
            $.each(data.service_ports, function(k,v){
               line = line + v.user_vlan + '/'+ v.service_vlan + " "
            })

            $('#service_ports').html(line)


            if (data.status && data.status != cpe.state) {
                //notify("{{cpe_host.host_name}} is " + data.status);
                cpe.state = data.status;
            }

            updateGraphs(data)

        }

    });
}

var realtimeTimer = window.setInterval(function(){
  poll_cpe()
}, 5000);





</script>
<style>
.panel-default {
    padding-left:  0px !important;
    padding-right: 0px !important;
}

.content{
    padding-top: 1em;
}

.vis-group {
     /*height: 20px !important; */
}

.font-fixed {
  font-family: "Courier New", Courier, "Lucida Sans Typewriter", "Lucida Typewriter", monospace;
}

.right {
  text-align: right;
}

</style>

<div class="row">
    <div class="col-md-8">
        <div style="float: left; padding: 10px; border-right: 2px solid black; margin-right: 10px">
            <div class="right" style="font-size: 22px"><a href="/host/{{ cpe.host_name }}">{{ cpe.host_name }}</a></div>
            <div class="right" style="font-size: 10px; ">{{cpe.customs.get('_CPE_MODEL')}}</div>
            <div class="font-fixed" style="font-size: 12px; text-align: right; color: #9E9E9E;">{{ cpe.customs.get('_SN', '').upper() }}{{ cpe.customs.get('_MAC', '').upper() }}</div>

        </div>
        <div>
            <div style="font-size: 22px">{{ cpe.customs.get('_CUSTOMER_NAME')}} {{cpe.customs.get('_CUSTOMER_SURNAME')}}</div>
            <div style="font-size: 18px; color: #666;">
                <!--
                                <a href="https://www.google.es/maps?q={{ cpe.customs.get('_CUSTOMER_ADDRESS')}} {{cpe.customs.get('_CUSTOMER_CITY')}}" target="_blank">{{cpe.customs.get('_CUSTOMER_ADDRESS')}} {{cpe.customs.get('_CUSTOMER_CITY')}}</a>
                -->
                <a href="/host/{{ cpe.cpe_registration_host }}" data-type="host">{{ cpe.cpe_registration_host }}</a>
                <span>/</span>
                <a href="/all?search=type:host {{cpe.cpe_registration_host}}">{{ cpe.cpe_registration_id }}</a>
                <span>:</span>
                <span id="registration_state"> <i class="fa fa-spinner fa-spin"></i> <!--{{cpe.cpe_registration_state}}--></span>
            </div>
            <div style="font-size: 18px; color: #999;">
                %if cpe.customs.get('_ACCESS') == '1':
                <span style="color: #64DD17"><i class="fa fa-globe"></i><!--Internet access--></span>
                %else:
                <span style="color: #E65100"><i class="fa fa-globe text-danger"></i><!--Disabled Internet access--></span>
                %end
                <span style="color: #9E9E9E"><i class="fa fa-arrow-circle-o-down"></i>{{cpe.customs.get('_DOWNSTREAM')}}</span>
                <span style="color: #9E9E9E"><i class="fa fa-arrow-circle-o-up"></i>{{cpe.customs.get('_UPSTREAM')}}</span>

                %if cpe.customs.get('_VOICE1_CLI'):
                 | <span style="color: #607D8B">1<i class="fa fa-phone" aria-hidden="true"></i> {{ cpe.customs.get('_VOICE1_CLI') }}</span>
                %end
                %if cpe.customs.get('_VOICE2_CLI'):
                 | <span style="color: #607D8B">2<i class="fa fa-phone" aria-hidden="true"></i> {{ cpe.customs.get('_VOICE2_CLI') }}</span>
                %end
            </div>


        </div>
    </div>


    <div class="col-md-4">
        <div class="btn-group pull-right" role="group">
            %if cpe.customs.get('_TECH') == 'wimax':
            <button id="btn-update" type="button" class="btn btn-default">Update</button>
            <button id="btn-reboot" type="button" class="btn btn-default" {{'disabled' if not reboot_available else ''}} >Reboot</button>
            <button id="btn-backup" type="button" class="btn btn-default">Backup</button>
            %end
            %if cpe.customs.get('_TECH') == 'gpon':
            <button id="btn-reboot" type="button" class="btn btn-default" {{'disabled' if not reboot_available else ''}} >
            Reboot</button>
            <button id="btn-factrestore" type="button" class="btn btn-default" {{'disabled' if not reboot_available else ''}} >Factory</button>
            <button id="btn-unprovision" type="button" class="btn btn-default" {{'disabled' if not reboot_available else ''}} >Unprovision</button>
            <button id="btn-tr069" type="button" class="btn btn-default" {{'disabled' if not tr069_available else ''}} >TR069</button>
            %end
        </div>

    </div>


</div>

<br />

    <div class="col-md-6">
        <div id="timeline"></div>
    </div>

    <div class="col-md-6">
          {{!helper.print_aggregation_tree(helper.get_host_service_aggregation_tree(cpe, app), helper.get_html_id(cpe), show_output=True)}}
    </div>


    <div class="col-md-12 panel panel-default">
        <div class="panel-heading">

          <div class="pull-right">
            <span>Summary: </span>
            <span class="fa fa-calendar"></span> <span id="uptime">-</span></span>
            <span class="fa fa-dashboard"></span> <span id="dnbw">-</span>/<span id="upbw">-</span>
            <span class="fa fa-signal"></span> <span id="uprx">-</span>/<span id="dnrx">-</span>dbm
            <span class="fa fa-reorder"></span> <span id="service_ports"></span>
            <span>&nbsp;</span>
            <span class="btn btn-primary btn-xs" data-toggle="collapse" data-target="#info-panel">+</span>
          </div>

        <h4 class="panel-title">Realtime</h4>

        </div>
        <div class="panel-body">
          <div class="col-md-6">
            <div id="bw" style="width: 100%; height: 120px;"></div>
          </div>
          <div class="col-md-6">
            <div id="rx" style="width: 100%; height: 120px;"></div>
          </div>
        </div>

        <div id="info-panel" class="panel-body collapse">

        <div class="col-sm-4">
          <dl class="dl-horizontal">
            <dt>Serial Number</dt><dd>{{ cpe.customs.get('_SN', '').upper() }}</dd>
            %if cpe.customs.get('_DSN'):
            <dt>DSN</dt><dd>{{ cpe.customs.get('_DSN') }}</dd>
            %end
            %if cpe.customs.get('_MAC') and len(cpe.customs.get('_MAC')):
            <dt>MAC Address</dt><dd>{{cpe.customs.get('_MAC','00:00:00:00:00:00')}}</dd>
            %end
            %if cpe.customs.get('_MTAMAC') and len(cpe.customs.get('_MTAMAC')):
            <dt>MTA MAC</dt><dd>{{cpe.customs.get('_MTAMAC')}}</dd>
            %end
            <dt>CPE IP Address</dt><dd>{{cpe.cpe_address}}</dd>

            <dt>Registration host</dt><dd>{{ cpe.cpe_registration_host }}
                <a href="/all?search=type:host {{cpe.cpe_registration_host}}"><i class="fa fa-search"></i></a></dd>
            <dt>Registration ID</dt><dd>{{cpe.cpe_registration_id}}
                <a href="/all?search=type:host {{cpe.cpe_registration_host}} {{cpe.cpe_registration_id[:-1]}}"><i class="fa fa-search"></i></a></dd>

            <!--<dt>Registration state</dt><dd id="status">{{cpe.cpe_registration_state}}</dd>-->
            <dt>Registration tags</dt><dd>{{cpe.cpe_registration_tags}}</dd>
          </dl>
        </div>


        <div class="col-sm-4">
          <dl class="dl-horizontal">
            <dt>Configuration URL</dt>

        <dd>{{cpe.cpe_connection_request_url}}</dd>
            %if cpe.cpe_ipleases:
            %try:
            %cpe_ipleases = ast.literal_eval(cpe.cpe_ipleases) or {'foo': 'bar'}
            %for ip,lease in cpe_ipleases.iteritems():
            %if app.proxy_sufix:
            <dt><a href="http://{{ip}}.{{app.proxy_sufix}}" target=_blank>{{ip}}</a></dt>
            %else:
            <dt>{{ip}}</dt>
            %end
            <dd>{{lease}}</dd>
            %end
            %except Exception, exc:
            <dt>{{cpe.cpe_ipleases}}</dt>
            <dd>{{exc}}</dd>
            %end
            %else:
            <dt>IP Leases</dt>
            %if app.proxy_sufix:
            <dt><a href="http://10.11.12.13.{{app.proxy_sufix}}" target=_blank>N/A</a></dt>
            %else:
            <dt>N/A</dt>
            %end
            %end

         <!--<button class="btn btn-default btn-xs center-block" data-toggle="collapse" data-target="#more-info">More</button>-->

       </dl>
     </div>
    <div>
    <div class="col-sm-4 dl-horizontal">
        <dl >
            <dt>Name</dt>
            <dd>{{cpe.customs.get('_CUSTOMER_NAME')}}</dd><dt>Surname</dt>
            <dd>{{cpe.customs.get('_CUSTOMER_SURNAME')}}</dd><dt>Address</dt>
            <dd>{{cpe.customs.get('_CUSTOMER_ADDRESS')}}</dd><dt>City</dt>
            <dd>{{cpe.customs.get('_CUSTOMER_CITY')}}</dd></dl>
        </dl>
    </div>

    </div>
    </div>


    </div>


<!--<div class="col-md-12 panel panel-default">
<div class="panel-heading clearfix">
    <h2 class="panel-title pull-left">Info</h2>

</div>

</div>-->

<br />





<div class="row container-fluid">
    %if app.logs_module.is_available():
    <div class="col-md-6 panel panel-default">
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
    <div class="col-md-6 panel panel-default">
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


<div id="element" class="row container-fluid">

</div>
<div class="row container-fluid">



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

%#End of the element exist or not case
%end


<script>
$("[data-type='host']").each(function(key, value){
    item = $(value)
    $.getJSON('/quick/'+item.html(), function(data){
        //console.log(data)
        if (data.last_state_id == 0) {
            item.addClass('font-up')
        } else if (data.last_state_id == 1) {
            item.addClass('font-unreachable')
        } else if (data.last_state_id == 2) {
           item.addClass('font-down')
        }
    });
});


</script>
