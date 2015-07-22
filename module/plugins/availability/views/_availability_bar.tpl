%t_0=int(log['daily_0'])
%t_1=int(log['daily_1'])
%t_2=int(log['daily_2'])
%t_3=int(log['daily_3'])
%t_4=int(log['daily_4'])
%p_0=round(100.0 * t_0 / (86400-t_4), 2)
%p_1=round(100.0 * t_1 / (86400-t_4), 2)
%p_2=round(100.0 * t_2 / (86400-t_4), 2)
%p_3=round(100.0 * t_3 / (86400-t_4), 2)
%p_4=round(100.0 * t_4 / (86400-t_4), 2)

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
