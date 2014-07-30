%rebase layout globals(), title='Shinken daemons status'

%from shinken.bin import VERSION
%helper = app.helper

<div class="col-sm-12">
  <div class="col-sm-8">
    %types = [ ('scheduler', schedulers), ('poller', pollers), ('broker', brokers), ('reactionner', reactionners), ('receiver', receivers)]
    %for (sat_type, sats) in types:
    <h4><i class="icon-wrench"></i> {{sat_type.capitalize()}}</h4>
    <table class="table table-hover">
      <thead>
        <tr>
          <th>Name</th>
          <th>State</th>
          <th>Alive</th>
          <th>Attemts</th>
          <th>Last Check</th>
          <th>Realm</th>
        </tr>
      </thead>
      <tbody>
      %for s in sats:
        <tr>
          <td style="width: 200px;">{{s.get_name()}}</td>
          <td><img style="width: 16px; height: 16px;" src="{{helper.get_icon_state(s)}}" /></td>
          <td>{{s.alive}}</td>
          <td>{{s.attempt}}/{{s.max_check_attempts}}</td>
          <td title='{{helper.print_date(s.last_check)}}'>{{helper.print_duration(s.last_check, just_duration=True, x_elts=2)}}</td>
          <td>{{s.realm}}</td>
        </tr>
      </tbody>
      %end  
    </table>
    %end
  </div>
  <div class="col-sm-4">
    <div class="well">
      <!-- <img alt="" src="http://placehold.it/300x200"> -->
      <div class="caption">
        <h3 class="font-blue"><i class="icon-question-sign"></i> Information</h3>
        <p><strong>Arbiter:</strong> The arbiter daemon reads the configuration, divides it into parts (N schedulers = N parts), and distributes them to the appropriate Shinken daemons.</p>
        <p><strong>Scheduler:</strong> The scheduler daemon manages the dispatching of checks and actions to the poller and reactionner daemons respectively.</p>
        <p><strong>Poller:</strong> The poller daemon launches check plugins as requested by schedulers. When the check is finished it returns the result to the schedulers.</p>
        <p><strong>Reactionner:</strong> The reactionner daemon issues notifications and launches event_handlers. </p>
        <p><strong>Broker:</strong> The broker daemon exports and manages data from schedulers. The broker uses modules exclusively to get the job done.</p>
        <p><strong>Receiver (<b>optional</b>):</strong> The receiver daemon receives passive check data and serves as a distributed command buffer.</p>
        <hr>
        <p><a href="https://shinken.readthedocs.org/en/latest/" target="_blank" class="btn btn-lg btn-flat btn-primary btn-block">Learn more »</a></p>
      </div>
    </div>
  </div>
</div>
