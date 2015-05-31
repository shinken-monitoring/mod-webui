%# If got no group, bailout
%if not group:
%rebase("layout", title='Invalid group name')

Invalid group name

%else:

%if group=='all':
%groupname = 'all'
%groupalias = 'All services'
%else:
%groupname = group.get_name()
%groupalias = group.alias
%if groupalias == '':
%groupalias = groupname
%end
%end

%helper = app.helper
%datamgr = app.datamgr
%end

%# Specific content for breadrumb
%rebase("layout", title='Services group detail for ' + groupalias, css=['groups/css/groups-overview.css'], refresh=True, breadcrumb=[ ['All groups', '/hosts-groups'], [groupalias, '/minemap/'+groupname] ])

<div id="content_container">
   <div class="panel panel-default">
      <div class="panel-heading">
         <h3 class="panel-title">{{groupalias}} ({{groupname}})</h3>
      </div>
      
      <div class="panel-body">
%nServices=0
%sOk=sCritical=sWarning=sUnknown=sAck=sCriticaltime=0
%pctOk=pctCritical=pctWarning=pctUnknown=0
%for s in services:
   %nServices=nServices+1
   %if s.state == 'OK':
      %sOk=sOk+1
   %elif s.state == 'CRITICAL':
      %sCritical=sCritical+1
   %elif s.state == 'WARNING':
      %sWarning=sWarning+1
   %else:
      %sUnknown=sUnknown+1
   %end
   %if s.problem_has_been_acknowledged:
      %sAck=sAck+1
   %end
   %if s.in_scheduled_downtime:
      %sCriticaltime=sCriticaltime+1
   %end
%end
%if nServices != 0:
   %pctOk         = round(100.0 * sOk / nServices, 2)
   %pctCritical   = round(100.0 * sCritical / nServices, 2)
   %pctWarning    = round(100.0 * sWarning / nServices, 2)
   %pctUnknown    = round(100.0 * sUnknown / nServices, 2)
%end
         %if progress_bar:
         <div class="row">
            <div class="col-sm-12 text-center center-block"><em>Currently displaying {{nServices}} services ...</em></div>
            <div class="col-sm-1"></div>
            <div class="progress col-sm-10 no-bottommargin no-leftpadding no-rightpadding" style="height: 45px;">
               <div title="{{sOk}} hosts Up" class="progress-bar progress-bar-success quickinfo" role="progressbar" 
                  data-toggle="tooltip" data-placement="bottom" 
                  style="line-height: 45px; width: {{pctOk}}%;">{{pctOk}}% Up</div>
               
               <div title="{{sCritical}} hosts Down" class="progress-bar progress-bar-danger quickinfo" 
                  data-toggle="tooltip" data-placement="bottom" 
                  style="line-height: 45px; width: {{pctCritical}}%;">{{pctCritical}}% Down</div>
               
               <div title="{{sWarning}} hosts Unreachable" class="progress-bar progress-bar-warning quickinfo" 
                  data-toggle="tooltip" data-placement="bottom" 
                  style="line-height: 45px; width: {{pctWarning}}%;">{{pctWarning}}% Unreachable</div>
               
               <div title="{{hPending}} hosts Pending/Unknown" class="progress-bar progress-bar-info quickinfo" 
                  data-toggle="tooltip" data-placement="bottom" 
                  style="line-height: 45px; width: {{pctUnknown}}%;">{{pctUnknown}}% Unknown</div>
            </div>
            <div class="col-sm-1"></div>
         </div>
         %end
         <div class="row">
            <div class="col-sm-12 text-center center-block"><em>Currently displaying {{nServices}} services ...</em></div>
            <div class="col-sm-1"></div>
            <div class="col-sm-10" >
               <table class="table table-invisible">
                  <tbody>
                     <tr>
                        <td>
                           {{!helper.get_fa_icon_state(cls='host', state='up')}} <span class="num">{{sOk}} <i>({{pctOk}}% Up)</i></span>
                        </td>
                        <td>
                           {{!helper.get_fa_icon_state(cls='host', state='unreachable')}} <span class="num">{{sWarning}} <i>({{pctWarning}}% Unreachable)</i></span>
                        </td>
                        <td>
                           {{!helper.get_fa_icon_state(cls='host', state='down')}} <span class="num">{{sCritical}} <i>({{pctCritical}}% Down)</i></span>
                        </td>
                        <td>
                           {{!helper.get_fa_icon_state(cls='host', state='unknown')}} <span class="num">{{sUnknown}} <i>({{pctUnknown}}% Unknown)</i></span>
                        </td>
                        <td>
                           {{!helper.get_fa_icon_state(cls='host', state='ack')}} <span class="num">{{sAck}}</span>
                        </td>
                        <td>
                           {{!helper.get_fa_icon_state(cls='host', state='downtime')}} <span class="num">{{sCriticaltime}}</span>
                        </td>
                     </tr>
                  </tbody>
               </table>
            </div>
            <div class="col-sm-1"></div>
         </div>

%nServices=0
%sOk=sCritical=sWarning=sUnknown=sAck=sCriticaltime=0
%pctOk=pctCritical=pctWarning=pctUnknown=0
%for s in all_services:
   %nServices=nServices+1
   %if s.state == 'OK':
      %sOk=sOk+1
   %elif s.state == 'CRITICAL':
      %sCritical=sCritical+1
   %elif s.state == 'WARNING':
      %sWarning=sWarning+1
   %else:
      %sUnknown=sUnknown+1
   %end
   %if s.problem_has_been_acknowledged:
      %sAck=sAck+1
   %end
   %if s.in_scheduled_downtime:
      %sCriticaltime=sCriticaltime+1
   %end
%end
%if nServices != 0:
   %pctOk         = round(100.0 * sOk / nServices, 2)
   %pctCritical    = round(100.0 * sCritical / nServices, 2)
   %pctWarning   = round(100.0 * sWarning / nServices, 2)
   %pctUnknown    = round(100.0 * sUnknown / nServices, 2)
%end
         %if progress_bar:
         <div class="row">
            <div class="col-sm-12 text-center center-block"><em>... out of {{nServices}} services.</em></div>
            <div class="col-sm-1"></div>
            <div class="progress col-sm-10 no-leftpadding no-rightpadding" style="height: 25px;">
               <div title="{{sOk}} hosts Up" class="progress-bar progress-bar-success quickinfo" role="progressbar" 
                  data-toggle="tooltip" data-placement="bottom" 
                  style="line-height: 25px; width: {{pctOk}}%;">{{pctOk}}% Up</div>
            
               <div title="{{sCritical}} hosts Down" class="progress-bar progress-bar-danger quickinfo" 
                  data-toggle="tooltip" data-placement="bottom" 
                  style="line-height: 25px; width: {{pctCritical}}%;">{{pctCritical}}% Down</div>

               <div title="{{sWarning}} hosts Unreachable" class="progress-bar progress-bar-warning quickinfo" 
                  data-toggle="tooltip" data-placement="bottom" 
                  style="line-height: 25px; width: {{pctWarning}}%;">{{pctWarning}}% Unreachable</div>

               <div title="{{hPending}} hosts Pending" class="progress-bar progress-bar-info quickinfo" 
                  data-toggle="tooltip" data-placement="bottom" 
                  style="line-height: 25px; width: {{pctPending}}%;">{{pctPending}}% Pending</div>

               <div title="{{hPending}} hosts Pending/Unknown" class="progress-bar progress-bar-info quickinfo" 
                  data-toggle="tooltip" data-placement="bottom" 
                  style="line-height: 25px; width: {{pctUnknown}}%;">{{pctUnknown}}% Unknown</div>
            </div>
            <div class="col-sm-1"></div>
         </div>
         %end
         <div class="row">
            <div class="col-sm-12 text-center center-block"><em>... out of {{nServices}} services</em></div>
            <div class="col-sm-1"></div>
            <div class="col-sm-10" >
               <table class="table table-invisible">
                  <tbody>
                     <tr>
                        <td>
                           {{!helper.get_fa_icon_state(cls='host', state='up')}} <span class="num">{{sOk}} <i>({{pctOk}}% Up)</i></span>
                        </td>
                        <td>
                           {{!helper.get_fa_icon_state(cls='host', state='unreachable')}} <span class="num">{{sWarning}} <i>({{pctWarning}}% Unreachable)</i></span>
                        </td>
                        <td>
                           {{!helper.get_fa_icon_state(cls='host', state='down')}} <span class="num">{{sCritical}} <i>({{pctCritical}}% Down)</i></span>
                        </td>
                        <td>
                           {{!helper.get_fa_icon_state(cls='host', state='unknown')}} <span class="num">{{sUnknown}} <i>({{pctUnknown}}% Unknown)</i></span>
                        </td>
                        <td>
                           {{!helper.get_fa_icon_state(cls='host', state='ack')}} <span class="num">{{sAck}}</span>
                        </td>
                        <td>
                           {{!helper.get_fa_icon_state(cls='host', state='downtime')}} <span class="num">{{sCriticaltime}}</span>
                        </td>
                     </tr>
                  </tbody>
               </table>
            </div>
            <div class="col-sm-1"></div>
         </div>
      </div>
   </div>
   <div class="panel panel-default">
      <div class="panel-heading">
         <h3 class="panel-title">{{groupalias}} ({{groupname}})</h3>
      </div>
      
      <div class="panel-body">
   
   <div class="panel panel-default">
      <div class="panel-body">
         <div class='col-lg-12'>
            %include("pagination_element", navi=navi, app=app, page="services-group/"+groupname, div_class="center no-margin")
         </div>

         <table class="table table-hover">
            <tbody>
               <tr>
                  <th>Host</th>
                  <th>Service</th>
                  <th>Last Check</th>
                  <th>Duration</th>
                  <th>Attempt</th>
                  <th>Status Information</th>
               </tr>
               %for s in services:
                  <tr class="service service_{{s.get_name()}} font-{{s.state.lower()}}">
                     <td>{{s.host_name}}</td>
                     <td style="white-space: normal" class="font-{{s.state.lower()}}">
                        <span><a href="/service/{{s.get_name()}}/{{s.get_name()}}">{{s.get_name()}}</a></span>
                     </td>
                     <td>{{helper.print_duration(s.last_chk)}}</td>
                     <td>{{s.get_duration()}}</td>
                     <td>{{s.attempt}}/{{s.max_check_attempts}}</td>
                     <td>{{!helper.get_fa_icon_state(s)}}</td>   
                  </tr>
               %end
            </tbody>
         </table>

         <div class='col-lg-12'>
            %include("pagination_element", navi=navi, app=app, page="services-group/"+groupname, div_class="center no-margin")
         </div>
      </div>
   </div>
</div>

