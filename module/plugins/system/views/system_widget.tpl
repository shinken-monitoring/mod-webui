%helper = app.helper

%rebase("widget")

%types = [ ('scheduler', schedulers), ('poller', pollers), ('broker', brokers), ('reactionner', reactionners), ('receiver', receivers)]

<table class="table table-condensed no-bottommargin topmmargin">
   <thead>
      <tr>
         <th>Name</th>
         <th>State</th>
         <th>Last Check</th>
         <th>Realm</th>
      </tr>
   </thead>

   <tbody>
   %for (sat_type, sats) in types:
      %for s in sats:
      <tr>
         <td>{{s.get_name()}}</td>
         <td>
            %if not s.alive:
               {{!helper.get_fa_icon_state(cls='service', state='warning')}}
            %else:
               {{!helper.get_fa_icon_state(cls='service', state='ok')}}
            %end
         </td>
         <td title='{{helper.print_date(s.last_check)}}'>{{helper.print_duration(s.last_check, just_duration=True, x_elts=2)}}</td>
         <td>{{s.realm}}</td>
      </tr>
      %# End of this satellite
      %end
   %end
   </tbody>
</table>
