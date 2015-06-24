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
      %nHosts=h['nb_up']
      %nGroups=len(hostgroups)
      <li class="clearfix {{even}} {{'alert' if h['nb_up'] == h['nb_down'] and h['nb_up'] != 0 else ''}}">
         <section class="left">
           <h3>All hosts
               {{!helper.get_business_impact_text(h['bi'])}}
           </h3>
           <span class="meta">
            <span class="{{'font-up' if h['nb_up'] > 0 else 'font-greyed'}}">
               {{!helper.get_fa_icon_state(cls='host', state='up', disabled=(not h['nb_up']))}}
               <span class="num">{{h['nb_up']}}</span>
            </span> 
             
            <span class="{{'font-unreachable' if h['nb_unreachable'] > 0 else 'font-greyed'}}">
               {{!helper.get_fa_icon_state(cls='host', state='unreachable', disabled=(not h['nb_unreachable']))}} 
               <span class="num">{{h['nb_unreachable']}}</span>
            </span> 

            <span class="{{'font-down' if h['nb_down'] > 0 else 'font-greyed'}}">
               {{!helper.get_fa_icon_state(cls='host', state='down', disabled=(not h['nb_down']))}} 
               <span class="num">{{h['nb_down']}}</span>
            </span> 

            <span class="{{'font-unknown' if h['nb_unknown'] > 0 else 'font-greyed'}}">
               {{!helper.get_fa_icon_state(cls='host', state='unknown', disabled=(not h['nb_unknown']))}} 
               <span class="num">{{h['nb_unknown']}}</span>
            </span> 
           </span>
         </section>
         
         <section class="right">
           <div class="pull-right">
             <span class="sumHosts">{{'1 host' if h['nb_elts'] == 1 else '%d hosts' % h['nb_elts']}}</span>
             <span class="sumGroups">{{'1 group' if nGroups == 1 else '' if nGroups == 0 else '%d groups' % nGroups}}</span>
           </div>
           <span class="darkview">
             <a href="/all?search=type:host" class="firstbtn"><i class="fa fa-angle-double-down"></i> Details</a>
             <br/>
             <a href="/minemap" class="firstbtn"><i class="fa fa-table"></i> Minemap</a>
           </span>
         </section>
      </li>
    
      %even='alt'
      %for group in hostgroups:
         %# To be improved ... hosts groups filtering by level
         %#if not hasattr(group, 'level') or (hasattr(group, 'level') and group.level > 0):
         %#continue
         %#end
         %#
         %# Should use filter as bi>3 ...
         %#
         %#
         %hosts = app.search_hosts_and_services('type:host hg:'+group.get_name(), user, hosts_only=True)
         %hosts = app.get_hosts(user)
         %h = helper.get_synthesis(hosts)['hosts']
         %if even =='':
           %even='alt'
         %else:
           %even=''
         %end

         %nHosts=h['nb_up']
         %nGroups=len(group.get_hostgroup_members())
         <!-- <li>{{group.get_name()}} - {{nHosts}} - {{nGroups}} - {{group.get_hostgroup_members()}}</li> -->
         %#if nHosts > 0 or nGroups > 0:
        
         <li class="clearfix {{even}} {{'alert' if h['nb_up'] == h['nb_down'] and h['nb_up'] != 0 else ''}}">
            <section class="left">
               <h3>{{group.alias if group.alias != '' else group.get_name()}}
                  {{!helper.get_business_impact_text(h['bi'])}}
               </h3>
               <span class="meta">
                  <span class="{{'font-up' if h['nb_up'] > 0 else 'font-greyed'}}">
                     {{!helper.get_fa_icon_state(cls='host', state='up', disabled=(not h['nb_up']))}}
                     <span class="num">{{h['nb_up']}}</span>
                  </span> 
                
                  <span class="{{'font-unreachable' if h['nb_unreachable'] > 0 else 'font-greyed'}}">
                     {{!helper.get_fa_icon_state(cls='host', state='unreachable', disabled=(not h['nb_unreachable']))}} 
                     <span class="num">{{h['nb_unreachable']}}</span>
                  </span> 

                  <span class="{{'font-down' if h['nb_down'] > 0 else 'font-greyed'}}">
                     {{!helper.get_fa_icon_state(cls='host', state='down', disabled=(not h['nb_down']))}} 
                     <span class="num">{{h['nb_down']}}</span>
                  </span> 

                  <span class="{{'font-unknown' if h['nb_unknown'] > 0 else 'font-greyed'}}">
                     {{!helper.get_fa_icon_state(cls='host', state='unknown', disabled=(not h['nb_unknown']))}} 
                     <span class="num">{{h['nb_unknown']}}</span>
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
               <a href="/minemap?search=type:host hg:{{group.get_name()}}" class="firstbtn"><i class="fa fa-table"></i> Minemap</a>
            </span>
          </section>
        </li>
         %#end
      %end
   </ul>
</div>
