<!-- Problems synthesis -->
%setdefault('header', True)

%if header:
%synthesis = app.datamgr.get_synthesis(pbs)
%s = synthesis['services']
%h = synthesis['hosts']

<div class="panel panel-default">
   <div class="panel-body">
      <table class="table table-invisible table-condensed">
         <tbody>
            %if 'type:service' not in search_string:
            <tr>
               <td>
               <b>{{h['nb_elts']}} hosts:&nbsp;</b>
               </td>

               %for state in 'up', 'unreachable', 'down', 'pending', 'unknown':
               <td>
                 %label = "%s hosts %s (%s%%)" % (h['nb_' + state], state, h['pct_' + state])
                 <a style="text-decoration: none;" href="/all?search=type:host is:{{state}} isnot:ack isnot:downtime" title="{{label}}">
                 {{! helper.get_fa_icon_state_and_label(cls='host', state=state, label=h['nb_' + state], useTitle=False, disabled=(not h['nb_' + state]))}}
                 </a>
               </td>
               %end
               %for state in 'ack', 'downtime':
               <td>
                 %label = "%s hosts %s (%s%%)" % (h['nb_' + state], state, h['pct_' + state])
                 <a style="text-decoration: none;" href="/all?search=type:host is:{{state}}" title="{{label}}">
                 {{! helper.get_fa_icon_state_and_label(cls='host', state=state, label=h['nb_' + state], useTitle=False, disabled=(not h['nb_' + state]))}}
                 </a>
               </td>
               %end
            </tr>
            %end
            %if 'type:host' not in search_string:
            <tr>
               <td>
                  <b>{{s['nb_elts']}} services:&nbsp;</b>
               </td>

               %for state in 'ok', 'warning', 'critical', 'pending', 'unknown':
               <td>
                 %label = "%s services %s (%s%%)" % (s['nb_' + state], state, s['pct_' + state])
                 <a style="text-decoration: none;" href="/all?search=type:service is:{{state}} isnot:ack isnot:downtime" title="{{label}}">
                 {{!helper.get_fa_icon_state_and_label(cls='service', state=state, label=s['nb_' + state], useTitle=False, disabled=(not s['nb_' + state]))}}
                 </a>
               </td>
               %end
               %for state in 'ack', 'downtime':
               <td>
                 %label = "%s services %s (%s%%)" % (s['nb_' + state], state, s['pct_' + state])
                 <a style="text-decoration: none;" href="/all?search=type:service is:{{state}}" title="{{label}}">
                 {{!helper.get_fa_icon_state_and_label(cls='service', state=state, label=s['nb_' + state], useTitle=False, disabled=(not s['nb_' + state]))}}
                 </a>
               </td>
               %end
            </tr>
            %end
         </tbody>
      </table>
   </div>
</div>
%end
