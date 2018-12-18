%rebase("layout", title='Alignak livesynthesis', css=['system/css/alignak.css'], js=['system/js/jquery.floatThead.min.js'], breadcrumb=[ ['Alignak status', '/alignak/status'] ])

%helper = app.helper

<div class="col-sm-12 panel panel-default">
   <div class="panel-body">
   %if not status:
      <div class="page-header text-center">
         <h3>No system information is available.</h3>
      </div>
   %else:
      %livestate = status['livestate']
      %state = livestate.get('state', 'unknown').lower()
      <div class="panel-heading">
         <div style="display: table-cell; vertical-align: middle;">
            {{!helper.get_fa_icon_state_and_label(cls="host", state=state)}}
         </div>
         <div style="display: table-cell; vertical-align: middle;" class="font-{{state}} text-center">
            <h3 class="panel-title">{{status['name']}}</h3>
         </div>
      </div>

      <table class="table table-hover table-condensed table-fixed-header">
         <thead>
            <tr>
               <th>Satellite</th>
               <th>State</th>
               <th>Last check</th>
               <th>Message</th>
            </tr>
         </thead>
         <tbody>
         %for satellite in status['services']:
            %livestate = satellite['livestate']
            %state = livestate.get('state', 'unknown').lower()
            %last_check = livestate.get('timestamp', 0)
            <tr>
               <td>{{livestate.get('name', satellite['name'])}}</td>
               <td>{{!helper.get_fa_icon_state_and_label(cls="service", state=state, label=state)}}</td>
               <td title='{{helper.print_date(last_check)}}' data-container="body">{{helper.print_duration(last_check, just_duration=True, x_elts=2)}}</td>
               <td title="{{livestate.get('long_output', 'n/a')}} - {{livestate.get('perf_data', 'n/a')}}">{{livestate.get('output', 'n/a')}}</td>
            </tr>
         %end
         </tbody>
      </table>

      <!-- {{ls['alignak']}} - {{ls['version']}} - {{ls['type']}} - {{ls['name']}} - {{ls['start_time']}} -->

      %columns = sorted(ls['livesynthesis']['_overall']['livesynthesis'].keys())

      <table class="table table-hover table-condensed table-fixed-header">
         <thead>
            <tr>
               <th></th>
               %for counter in columns:
                  <th class="vertical">
                  <div class="rotated-text"><span class="rotated-text__inner">
                     {{counter}}
                  </span></div>
                  </th>
               %end
            </tr>
         </thead>
         <tbody>
         %for scheduler in ls['livesynthesis']:
            <tr>
               <td>{{scheduler}}</td>
               %for counter in columns:
                  %cpt = ls['livesynthesis'][scheduler]['livesynthesis'][counter]
                  <td>{{ cpt if cpt else '-' }}</td>
               %end
            </tr>
         %end
         </tbody>
      </table>
   %end
   </div>
</div>
