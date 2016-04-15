%helper = app.helper

%rebase("widget")

%types = [ ('scheduler', schedulers), ('poller', pollers), ('broker', brokers), ('reactionner', reactionners), ('receiver', receivers)]

%daemons = [ ('scheduler', schedulers), ('poller', pollers), ('broker', brokers), ('reactionner', reactionners), ('receiver', receivers)]
%present = sum(1 for (type, satellites) in daemons if satellites)
%if not present:
  <center>
    <h3>No system information is available.</h3>
  </center>
%else:
    <table class="table table-condensed no-bottommargin topmmargin">
       <thead>
          <tr>
             <th>Name</th>
             <th>Main</th>
             <th>State</th>
             <th>Last Check</th>
             <th>Realm</th>
          </tr>
       </thead>

       <tbody>
       %for (type, satellites) in daemons:
          %for s in satellites:
          <tr>
             <td>{{s.get_name()}}</td>
             %if not s.spare:
             <td><i title="Is not a spare daemon" class="fa fa-check font-green"></i></td>
             %else:
             <td></td>
             <!--<td>{{!helper.get_on_off(status=s.spare)}}</td>-->
             %end
             <td>
                %if not s.alive:
                    {{!helper.get_fa_icon_state(cls='service', state='warning')}}
                %else:
                    %if s.attempt:
                        {{!helper.get_fa_icon_state(cls='service', state='critical')}}
                    %else:
                        {{!helper.get_fa_icon_state(cls='service', state='ok')}}
                    %end
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
%end