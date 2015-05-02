%# If got no group, bailout
%if not group:
%rebase layout title='Invalid group name'

Invalid group name

%else:

%if group=='all':
%groupname = 'all'
%groupalias = 'All hosts'
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
%rebase layout globals(), title='Hosts group detail for ' + groupalias, css=['groups/css/groups-overview.css'], refresh=True, breadcrumb=[ ['All groups', '/hosts-groups'], [groupalias, '/minemap/'+groupname] ]

<div id="content_container">
   <div class="panel panel-default">
      <div class="panel-heading">
         <h3 class="panel-title">{{groupalias}} ({{groupname}})</h3>
      </div>
      <div class="panel-body">
%nHosts=0
%hUp=hDown=hUnreachable=hPending=hUnknown=0
%pctUp=pctDown=pctUnreachable=pctPending=pctUnknown=0
%for h in hosts:
   %nHosts=nHosts+1
   %if h.state == 'UP':
      %hUp=hUp+1
   %elif h.state == 'DOWN':
      %hDown=hDown+1
   %elif h.state == 'UNREACHABLE':
      %hUnreachable=hUnreachable+1
   %elif h.state == 'PENDING':
      %hPending=hPending+1
   %else:
      %hUnknown=hUnknown+1
   %end
%end
%if nHosts != 0:
   %pctUp         = round(100.0 * hUp / nHosts, 2)
   %pctDown    = round(100.0 * hDown / nHosts, 2)
   %pctUnreachable   = round(100.0 * hUnreachable / nHosts, 2)
   %pctPending    = round(100.0 * hPending / nHosts, 2)
   %pctUnknown    = round(100.0 * hUnknown / nHosts, 2)
%end
         <div class="row">
           <div class="col-sm-12 text-center center-block"><em>Currently displaying {{nHosts}} hosts ...</em></div>
           <div class="col-sm-1"></div>
           <div class="progress col-sm-10 no-bottommargin no-leftpadding no-rightpadding" style="height: 45px;">
             <div title="{{hUp}} hosts Up" class="progress-bar progress-bar-success quickinfo" role="progressbar" 
               data-toggle="tooltip" data-placement="bottom" 
               style="line-height: 45px; width: {{pctUp}}%;">{{pctUp}}% Up</div>
               
             <div title="{{hDown}} hosts Down" class="progress-bar progress-bar-danger quickinfo" 
               data-toggle="tooltip" data-placement="bottom" 
               style="line-height: 45px; width: {{pctDown}}%;">{{pctDown}}% Down</div>
               
             <div title="{{hUnreachable}} hosts Unreachable" class="progress-bar progress-bar-warning quickinfo" 
               data-toggle="tooltip" data-placement="bottom" 
               style="line-height: 45px; width: {{pctUnreachable}}%;">{{pctUnreachable}}% Unreachable</div>
               
             <div title="{{hPending}} hosts Pending" class="progress-bar progress-bar-info quickinfo" 
               data-toggle="tooltip" data-placement="bottom" 
               style="line-height: 45px; width: {{pctPending}}%;">{{pctPending}}% Pending</div>
               
             <div title="{{hPending}} hosts Pending/Unknown" class="progress-bar progress-bar-info quickinfo" 
               data-toggle="tooltip" data-placement="bottom" 
               style="line-height: 45px; width: {{pctPending}}%;">{{pctUnknown}}% Unknown</div>
           </div>
           <div class="col-sm-1"></div>
         </div>

%nHosts=0
%hUp=hDown=hUnreachable=hPending=hUnknown=0
%pctUp=pctDown=pctUnreachable=pctPending=pctUnknown=0
%for h in all_hosts:
   %nHosts=nHosts+1
   %if h.state == 'UP':
      %hUp=hUp+1
   %elif h.state == 'DOWN':
      %hDown=hDown+1
   %elif h.state == 'UNREACHABLE':
      %hUnreachable=hUnreachable+1
   %elif h.state == 'PENDING':
      %hPending=hPending+1
   %else:
      %hUnknown=hUnknown+1
   %end
%end
%if nHosts != 0:
   %pctUp         = round(100.0 * hUp / nHosts, 2)
   %pctDown    = round(100.0 * hDown / nHosts, 2)
   %pctUnreachable   = round(100.0 * hUnreachable / nHosts, 2)
   %pctPending    = round(100.0 * hPending / nHosts, 2)
   %pctUnknown    = round(100.0 * hUnknown / nHosts, 2)
%end
         <div class="row">
        <div class="col-sm-12 text-center center-block"><em>... out of {{length}} hosts</em></div>
        <div class="col-sm-1"></div>
        <div class="progress col-sm-10 no-leftpadding no-rightpadding" style="height: 25px;">
          <div title="{{hUp}} hosts Up" class="progress-bar progress-bar-success quickinfo" role="progressbar" 
            data-toggle="tooltip" data-placement="bottom" 
            style="line-height: 25px; width: {{pctUp}}%;">{{pctUp}}% Up</div>
            
          <div title="{{hDown}} hosts Down" class="progress-bar progress-bar-danger quickinfo" 
            data-toggle="tooltip" data-placement="bottom" 
            style="line-height: 25px; width: {{pctDown}}%;">{{pctDown}}% Down</div>
            
          <div title="{{hUnreachable}} hosts Unreachable" class="progress-bar progress-bar-warning quickinfo" 
            data-toggle="tooltip" data-placement="bottom" 
            style="line-height: 25px; width: {{pctUnreachable}}%;">{{pctUnreachable}}% Unreachable</div>
            
          <div title="{{hPending}} hosts Pending" class="progress-bar progress-bar-info quickinfo" 
            data-toggle="tooltip" data-placement="bottom" 
            style="line-height: 25px; width: {{pctPending}}%;">{{pctPending}}% Pending</div>
            
          <div title="{{hPending}} hosts Pending/Unknown" class="progress-bar progress-bar-info quickinfo" 
            data-toggle="tooltip" data-placement="bottom" 
            style="line-height: 25px; width: {{pctPending}}%;">{{pctUnknown}}% Unknown</div>
        </div>
        <div class="col-sm-1"></div>
         </div>
      </div>
   </div>

   <div class='col-lg-12'>
      %include pagination_element navi=navi, app=app, page="hosts-group/"+groupname, div_class="center no-margin"
   </div>

   <div class="clearfix">
      <table class="table table-hover">
         <tbody>
            <tr>
               <th>Host</th>
               <th>Service</th>
               <th>State</th>
               <th>Last Check</th>
               <th>Duration</th>
               <th>Attempt</th>
               <th>Status Information</th>
            </tr>
            %for h in hosts:
               <tr id="host_{{h.get_name()}}" class="font-{{h.state.lower()}}">
                  <td>
                     <span><a href="/host/{{h.get_name()}}">{{h.get_name()}}</a></span>
                  </td>
                  <td style="white-space: normal">
                     <span>{{h.get_check_command()}}</span>
                  </td>
                  <td >{{h.state}}</td>
                  <td>{{helper.print_duration(h.last_chk)}}</td>
                  <td>{{h.get_duration()}}</td>
                  <td>{{h.attempt}}/{{h.max_check_attempts}}</td>
                  <td><span class="{{h.state.lower()}}">{{h.state}}</span></td>  
               </tr>
               %for s in h.services:
                  <tr class="service service_{{h.get_name()}} font-{{s.state.lower()}}" style="display: none;">
                     <td></td>
                     <td></td>

                     <td style="white-space: normal" class="font-{{s.state.lower()}}">
                        <span><a href="/service/{{h.get_name()}}/{{s.get_name()}}">{{s.get_name()}}</a></span>
                     </td>
                     <td>{{helper.print_duration(s.last_chk)}}</td>
                     <td>{{s.get_duration()}}</td>
                     <td>{{s.attempt}}/{{s.max_check_attempts}}</td>
                     <td><span class="font-{{s.state.lower()}}">{{s.state}}</span></td>   
                  </tr>
               %end
            %end
         </tbody>
      </table>
   </div>

   <div class='col-lg-12'>
      %include pagination_element navi=navi, app=app, page="hosts-group/"+groupname, div_class="center no-margin"
   </div>
</div>


<script type="text/javascript">
   $(document).ready(function(){
%for h in hosts:
      $('#host_{{h.get_name()}}').click(function() {
         $(".service_{{h.get_name()}}").toggle();
      });
%end
    // Buttons tooltips
    $('div.progress-bar').tooltip();
  });
</script>
