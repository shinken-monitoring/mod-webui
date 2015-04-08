%rebase layout globals(), css=['groups/css/groups-overview.css'], js=['groups/js/groups-overview.js'], title='Services groups overview', refresh=True

%helper = app.helper
%datamgr = app.datamgr

<div class="row">
  <span class="btn-group pull-right">
    <a href="#" id="listview" class="btn btn-small switcher quickinfo pull-right" data-original-title='List'> <i class="fa fa-align-justify"></i> </a>
    <a href="#" id="gridview" class="btn btn-small switcher active quickinfo pull-right" data-original-title='Grid'> <i class="fa fa-th"></i> </a>
  </span>
</div>

<div class="row">
   <ul id="groups" class="grid row">
      %even='alt'
      %nGroups=0
      %nServices=0
      %sOk=0
      %sCritical=0
      %sWarning=0
      %sPenging=0
      %for h in datamgr.get_services():
         %nServices=nServices+1
         %if h.state == 'OK':
            %sOk=sOk+1
         %elif h.state == 'CRITICAL':
            %sCritical=sCritical+1
         %elif h.state == 'WARNING':
            %sWarning=sWarning+1
         %else:
            %sPenging=sPenging+1
         %end
      %end
    %for group in servicegroups:
      %nGroups=nGroups+1
    %end
      <li class="clearfix {{even}}">
         <section class="left">
            <h3>All services</h3>
              <span class="meta">
               %if sOk > 0:
                  <span class="fa-stack font-ok"> <i class="fa fa-circle fa-stack-2x"></i> <i class="fa fa-check fa-stack-1x fa-inverse"></i></span> 
                  <span class="num">{{sOk}}</span>
               %else:
                  <span class="fa-stack font-greyed"> <i class="fa fa-circle fa-stack-2x"></i> <i class="fa fa-check fa-stack-1x fa-inverse"></i></span> 
                  <span class="num"><em>{{sOk}}</em></span>
               %end

               %if sWarning > 0:
                  <span class="fa-stack font-warning"> <i class="fa fa-circle fa-stack-2x"></i> <i class="fa fa-check fa-stack-1x fa-inverse"></i></span> 
                  <span class="num">{{sWarning}}</span>
               %else:
                  <span class="fa-stack font-greyed"> <i class="fa fa-circle fa-stack-2x"></i> <i class="fa fa-check fa-stack-1x fa-inverse"></i></span> 
                  <span class="num"><em>{{sWarning}}</em></span>
               %end

               %if sCritical > 0:
                  <span class="fa-stack font-critical"> <i class="fa fa-circle fa-stack-2x"></i> <i class="fa fa-check fa-stack-1x fa-inverse"></i></span> 
                  <span class="num">{{sCritical}}</span>
               %else:
                  <span class="fa-stack font-greyed"> <i class="fa fa-circle fa-stack-2x"></i> <i class="fa fa-check fa-stack-1x fa-inverse"></i></span> 
                  <span class="num"><em>{{sCritical}}</em></span>
               %end

               %if sPenging > 0:
                  <span class="fa-stack font-pending"> <i class="fa fa-circle fa-stack-2x"></i> <i class="fa fa-check fa-stack-1x fa-inverse"></i></span> 
                  <span class="num">{{sPenging}}</span>
               %else:
                  <span class="fa-stack font-greyed"> <i class="fa fa-circle fa-stack-2x"></i> <i class="fa fa-check fa-stack-1x fa-inverse"></i></span> 
                  <span class="num"><em>{{sPenging}}</em></span>
               %end
              </span>
        <!--
        <span class="meta"> <span class="label label-important pulsate">Business impact</span> </span>
        -->
         </section>
         
         <section class="right">
            %if nServices == 1:
            <span class="sum">{{nServices}} service</span>
            %else:
            <span class="sum">{{nServices}} services</span>
            %end
            <span class="darkview">
          <a href="/services-group/all" class="firstbtn"><i class="fa fa-angle-double-down"></i> Details</a>
          <br/>
          <a href="/minemap/all" class="firstbtn"><i class="fa fa-table"></i> Minemap</a>
            </span>
         </section>
      </li>

      %even='alt'
      %for group in servicegroups:
         %if even =='':
            %even='alt'
         %else:
            %even=''
         %end

      %nGroups=0
         %nServices=0
         %sOk=0
         %sCritical=0
         %sWarning=0
         %sPenging=0 # Pending / unknown
         %business_impact = 0
         %for h in group.get_services():
            %business_impact = max(business_impact, h.business_impact)
            %nServices=nServices+1
            %if h.state == 'OK':
               %sOk=sOk+1
            %elif h.state == 'CRITICAL':
               %sCritical=sCritical+1
            %elif h.state == 'WARNING':
               %sWarning=sWarning+1
            %else:
               %sPenging=sPenging+1
            %end
         %end
      
      %for h in group.get_servicegroup_members():
        %nGroups=nGroups+1
      %end
      <!-- <li>{{group.get_name()}} - {{nServices}} - {{nGroups}} - {{group.get_servicegroup_members()}}</li> -->
      %if nServices > 0 or nGroups > 0:
        <li class="clearfix {{even}}">
          <section class="left">
            <h3>{{group.alias if group.alias != '' else group.get_name()}}
               %for i in range(0, business_impact-2):
               <img alt="icon state" src="/static/images/star.png">
               %end
            </h3>
            <span class="meta">
               <span class="{{'font-ok' if sOk > 0 else 'font-greyed'}}">
                  <span class="fa-stack"><i class="fa fa-circle fa-stack-2x"></i> <i class="fa fa-check fa-stack-1x fa-inverse"></i></span> 
                  <span class="num">{{sOk}}</span>
               </span> 
                
               <span class="{{'font-warning' if hUnreachable > 0 else 'font-greyed'}}">
                  <span class="fa-stack"> <i class="fa fa-circle fa-stack-2x"></i> <i class="fa fa-exclamation fa-stack-1x fa-inverse"></i></span> 
                  <span class="num">{{sWarning}}</span>
               </span> 

               <span class="{{'font-critical' if sCritical > 0 else 'font-greyed'}}">
                  <span class="fa-stack"> <i class="fa fa-circle fa-stack-2x"></i> <i class="fa fa-arrow-down fa-stack-1x fa-inverse"></i></span> 
                  <span class="num">{{sCritical}}</span>
               </span> 

               <span class="{{'font-pending' if sPending > 0 else 'font-greyed'}}">
                  <span class="fa-stack"> <i class="fa fa-circle fa-stack-2x"></i> <i class="fa fa-question fa-stack-1x fa-inverse"></i></span> 
                  <span class="num">{{sPending}}</span>
               </span> 
            </span>
          </section>
          
          <section class="right">
            <div class="pull-right">
              <span class="sumHosts">{{'%d service' % nServices if nServices == 1 else '%d services' % nServices}}</span>
              <span class="sumGroups">{{'%d group' % nGroups if nGroups == 1 else '' if nGroups == 0 else '%d groups' % nGroups}}</span>
            </div>
            <span class="darkview">
              <a href="/services-group/{{group.get_name()}}" class="firstbtn"><i class="fa fa-angle-double-down"></i> Details</a>
              <br/>
              <a href="/minemap/{{group.get_name()}}" class="firstbtn"><i class="fa fa-table"></i> Minemap</a>
            </span>
          </section>
        </li>
      %end
      %end
   </ul>
</div>