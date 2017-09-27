%import time
%helper = app.helper

%date_format='%Y-%m-%d %H:%M:%S'
%elt_type = elt.__class__.my_type

%if hasattr(records,"__iter__"):
%for daterange, logs in helper.group_by_daterange(records, key=lambda x: x['time']).items():
%if logs:
<div class="daterange-title">{{ daterange }}</div>
   <table class="table table-condensed">
      <tbody style="font-size:small;">
         %for log in logs:
         <tr>
           <td width="150px" style="vertical-align: middle;">{{time.strftime(date_format, time.localtime(log['time']))}}</td>
           %if log['logclass'] == 1 and log['state_type'] in ['SOFT', 'HARD']:
           %state = log['message'].split(';')[2]
           <td class="text-center" style="vertical-align: middle;">
             <i class="fa fa-warning fa-2x font-{{ state.lower() }}" title="State change"></i>
           </td>
           <td class="text-center" style="vertical-align: middle;">
             <strong class="font-{{ state.lower() }}">
               {{ state }}<br>
               <small>
                 {{ log['state_type'] }} 
                 %if log['state_type'] == 'SOFT':
                 {{ log['attempt'] }}
                 %end
               </small>
             </strong>
           </td>
           <td>
             {{ log['service_description'] }}<br>
             <samp class="text-muted">{{ log['plugin_output'] }}</samp>
           </td>
           %elif log['logclass'] == 1:
           <td class="text-center" style="vertical-align: middle;">
             <i class="fa fa-info-circle text-primary fa-2x" title="State change"></i>
           </td>
           <td class="text-center text-primary" style="vertical-align: middle;">
             <strong>
               %if "FLAPPING" in log['message']:
               FLAPPING<br>
               %elif "DOWNTIME" in log['message']:
               DOWNTIME<br>
               %end
               {{ log['state_type'] }}<br>
             </strong>
           </td>
           <td>
             {{ log['service_description'] }}<br>
             <samp class="text-muted">{{ log['message'].split(';')[-1] }}</samp>
           </td>
           %elif log['logclass'] == 3:
           <td class="text-center" style="vertical-align: middle;">
             <i class="fa fa-bell-o fa-2x font-{{ log['state_type'].lower() }}" title="Notification"></i>
           </td>
           <td class="text-center" style="vertical-align: middle;">
             <strong class="font-{{ log['state_type'].lower() }}">
               {{ log['state_type'] }}
             </strong>
           </td>
           <td>
             User {{ log['contact_name'] }} notified with <code>{{ log['command_name'] }}</code><br>
             <samp class="text-muted">{{ log['message'].split(';')[-1] }}</samp>
           </td>
           %else:
           <td>
           </td>
           <td>
           </td>
           <td>
             {{ log['message'] }}
           </td>
           %end
         </tr>
         %end
      </tbody>
   </table>
%end
%end
%else:
   No logs found
%end

