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

%js=['js/shinken-actions.js', 'cpe/js/bootstrap-switch.min.js', 'cpe/js/datatables.min.js', 'cpe/js/google-charts.min.js', 'cpe/js/vis.min.js', 'cpe/js/cpe.js?1234']
%css=['cpe/css/bootstrap-switch.min.css', 'cpe/css/datatables.min.css', 'cpe/css/vis.min.css', 'cpe/css/cpe.css']
%rebase("layout", js=js, css=css, breadcrumb=breadcrumb, title=title)

<!--<script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>-->

<script src="http://www.flotcharts.org/flot/jquery.flot.js" charset="utf-8"></script>
<script src="/static/cpe/js/plots.js" charset="utf-8"></script>
<script>
var CPE_QUICKSERVICES_UPDATE_FREQUENCY = 2500
var CPE_POOL_UPDATE_FREQUENCY = 5000

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

var STATUS_GREEN   = ["UP", "WORKING", "OK"];
var STATUS_RED     = ["DOWN", "LOS", "DYINGGASP", "OFFLINE", "AUTHFAILED"];
var STATUS_YELLOW  = ["NOT FOUND", "NOTFOUND", "SYNCMIB", "LOGGING"];
var STATUS_BLUE    = ["NONE", "NULL", ""];

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

            console.log(data);
            //enable or disable buttons

            if ( $.inArray(data.status, STATUS_GREEN ) >= 0 ) {
              $('#btn-reboot')      .removeClass("disabled").prop("disabled", false);
              $('#btn-factrestore') .removeClass("disabled").prop("disabled", false);
              $('#btn-unprovision') .removeClass("disabled").prop("disabled", false);
              $('#btn-tr069')       .removeClass("disabled").prop("disabled", false);
            } else if ( $.inArray(data.status, STATUS_RED ) >= 0 )  {
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

            if ( typeof data.ips !== 'undefined' ) {
               $("#ips").html('')
               $.each(data.ips, function(v,k){
                 $("#ips").append('<a href="http://'+proxy_prefix+k[1]+'.'+proxy_sufix+'">'+k[1]+'</a> | ');
               })
            }

            //if(data.status == "UP" || data.status == "WORKING" || data.status == "WORKING") {
            if ( $.inArray(data.status, STATUS_GREEN ) >= 0 ) {
                $('#registration_state').css('color','#8BC34A');
		            $('#status2').html(getHTMLState(0))
            } else if ( $.inArray(data.status, STATUS_RED ) >= 0 )  {
                $('#registration_state').css('color','#FF7043');
		            $('#status2').html(getHTMLState(2))
            } else if ( $.inArray(data.status, STATUS_YELLOW ) >= 0 )  {
                $('#registration_state').css('color','#FAA732');
                $('#status2').html(getHTMLState(1))
            } else if ( $.inArray(data.status, STATUS_BLUE ) >= 0 )  {
                $('#registration_state').css('color','#49AFCD');
                $('#status2').html(getHTMLState(3))
            } else { // GRAY COLOR
                $('#registration_state').css('color','#DDD');
                $('#status2').html(getHTMLState(3))
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
              <!--
              %if len(cpe.parents):
              <a href="/cpe/{{ cpe.parents[0].host_name }}" title="Parent: {{ cpe.parents[0].host_name }}"><i class="fa fa-chevron-left"></i></a>
              %end
              -->
              <a href="/host/{{ cpe.host_name }}">{{ cpe.host_name }}</a>
              <!--
              %if len(cpe.childs):
              <a href="/cpe/{{ cpe.childs[0].host_name }}" title="Child: {{ cpe.childs[0].host_name }}"><i class="fa fa-chevron-right"></i></a>
              %end
              -->



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
        <div style="font-size: 18px; color: #666;">
            <!--
                            <a href="https://www.google.es/maps?q={{ cpe.customs.get('_CUSTOMER_ADDRESS')}} {{cpe.customs.get('_CUSTOMER_CITY')}}" target="_blank">{{cpe.customs.get('_CUSTOMER_ADDRESS')}} {{cpe.customs.get('_CUSTOMER_CITY')}}</a>
            -->
            <a href="/cpe/{{ cpe.cpe_registration_host }}" data-type="registration-host">{{ cpe.cpe_registration_host }}</a>
            <span>/</span>
            <a href="/all?search=type:host {{cpe.cpe_registration_host}}" data-type="registration-id">{{ cpe.cpe_registration_id }}</a>
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
            %if cpe.customs.get('_TECH') == 'wimax':
            <button id="btn-update" type="button" class="btn btn-default"><i class="fa fa-arrow-up" aria-hidden="true"></i>&nbsp; Update</button>
            <button id="btn-backup" type="button" class="btn btn-default"><i class="fa fa-save" aria-hidden="true"></i>&nbsp; Backup</button>
            %end
            <button id="btn-reboot" type="button" class="btn btn-default" {{'disabled' if not reboot_available else ''}} ><i class="fa fa-refresh" aria-hidden="true"></i>&nbsp; Reboot</button>
            %if cpe.customs.get('_TECH') == 'gpon':
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
            <span class="fa fa-reorder"></span> <span id="service_ports"></span>
            <span>&nbsp;</span>
            <span class="btn btn-primary btn-xs" data-toggle="collapse" data-target="#info-panel">+</span>
          </div>

        <h4 class="panel-title">Realtime</h4>

        </div>

        <div class="panel-body {{ 'hidden' if not cpe.customs.get('_TECH') == 'gpon' else '' }} ">

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
        <div class="panel-heading">
          <div class="pull-right">
            <a class="btn btn-primary btn-xs" data-toggle="collapse" href="#eventHistory">+</a>
          </div>
          <h4 class="panel-title">Event History</h4>
        </div>
        <div id="eventHistory" class="panel-body panel-collapse collapse">
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


var cpeSRN = document.getElementById("cpe-sn");
var cpeMAC = document.getElementById("cpe-mac");

if (cpeSRN) {
  cpeSRN.addEventListener("click", function() { copyToClipboard(cpeSRN) });
}

if (cpeMAC) {
  cpeMAC.addEventListener("click", function() { copyToClipboard(cpeMAC) });
}


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
var realtimeTimer = window.setInterval(function(){
  poll_cpe()
}, CPE_POOL_UPDATE_FREQUENCY);

</script>
