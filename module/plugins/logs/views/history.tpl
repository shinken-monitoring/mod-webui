%import time

%date_format='%Y-%m-%d %H:%M:%S'
%elt_type = elt.__class__.my_type

%if hasattr(records,"__iter__"):
   <table class="table table-condensed">
      <thead>
         <tr>
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

