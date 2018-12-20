<div class="tab-pane fade {{_go_active}} {{_go_fadein}}" id="information">
  <div class="panel panel-default" style="border-top:none; border-radius:0;">
    <div class="panel-body">

      <div class="row">
        <div class="status-lead" style="margin-left: 10px; margin-top: 20px;">
          <div style="display: table-cell; vertical-align: middle; ">
            {{!helper.get_fa_icon_state(elt, use_title=False)}}
          </div>
          <div style="display: table-cell; vertical-align: middle; padding-right: 10px;" class="font-{{elt.state.lower()}} text-center">
            <strong>{{ elt.state }}</strong><br>
            <span title="Since {{time.strftime("%d %b %Y %H:%M:%S", time.localtime(elt.last_state_change))}}">
              <small>
              %if elt.state_type == 'HARD':
              {{!helper.print_duration(elt.last_state_change, just_duration=True, x_elts=2)}}
              %else:
              attempt {{elt.attempt}}/{{elt.max_check_attempts}}
              <!--soft state-->
              %end
              </small>
            </span>
          </div>
          <div style="display: table-cell; vertical-align: middle;">
            %if elt_type == 'service':
            <a href="{{'/host/'+elt.host_name }}">{{ elt.host.display_name if elt.host.display_name else elt.host.get_name() }}</a>:
            %end
            {{ elt.display_name }}
            %if elt_type == 'host':
            ({{ elt.address }})
            %end
            <br>
            <samp>{{! elt.output}}</samp>
          </div>
        </div>
      </div>

      <div class="row">
      <div class="col-lg-6">
        <h4 class="page-header">Last check</h4>
        <table class="table table-condensed table-nowrap">
          <colgroup>
            <col style="width: 40%" />
            <col style="width: 60%" />
          </colgroup>
          <tbody class="small">
            <tr>
              <td><strong>Last Check:</strong></td>
              <td><span class="popover-dismiss" data-html="true" data-toggle="popover" data-placement="bottom" data-content="Last check was at {{time.asctime(time.localtime(elt.last_chk))}}">was {{helper.print_duration(elt.last_chk)}}</span></td>
            </tr>
            <!--
            <tr>
              <td><strong>Output:</strong></td>
              <td><span class="popover-dismiss popover-large"
                  data-html="true" data-toggle="popover" data-placement="bottom"
                  data-title="{{elt.get_full_name()}} check output"
                  data-content=" {{elt.output}}{{'<br/>'+elt.long_output.replace('\n', '<br/>') if elt.long_output else ''}}"
                  >
                  {{! elt.output}}
                </span>
              </td>
            </tr>
            <tr>
              <td><strong>Performance data:</strong></td>
              <td><span class="popover-dismiss popover-large ellipsis"
                  data-html="true" data-toggle="popover" data-placement="bottom"
                  data-title="{{elt.get_full_name()}} performance data"
                  data-content=" {{elt.perf_data if elt.perf_data else '(none)'}}"
                  >
                  {{elt.perf_data if elt.perf_data else '(none)'}}
                </span>
              </td>
            </tr>
            -->
            <tr>
              <td><strong>Check latency / duration:</strong></td>
              <td>
                {{'%.2f' % elt.latency}} / {{'%.2f' % elt.execution_time}} seconds
              </td>
            </tr>

            <tr>
              <td><strong>Last State Change:</strong></td>
              <td><span class="popover-dismiss" data-html="true" data-toggle="popover" data-placement="bottom" data-content="Last state change at {{time.asctime(time.localtime(elt.last_state_change))}}">{{helper.print_duration(elt.last_state_change)}}</span></td>
            </tr>
            <tr>
              <td><strong>Current Attempt:</strong></td>
              <td>{{elt.attempt}}/{{elt.max_check_attempts}} ({{elt.state_type}} state)</td>
            </tr>
            <tr>
              <td><strong>Next Active Check:</strong></td>
              <td><span class="popover-dismiss" data-html="true" data-toggle="popover" data-placement="bottom" data-content="Next active check at {{time.asctime(time.localtime(elt.next_chk))}}">{{helper.print_duration(elt.next_chk)}}</span></td>
            </tr>
          </tbody>
        </table>

        %if elt.customs and ('_IMPACT' in elt.customs or '_DETAILLEDESC' in elt.customs or '_FIXACTIONS' in elt.customs):
        <h4 class="page-header"><i class="fa fa-question-circle-o"></i> Documentation</h4>
        <dl class="dl-horizontal">
          %if '_DETAILLEDESC' in elt.customs:
          <dt style="width: 100px;">Description </dt><dd style="margin-left: 120px;"> {{ elt.customs['_DETAILLEDESC'] }}</dd>
          %end
          %if '_IMPACT' in elt.customs:
          <dt style="width: 100px;">Impact </dt><dd style="margin-left: 120px;"> {{ elt.customs['_IMPACT'] }}</dd>
          %end
          %if '_FIXACTIONS' in elt.customs:
          <dt style="width: 100px;">How to fix </dt><dd style="margin-left: 120px;"> {{ elt.customs['_FIXACTIONS'] }}</dd>
          %end
        </dl>
        %end

        %if elt.perf_data:
        <h4 class="page-header">Performance data</h4>
        <div>
          {{!helper.get_perfdata_table(elt)}}
        </div>
        %end

        <h4 class="page-header">Checks configuration</h4>
        <table class="table table-condensed">
          <colgroup>
            <col style="width: 40%" />
            <col style="width: 60%" />
          </colgroup>
          <tbody class="small">
            <tr>
              <td><strong>Check period:</strong></td>
              %if hasattr(elt, "check_period") and hasattr(elt.check_period, "get_name"):
              %tp=app.datamgr.get_timeperiod(elt.check_period.get_name())
              <td name="check_period" class="popover-dismiss"
                data-html="true" data-toggle="popover" data-placement="left"
                data-title='{{tp.alias if hasattr(tp, "alias") else tp.timeperiod_name}}'
                data-content='{{!helper.get_timeperiod_html(tp)}}'
                >
                {{! helper.get_on_off(elt.check_period.is_time_valid(now), 'Is element check period currently active?')}}
                <a href="/timeperiods">{{elt.check_period.alias}}</a>
              </td>
              %else:
              <td name="check_period">
                Always
              </td>
              %end
            </tr>
            %if elt.maintenance_period is not None:
            <tr>
              <td><strong>Maintenance period:</strong></td>
              %tp=app.datamgr.get_timeperiod(elt.maintenance_period.get_name())
              <td name="maintenance_period" class="popover-dismiss"
                data-html="true" data-toggle="popover" data-placement="left"
                data-title='{{tp.alias if hasattr(tp, "alias") else tp.timeperiod_name}}'
                data-content='{{!helper.get_timeperiod_html(tp)}}'
                >
                {{! helper.get_on_off(elt.maintenance_period.is_time_valid(now), 'Is element maintenance period currently active?')}}
                <a href="/timeperiods">{{elt.maintenance_period.alias}}</a>
              </td>
            </tr>
            %end
            <tr>
              <td><strong>Check command:</strong></td>
              <td>
                %if elt.check_command:
                <a href="/commands#{{elt.get_check_command()}}">{{elt.get_check_command()}}</a>
                %else:
                <strong>No check command</strong>
                %end
              </td>
              <td>
              </td>
            </tr>
            <tr>
              <td><strong>Active checks:</strong></td>
              <td>
                <input type="checkbox" class="js-toggle-parameter"
                {{'checked' if elt.active_checks_enabled else ''}}
                {{'readonly' if not app.can_action() else ''}}
                data-action="toggle_active_checks"
                data-element="{{helper.get_uri_name(elt)}}"
                >
              </td>
            </tr>
            %if (elt.active_checks_enabled):
            <tr>
              <td><strong>Check interval:</strong></td>
              <td>{{elt.check_interval * configintervallength}} seconds</td>
            </tr>
            <tr>
              <td><strong>Retry interval:</strong></td>
              <td>{{elt.retry_interval * configintervallength}} seconds</td>
            </tr>
            <tr>
              <td><strong>Max check attempts:</strong></td>
              <td>{{elt.max_check_attempts}}</td>
            </tr>
            %end
            <tr>
              <td><strong>Passive checks:</strong></td>
              <td>
                <input type="checkbox" class="js-toggle-parameter"
                {{'checked' if elt.passive_checks_enabled else ''}}
                {{'readonly' if not app.can_action() else ''}}
                data-action="toggle_passive_checks"
                data-element="{{helper.get_uri_name(elt)}}"
                >
              </td>
            </tr>
            %if (elt.passive_checks_enabled):
            <tr>
              <td><strong>Freshness check:</strong></td>
              <td>{{! helper.get_on_off(elt.check_freshness, 'Is freshness check enabled?')}}</td>
            </tr>
            %if (elt.check_freshness):
            <tr>
              <td><strong>Freshness threshold:</strong></td>
              <td>{{elt.freshness_threshold}} seconds</td>
            </tr>
            %end
            %end
            <tr>
              <td><strong>Process performance data:</strong></td>
              <td>{{! helper.get_on_off(elt.process_perf_data, 'Is perfdata process enabled?')}}</td>
            </tr>
          </tbody>
        </table>
      </div>

      <div class="col-lg-6">
        %if elt.notes or elt.notes_url:
        <h4 class="page-header">Notes</h4>

        %if elt.notes:
        <ul class="list-group">
        %for note in helper.get_element_notes(elt, popover=False, css='class="list-group-item"'):
          {{! note}}
        %end
        </ul>
        %end

        %if elt.notes_url:
        <ul class="list-inline">
        %for note in helper.get_element_notes_url(elt, default_title="More notes", default_icon="external-link-square", popover=True, css='class="btn btn-info"'):
          <li>{{! note}}</li>
        %end
        </ul>
        %end
        %end

        %if elt.action_url:
        <h4 class="page-header">Actions</h4>
        <ul class="list-inline">
        %for action in helper.get_element_actions_url(elt, default_title="Launch custom action", default_icon="cogs", popover=True, css='class="btn btn-warning"'):
          <li>{{! action}}</li>
        %end
        </ul>
        %end

        %elt_type = elt.__class__.my_type
        %tags = elt.get_service_tags() if elt_type=='service' else elt.get_host_tags()
        %if tags:
        %tag='stag' if elt_type=='service' else 'htag'
        <h4 class="page-header">Tags</h4>
        <div class="btn-group">
          %for t in sorted(tags):
            <a href="/all?search={{tag}}:{{t}}">
            %if app.tag_as_image:
               <img src="/tag/{{t.lower()}}" alt="{{t.lower()}}" =title="Tag: {{t.lower()}}" style="height: 24px"></img>
            %else:
               <button class="btn btn-default btn-xs bg-{{elt_type}}"><i class="fa fa-tag"></i> {{t.lower()}}</button>
            %end
            </a>
          %end
        </div>
        %end

        %if elt.event_handler:
        <h4 class="page-header">Event handler</h4>
        <table class="table table-condensed">
          <colgroup>
            <col style="width: 40%" />
            <col style="width: 60%" />
          </colgroup>
          <tbody class="small">
            <tr>
              <td><strong>Event handler enabled:</strong></td>
              <td>
                <input type="checkbox" class="js-toggle-parameter"
                {{'checked' if elt.event_handler_enabled else ''}}
                {{'readonly' if not app.can_action() else ''}}
                data-action="toggle_event_handlers"
                data-element="{{helper.get_uri_name(elt)}}"
                >
              </td>
            </tr>
            <tr>
              <td><strong>Event handler:</strong></td>
              <td>
                <a href="/commands#{{elt.event_handler.get_name()}}">{{ elt.event_handler.get_name() }}</a>
              </td>
            </tr>
          </tbody>
        </table>
        %end

        <h4 class="page-header">Flapping detection</h4>
        <table class="table table-condensed">
          <colgroup>
            <col style="width: 40%" />
            <col style="width: 60%" />
          </colgroup>
          <tbody class="small">
            <tr>
              <td><strong>Flapping detection:</strong></td>
              <td>
                <input type="checkbox" class="js-toggle-parameter"
                {{'checked' if elt.flap_detection_enabled else ''}}
                {{'readonly' if not app.can_action() else ''}}
                data-action="toggle_flap_detection"
                data-element="{{helper.get_uri_name(elt)}}"
                >
              </td>
            </tr>
            %if elt.flap_detection_enabled:
            <tr>
              <td><strong>Options:</strong></td>
              <td>{{', '.join(elt.flap_detection_options)}}</td>
            </tr>
            <tr>
              <td><strong>Low threshold:</strong></td>
              <td>{{elt.low_flap_threshold}}</td>
            </tr>
            <tr>
              <td><strong>High threshold:</strong></td>
              <td>{{elt.high_flap_threshold}}</td>
            </tr>
            %end
          </tbody>
        </table>

        %if elt.stalking_options and elt.stalking_options[0]:
        <h4 class="page-header">Stalking options</h4>
        <table class="table table-condensed">
          <colgroup>
            <col style="width: 40%" />
            <col style="width: 60%" />
          </colgroup>
          <tbody class="small">
            <tr>
              <td><strong>Options:</strong></td>
              <td>{{', '.join(elt.stalking_options)}}</td>
            </tr>
          </tbody>
        </table>
        %end

        <h4 class="page-header">Notifications</h4>
        <table class="table table-condensed">
          <colgroup>
            <col style="width: 40%" />
            <col style="width: 60%" />
          </colgroup>
          <tbody class="small">
            <tr>
              <td><strong>Importance:</strong></td>
              <td>
                {{!helper.get_business_impact_text(elt.business_impact, True)}}
              </td>
            </tr>
            <tr>
              <td><strong>Notifications:</strong></td>
              <td>
                <input type="checkbox" class="js-toggle-parameter"
                {{'checked' if elt.notifications_enabled else ''}}
                {{'readonly' if not app.can_action() else ''}}
                data-action="toggle_notifications"
                data-element="{{helper.get_uri_name(elt)}}"
                >
              </td>
            </tr>
            %if elt.notifications_enabled:
            <tr>
              <td><strong>Notification period:</strong></td>
              %if elt.notification_period:
              %tp=app.datamgr.get_timeperiod(elt.notification_period.get_name())
              <td name="notification_period" class="popover-dismiss" data-html="true" data-toggle="popover" data-placement="left"
                data-title='{{tp.alias if hasattr(tp, "alias") else tp.timeperiod_name}}'
                data-content='{{!helper.get_timeperiod_html(tp)}}'>
                {{! helper.get_on_off(elt.notification_period.is_time_valid(now), 'Is element notification period currently active?')}}
                <a href="/timeperiods">{{elt.notification_period.alias}}</a>
              </td>
              %else:
              <td name="notification_period">
                Always
              </td>
              %end
            </tr>
            <tr>
              %if elt_type=='host':
              %message = {}
              %# [d,u,r,f,s,n]
              %message['d'] = 'Down'
              %message['u'] = 'Unreachable'
              %message['r'] = 'Recovery'
              %message['f'] = 'Flapping'
              %message['s'] = 'Downtimes'
              %message['n'] = 'None'
              %else:
              %message = {}
              %# [w,u,c,r,f,s,n]
              %message['w'] = 'Warning'
              %message['u'] = 'Unknown'
              %message['c'] = 'Critical'
              %message['r'] = 'Recovery'
              %message['f'] = 'Flapping'
              %message['s'] = 'Downtimes'
              %message['n'] = 'None'
              %end
              <td><strong>Notification options:</strong></td>
              <td>
                %for m in message:
                {{! helper.get_on_off(m in elt.notification_options, '', message[m]+'&nbsp;')}}
                %end
              </td>
            </tr>
            <tr>
              <td><strong>Last notification:</strong></td>
              <td>{{helper.print_date(elt.last_notification)}} (notification {{elt.current_notification_number}})</td>
            </tr>
            <tr>
              <td><strong>Notification interval:</strong></td>
              <td>{{elt.notification_interval}} mn</td>
            </tr>
            <tr>
              <td><strong>Contacts:</strong></td>
              <td>
                %contacts = [c for c in elt.contacts if app.datamgr.get_contact(name=c.contact_name, user=user)]
                %for c in contacts:
                <a href="/contact/{{c.contact_name}}">{{ c.alias if c.alias and c.alias != 'none' else c.contact_name }}</a>,
                %end
              </td>
            </tr>
            <tr>
              <td><strong>Contacts groups:</strong></td>
              <td>
                %contact_groups = [c for c in elt.contact_groups if app.datamgr.get_contactgroup(c, user)]
                {{!', '.join(contact_groups)}}
              </td>
            </tr>
            %end
          </tbody>
        </table>

        %# Could be displayed here
        %#<dt>Member of:</dt>
        %#%if elt_service.servicegroups:
        %#<dd>
          %#%for sg in elt_service.servicegroups:
          %#<a href="/services-group/{{sg.get_name()}}" class="link">{{sg.alias}} ({{sg.get_name()}})</a>
          %#%end
          %#</dd>
        %#%else:
        %#<dd>(none)</dd>
        %#%end

      </div>
      </div>
    </div>
  </div>
</div>
