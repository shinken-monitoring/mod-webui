%user = app.get_user()
%title = 'Minemap for all hosts'

%helper = app.helper

%search_string = app.get_search_string()

%# Specific content for breadrumb
%rebase("layout", title='Minemap for hosts/services', css=['minemap/css/minemap.css'], js=['minemap/js/jquery.floatThead.min.js'], breadcrumb=[ ['Minemap', '/minemap'] ])


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

      %# items is a list of hosts
      %for host in items:
          %rows.append(host.get_name())
          %for s in host.services:
             %if s.service_description not in columns:
                %columns.append(s.service_description)
             %end
          %end
      %end
      %#rows.sort()
      %try:
      %# For Python < 2.7 ...
      %import collections
      %columns = collections.Counter(columns)
      %columns = [c for c, i in columns.most_common()]
      %except:
      %pass
      %end

      <!-- Problems synthesis -->
      %s = app.datamgr.get_services_synthesis(user=user)
      %h = app.datamgr.get_hosts_synthesis(user=user)
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

      <table class="table table-hover table-condensed table-fixed-header">
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
                  <td title="{{h.get_name()}} - {{h.state}} - {{helper.print_duration(h.last_chk)}} - {{h.output}}" data-container="body">
                     <a href="/host/{{h.get_name()}}">
                        {{!helper.get_fa_icon_state(h, use_title=False)}}
                        {{h.get_name() if h.display_name == '' else h.display_name}}
                     </a>
                  </td>
                  %for c in columns:
                     %s = app.datamgr.get_service(r, c, user)
                     %if s:
                        <td title="{{s.get_name()}} - {{s.state}} - {{helper.print_duration(s.last_chk)}} - {{s.output}}" data-container="body">
                           <a href="/service/{{h.get_name()}}/{{s.get_name()}}">
                              {{!helper.get_fa_icon_state(s, use_title=False)}}
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

     <script language="javascript" type="text/javascript" >
       $(document).ready(function(){
         $('table.table-fixed-header').floatThead({});
       });
     </script>
   %end
</div>
