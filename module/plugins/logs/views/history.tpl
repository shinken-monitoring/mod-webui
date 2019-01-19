%import time
%helper = app.helper

%date_format='%Y-%m-%d %H:%M:%S'

%if hasattr(records,"__iter__"):
%for daterange, logs in helper.group_by_daterange(records, key=lambda x: x['time']).items():
%if logs:
<div class="daterange-title">{{ daterange }}</div>
   <table class="table table-condensed">
      <tbody style="font-size:small;">
         %for log in logs:
         <tr>
           <td width="150px" style="vertical-align: middle;">{{time.strftime(date_format, time.localtime(log['time']))}}</td>
           %# STATE CHANGE
           %if log['logclass'] == 1 and log['state_type'] in ['SOFT', 'HARD']:
           %state = log['message'].split(';')[2]
           <td width="40px" class="text-center" style="vertical-align: middle;">
             <i class="fas fa-warning fa-2x font-{{ state.lower() }}" title="State change"></i>
           </td>
           <td width="100px" class="text-center" style="vertical-align: middle;">
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
           %# FLAPPING/DOWNTIME
           %elif log['logclass'] == 1:
           <td width="40px" class="text-center" style="vertical-align: middle;">
             <i class="fas fa-info-circle text-primary fa-2x" title="State change"></i>
           </td>
           <td width="100px" class="text-center text-primary" style="vertical-align: middle;">
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
           %# NOTIFICATION
           %elif log['logclass'] == 3:
           %# Not used for now
           %if 'sms' in log['command_name']:
           %icon = 'fa-mobile'
           %elif 'mail' in log['command_name']:
           %icon = 'fa-envelope'
           %elif 'slack' in log['command_name']:
           %icon = 'fa-slack'
           %else:
           %icon = 'fa-bell'
           %end
           <td width="40px" class="text-center" style="vertical-align: middle;">
             <i class="fas fa-bell fa-2x font-{{ log['state_type'].lower() }}" title="Notification"></i>
           </td>
           <td width="100px" class="text-center" style="vertical-align: middle;">
             <strong class="font-{{ log['state_type'].lower() }}">
               {{ log['state_type'] }}
             </strong>
           </td>
           <td>
             User {{ log['contact_name'] }} notified with <code>{{ log['command_name'] }}</code><br>
             {{ log['host_name'] }} / {{ log['service_description'] }} &nbsp;&nbsp;&nbsp;&nbsp;
             <samp class="text-muted">{{ log['message'].split(';')[-1] }}</samp>
           </td>
           %else:
           <td width="40px">
           </td>
           <td width="100px">
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

