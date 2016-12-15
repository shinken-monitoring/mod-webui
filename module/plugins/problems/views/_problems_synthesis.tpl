<!-- Problems synthesis -->
%setdefault('header', True)
%setdefault('widget', False)

%if header:
%s = app.datamgr.get_services_synthesis(user=user, elts=all_pbs)
%h = app.datamgr.get_hosts_synthesis(user=user, elts=all_pbs)

<div class="panel panel-default">
   <div class="panel-body">
      <table class="table table-invisible table-condensed">
         <tbody>
            %if 'type:service' not in search_string:
            <tr>
               <td>
               <b>{{h['nb_elts']}} hosts</b>
               </td>

               %if not widget:
               %states = ['up', 'unreachable', 'down', 'pending', 'unknown']
               %else:
               %states = ['unreachable', 'down', 'pending', 'unknown']
               %end
               %for state in states:
               <td>
                 %label = "%s hosts %s (%s%%)" % (h['nb_' + state], state, h['pct_' + state])
                 <a style="text-decoration: none;" href="/all?search=type:host is:{{state}} isnot:ack isnot:downtime" title="{{label}}">
                 {{! helper.get_fa_icon_state_and_label(cls='host', state=state, label=h['nb_' + state], useTitle=False, disabled=(not h['nb_' + state]))}}
                 </a>
               </td>
               %end
               %if not widget:
               %for state in 'ack', 'downtime':
               <td>
                 %label = "%s hosts %s (%s%%)" % (h['nb_' + state], state, h['pct_' + state])
                 <a style="text-decoration: none;" href="/all?search=type:host is:{{state}}" title="{{label}}">
                 {{! helper.get_fa_icon_state_and_label(cls='host', state=state, label=h['nb_' + state], useTitle=False, disabled=(not h['nb_' + state]))}}
                 </a>
               </td>
               %end
               %end
            </tr>
            %end
            %if 'type:host' not in search_string:
            <tr>
               <td>
                  <b>{{s['nb_elts']}} services</b>
               </td>

               %if not widget:
               %states = ['ok', 'warning', 'critical', 'pending', 'unknown']
               %else:
               %states = ['warning', 'critical', 'pending', 'unknown']
               %end
               %for state in states:
               <td>
                 %label = "%s services %s (%s%%)" % (s['nb_' + state], state, s['pct_' + state])
                 <a style="text-decoration: none;" href="/all?search=type:service is:{{state}} isnot:ack isnot:downtime" title="{{label}}">
                 {{!helper.get_fa_icon_state_and_label(cls='service', state=state, label=s['nb_' + state], useTitle=False, disabled=(not s['nb_' + state]))}}
                 </a>
               </td>
               %end
               %if not widget:
               %for state in 'ack', 'downtime':
               <td>
                 %label = "%s services %s (%s%%)" % (s['nb_' + state], state, s['pct_' + state])
                 <a style="text-decoration: none;" href="/all?search=type:service is:{{state}}" title="{{label}}">
                 {{!helper.get_fa_icon_state_and_label(cls='service', state=state, label=s['nb_' + state], useTitle=False, disabled=(not s['nb_' + state]))}}
                 </a>
               </td>
               %end
               %end
            </tr>
            %end
         </tbody>
      </table>
   </div>
</div>
%end
