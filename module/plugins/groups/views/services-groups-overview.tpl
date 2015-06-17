%rebase("layout", css=['groups/css/groups-overview.css'], js=['groups/js/groups-overview.js'], title='Services groups overview', refresh=True)

%helper = app.helper

%from shinken.misc.filter import only_related_to

%services = app.get_services(user)
%s = helper.get_synthesis(services)['services']

<div class="row">
   <div class="pull-left col-sm-2">
      <span class="pull-right">Total services: {{s['nb_elts']}}</span>
   </div>
   <div class="pull-left progress col-sm-8 no-leftpadding no-rightpadding" style="height: 25px;">
      <div title="{{s['nb_ok']}} services Ok" class="progress-bar progress-bar-success quickinfo" role="progressbar" 
         data-toggle="tooltip" data-placement="bottom" 
         style="line-height: 25px; width: {{s['pct_ok']}}%;">{{s['pct_ok']}}% Ok</div>

      <div title="{{s['nb_critical']}} services Critical" class="progress-bar progress-bar-danger quickinfo" 
         data-toggle="tooltip" data-placement="bottom" 
         style="line-height: 25px; width: {{s['pct_critical']}}%;">{{s['pct_critical']}}% Critical</div>

      <div title="{{s['nb_warning']}} services Warning" class="progress-bar progress-bar-warning quickinfo" 
         data-toggle="tooltip" data-placement="bottom" 
         style="line-height: 25px; width: {{s['pct_warning']}}%;">{{s['pct_warning']}}% Warning</div>

      <div title="{{s['nb_pending']}} services Pending" class="progress-bar progress-bar-info quickinfo" 
         data-toggle="tooltip" data-placement="bottom" 
         style="line-height: 25px; width: {{s['pct_pending']}}%;">{{s['pct_pending']}}% Pending</div>

      <div title="{{s['nb_unknown']}} services Unknown" class="progress-bar progress-bar-info quickinfo" 
         data-toggle="tooltip" data-placement="bottom" 
         style="line-height: 25px; width: {{s['pct_unknown']}}%;">{{s['pct_unknown']}}% Unknown</div>
   </div>
   <div class="pull-right col-sm-2">
      <span class="btn-group pull-right">
         <a href="#" id="listview" class="btn btn-small switcher pull-right" data-original-title='List'> <i class="fa fa-align-justify"></i> </a>
         <a href="#" id="gridview" class="btn btn-small switcher active pull-right" data-original-title='Grid'> <i class="fa fa-th"></i> </a>
      </span>
   </div>
</div>

<div class="row">
   <ul id="groups" class="grid row">
      %even='alt'
      %nServices=0
      %sOk=sCritical=sWarning=sPending=sUnknown=sAck=sDowntime=0
      %for s in app.get_services(user):
         %nServices=nServices+1
         %if s.state == 'OK':
            %sOk=sOk+1
         %elif s.state == 'CRITICAL':
            %sCritical=sCritical+1
         %elif s.state == 'WARNING':
            %sWarning=sWarning+1
         %elif s.state == 'PENDING':
            %sPending=sPending+1
         %else:
            %sUnknown=sUnknown+1
         %end
         %if s.problem_has_been_acknowledged:
            %sAck=sAck+1
         %end
         %if s.in_scheduled_downtime:
            %sDowntime=sDowntime+1
         %end
      %end
      %nGroups=len(servicegroups)
      <li class="clearfix {{even}}">
         <section class="left">
            <h3>All services</h3>
            <span class="meta">
               <span class="{{'font-ok' if sOk > 0 else 'font-greyed'}}">
                  {{!helper.get_fa_icon_state(cls='service', state='ok')}}
                  <span class="num">{{sOk}}</span>
               </span> 
                
               <span class="{{'font-warning' if sWarning > 0 else 'font-greyed'}}">
                  {{!helper.get_fa_icon_state(cls='service', state='warning')}} 
                  <span class="num">{{sWarning}}</span>
               </span> 

               <span class="{{'font-critical' if sCritical > 0 else 'font-greyed'}}">
                  {{!helper.get_fa_icon_state(cls='service', state='critical')}} 
                  <span class="num">{{sCritical}}</span>
               </span> 

               <span class="{{'font-pending' if sPending > 0 else 'font-greyed'}}">
                  {{!helper.get_fa_icon_state(cls='service', state='pending')}} 
                  <span class="num">{{sPending}}</span>
               </span> 

               <span class="{{'font-unknown' if sUnknown > 0 else 'font-greyed'}}">
                  {{!helper.get_fa_icon_state(cls='service', state='unknown')}} 
                  <span class="num">{{sUnknown}}</span>
               </span> 
            </span>
         </section>
         
         <section class="right">
            %if nServices == 1:
            <span class="sum">{{nServices}} service</span>
            %else:
            <span class="sum">{{nServices}} services</span>
            %end
            <span class="darkview">
          <a href="/all?search=type:service" class="firstbtn"><i class="fa fa-angle-double-down"></i> Details</a>
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

         %nServices=0
         %sOk=sCritical=sWarning=sPending=sUnknown=sAck=sDowntime=0
         %business_impact = 0
         %for s in group.get_services():
            %business_impact = max(business_impact, h.business_impact)
            %nServices=nServices+1
            %if s.state == 'OK':
               %sOk=sOk+1
            %elif s.state == 'CRITICAL':
               %sCritical=sCritical+1
            %elif s.state == 'WARNING':
               %sWarning=sWarning+1
            %elif s.state == 'PENDING':
               %sPending=sPending+1
            %else:
               %sUnknown=sUnknown+1
            %end
            %if s.problem_has_been_acknowledged:
               %sAck=sAck+1
            %end
            %if s.in_scheduled_downtime:
               %sDowntime=sDowntime+1
            %end
         %end
      
         %nGroups=len(group.get_servicegroup_members())
         <!-- <li>{{group.get_name()}} - {{nServices}} - {{nGroups}} - {{group.get_servicegroup_members()}}</li> -->
         %#if nServices > 0 or nGroups > 0:
           <li class="clearfix {{even}} {{'alert' if nServices == sCritical and nServices != 0 else ''}}">
             <section class="left">
               <h3>{{group.alias if group.alias != '' else group.get_name()}}
                  {{!helper.get_business_impact_text(business_impact)}}
               </h3>
               <span class="meta">
                  <span class="{{'font-ok' if sOk > 0 else 'font-greyed'}}">
                     {{!helper.get_fa_icon_state(cls='service', state='ok')}}
                     <span class="num">{{sOk}}</span>
                  </span> 
                   
                  <span class="{{'font-warning' if sWarning > 0 else 'font-greyed'}}">
                     {{!helper.get_fa_icon_state(cls='service', state='warning')}} 
                     <span class="num">{{sWarning}}</span>
                  </span> 

                  <span class="{{'font-critical' if sCritical > 0 else 'font-greyed'}}">
                     {{!helper.get_fa_icon_state(cls='service', state='critical')}} 
                     <span class="num">{{sCritical}}</span>
                  </span> 

                  <span class="{{'font-pending' if sPending > 0 else 'font-greyed'}}">
                     {{!helper.get_fa_icon_state(cls='service', state='pending')}} 
                     <span class="num">{{sPending}}</span>
                  </span> 

                  <span class="{{'font-unknown' if sUnknown > 0 else 'font-greyed'}}">
                     {{!helper.get_fa_icon_state(cls='service', state='unknown')}} 
                     <span class="num">{{sUnknown}}</span>
                  </span> 
               </span>
             </section>
             
             <section class="right">
               <div class="pull-left">
               <span class="groupLevel">{{'Level %d' % group.level if group.has('level') else 'Root'}}</span>
               </div>
               <div class="pull-right">
                 <span class="sumHosts">{{'%d service' % nServices if nServices == 1 else '%d services' % nServices}}</span>
                 <span class="sumGroups">{{'%d group' % nGroups if nGroups == 1 else '' if nGroups == 0 else '%d groups' % nGroups}}</span>
               </div>
               <span class="darkview">
                 <a href="/all?search=type:host sg:{{group.get_name()}}" class="firstbtn"><i class="fa fa-angle-double-down"></i> Details</a>
                 <br/>
                 <a href="/minemap/{{group.get_name()}}" class="firstbtn"><i class="fa fa-table"></i> Minemap</a>
               </span>
             </section>
           </li>
         %#end
      %end
   </ul>
</div>
