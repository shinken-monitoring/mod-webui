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
               %if log['state'] is not None:
                   %if log['type'] in ['SERVICE FLAPPING ALERT','HOST FLAPPING ALERT'] :
                        %if log['state_type'] == 'STARTED':
                        <i class="fa fa-exclamation-circle fa-2x font-warning"></i>
                        %else:
                        <i class="fa fa-check-circle fa-2x font-ok"></i>
                        %end
                   %elif log['type'] == 'HOST ALERT':
                        %if log['state'] == 0: # UP
                        <i class="fa fa-check-circle fa-2x font-ok"></i>
                        %elif log['state'] == 3 : # UNKNOWN
                        <i class="fa fa-question-circle fa-2x font-unknown"></i>
                        %else: # DOWN 1/UNREACHABLE 2
                        <i class="fa fa-times-circle fa-2x font-critical"></i>
                        %end
                   %else:
                        %if log['state'] == 0: # OK
                        <i class="fa fa-check-circle fa-2x font-ok"></i>
                        %elif log['state'] == 1: # WARNING
                        <i class="fa fa-exclamation-circle fa-2x font-warning"></i>
                        %elif log['state'] == 2:    # 2, CRITICAL
                        <i class="fa fa-times-circle fa-2x font-critical"></i>
                        %else: # UNKNWON
                        <i class="fa fa-question-circle fa-2x font-unknown"></i>
                        %end
                   %end
               %else: # UNKNOWN
                   <i class="fa fa-question-circle fa-2x font-greyed"></i>
               %end
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

