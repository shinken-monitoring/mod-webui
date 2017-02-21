%import time

%date_format='%Y-%m-%d %H:%M:%S'
%elt_type = elt.__class__.my_type

%if hasattr(records,"__iter__"):
   <table class="table table-condensed">
      <thead>
         <tr>
            <th>State</th>
            <th>Time</th>
            %if elt_type == 'host':
            <th>Service</th>
            %end
            <th>Message</th>
         </tr>
      </thead>
      <tbody style="font-size:x-small;">
         %for log in records:
            <tr>
               <td>
               %if log['state_type']:
                   %if log['state_type'] is 'UP':
                   <i class="fa fa-check-circle fa-2x font-ok"></i>
                   %elif log['state_type'] is 'WARNING':
                   <i class="fa fa-exclamation-circle fa-2x font-warning"></i>
                   %else:    # SOFT/HARD/DOWN/CRITICAL
                   <i class="fa fa-times-circle fa-2x font-critical"></i>
               %else:
                   <i class="fa fa-check-circle fa-2x font-greyed"></i>
               </td>
               <td>{{time.strftime(date_format, time.localtime(log['timestamp']))}}</td>
               %if elt_type == 'host':
               <td>{{log['service']}}</td>
               %end
               <td>{{log['message']}}</td>
            </tr>
         %end
      </tbody>
   </table>
%else:
   No logs found
%end

