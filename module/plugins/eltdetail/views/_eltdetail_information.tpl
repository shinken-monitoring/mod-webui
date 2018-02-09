<div class="tab-pane fade {{_go_active}} {{_go_fadein}}" id="information">
  <div class="panel panel-default" style="border-top:none; border-radius:0;">
    <div class="panel-body">
      <div class="col-lg-6">
        <h4 class="page-header">Status</h4>
        <table class="table table-condensed">
          <colgroup>
            <col style="width: 40%" />
            <col style="width: 60%" />
          </colgroup>
          <tbody style="font-size:x-small;">
            <tr>
              <td><strong>Status:</strong></td>
              <td>
                {{! helper.get_fa_icon_state(obj=elt, label='title')}}
              </td>
            </tr>
            <tr>
              <td><strong>Since:</strong></td>
              <td><span class="popover-dismiss"
                  data-html="true" data-toggle="popover" data-placement="bottom"
                  data-title="{{elt.get_full_name()}} last state change date"
                  data-content=" {{time.strftime('%d %b %Y %H:%M:%S', time.localtime(elt.last_state_change))}} "
                  >
                  {{! helper.print_duration(elt.last_state_change, just_duration=True, x_elts=2)}}
                </span>
              </td>
            </tr>
            <tr>
              <td><strong>Importance:</strong></td>
              <td>
                {{!helper.get_business_impact_text(elt.business_impact, True)}}
              </td>
            </tr>
          </tbody>
        </table>

        <h4 class="page-header">Last check</h4>
        <table class="table table-condensed table-nowrap">
          <colgroup>
            <col style="width: 40%" />
            <col style="width: 60%" />
          </colgroup>
          <tbody style="font-size:x-small;">
            <tr>
              <td><strong>Last Check:</strong></td>
              <td><span class="popover-dismiss" data-html="true" data-toggle="popover" data-placement="bottom" data-content="Last check was at {{time.asctime(time.localtime(elt.last_chk))}}">was {{helper.print_duration(elt.last_chk)}}</span></td>
            </tr>
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

        <h4 class="page-header">Checks configuration</h4>
        <table class="table table-condensed">
          <colgroup>
            <col style="width: 40%" />
            <col style="width: 60%" />
          </colgroup>
          <tbody style="font-size:x-small;">
            %if hasattr(elt, "check_period") and hasattr(elt.check_period, "get_name"):
            <tr>
              <td><strong>Check period:</strong></td>
              %tp=app.datamgr.get_timeperiod(elt.check_period.get_name())
              <td name="check_period" class="popover-dismiss"
                data-html="true" data-toggle="popover" data-placement="left"
                data-title='{{tp.alias if hasattr(tp, "alias") else tp.timeperiod_name}}'
                data-content='{{!helper.get_timeperiod_html(tp)}}'
                >
                {{! helper.get_on_off(elt.check_period.is_time_valid(now), 'Is element check period currently active?')}}
                <a href="/timeperiods">{{elt.check_period.alias}}</a>
              </td>
            </tr>
            %else:
            <tr>
              <td><strong>No defined check period!</strong></td>
              <td></td>
            </tr>
            %end
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
                <a href="/commands#{{elt.get_check_command()}}">{{elt.get_check_command()}}</a>
              </td>
              <td>
              </td>
            </tr>
            <tr>
              <td><strong>Active checks:</strong></td>
              <td>
                <input type="checkbox" class="switch"
                {{'checked' if elt.active_checks_enabled else ''}}
                {{'readonly' if not app.can_action() else ''}}
                data-size="mini"
                data-on-color="success" data-off-color="danger"
                data-type="action" action="toggle-active-checks"
                data-element="{{helper.get_uri_name(elt)}}"
                data-value="{{elt.active_checks_enabled}}"
                >
              </td>
            </tr>
            %if (elt.active_checks_enabled):
            <tr>
              <td><strong>Check interval:</strong></td>
              <td>{{elt.check_interval*configintervallength}} seconds</td>
            </tr>
            <tr>
              <td><strong>Retry interval:</strong></td>
              <td>{{elt.retry_interval*configintervallength}} seconds</td>
            </tr>
            <tr>
              <td><strong>Max check attempts:</strong></td>
              <td>{{elt.max_check_attempts}}</td>
            </tr>
            %end
            <tr>
              <td><strong>Passive checks:</strong></td>
              <td>
                <input type="checkbox" class="switch"
                {{'checked' if elt.passive_checks_enabled else ''}}
                {{'readonly' if not app.can_action() else ''}}
                data-size="mini"
                data-on-color="success" data-off-color="danger"
                data-type="action" action="toggle-passive-checks"
                data-element="{{helper.get_uri_name(elt)}}"
                data-value="{{elt.passive_checks_enabled}}"
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
        %if elt.notes_url or elt.action_url or elt.notes:
        <h4 class="page-header">Notes</h4>
        %if elt.notes != '':
        <p>{{ elt.notes }}</p>
        %end
        <div>
          %if elt.notes_url != '':
          <a class="btn btn-info" href="{{elt.notes_url}}" target=_blank><i class="fa fa-external-link-square"></i> More notes</a>
          %end
          %if elt.action_url != '':
          <a class="btn btn-warning" href="{{elt.action_url}}" target=_blank title="{{ elt.action_url }}"><i class="fa fa-cogs"></i> Launch custom action</a>
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
          <tbody style="font-size:x-small;">
            <tr>
              <td><strong>Event handler enabled:</strong></td>
              <td>
                <input type="checkbox" class="switch"
                {{'checked' if elt.event_handler_enabled else ''}}
                {{'readonly' if not app.can_action() else ''}}
                data-size="mini"
                data-on-color="success" data-off-color="danger"
                data-type="action" action="toggle-event-handler"
                data-element="{{helper.get_uri_name(elt)}}"
                data-value="{{elt.event_handler_enabled}}"
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
          <tbody style="font-size:x-small;">
            <tr>
              <td><strong>Flapping detection:</strong></td>
              <td>
                <input type="checkbox" class="switch"
                {{'checked' if elt.flap_detection_enabled else ''}}
                {{'readonly' if not app.can_action() else ''}}
                data-size="mini"
                data-on-color="success" data-off-color="danger"
                data-type="action" action="toggle-flap-detection"
                data-element="{{helper.get_uri_name(elt)}}"
                data-value="{{elt.flap_detection_enabled}}"
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
          <tbody style="font-size:x-small;">
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
          <tbody style="font-size:x-small;">
            <tr>
              <td><strong>Notifications:</strong></td>
              <td>
                <input type="checkbox" class="switch"
                {{'checked' if elt.notifications_enabled else ''}}
                {{'readonly' if not app.can_action() else ''}}
                data-size="mini"
                data-on-color="success" data-off-color="danger"
                data-type="action" action="toggle-notifications"
                data-element="{{helper.get_uri_name(elt)}}"
                data-value="{{elt.notifications_enabled}}"
                >
              </td>
            </tr>
            %if elt.notifications_enabled and elt.notification_period:
            <tr>
              <td><strong>Notification period:</strong></td>
              %tp=app.datamgr.get_timeperiod(elt.notification_period.get_name())
              <td name="notification_period" class="popover-dismiss" data-html="true" data-toggle="popover" data-placement="left"
                data-title='{{tp.alias if hasattr(tp, "alias") else tp.timeperiod_name}}'
                data-content='{{!helper.get_timeperiod_html(tp)}}'>
                {{! helper.get_on_off(elt.notification_period.is_time_valid(now), 'Is element notification period currently active?')}}
                <a href="/timeperiods">{{elt.notification_period.alias}}</a>
              </td>
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
