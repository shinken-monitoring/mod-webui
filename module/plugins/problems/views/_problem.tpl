%helper = app.helper
        
<div class="panel panel-default">
  <div class="panel-heading">
    <h4 data-toggle="collapse" data-parent="#problems_{{ pb.host_name }}" href="#{{ pb.id }}">
      <table class="table table-condensed">
        <thead style="border: none;">
          <tr class="background-{{ pb.state.lower() }}" style="font-size: x-small; font-weight: normal;">


            <th class="col-md-5">
              <span class="cut_long">{{!helper.get_link(pb, short=False)}}</span>
            </th>

            <th class="col-md-1">
              <span class='txt_status'>{{ pb.state }}</span>
            </th>

            %# Status output ...
            %if len(pb.output) > 100:
            %if app.allow_html_output:
            <th class="col-lg-2 hidden-md">
              <span class='output' rel="tooltip" data-original-title="{{!helper.strip_html_output(pb.output[:app.max_output_length])}}">{{!helper.strip_html_output(pb.output[:app.max_output_length])}}</span>
            </th>
            %else:
            <th class="col-lg-2 hidden-md">
              <span class='output' rel="tooltip" data-original-title="{{pb.output}}">{{pb.output[:app.max_output_length]}}</span>
            </th>
            %end
            %else:
            %if app.allow_html_output:
            <th class="col-lg-2 hidden-md">
              <span class='output'>{{!helper.strip_html_output(pb.output)}}</span>
            </th>
            %else:
            <th class="col-lg-2 hidden-md">
              <span class='output'>{{pb.output}}</span>
            </th>
            %end
            %end

            %# Graphs
            %if graphs:
            %import time
            %now = time.time()
            %graphs = app.get_graph_uris(pb, now-4*3600, now, 'dashboard')
            %onmouse_code = ''
            %if len(graphs) > 0:
            %onmouse_code = 'onmouseover="display_hover_img(\'%s\',\'\');" onmouseout="hide_hover_img();" ' % graphs[0]['img_src']
            %end
            <th class="col-lg-4 hidden-md">
              <span class="perfometer" {{ onmouse_code }}>{{!helper.get_perfometer(pb)}}</span>
            </th>
            %end
        
            %## Status text ...
            <th class="col-sm-1">
              <a class="pull-right"><i class="fa fa-chevron-down pull-right"></i></a>
            </th>

          </tr>
        </thead>
      </table>
    </h4>
  </div>
        
  <div id="{{pb.id}}" data-raw-obj-name='{{pb.get_full_name()}}' class="detail panel-collapse collapse in">
    <div class="panel-body">

      <table class="table table-bordered">
        <thead><tr>
            <th>Host</th>
            %if pb.__class__.my_type == 'service':
            <th>Service</th>
            %end
            <th>Realm</th>
            <th>State</th>
            <th>Since</th>
            <th>Last check</th>
            <th>Next check</th>
            %if actions_allowed:
            <th>Actions</th>
            %end
        </tr></thead>

        <tbody>
          <tr>
            <td><a href="/host/{{pb.host_name}}">{{pb.host_name}}</a></td>
            %if pb.__class__.my_type == 'service':
            <td>{{!helper.get_link(pb, short=True)}}</td>
            %end
            <td>{{ pb.get_realm() }}</td>
            <td><span class='txt_status state_{{ pb.state.lower() }}'>{{ pb.state }}</span></td>
            <td>{{!helper.print_duration(pb.last_state_change, just_duration=True, x_elts=2)}}</td>
            <td>{{!helper.print_duration(pb.last_chk, just_duration=True, x_elts=2)}} ago</td>
            <td>in {{!helper.print_duration(pb.next_chk, just_duration=True, x_elts=2)}}</td>
            %if actions_allowed:
            <td>
              <div class="btn-group" role="group" aria-label="...">
                <button type="button" class="btn btn-default" title="Try to fix (launch event handler if defined)" onClick="try_to_fix_one('{{ pb.get_full_name() }}');">
                  <i class="fa fa-magic"></i>
                </button>
                <button type="button" class="btn btn-default" title="Launch the check command " onClick="recheck_now_one('{{ pb.get_full_name() }}');">
                  <i class="fa fa-refresh"></i>
                </button>
                <button type="button" class="btn btn-default" title="Force service to be considered as Ok" onClick="submit_check_ok_one('{{ pb.get_full_name() }}', '{{ user }}');">
                  <i class="fa fa-share"></i>
                </button>
                <button type="button" class="btn btn-default" title="Acknowledge the problem" onClick="acknowledge_one('{{ pb.get_full_name() }}', '{{ user }}');">
                  <i class="fa fa-check"></i>
                </button>
                <button type="button" class="btn btn-default" title="Schedule a one day downtime for the problem" onClick="downtime_one('{{ pb.get_full_name() }}', '{{ user }}');">
                  <i class="fa fa-ambulance"></i>
                </button>
                <button type="button" class="btn btn-default" title="Ignore checks for the service (disable checks, notifications, event handlers and force Ok)" onClick="remove_one('{{ pb.get_full_name() }}', '{{ user }}');">
                  <i class="fa fa-eraser"></i>
                </button>
              </div>
            </td>
            %end
          </tr>
          <tr>
            %if pb.__class__.my_type == 'service':
            <td colspan="8">
            %else:
            <td colspan="7">
            %end

            %# Status output ...
            %if len(pb.output) > 100:
            %if app.allow_html_output:
              <span class='output' rel="tooltip" data-original-title="{{ pb.output }}">{{!helper.strip_html_output(pb.output[:app.max_output_length])}}</span>
            </td>
            %else:
              <span class='output' rel="tooltip" data-original-title="{{ pb.output }}">{{ pb.output[:app.max_output_length] }}</span>
            </td>
            %end
            %else:
            %if app.allow_html_output:
            <span class='output'>{{!helper.strip_html_output(pb.output)}}</span>
            </td>
            %else:
            <span class='output'>{{ pb.output }}</span>
            </td>
            %end
            %end

          </tr>
        </tbody>
      </table>

      %if len(pb.impacts) > 0:
      <div>
        <hr />
        <h4>Impacts:</h4>

        %for i in helper.get_impacts_sorted(pb):
        <div>
          <p><img style="width: 16px; height: 16px;" src="{{!helper.get_icon_state(i)}}" />
            <span class="alert-small alert-{{ i.state.lower() }}">{{ i.state.lower() }}</span> for {{!helper.get_link(i)}}
          </p>
        </div>
        %end
      </div>
      %end

    </div>
  </div>
</div>
