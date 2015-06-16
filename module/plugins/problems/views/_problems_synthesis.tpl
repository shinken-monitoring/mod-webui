<!-- Problems synthesis -->

%hosts = [i for i in pbs if i.__class__.my_type == 'host']
%nHosts = len(hosts)
%hUp = len([i for i in hosts if i.state == 'UP'])
%hDown = len([i for i in hosts if i.state == 'DOWN'])
%hUnreachable = len([i for i in hosts if i.state == 'UNREACHABLE'])
%hPending = len([i for i in hosts if i.state == 'PENDING'])
%hUnknown = nHosts - hUp - hDown - hUnreachable - hPending
%hAck = len([i for i in hosts if i.problem_has_been_acknowledged])
%hDowntime = len([i for i in hosts if i.in_scheduled_downtime])
%pctHUp           = 0
%pctHDown         = 0
%pctHUnreachable  = 0
%pctHPending      = 0
%pctHUnknown      = 0
%pctHAck          = 0
%pctHDowntime     = 0

%if hosts:
  %pctHUp           = round(100.0 * hUp / nHosts, 2)
  %pctHDown         = round(100.0 * hDown / nHosts, 2)
  %pctHUnreachable  = round(100.0 * hUnreachable / nHosts, 2)
  %pctHPending      = round(100.0 * hPending / nHosts, 2)
  %pctHUnknown      = round(100.0 * hUnknown / nHosts, 2)
  %pctHAck          = round(100.0 * hAck / nHosts, 2)
  %pctHDowntime     = round(100.0 * hDowntime / nHosts, 2)
%end

%services = [i for i in pbs if i.__class__.my_type == 'service']
%nServices = len(services)
%sOk = len([i for i in services if i.state == 'OK'])
%sCritical = len([i for i in services if i.state == 'CRITICAL'])
%sWarning = len([i for i in services if i.state == 'WARNING'])
%sPending = len([i for i in services if i.state == 'PENDING'])
%sUnknown = nServices - sOk - sCritical - sWarning - sPending
%sAck = len([i for i in services if i.problem_has_been_acknowledged])
%sDowntime = len([i for i in services if i.in_scheduled_downtime])
%pctSOk           = 0
%pctSCritical     = 0
%pctSWarning      = 0
%pctSPending      = 0
%pctSUnknown      = 0
%pctSAck          = 0
%pctSDowntime     = 0

%if services:
  %pctSOk           = round(100.0 * sOk / nServices, 2)
  %pctSCritical     = round(100.0 * sCritical / nServices, 2)
  %pctSWarning      = round(100.0 * sWarning / nServices, 2)
  %pctSPending      = round(100.0 * sPending / nServices, 2)
  %pctSUnknown      = round(100.0 * sUnknown / nServices, 2)
  %pctSAck          = round(100.0 * sAck / nServices, 2)
  %pctSDowntime     = round(100.0 * sDowntime / nServices, 2)
%end

<div class="panel panel-default">
   <div class="panel-body">
      <table class="table table-invisible table-condensed">
         <tbody>
           %if 'type:service' not in search_string:
            <tr>
               <td>
               <b>{{nHosts}} hosts:&nbsp;</b> 
               </td>
             
               <td><span title="Up" class="{{'font-up' if hUp > 0 else 'font-greyed'}}">
               <span class="fa-stack"><i class="fa fa-circle fa-stack-2x"></i> <i class="fa fa-server fa-stack-1x fa-inverse"></i></span> 
               <span class="num">{{hUp}} <i>({{pctHUp}}%)</i></span>
               </span></td>
             
               <td><span title="Unreachable" class="{{'font-unreachable' if hUnreachable > 0 else 'font-greyed'}}">
               <span class="fa-stack"> <i class="fa fa-circle fa-stack-2x"></i> <i class="fa fa-server fa-stack-1x fa-inverse"></i></span> 
               <span class="num">{{hUnreachable}} <i>({{pctHUnreachable}}%)</i></span>
               </span></td>

               <td><span title="Down" class="{{'font-down' if hDown > 0 else 'font-greyed'}}">
               <span class="fa-stack"> <i class="fa fa-circle fa-stack-2x"></i> <i class="fa fa-server fa-stack-1x fa-inverse"></i></span> 
               <span class="num">{{hDown}} <i>({{pctHDown}}%)</i></span>
               </span></td>

               <td><span title="Pending" class="{{'font-pending' if hPending > 0 else 'font-greyed'}}">
               <span class="fa-stack"> <i class="fa fa-circle fa-stack-2x"></i> <i class="fa fa-server fa-stack-1x fa-inverse"></i></span> 
               <span class="num">{{hPending}} <i>({{pctHPending}}%)</i></span>
               </span></td>

               <td><span title="Unknown" class="{{'font-unknown' if hUnknown > 0 else 'font-greyed'}}">
               <span class="fa-stack"> <i class="fa fa-circle fa-stack-2x"></i> <i class="fa fa-server fa-stack-1x fa-inverse"></i></span> 
               <span class="num">{{hUnknown}} <i>({{pctHUnknown}}%)</i></span>
               </span></td>

               <td><span title="Acknowledged" class="{{'font-ack' if hAck > 0 else 'font-greyed'}}">
               <span class="fa-stack"> <i class="fa fa-circle fa-stack-2x"></i> <i class="fa fa-check fa-stack-1x fa-inverse"></i></span> 
               <span class="num">{{hAck}} <i>({{pctHAck}}%)</i></span>
               </span></td>

               <td><span title="In scheduled downtime" class="{{'font-downtime' if hDowntime > 0 else 'font-greyed'}}">
               <span class="fa-stack"> <i class="fa fa-circle fa-stack-2x"></i> <i class="fa fa-ambulance fa-stack-1x fa-inverse"></i></span> 
               <span class="num">{{hDowntime}} <i>({{pctHDowntime}}%)</i></span>
               </span></td>
            </tr>
            %end
            %if 'type:host' not in search_string:
            <tr>
               <td>
                  <b>{{nServices}} services:&nbsp;</b> 
               </td>
          
               <td><span title="Ok" class="{{'font-ok' if sOk > 0 else 'font-greyed'}}">
               <span class="fa-stack"><i class="fa fa-circle fa-stack-2x"></i> <i class="fa fa-arrow-up fa-stack-1x fa-inverse"></i></span> 
               <span class="num">{{sOk}} <i>({{pctSOk}}%)</i></span>
               </span></td>
          
               <td><span title="Warning" class="{{'font-warning' if sWarning > 0 else 'font-greyed'}}">
               <span class="fa-stack"> <i class="fa fa-circle fa-stack-2x"></i> <i class="fa fa-exclamation fa-stack-1x fa-inverse"></i></span> 
               <span class="num">{{sWarning}} <i>({{pctSWarning}}%)</i></span>
               </span></td>

               <td><span title="Critical" class="{{'font-critical' if sCritical > 0 else 'font-greyed'}}">
               <span class="fa-stack"> <i class="fa fa-circle fa-stack-2x"></i> <i class="fa fa-arrow-down fa-stack-1x fa-inverse"></i></span> 
               <span class="num">{{sCritical}} <i>({{pctSCritical}}%)</i></span>
               </span></td>

               <td><span title="Pending" class="{{'font-pending' if sPending > 0 else 'font-greyed'}}">
               <span class="fa-stack"> <i class="fa fa-circle fa-stack-2x"></i> <i class="fa fa-pause fa-stack-1x fa-inverse"></i></span> 
               <span class="num">{{sPending}} <i>({{pctSPending}}%)</i></span>
               </span></td>

               <td><span title="Unknown" class="{{'font-unknown' if sUnknown > 0 else 'font-greyed'}}">
               <span class="fa-stack"> <i class="fa fa-circle fa-stack-2x"></i> <i class="fa fa-question fa-stack-1x fa-inverse"></i></span> 
               <span class="num">{{sUnknown}} <i>({{pctSUnknown}}%)</i></span>
               </span></td>

               <td><span title="Acknowledged" class="{{'font-ack' if sAck > 0 else 'font-greyed'}}">
               <span class="fa-stack"> <i class="fa fa-circle fa-stack-2x"></i> <i class="fa fa-check fa-stack-1x fa-inverse"></i></span> 
               <span class="num">{{sAck}} <i>({{pctSAck}}%)</i></span>
               </span></td>

               <td><span title="In downtime" class="{{'font-downtime' if sDowntime > 0 else 'font-greyed'}}">
               <span class="fa-stack"> <i class="fa fa-circle fa-stack-2x"></i> <i class="fa fa-ambulance fa-stack-1x fa-inverse"></i></span> 
               <span class="num">{{sDowntime}} <i>({{pctSDowntime}}%)</i></span>
               </span></td>
            </tr>
            %end
         </tbody>
      </table>
   </div>
</div>

