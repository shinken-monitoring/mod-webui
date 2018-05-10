%import time
%import re
%import ast
%import json
%import yaml

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
%if hasattr(cpe.__class__, 'my_type'):
  %cpe_type = cpe.__class__.my_type
%else:
  %cpe_type = 'None'
%end

%if hasattr(cpe, 'host'):
  %cpe_host = cpe if cpe_type=='host' else cpe.host
  %cpe_name = cpe.host_name if cpe_type=='host' else cpe.host.host_name+'/'+cpe.service_description
  %cpe_display_name = cpe_host.display_name if cpe_type=='host' else cpe_service.display_name+' on '+cpe_host.display_name
  %cpe_graphs = helper.get_graphs_for_cpe(cpe_host.host_name, cpe.customs.get('_TECH'));
%else:
  %cpe_host = cpe
  %cpe_display_name = "none"
  %cpe_name = "NONE"
  %cpe_graphs = []
%end

%if hasattr(cpe, 'cpe_registration_host') and hasattr(cpe, 'cpe_registration_id'):
  %reboot_available = cpe.cpe_registration_host and cpe.cpe_registration_id
%else:
  %reboot_available = True
%end


%if hasattr(cpe, 'cpe_connection_request_url'):
  %tr069_available = cpe.cpe_connection_request_url
%end

%# Replace MACROS in display name ...
%if hasattr(cpe, 'get_data_for_checks'):
    %cpe_display_name = MacroResolver().resolve_simple_macros_in_string(cpe_display_name, cpe.get_data_for_checks())
%end

%business_rule = False
%if hasattr(cpe, 'get_check_command') and cpe.get_check_command().startswith('bp_rule'):
%business_rule = True
%end

%breadcrumb = [ ['All '+ ( cpe_type.title() if hasattr(cpe_type, 'title') else 'UNK' ) + 's', '/'+cpe_type+'s-groups'], [cpe_display_name, '/host/'+cpe_name] ]
%breadcrumb = []

%title = ( cpe_type.title() if hasattr(cpe_type, 'title') else 'KIWI' ) +' detail: ' + cpe_display_name

%title = cpe_host.host_name


%js=['js/shinken-actions.js', 'cpe/js/bootstrap-switch.min.js', 'cpe/js/datatables.min.js', 'cpe/js/google-charts.min.js', 'cpe/js/vis.min.js', 'cpe/js/cpe.js?122345']
%css=['cpe/css/bootstrap-switch.min.css', 'cpe/css/datatables.min.css', 'cpe/css/vis.min.css', 'cpe/css/cpe.css']
%rebase("layout", js=js, css=css, breadcrumb=breadcrumb, title=title)

<!--<script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>-->

<script src="https://www.flotcharts.org/flot/jquery.flot.js" charset="utf-8"></script>
<script src="/static/cpe/js/plots.js" charset="utf-8"></script>
<script>
var CPE_QUICKSERVICES_UPDATE_FREQUENCY = 5000;
var CPE_POOL_UPDATE_FREQUENCY = 10000;

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
    name: '{{ cpe_host.host_name }}',
    state: '{{ cpe_host.state if hasattr(cpe_host,"state") else "UNK" }}',
    state_id: '{{cpe_host.state_id  if hasattr(cpe_host,"state_id") else 0 }}',
    last_state_change: '{{cpe_host.last_state_change  if hasattr(cpe_host,"last_state_change") else "UNK" }}',
    url: '/host/{{cpe_host.host_name}}'
};

var cpe_name = cpe.name
var cpe_graphs = JSON.parse('{{!json.dumps(cpe_graphs)}}');
var services = [];
%for service in ( cpe.services if hasattr(cpe,"state") else []):
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

var STATUS_GREEN   = ["UP", "WORKING", "OK"];
var STATUS_RED     = ["DOWN", "LOS", "DYINGGASP", "OFFLINE", "AUTHFAILED"];
var STATUS_YELLOW  = ["NOT FOUND", "NOTFOUND", "SYNCMIB", "LOGGING"];
var STATUS_BLUE    = ["NONE", "NULL", ""];

function poll_cpe() {
  $.getJSON('/cpe_poll/{{cpe_host.host_name}}', function(data){


        if ( typeof data.hostevent !== 'undefined' ) {
          $.each(data.hostevent, function(k,v){

              if ( typeof v.leased_address !== 'undefined' ) {
                alertify.log("New IP ADDRESS: " + v.leased_address, "info", 15000);
              }

          });
        }


        if(data && data.status) {

            data.status = data.status.replace(/\W+\s+/g, '').toUpperCase()

            $('#registration_state').html(data.status)
            $('#upbw').html(humanBytes(data.upbw))
            $('#dnbw').html(humanBytes(data.dnbw))
            $('#dnrx').html(data.dnrx)
            $('#uprx').html(data.uprx)

            if (typeof data.ccq !== 'undefined') {
              $('#ccq').html(data.ccq + "%").show()
            }

            if (typeof data.uptime !== 'undefined') {
              d1 = Date.parse(data.uptime);
              d2 = new Date();
              delta = (d2 - d1) / 1000;
              $('#uptime').html(toHHMMSS(data.uptime));
            }

            $('#registration_state').html('<span>'+data.status+'</span>');


            //console.log(data);
            //enable or disable buttons

            if ( data.status_id == 0 ) {
              $('#btn-reboot')      .removeClass("disabled").prop("disabled", false);
              $('#btn-factrestore') .removeClass("disabled").prop("disabled", false);
              $('#btn-unprovision') .removeClass("disabled").prop("disabled", false);
              $('#btn-tr069')       .removeClass("disabled").prop("disabled", false);
            } else if ( data.status_id == 2 )  {
              $('#btn-reboot')      .addClass("disabled").prop("disabled", true);
              $('#btn-factrestore') .addClass("disabled").prop("disabled", true);
              $('#btn-tr069')       .addClass("disabled").prop("disabled", true);
              $('#btn-unprovision') .removeClass("disabled").prop("disabled", false);
            }

            if ( typeof data.cpe_registration_host === 'undefined' ) {
              $('#btn-reboot')     .addClass("disabled").prop("disabled", true);
              $('#btn-factrestore').addClass("disabled").prop("disabled", true);
              $('#btn-unprovision').addClass("disabled").prop("disabled", true);
              $('#btn-tr069')      .addClass("disabled").prop("disabled", true);
            } else {
              $('[data-type="registration-host"]').html(data.cpe_registration_host)
              $('[data-type="registration-id"]').html(data.cpe_registration_id)
            }


            if ( typeof data.lapse !== 'undefined' ) {
               CPE_POOL_UPDATE_FREQUENCY = Math.round( (data.lapse * 1000 ) * 1.20 );
               if ( CPE_POOL_UPDATE_FREQUENCY < 10000 ) {
                 CPE_POOL_UPDATE_FREQUENCY = 10000;
               }
            }

            if ( typeof data.ips !== 'undefined' ) {
               $("#ips").html('')
               $.each(data.ips, function(v,k){
                 $("#ips").append('<a href="http://'+proxy_prefix+k[1]+'.'+proxy_sufix+'">'+k[1]+'</a> | ');
               })
            }

            if (typeof data.status_id !== "undefined") {
              $('#registration_state').css('color', getColorState(data.status_id) );
              $('#status2').html(getHTMLState(data.status_id));
            }

            line = ""
            $.each(data.service_ports, function(k,v){
               line = line + v.service_vlan + '/'+ v.user_vlan
               if ( typeof v.native_vlan !== 'undefined' && v.native_vlan ) {
                 line = line + "N";
               }
               line = line + " ";
            })

            $('#service_ports').html(line)


            if (data.status && data.status != cpe.state) {
                //notify("{{cpe_host.host_name}} is " + data.status);
                cpe.state = data.status;
            }

            if (typeof data.perfdatas  !== 'undefined') {

              var downstreams = Krill.parsePerfdata(data.perfdatas.downstream);
              var upstreams   = Krill.parsePerfdata(data.perfdatas.upstream);
              var qoss        = Krill.parsePerfdata(data.perfdatas.qos);

              for (var i = 0; i < downstreams; i++) {
                if (downstreams[i][0] == 'dnrx') {
                  data.dnrx = parseFloat(downstreams[i][1])
                }
              }

              for (var i = 0; i < upstreams; i++) {
                if (upstreams[i][0] == 'uptx') {
                  data.uptx = parseFloat(upstreams[i][1])
                }
              }


              for (var i = 0; i < qoss; i++) {
                if (qoss[i][0] == 'dncorr') {
                  data.dncorr = parseFloat(upstreams[i][1])
                }
                if (qoss[i][0] == 'dnko') {
                  data.dnko = parseFloat(upstreams[i][1])
                }
              }



              qoss_table          = parsePerfdataTable(qoss)
              qoss_table_titles   = Object.keys(qoss_table)
              qoss_table_rows     = Object.values(qoss_table)

              downstreams_table        = parsePerfdataTable(downstreams)
              upstreams_table          = parsePerfdataTable(upstreams)

              downstreams_table.dncorr = qoss_table.dncorr
              downstreams_table.dnko   = qoss_table.dnko
              upstreams_table.upcorr   = qoss_table.upcorr
              upstreams_table.upko     = qoss_table.upko

              downstreams_table_titles = Object.keys(downstreams_table)
              downstreams_table_rows   = Object.values(downstreams_table)


              upstreams_table_titles   = Object.keys(upstreams_table)
              upstreams_table_rows     = Object.values(upstreams_table)


              try {
                $('#docsisDownstreamTable').html(generatePerfTable(downstreams_table_titles, downstreams_table_rows));
                $('#docsisUpstreamTable').html(generatePerfTable(upstreams_table_titles, upstreams_table_rows));
              } catch(err) {
                console.log(err)
              }
              //$('#docsisQosTable').html(generatePerfTable(qoss_table_titles, qoss_table_rows));

            }


            updateGraphs(data);

        }

    });
}
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
    <div class="col-md-2">


        %if cpe.customs.get('_CPE_ID'):
            <div class="right" style="font-size: 24px"><a href="/host/{{ cpe.host_name }}">{{ cpe.host_name }}</a></div>
            <div class="right" style="font-size: 18px; ">{{cpe.customs.get('_CPE_MODEL')}}</div>
            %if cpe.customs.get('_SN') and len(cpe.customs.get('_SN')):
            <div title="{{ cpe.customs.get('_CPE_NOTES') }}" id="cpe-sn" style="cursor: pointer; text-align: right" class="font-fixed" style="font-size: 12px; text-align: right; color: #9E9E9E;">{{ cpe.customs.get('_SN', '') }}</div>
            %end

            %if cpe.customs.get('_MAC') and len(cpe.customs.get('_MAC')):
            <div title="{{ cpe.customs.get('_CPE_NOTES') }}" id="cpe-mac" style="cursor: pointer; text-align: right" class="font-fixed" style="font-size: 12px; text-align: right; color: #9E9E9E;">{{ cpe.customs.get('_MAC', '') }}</div>
            %end

            %if cpe.customs.get('_CPE_NOTES'):
            <div id="cpe-notes" style="cursor: pointer; text-align: right" class="font-fixed" style="font-size: 12px; text-align: right; color: #9E9E9E;">{{ cpe.customs.get('_CPE_NOTES') }}</div>
            %end

        %else:
            <div class="right" style="font-size: 24px">
              <a href="/host/{{ cpe.host_name }}">{{ cpe.host_name }}</a>




            </div>
            <div class="right" style="font-size: 22px; "><a href="http://{{ cpe.address }}.{{app.proxy_sufix}}" target=_blank>{{ cpe.address }}</a></div>
            %if cpe.customs.get('_MAC') and len(cpe.customs.get('_MAC')):
            <div title="{{ cpe.customs.get('_CPE_NOTES') }}" id="cpe-mac" style="cursor: pointer; text-align: right" class="font-fixed" style="font-size: 12px; text-align: right; color: #9E9E9E;">{{ cpe.customs.get('_MAC', '') }}</div>
            %end
        %end
    </div>

    <div class="col-md-6">
        %if cpe.customs.get('_CPE_ID'):
        <div style="font-size: 22px">{{ cpe.customs.get('_CUSTOMER_NAME')}} {{cpe.customs.get('_CUSTOMER_SURNAME')}}</div>
        <div style="font-size: 18px; color: #666; white-space:normal;">
            <a href="/cpe/{{ cpe.cpe_registration_host }}" data-type="registration-host">{{ cpe.cpe_registration_host }}</a>
            <span>/</span>
            <a href="/all?search=type:host {{cpe.cpe_registration_id}}" data-type="registration-id">{{ cpe.cpe_registration_id }}</a>
            <span>:</span>
            <span id="registration_state"> <i class="fa fa-spinner fa-spin"></i> <!--{{cpe.cpe_registration_state}}--></span>
        </div>
        <div style="font-size: 18px; color: #999;">
            %if cpe.customs.get('_ACTIVE') == '1':
            <span style="color: #64DD17" alt="Enabled Internet access" title="CPE Enabled"><i class="fa fa-thumbs-up"></i></span>
                %if cpe.customs.get('_ACCESS') == '1':
                <span style="color: #64DD17" alt="Enabled Internet access" title="Enabled Internet access"><i class="fa fa-globe"></i><!--Internet access--></span>
                %else:
                <span style="color: #E65100" alt="Disabled Internet access" title="Disabled Internet access"><i class="fa fa-globe text-danger"></i><!--Disabled Internet access--></span>
                %end
            %else:
            <span style="color: #E65100" alt="Disabled Internet access" title="CPE disabled"><i class="fa fa-thumbs-down text-danger"></i><!--Disabled Internet access--></span>
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
        <div style="font-size: 18px; color: #333;" id="ips"> </div>
        %else:
          <span></span>
        %end
    </div>

    <div class="col-md-4">
        <div class="btn-group pull-right" role="group">
            %if str(cpe.customs.get('_TECH') if hasattr(cpe,'customs') else cpe.tech) in ('wimax'):
            <button id="btn-update" type="button" class="btn btn-default"><i class="fa fa-arrow-up" aria-hidden="true"></i>&nbsp; Update</button>
            <button id="btn-backup" type="button" class="btn btn-default"><i class="fa fa-save" aria-hidden="true"></i>&nbsp; Backup</button>
            %end
            <button id="btn-reboot" type="button" class="btn btn-default" {{'disabled' if not reboot_available else ''}} ><i class="fa fa-refresh" aria-hidden="true"></i>&nbsp; Reboot</button>
            %if str(cpe.customs.get('_TECH') if hasattr(cpe,'customs') else cpe.tech) in ('gpon'):
            <button id="btn-factrestore" type="button" class="btn btn-default" {{'disabled' if not reboot_available else ''}} ><i class="fa fa-fast-backward" aria-hidden="true"></i>&nbsp; Factory</button>
            <button id="btn-unprovision" type="button" class="btn btn-default" {{'disabled' if not reboot_available else ''}} ><i class="fa fa-reply" aria-hidden="true"></i>&nbsp; Unprovision</button>
            <button id="btn-tr069"       type="button" class="btn btn-default" {{'disabled' if not tr069_available else  ''}} ><i class="fa fa-gears" aria-hidden="true"></i>&nbsp; Reconfig (TR069)</button>
            %end
        </div>
    </div>


</div>

<hr />

<div class="row">
  <div class="col-md-6"><div id="timeline"></div></div>
  <div class="col-md-6" id="quickservices"> </div>
</row>

<div clas="row">
    <div class="col-md-12 panel panel-default">
        <div class="panel-heading">

          <div class="pull-right">
            <span>Summary: </span>
            <span class="fa fa-calendar"></span> <span id="uptime">-</span></span>
            <span class="fa fa-dashboard"></span> <span id="dnbw">-</span>/<span id="upbw">-</span>
            <span class="fa fa-signal"></span> <span id="uprx">-</span>/<span id="dnrx">-</span>dbm
            <span class="fa fa-signal"></span> <span id="ccq">-</span>dbm
            <span class="fa fa-reorder"></span> <span id="service_ports"></span>
            <span>&nbsp;</span>
            <span class="btn btn-primary btn-xs" data-toggle="collapse" data-target="#info-panel">+</span>
          </div>

          <h4 class="panel-title">Realtime</h4>

        </div>

        <div class="panel-body">
          <div class="row">
            <div class="col-md-4">
              <div id="plot_bw" style="width: 100%; height: 120px;"></div>
            </div>

            <div class="col-md-4">
              <div id="plot_rx" style="width: 100%; height: 120px;"></div>
            </div>

            <div class="col-md-4">
              <div id="plot_ccq" style="width: 100%; height: 120px;"></div>
            </div>
          </div>
          <div class="row">
            <div class="col-md-6" id="docsisDownstreamTable"></div>
            <div class="col-md-6" id="docsisUpstreamTable"></div>
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
            <dt>CPE IP Address</dt><dd>{{cpe.cpe_address if hasattr(cpe, 'cpe_address') else '' }}</dd>

            <dt>Registration host</dt><dd>{{ cpe.cpe_registration_host if hasattr(cpe, 'cpe_registration_host') else '' }}
                <a href="/all?search=type:host {{ cpe.cpe_registration_host if hasattr(cpe, 'cpe_registration_host') else '' }}"><i class="fa fa-search"></i></a></dd>
            <dt>Registration ID</dt><dd>{{cpe.cpe_registration_id if hasattr(cpe, 'cpe_registration_id') else '' }}
                <a href="/all?search=type:host {{ cpe.cpe_registration_host if hasattr(cpe, 'cpe_registration_host') else '' }}"><i class="fa fa-search"></i></a></dd>


            <dt>Registration tags</dt><dd>{{cpe.cpe_registration_tags if hasattr(cpe, 'cpe_registration_tags') else ''  }}</dd>
          </dl>
        </div>


        <div class="col-sm-4">
          <dl class="dl-horizontal">
            <dt>Configuration URL</dt>

        <dd>{{cpe.cpe_connection_request_url}}</dd>
            %if cpe.cpe_ipleases if hasattr(cpe, 'cpe_ipleases') else False:
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
</div>

<div class="row container-fluid clearfix">
    %if app.logs_module.is_available():
    <div class="col-md-6 panel panel-default">
        <div class="panel-heading">
          <div class="pull-right">
            <a class="btn btn-primary btn-xs" data-toggle="collapse" href="#logHistory">+</a>
          </div>
          <h4 class="panel-title">Log History</h4>
        </div>
        <div id="logHistory" class="panel-body panel-collapse collapse">
            <table id="inner_history" class="table" data-element='{{ cpe.get_full_name() if hasattr(cpe, "get_full_name") else '' }}'>
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
        <div class="panel-heading">
          <div class="pull-right">
            <a class="btn btn-primary btn-xs" data-toggle="collapse" href="#eventHistory">+</a>
          </div>
          <h4 class="panel-title">Event History</h4>
        </div>
        <div id="eventHistory" class="panel-body panel-collapse collapse">
            <table id="inner_events" class="table" data-element='{{ cpe.get_full_name() if hasattr(cpe, "get_full_name") else '' }}'>
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


var cpeSRN = document.getElementById("cpe-sn");
var cpeMAC = document.getElementById("cpe-mac");

if (cpeSRN) {
  cpeSRN.addEventListener("click", function() { copyToClipboard(cpeSRN) });
}

if (cpeMAC) {
  cpeMAC.addEventListener("click", function() { copyToClipboard(cpeMAC) });
}


// Actualizador servicios
(function worker() {
  $.ajax({
    url: '/cpe/quickservices/{{cpe_host.host_name}}',
    success: function(data) {
      $('#quickservices').html( $('ul',data) );
    },
    complete: function() {
      setTimeout(worker, CPE_QUICKSERVICES_UPDATE_FREQUENCY);
    }
  });
})();

// Poller
// var realtimeTimer = window.setInterval(function(){
//   poll_cpe()
//}, CPE_POOL_UPDATE_FREQUENCY);


function poll_cpe_timeout() {
  if ( CPE_POOL_UPDATE_FREQUENCY > 0) {

    poll_cpe();

    window.setTimeout(function(){
          poll_cpe_timeout();
    }, CPE_POOL_UPDATE_FREQUENCY);

  }
}

// lazy start
window.setTimeout(function(){
      poll_cpe_timeout();
}, 1000);


</script>
