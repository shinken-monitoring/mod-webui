%rebase("layout", title='Shinken daemons status')

%from shinken.bin import VERSION
%helper = app.helper

<div class="col-sm-12">
   %types = [ ('scheduler', schedulers), ('poller', pollers), ('broker', brokers), ('reactionner', reactionners), ('receiver', receivers)]
   %for (sat_type, sats) in types:
   <h4><i class="icon-wrench"></i> {{sat_type.capitalize()}}</h4>
   <table class="table table-hover">
      <colgroup>
         <col style="width: 200px"></col>
         <col></col>
         <col></col>
         <col></col>
         <col></col>
         <col></col>
         <col></col>
         <col></col>
      </colgroup>
      <thead>
         <tr>
            <th>Name</th>
            <th>Port</th>
            <th>State</th>
            <th>Alive</th>
            <th>Spare</th>
            <th>Attempts</th>
            <th>Last Check</th>
            <th>Realm</th>
         </tr>
      </thead>
      <tbody>
         %for s in sats:
         <tr>
            <td>{{s.get_name()}}</td>
            <td>{{s.port}}</td>
            <td>
               %if not s.alive:
                  {{!helper.get_fa_icon_state(cls='service', state='warning')}}
               %else:
                  {{!helper.get_fa_icon_state(cls='service', state='ok')}}
               %end
            </td>
            <td>{{!helper.get_on_off(status=s.alive, title=None, message='')}}</td>
            <td>{{!helper.get_on_off(status=s.spare)}}</td>
            <td>{{s.attempt}}/{{s.max_check_attempts}}</td>
            <td title='{{helper.print_date(s.last_check)}}'>{{helper.print_duration(s.last_check, just_duration=True, x_elts=2)}}</td>
            <td>{{s.realm}}</td>
         </tr>
         %end  
      </tbody>
   </table>
   %end
</div>
