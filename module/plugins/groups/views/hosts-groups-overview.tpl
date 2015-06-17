%rebase("layout", css=['groups/css/groups-overview.css'], js=['groups/js/groups-overview.js'], title='Hosts groups overview', refresh=True)

%helper = app.helper

%from shinken.misc.filter import only_related_to

%hosts = app.get_hosts(user)
%h = helper.get_synthesis(hosts)['hosts']

<div class="row">
   <div class="pull-left col-sm-2">
      <span class="pull-right">Total hosts: {{h['nb_elts']}}</span>
   </div>
   <div class="pull-left progress col-sm-8 no-leftpadding no-rightpadding" style="height: 25px;">
      <div title="{{h['nb_up']}} hosts Up" class="progress-bar progress-bar-success quickinfo" role="progressbar" 
         data-toggle="tooltip" data-placement="bottom" 
         style="line-height: 25px; width: {{h['pct_up']}}%;">{{h['pct_up']}}% Up</div>

      <div title="{{h['nb_down']}} hosts Down" class="progress-bar progress-bar-danger quickinfo" 
         data-toggle="tooltip" data-placement="bottom" 
         style="line-height: 25px; width: {{h['pct_down']}}%;">{{h['pct_down']}}% Down</div>

      <div title="{{h['nb_unreachable']}} hosts Unreachable" class="progress-bar progress-bar-warning quickinfo" 
         data-toggle="tooltip" data-placement="bottom" 
         style="line-height: 25px; width: {{h['pct_unreachable']}}%;">{{h['pct_unreachable']}}% Unreachable</div>

      <div title="{{h['nb_pending']}} hosts Pending" class="progress-bar progress-bar-info quickinfo" 
         data-toggle="tooltip" data-placement="bottom" 
         style="line-height: 25px; width: {{h['pct_pending']}}%;">{{h['pct_pending']}}% Pending</div>

      <div title="{{h['nb_unknown']}} hosts Unknown" class="progress-bar progress-bar-info quickinfo" 
         data-toggle="tooltip" data-placement="bottom" 
         style="line-height: 25px; width: {{h['pct_unknown']}}%;">{{h['pct_unknown']}}% Unknown</div>
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
    %nGroups=0
    %nHosts=0
    %hUp=hDown=hUnreachable=hUnknown=hAck=hDowntime=0
    %for h in hosts:
      %nHosts=nHosts+1
      %if h.state == 'UP':
        %hUp=hUp+1
      %elif h.state == 'DOWN':
        %hDown=hDown+1
      %elif h.state == 'UNREACHABLE':
        %hUnreachable=hUnreachable+1
      %else:
        %hUnknown=hUnknown+1
      %end
      %if h.problem_has_been_acknowledged:
         %hAck=hAck+1
      %end
      %if h.in_scheduled_downtime:
         %hDowntime=hDowntime+1
      %end
    %end
    %nGroups=len(hostgroups)
    <li class="clearfix {{even}}">
      <section class="left">
        <h3>All hosts</h3>
        <span class="meta">
         <span class="{{'font-up' if hUp > 0 else 'font-greyed'}}">
            {{!helper.get_fa_icon_state(cls='host', state='up', disabled=(not hUp))}}
            <span class="num">{{hUp}}</span>
         </span> 
          
         <span class="{{'font-unreachable' if hUnreachable > 0 else 'font-greyed'}}">
            {{!helper.get_fa_icon_state(cls='host', state='unreachable', disabled=(not hUnreachable))}} 
            <span class="num">{{hUnreachable}}</span>
         </span> 

         <span class="{{'font-down' if hDown > 0 else 'font-greyed'}}">
            {{!helper.get_fa_icon_state(cls='host', state='down', disabled=(not hDown))}} 
            <span class="num">{{hDown}}</span>
         </span> 

         <span class="{{'font-unknown' if hUnknown > 0 else 'font-greyed'}}">
            {{!helper.get_fa_icon_state(cls='host', state='unknown', disabled=(not hUnknown))}} 
            <span class="num">{{hUnknown}}</span>
         </span> 
        </span>
      </section>
      
      <section class="right">
        <div class="pull-right">
          <span class="sumHosts">{{'%d host' % nHosts if nHosts == 1 else '%d hosts' % nHosts}}</span>
          <span class="sumGroups">{{'%d group' % nGroups if nGroups == 1 else '' if nGroups == 0 else '%d groups' % nGroups}}</span>
        </div>
        <span class="darkview">
          <a href="/all?search=type:host" class="firstbtn"><i class="fa fa-angle-double-down"></i> Details</a>
          <br/>
          <a href="/minemap/all" class="firstbtn"><i class="fa fa-table"></i> Minemap</a>
        </span>
      </section>
    </li>
    
    %even='alt'
    %for group in hostgroups:
      %# To be improved ... hosts groups filtering by level
      %#if not hasattr(group, 'level') or (hasattr(group, 'level') and group.level > 0):
      %#continue
      %#end
      %if even =='':
        %even='alt'
      %else:
        %even=''
      %end

      %nHosts=0
      %hosts=only_related_to(group.get_hosts(),user)
      %hUp=hDown=hUnreachable=hUnknown=hAck=hDowntime=0
      %business_impact = 0
      %for h in hosts:
        %business_impact = max(business_impact, h.business_impact)
        %nHosts=nHosts+1
        %if h.state == 'UP':
          %hUp=hUp+1
        %elif h.state == 'DOWN':
          %hDown=hDown+1
        %elif h.state == 'UNREACHABLE':
          %hUnreachable=hUnreachable+1
        %else:
          %hUnknown=hUnknown+1
        %end
      %end
      
      %nGroups=len(group.get_hostgroup_members())
      <!-- <li>{{group.get_name()}} - {{nHosts}} - {{nGroups}} - {{group.get_hostgroup_members()}}</li> -->
      %#if nHosts > 0 or nGroups > 0:
        
         <li class="clearfix {{even}} {{'alert' if nHosts == hDown and nHosts != 0 else ''}}">
            <section class="left">
               <h3>{{group.alias if group.alias != '' else group.get_name()}}
                  {{!helper.get_business_impact_text(business_impact)}}
               </h3>
               <span class="meta">
                  <span class="{{'font-up' if hUp > 0 else 'font-greyed'}}">
                     {{!helper.get_fa_icon_state(cls='host', state='up', disabled=(not hUp))}}
                     <span class="num">{{hUp}}</span>
                  </span> 
                   
                  <span class="{{'font-unreachable' if hUnreachable > 0 else 'font-greyed'}}">
                     {{!helper.get_fa_icon_state(cls='host', state='unreachable', disabled=(not hUnreachable))}} 
                     <span class="num">{{hUnreachable}}</span>
                  </span> 

                  <span class="{{'font-down' if hDown > 0 else 'font-greyed'}}">
                     {{!helper.get_fa_icon_state(cls='host', state='down', disabled=(not hDown))}} 
                     <span class="num">{{hDown}}</span>
                  </span> 

                  <span class="{{'font-unknown' if hUnknown > 0 else 'font-greyed'}}">
                     {{!helper.get_fa_icon_state(cls='host', state='unknown', disabled=(not hUnknown))}} 
                     <span class="num">{{hUnknown}}</span>
                  </span> 
               </span>
            </section>
          
            <section class="right">
               <div class="pull-left">
               <span class="groupLevel">{{'Level %d' % group.level if group.has('level') else 'Root'}}</span>
               </div>
               <div class="pull-right">
               <span class="sumHosts">{{'%d host' % nHosts if nHosts == 1 else '%d hosts' % nHosts}}</span>
               <span class="sumGroups">{{'%d group' % nGroups if nGroups == 1 else '' if nGroups == 0 else '%d groups' % nGroups}}</span>
               </div>
            <span class="darkview">
               <a href="/all?search=type:host hg:{{group.get_name()}}" class="firstbtn"><i class="fa fa-angle-double-down"></i> Details</a>
               <br/>
               <a href="/minemap/{{group.get_name()}}" class="firstbtn"><i class="fa fa-table"></i> Minemap</a>
            </span>
          </section>
        </li>
      %#end
    %end
  </ul>
</div>
