%rebase layout globals(), css=['groups/css/groups-overview.css'], js=['groups/js/groups-overview.js'], title='Hosts groups overview', menu_part='', refresh=True

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
    %even=''
    %nGroups=0
    %nHosts=0
    %hUp=0
    %hDown=0
    %hUnreachable=0
    %hPending=0 # Pending / unknown
    %for h in datamgr.get_hosts():
      %nHosts=nHosts+1
      %if h.state == 'UP':
        %hUp=hUp+1
      %elif h.state == 'DOWN':
        %hDown=hDown+1
      %elif h.state == 'UNREACHABLE':
        %hUnreachable=hUnreachable+1
      %else:
        %hPending=hPending+1
      %end
    %end
    %for group in hgroups:
      %nGroups=nGroups+1
    %end
    <li class="clearfix {{even}}">
      <section class="left">
        <h3>All hosts</h3>
        <span class="meta">
          <span class="fa-stack font-up"> <i class="fa fa-circle fa-stack-2x"></i> <i class="fa fa-check fa-stack-1x fa-inverse"></i></span> 
          <span class="num">
            %if hUp > 0:
            {{hUp}}
            %else:
            <em>{{hUp}}</em>
            %end
          </span>
          <span class="fa-stack font-unreachable"> <i class="fa fa-circle fa-stack-2x"></i> <i class="fa fa-exclamation fa-stack-1x fa-inverse"></i></span> 
          <span class="num">
            %if hUnreachable > 0:
            {{hUnreachable}}
            %else:
            <em>{{hUnreachable}}</em>
            %end
          </span>
          <span class="fa-stack font-down"> <i class="fa fa-circle fa-stack-2x"></i> <i class="fa fa-arrow-down fa-stack-1x fa-inverse"></i></span> 
          <span class="num">
            %if hDown > 0:
            {{hDown}}
            %else:
            <em>{{hDown}}</em>
            %end
          </span> 
          <span class="fa-stack font-unknown"> <i class="fa fa-circle fa-stack-2x"></i> <i class="fa fa-question fa-stack-1x fa-inverse"></i></span> 
          <span class="num">
            %if hPending > 0:
            {{hPending}}
            %else:
            <em>{{hPending}}</em>
            %end
          </span>
        </span>
        <!--
        <span class="meta"> <span class="label label-important pulsate">Business impact</span> </span>
        -->
      </section>
      
      <section class="right">
        <div class="pull-right">
          <span class="sumHosts">{{'%d host' % nHosts if nHosts == 1 else '%d hosts' % nHosts}}</span>
          <span class="sumGroups">{{'%d group' % nGroups if nGroups == 1 else '' if nGroups == 0 else '%d groups' % nGroups}}</span>
        </div>
        <span class="darkview">
          <a href="/hostgroup/all" class="firstbtn"><i class="fa fa-angle-double-down"></i> Details</a>
          <a href="/minemap/all" class="firstbtn"><i class="fa fa-table"></i> Minemap</a>
        </span>
      </section>
    </li>

    %even='alt'
    %for group in hgroups:
      %if even =='':
        %even='alt'
      %else:
        %even=''
      %end

      %nGroups=0
      %nHosts=0
      %hUp=0
      %hDown=0
      %hUnreachable=0
      %hPending=0
      %business_impact = 0
      %for h in group.get_hosts():
        %business_impact = max(business_impact, h.business_impact)
        %nHosts=nHosts+1
        %if h.state == 'UP':
          %hUp=hUp+1
        %elif h.state == 'DOWN':
          %hDown=hDown+1
        %elif h.state == 'UNREACHABLE':
          %hUnreachable=hUnreachable+1
        %else:
          %hPending=hPending+1
        %end
      %end
      
      %for h in group.get_hostgroup_members():
        %nGroups=nGroups+1
      %end
      <!-- <li>{{group.get_name()}} - {{nHosts}} - {{nGroups}} - {{group.get_hostgroup_members()}}</li> -->
      %if nHosts > 0 or nGroups > 0:
        <li class="clearfix {{even}}">
          <section class="left">
            <h3>{{group.alias if group.alias != '' else group.get_name()}}
              %for i in range(0, business_impact-2):
              <img alt="icon state" src="/static/images/star.png">
              %end
            </h3>
            <span class="meta">
              <span class="fa-stack font-up"> <i class="fa fa-circle fa-stack-2x"></i> <i class="fa fa-check fa-stack-1x fa-inverse"></i></span> 
              <span class="num">
                %if hUp > 0:
                {{hUp}}
                %else:
                <em>{{hUp}}</em>
                %end
              </span>
              <span class="fa-stack font-unreachable"> <i class="fa fa-circle fa-stack-2x"></i> <i class="fa fa-exclamation fa-stack-1x fa-inverse"></i></span> 
              <span class="num">
                %if hUnreachable > 0:
                {{hUnreachable}}
                %else:
                <em>{{hUnreachable}}</em>
                %end
              </span>
              <span class="fa-stack font-down"> <i class="fa fa-circle fa-stack-2x"></i> <i class="fa fa-arrow-down fa-stack-1x fa-inverse"></i></span> 
              <span class="num">
                %if hDown > 0:
                {{hDown}}
                %else:
                <em>{{hDown}}</em>
                %end
              </span> 
              <span class="fa-stack font-unknown"> <i class="fa fa-circle fa-stack-2x"></i> <i class="fa fa-question fa-stack-1x fa-inverse"></i></span> 
              <span class="num">
                %if hPending > 0:
                {{hPending}}
                %else:
                <em>{{hPending}}</em>
                %end
              </span>
            </span>
          </section>
          
          <section class="right">
            <div class="pull-right">
              <span class="sumHosts">{{'%d host' % nHosts if nHosts == 1 else '%d hosts' % nHosts}}</span>
              <span class="sumGroups">{{'%d group' % nGroups if nGroups == 1 else '' if nGroups == 0 else '%d groups' % nGroups}}</span>
            </div>
            <span class="darkview">
              <a href="/hostgroup/{{group.get_name()}}" class="firstbtn"><i class="fa fa-angle-double-down"></i> Details</a>
              <a href="/minemap/{{group.get_name()}}" class="firstbtn"><i class="fa fa-table"></i> Minemap</a>
            </span>
          </section>
        </li>
      %end
    %end
  </ul>
</div>