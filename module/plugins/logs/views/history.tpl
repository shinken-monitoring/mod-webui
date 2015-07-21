%import json
%import time

%date_format='%Y-%m-%d %H:%M:%S'

<table class="table table-condensed">
   <thead>
      <tr>
         <th>Time</th>
         <th>Service</th>
         <th>Message</th>
      </tr>
   </thead>
   <tbody style="font-size:x-small;">
      %for log in records:
         <tr>
            <td>{{time.strftime(date_format, time.localtime(log['timestamp']))}}</td>
            <td>{{log['service']}}</td>
            <td>{{log['message']}}</td>
         </tr>
      %end
   </tbody>
</table>
