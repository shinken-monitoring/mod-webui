%groupname = 'all'
%groupalias = 'All hosts'
%title = 'Minemap for all hosts'

%helper = app.helper

%# Specific content for breadrumb
%rebase("layout", title='Minemap for hosts/services', css=['minemap/css/minemap.css'], breadcrumb=[ ['All hosts', '/minemap'] ])


<div id="minemap">
   %if not items:
      <center>
         %if search_string:
         <h3>Bummer, we couldn't find anything.</h3>
         Use the filters or the bookmarks to find what you are looking for, or try a new search query.
         %else:
         <h3>No host or service.</h3>
         %end
      </center>
   %else:
      %#rows and columns will contain, respectively, all different hosts and all different services ...
      %rows = []
      %columns = []

      %for h in items:
         %if h.my_type=='service':
            %if not h.host_name in rows:
               %rows.append(h.host_name)
            %end
            %if not h.get_name() in columns:
               %columns.append(h.get_name())
            %end
         %elif h.my_type=='host':
            %if not h.get_name() in rows:
               %rows.append(h.get_name())
               %for s in h.services:
                  %columns.append(s.get_name())
               %end
            %end
         %end
      %end
      %rows.sort()
      %import collections
      %columns = collections.Counter(columns)
      %columns = [c for c, i in columns.most_common()]

      %synthesis = helper.get_synthesis(items)
      %s = synthesis['services']
      %h = synthesis['hosts']
      
      <!-- Problems synthesis -->
      <div class="panel panel-default">
         <div class="panel-heading">
            <h3 class="panel-title">Current filtered hosts/services:</h3>
         </div>
         <div class="panel-body">
            <table class="table table-invisible table-condensed">
               <tbody>
                 %if 'type:service' not in search_string:
                  <tr>
                     <td>
                     <b>{{h['nb_elts']}} hosts:&nbsp;</b> 
                     </td>
                   
                     %for state in 'up', 'unreachable', 'down', 'pending', 'unknown', 'ack', 'downtime':
                     <td>
                       %label = "%s <i>(%s%%)</i>" % (h['nb_' + state], h['pct_' + state])
                       {{!helper.get_fa_icon_state_and_label(cls='host', state=state, label=label, disabled=(not h['nb_' + state]))}}
                     </td>
                     %end
                  </tr>
                  %end
                  %if 'type:host' not in search_string:
                  <tr>
                     <td>
                        <b>{{s['nb_elts']}} services:&nbsp;</b> 
                     </td>
                
                     %for state in 'ok', 'warning', 'critical', 'pending', 'unknown', 'ack', 'downtime':
                     <td>
                       %label = "%s <i>(%s%%)</i>" % (s['nb_' + state], s['pct_' + state])
                       {{!helper.get_fa_icon_state_and_label(cls='service', state=state, label=label, disabled=(not s['nb_' + state]))}}
                     </td>
                     %end
                  </tr>
                  %end
               </tbody>
            </table>
         </div>
      </div>

<!--
      <div class="panel panel-default">
         <div class="panel-heading">
            <h3 class="panel-title">Current filtered hosts</h3>
         </div>
         <div class="panel-body">
            <div class="pull-left col-lg-2" style="height: 45px;">
               <span>Members:</span>
               <span>{{h['nb_elts']}} hosts</span>
            </div>
            <div class="pull-right progress col-lg-6 no-bottommargin no-leftpadding no-rightpadding" style="height: 45px;">
               <div title="{{h['nb_up']}} hosts Up" class="progress-bar progress-bar-success quickinfo" role="progressbar" 
                  data-original-title="{{h['nb_up']}} Up"
                  style="width: {{h['pct_up']}}%; vertical-align:midddle; line-height: 45px;">{{h['pct_up']}}% Up</div>
               <div title="{{h['nb_down']}} hosts Down" class="progress-bar progress-bar-danger quickinfo" 
                  data-original-title="{{h['pct_down']}} Down"
                  style="width: {{h['pct_down']}}%; vertical-align:midddle; line-height: 45px;">{{h['pct_down']}}% Down</div>
               <div title="{{h['nb_unreachable']}} hosts Unreachable" class="progress-bar progress-bar-warning quickinfo" 
                  data-original-title="{{h['nb_unreachable']}} Unreachable" 
                  style="width: {{h['pct_unreachable']}}%; vertical-align:midddle; line-height: 45px;">{{h['pct_unreachable']}}% Unreachable</div>
               <div title="{{h['nb_pending'] + h['nb_unknown']}} hosts Pending/Unknown" class="progress-bar progress-bar-info quickinfo" 
                  data-original-title="{{h['nb_pending'] + h['nb_unknown']}} Pending / Unknown"
                  style="width: {{h['pct_pending'] + h['pct_unknown']}}%; vertical-align:midddle; line-height: 45px;">{{h['pct_pending'] + h['pct_unknown']}}% Pending or Unknown</div>
            </div>
         </div>
      </div>
-->

      <table class="table table-hover minemap">
         <thead>
            <tr>
               <th></th>
               %for c in columns:
                  <th class="vertical">
                  <div class="rotated-text"><span class="rotated-text__inner">
                     <a href="/all?search=type:service {{c}}">{{c}}</a>
                  </span></div>
                  </th>
               %end
            </tr>
         </thead>
         <tbody>
            %for r in rows:
               %h = app.datamgr.get_host(r, user)
               %if h:
               <tr>
                  <td title="{{h.get_name()}} - {{h.state}} - {{helper.print_duration(h.last_chk)}} - {{h.output}}">
                     <a href="/host/{{h.get_name()}}">
                        {{!helper.get_fa_icon_state(h, useTitle=False)}}
                        {{h.get_name()}}
                     </a>
                  </td>
                  %for c in columns:
                     %s = app.datamgr.get_service(r, c, user)
                     %if s:
                        <td title="{{s.get_name()}} - {{s.state}} - {{helper.print_duration(s.last_chk)}} - {{s.output}}">
                           <a href="/service/{{h.get_name()}}/{{s.get_name()}}">
                              {{!helper.get_fa_icon_state(s, useTitle=False)}}
                           </a>
                        </td>
                     %else:
                        <td>&nbsp;</td>
                     %end
                  %end
               </tr>
               %end
            %end
         </tbody>
      </table>
   %end
</div>
