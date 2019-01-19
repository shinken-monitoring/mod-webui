<!-- Problems synthesis -->
%setdefault('header', True)
%setdefault('widget', False)

%if header:
%s = app.datamgr.get_services_synthesis(user=user, elts=all_pbs)
%h = app.datamgr.get_hosts_synthesis(user=user, elts=all_pbs)
%s_all = app.datamgr.get_services_synthesis(user=user)
%h_all = app.datamgr.get_hosts_synthesis(user=user)

<div class="panel panel-default hidden-xs">
   <div class="panel-body">
      <table class="table table-invisible table-condensed">
         <tbody>
            %if 'type:service' not in search_string:
            <tr>
               <td>
               <strong>{{h['nb_elts']}}<small class='hidden-sm'> / {{h_all['nb_elts']}}</small> hosts</strong>
               </td>

               %if not widget:
               %states = ['up', 'unreachable', 'down', 'pending', 'unknown']
               %else:
               %states = ['unreachable', 'down', 'pending', 'unknown']
               %end
               %for state in states:
               <td>
                 %label = "%s hosts %s (%s%%)<br>%s with current filter" % (h_all['nb_' + state], state, h_all['pct_' + state], h['nb_' + state])
                 <a style="text-decoration: none;" href="/all?search=type:host is:{{state}} isnot:ack isnot:downtime" title="{{!label}}">
                   {{! helper.get_fa_icon_state_and_label(cls='host', state=state, label="%s<small class='hidden-sm'> / %s</small>" % (h['nb_' + state], h_all['nb_'+state]), use_title=False, disabled=(not h['nb_' + state]))}}
                 </a>
               </td>
               %end
               %if not widget:
               %for state in 'ack', 'downtime':
               <td>
                 %label = "%s hosts %s (%s%%)<br>%s with current filter" % (h_all['nb_' + state], state, h_all['pct_' + state], h['nb_' + state])
                 <a style="text-decoration: none;" class="font-{{ state.lower() if h['nb_' + state] else 'greyed' }}" href="/all?search=type:host is:{{state}}" title="{{!label}}">
                   <i class="fa fa-2x {{ 'fa-check' if state == 'ack' else 'fa-clock' }}"></i> {{ h['nb_' + state] }} <small class='hidden-sm'> / {{ h_all['nb_'+state] }}</small>
                 </a>
               </td>
               %end
               %end
            </tr>
            %end
            %if 'type:host' not in search_string:
            <tr>
               <td>
                  <strong>{{s['nb_elts']}}<small class='hidden-sm'> / {{s_all['nb_elts']}}</small> services</strong>
               </td>

               %if not widget:
               %states = ['ok', 'warning', 'critical', 'pending', 'unknown']
               %else:
               %states = ['warning', 'critical', 'pending', 'unknown']
               %end
               %for state in states:
               <td>
                 %label = "%s services %s (%s%%)<br>%s with current filter" % (s_all['nb_' + state], state, s_all['pct_' + state], s['nb_' + state])
                 <a style="text-decoration: none;" href="/all?search=type:service is:{{state}} isnot:ack isnot:downtime" title="{{!label}}">
                   {{!helper.get_fa_icon_state_and_label(cls='service', state=state, label="%s<small class='hidden-sm'> / %s</small>" % (s['nb_' + state], s_all['nb_'+state]), use_title=False, disabled=(not s['nb_' + state]))}}
                 </a>
               </td>
               %end
               %if not widget:
               %for state in 'ack', 'downtime':
               <td>
                 %label = "%s services %s (%s%%)<br>%s with current filter" % (s_all['nb_' + state], state, s_all['pct_' + state], s['nb_' + state])
                 <a style="text-decoration: none;" class="font-{{ state.lower() if s['nb_' + state] else 'greyed' }}" href="/all?search=type:service is:{{state}}" title="{{!label}}">
                   <i class="fa fa-2x {{ 'fa-check' if state == 'ack' else 'fa-clock' }}"></i> {{ s['nb_' + state] }} <small class='hidden-sm'> / {{ s_all['nb_'+state] }}</small>
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
