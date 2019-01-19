%rebase("layout", title='Monitoring framework daemons status')

%helper = app.helper

<div class="col-sm-12 panel panel-default">
  <div class="panel-body">
   %daemons = [ ('scheduler', schedulers), ('poller', pollers), ('broker', brokers), ('reactionner', reactionners), ('receiver', receivers)]
   %present = sum(1 for (type, satellites) in daemons if satellites)
   %if not present:
      <center>
        <h3>No system information is available.</h3>
      </center>
   %else:
       %for (type, satellites) in daemons:
       <h4><i class="icon-wrench"></i> {{type.capitalize()}}</h4>
       <table class="table table-hover">
          <thead>
             <tr>
                <th style="width: 200px">Name</th>
                <th>Port</th>
                <th>State</th>
                <th>Alive</th>
                <th>Main</th>
                <th>Attempts</th>
                <th>Last Check</th>
                <th>Realm</th>
             </tr>
          </thead>
          <tbody>
             %for s in satellites:
             <tr>
                <td>{{s.get_name()}}</td>
                <td>{{s.port}}</td>
                <td>
                %if not s.alive:
                    {{!helper.get_fa_icon_state(cls='service', state='critical')}}
                %else:
                    %if s.attempt > 0:
                        {{!helper.get_fa_icon_state(cls='service', state='warning')}}
                    %else:
                        {{!helper.get_fa_icon_state(cls='service', state='ok')}}
                    %end
                %end
                </td>
                %if s.alive:
                <td><i title="Is alive" class="fas fa-check font-green"></i></td>
                %else:
                <td><i title="Is dead!" class="fas fa-times font-red"></i></td>
                %end
                %if not s.spare:
                <td><i title="Is not a spare daemon" class="fas fa-check font-green"></i></td>
                %else:
                <td></td>
                %end
                <td>{{s.attempt}}/{{s.max_check_attempts}}</td>
                <td title='{{helper.print_date(s.last_check)}}' data-container="body">{{helper.print_duration(s.last_check, just_duration=True, x_elts=2)}}</td>
                <td>{{s.realm_name}}</td>
             </tr>
             %end
          </tbody>
       </table>
       %end
    %end
  </div>
</div>
