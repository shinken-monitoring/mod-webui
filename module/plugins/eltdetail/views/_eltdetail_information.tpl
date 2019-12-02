%elt_type = elt.__class__.my_type

<div class="tab-pane fade {{_go_active}} {{_go_fadein}}" id="information">
  <div class="panel panel-default" style="border-top:none; border-radius:0;">
    <div class="panel-body">

      <div class="col-lg-6">

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

        <h4 class="page-header"><i class="fas fa-bolt"></i> Last check</h4>
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
              <td><strong>Last State Update:</strong></td>
              <td><span class="popover-dismiss" data-html="true" data-toggle="popover" data-placement="bottom" data-content="Last state update at {{time.asctime(time.localtime(elt.last_state_update))}}">{{helper.print_duration(elt.last_state_update)}}</span></td>
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

        %if elt.perf_data:
        <h4 class="page-header"><i class="fas fa-chart-line"></i> Performance data</h4>
        <div>
          {{!helper.get_perfdata_table(elt)}}
        </div>
        %end

        <h4 class="page-header"><i class="fas fa-cogs"></i> Checks configuration</h4>
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
            %enabled = app.datamgr.get_configuration_parameter('execute_host_checks' if elt_type == 'host' else 'execute_service_checks')
            <tr>
              <td><strong>Active checks:</strong></td>
              <td>
                <input type="checkbox" class="js-toggle-parameter"
                {{'checked' if elt.active_checks_enabled else ''}}
                title="{{'Disable active checks' if elt.active_checks_enabled else 'Enable active checks'}}"
                {{'disabled' if not (enabled and app.can_action()) else ''}}
                data-action="toggle_active_checks"
                data-element="{{helper.get_uri_name(elt)}}">
                %if not enabled:
                <em>&nbsp;Globally disabled by configuration</em>
                %end
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
            %enabled = app.datamgr.get_configuration_parameter('accept_passive_host_checks' if elt_type == 'host' else 'accept_passive_service_checks')
            <tr>
              <td><strong>Passive checks:</strong></td>
              <td>
                <input type="checkbox" class="js-toggle-parameter"
                {{'checked' if elt.passive_checks_enabled else ''}}
                title="{{'Disable passive checks' if elt.passive_checks_enabled else 'Enable passive checks'}}"
                {{'disabled' if not (enabled and app.can_action()) else ''}}
                data-action="toggle_passive_checks"
                data-element="{{helper.get_uri_name(elt)}}">
                %if not enabled:
                <em>&nbsp;Globally disabled by configuration</em>
                %end
              </td>
            </tr>
            %if (elt.passive_checks_enabled):
            %enabled = app.datamgr.get_configuration_parameter('check_host_freshness' if elt_type == 'host' else 'check_service_freshness')
            <tr>
              <td><strong>Freshness check:</strong></td>
              <td>
                {{! helper.get_on_off(elt.check_freshness, 'Is freshness check enabled?')}}
                %if not enabled:
                <em>&nbsp;Globally disabled by configuration</em>
                %end
              </td>
            </tr>
            %if (elt.check_freshness):
            <tr>
              <td><strong>Freshness threshold:</strong></td>
              <td>{{elt.freshness_threshold}} seconds</td>
            </tr>
            %if (getattr(elt, 'freshness_state')):
            <tr>
              <td><strong>Freshness state:</strong></td>
              <td>{{elt.freshness_state}}</td>
            </tr>
            %end
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
        %some_doc = elt.notes or elt.notes_url or elt.action_url or elt.customs and ('_IMPACT' in elt.customs or '_DETAILLEDESC' in elt.customs or '_FIXACTIONS' in elt.customs)

        %if some_doc:
          <h4 class="page-header"><i class="fas fa-question-circle"></i> Documentation</h4>
          %if elt.notes or elt.notes_url:
            %if elt.notes:
            <p>{{! elt.notes}}</p>
            %end

            %if elt.notes_url:
              <ul class="list-inline">
              %for note in helper.get_element_notes_url(elt, icon="external-link-square", css='class="btn btn-info btn-xs"'):
              <li>{{! note}}</li>
              %end
              </ul>
            %end
          %end

          %if elt.action_url:
            <ul class="list-inline">
            %for action in helper.get_element_actions_url(elt, title="", icon="cogs", css='class="btn btn-warning btn-xs"'):
            <li>{{! action}}</li>
            %end
            </ul>
          %end

          %if elt.customs and ('_IMPACT' in elt.customs or '_DETAILLEDESC' in elt.customs or '_FIXACTIONS' in elt.customs):
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
        %end

        <h4 class="page-header"><i class="fas fa-paper-plane"></i> Notifications</h4>
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
            %enabled = app.datamgr.get_configuration_parameter('enable_notifications')
            <tr>
              <td><strong>Notifications:</strong></td>
              <td>
                <input type="checkbox" class="js-toggle-parameter"
                {{'checked' if elt.notifications_enabled else ''}}
                title="{{'Disable notifications' if elt.notifications_enabled else 'Enable notifications'}}"
                {{'disabled' if not (enabled and app.can_action()) else ''}}
                data-action="toggle_notifications"
                data-element="{{helper.get_uri_name(elt)}}">
                %if not enabled:
                <em>&nbsp;Globally disabled by configuration</em>
                %end
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
              %message['d'] = 'Down'
              %message['u'] = 'Unreachable'
              %message['x'] = 'Unreachable'
              %message['r'] = 'Recovery'
              %message['f'] = 'Flapping'
              %message['s'] = 'Downtimes'
              %message['n'] = 'None'
              %else:
              %message = {}
              %message['w'] = 'Warning'
              %message['u'] = 'Unknown'
              %message['x'] = 'Unreachable'
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

        %if elt.event_handler:
        <h4 class="page-header">Event handler</h4>
        <table class="table table-condensed">
          <colgroup>
            <col style="width: 40%" />
            <col style="width: 60%" />
          </colgroup>
          <tbody class="small">
            %enabled = app.datamgr.get_configuration_parameter('enable_flap_detection')
            <tr>
              <td><strong>Event handler enabled:</strong></td>
              <td>
                <input type="checkbox" class="js-toggle-parameter"
                {{'checked' if elt.event_handler_enabled else ''}}
                title="{{'Disable event handler' if elt.event_handler_enabled else 'Enable event handler'}}"
                {{'disabled' if not (enabled and app.can_action()) else ''}}
                data-action="toggle_event_handlers"
                data-element="{{helper.get_uri_name(elt)}}">
                %if not enabled:
                <em>&nbsp;Globally disabled by configuration</em>
                %end
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

        <h4 class="page-header"><i class="fas fa-arrows-alt-v"></i> Flapping detection</h4>
        <table class="table table-condensed">
          <colgroup>
            <col style="width: 40%" />
            <col style="width: 60%" />
          </colgroup>
          <tbody class="small">
            %enabled = app.datamgr.get_configuration_parameter('enable_flap_detection')
            <tr>
              <td><strong>Flapping detection:</strong></td>
              <td>
                <input type="checkbox" class="js-toggle-parameter"
                {{'checked' if elt.flap_detection_enabled else ''}}
                title="{{'Disable flapping detection' if elt.flap_detection_enabled else 'Enable flapping detection'}}"
                {{'disabled' if not (enabled and app.can_action()) else ''}}
                data-action="toggle_flap_detection"
                data-element="{{helper.get_uri_name(elt)}}">
                %if not enabled:
                <em>&nbsp;Globally disabled by configuration</em>
                %end
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
        <h4 class="page-header"><i class="fas fa-cogs"></i> Stalking options</h4>
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
        %tags = elt.get_service_tags() if elt_type=='service' else elt.get_host_tags()
        %if tags:
        %tag='stag' if elt_type=='service' else 'htag'
        <h4 class="page-header"><i class="fas fa-tag"></i> Tags</h4>
        <ul class="list-inline" style="line-height: 2;">
        %for t in sorted(tags):
        <li class="list-inline-item">
          %if app.tag_as_image:
          <a href="/all?search={{tag}}:{{t}}"><img src="/tag/{{t.lower()}}" alt="{{t.lower()}}" title="Tag: {{t.lower()}}" style="height: 24px"></img></a>
          %else:
          <a href="/all?search={{tag}}:{{t}}" class="btn btn-xs btn-default">{{t.lower()}}</a>
          %end
        </li>
        %end
        </ul>
        %end

        %if getattr(elt, 'hostgroups', None):
        <h4 class="page-header"><i class="fas fa-sitemap"></i> Hostgroups</h4>
        <ul class="list-inline" style="line-height: 2;">
        %for hg in elt.hostgroups:
        <li class="list-inline-item">
          <a href="/hosts-group/{{hg.get_name()}}" class="btn btn-xs btn-default">{{hg.get_name()}}{{" (%s)" % hg.alias if hg.alias != hg.get_name() else ""}}</a>
        </li>
        %end
        </ul>

        %end

      </div>
    </div>
  </div>
</div>
