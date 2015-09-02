<!-- Problems synthesis -->

%synthesis = helper.get_synthesis(all_pbs)
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
             
               %for state in 'up', 'unreachable', 'down', 'pending', 'unknown', 'ack', 'downtime':
               <td>
                 %label = "%s <i>(%s%%)</i>" % (h['nb_' + state], h['pct_' + state])
                 <a href="/all?search=type:host is:{{state}}">
                 {{!helper.get_fa_icon_state_and_label(cls='host', state=state, label=label, disabled=(not h['nb_' + state]))}}
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
          
               %for state in 'ok', 'warning', 'critical', 'pending', 'unknown', 'ack', 'downtime':
               <td>
                 %label = "%s <i>(%s%%)</i>" % (s['nb_' + state], s['pct_' + state])
                 <a href="/all?search=type:service is:{{state}}">
                 {{!helper.get_fa_icon_state_and_label(cls='service', state=state, label=label, disabled=(not s['nb_' + state]))}}
                 </a>
               </td>
               %end
            </tr>
            %end
         </tbody>
      </table>
   </div>
</div>

