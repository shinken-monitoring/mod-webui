%import json
%import time

%#date_format='%Y-%m-%d %H:%M:%S'
%date_format='%H:%M:%S'
%states = ['Up', 'down', 'unreachable', 'unknown', 'unchecked']

<table class="table table-condensed">
   <thead>
      <tr>
         <th>Hostname</th>
         <th>Service</th>
         <th>Day</th>
         <th>First check</th>
         <th>Last check</th>
         <th>Downtime</th>
         <th> ... </th>
      </tr>
   </thead>
   <tbody style="font-size:x-small;">
      %for log in records:
         %t_0=int(log['daily_0'])
         %t_1=int(log['daily_1'])
         %t_2=int(log['daily_2'])
         %t_3=int(log['daily_3'])
         %t_4=int(log['daily_4'])
         
         <tr>
            <td>{{log['hostname']}}</td>
            <td>{{log['service']}}</td>
            <td>{{log['day']}}</td>
            
            <td>{{time.strftime(date_format, time.localtime(log['first_check_timestamp']))}} {{!app.helper.get_fa_icon_state_and_label(cls='host', state=states[log['first_check_state']])}}</td>
            
            <td>{{time.strftime(date_format, time.localtime(log['last_check_timestamp']))}} {{!app.helper.get_fa_icon_state_and_label(cls='host', state=states[log['last_check_state']])}}</td>
            
            <td>{{! app.helper.get_on_off(bool(log['is_downtime']=='1'), 'Is in downtime period?')}}</td>
            
            %p_0=round(100.0 * t_0 / 86400, 2)
            %p_1=round(100.0 * t_1 / 86400, 2)
            %p_2=round(100.0 * t_2 / 86400, 2)
            %p_3=round(100.0 * t_3 / 86400, 2)
            %p_4=round(100.0 * t_4 / 86400, 2)
            <td>
               <div class="progress" style="margin-bottom: 0px;">
                  <div title="{{t_0}} seconds Up" class="progress-bar progress-bar-success " role="progressbar" 
                     aria-valuenow="{{p_0}}" aria-valuemin="0" aria-valuemax="100" 
                     data-toggle="tooltip" data-placement="bottom" 
                     style="width: {{p_0}}%;">{{p_0}}% Up</div>

                  <div title="{{t_1}} seconds Down" class="progress-bar progress-bar-danger " role="progressbar" 
                     aria-valuenow="{{p_1}}" aria-valuemin="0" aria-valuemax="100" 
                     data-toggle="tooltip" data-placement="bottom" 
                     style="width: {{p_1}}%;">{{p_1}}% Down</div>

                  <div title="{{t_2}} seconds Unreachable" class="progress-bar progress-bar-warning " role="progressbar" 
                     aria-valuenow="{{p_2}}" aria-valuemin="0" aria-valuemax="100" 
                     data-toggle="tooltip" data-placement="bottom" 
                     style="width: {{p_2}}%;">{{p_2}}% Unreachable</div>

                  <div title="{{t_3}} seconds Pending" class="progress-bar progress-bar-info " role="progressbar" 
                     aria-valuenow="{{p_3}}" aria-valuemin="0" aria-valuemax="100" 
                     data-toggle="tooltip" data-placement="bottom" 
                     style="width: {{p_3}}%;">{{p_3}}% Unknown</div>

                  <div title="{{t_4}} seconds Unknown" class="progress-bar " role="progressbar" 
                     aria-valuenow="{{p_4}}" aria-valuemin="0" aria-valuemax="100" 
                     data-toggle="tooltip" data-placement="bottom" 
                     style="width: {{p_4}}%;">{{p_4}}% Unchecked</div>
               </div>
            </td>
         </tr>
         <!--
         <tr>
            <td colspan="6">&nbsp;</td>
            <td>
               <div class="progress" style="margin-bottom: 0px;">
                 <div class="progress-bar" role="progressbar" aria-valuenow="60" aria-valuemin="0" aria-valuemax="100" style="min-width: 2em; width: {{p_0+p_1+p_2+p_3}}%;">
                   <span class="sr-only">{{p_0+p_1+p_2+p_3}} %</span>
                 </div>
               </div>
            </td>
         </tr>
         -->
         %if t_4 != 86400:
         <tr>
            <td colspan="6">&nbsp;</td>
            
            %p_0=round(100.0 * t_0 / (86400-t_4), 2)
            %p_1=round(100.0 * t_1 / (86400-t_4), 2)
            %p_2=round(100.0 * t_2 / (86400-t_4), 2)
            %p_3=round(100.0 * t_3 / (86400-t_4), 2)
            <td>
               <div class="progress" style="margin-bottom: 0px;">
                  <div title="{{t_0}} seconds Up" class="progress-bar progress-bar-success " role="progressbar" 
                     aria-valuenow="{{p_0}}" aria-valuemin="0" aria-valuemax="100" 
                     data-toggle="tooltip" data-placement="bottom" 
                     style="width: {{p_0}}%;">{{p_0}}% Up</div>

                  <div title="{{t_1}} seconds Down" class="progress-bar progress-bar-danger " role="progressbar" 
                     aria-valuenow="{{p_1}}" aria-valuemin="0" aria-valuemax="100" 
                     data-toggle="tooltip" data-placement="bottom" 
                     style="width: {{p_1}}%;">{{p_1}}% Down</div>

                  <div title="{{t_2}} seconds Unreachable" class="progress-bar progress-bar-warning " role="progressbar" 
                     aria-valuenow="{{p_2}}" aria-valuemin="0" aria-valuemax="100" 
                     data-toggle="tooltip" data-placement="bottom" 
                     style="width: {{p_2}}%;">{{p_2}}% Unreachable</div>

                  <div title="{{t_3}} seconds Pending" class="progress-bar progress-bar-info " role="progressbar" 
                     aria-valuenow="{{p_3}}" aria-valuemin="0" aria-valuemax="100" 
                     data-toggle="tooltip" data-placement="bottom" 
                     style="width: {{p_3}}%;">{{p_3}}% Unknown</div>

                  <div title="{{t_4}} seconds Unknown" class="progress-bar " role="progressbar" 
                     aria-valuenow="{{p_4}}" aria-valuemin="0" aria-valuemax="100" 
                     data-toggle="tooltip" data-placement="bottom" 
                     style="width: {{p_4}}%;">{{p_4}}% Unchecked</div>
               </div>
            </td>
         </tr>
         %end
      %end
   </tbody>
</table>
