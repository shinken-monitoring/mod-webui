%import time

%date_format='%Y-%m-%d %H:%M:%S'

%if hasattr(records,"__iter__"):
   <table class="table table-condensed">
      <thead>
         <tr>
            <th>Time</th>
            <th>Source</th>
            <th>Message</th>
         </tr>
      </thead>
      <tbody style="font-size:x-small;">
         %for event in records:
            <tr>
               <td>{{time.strftime(date_format, time.localtime(event['timestamp']))}}</td>
               <td>{{event['source']}}</td>
               <td>{{event['data']}}</td>
            </tr>
         %end
      </tbody>
   </table>
%else:
   No events found
%end

