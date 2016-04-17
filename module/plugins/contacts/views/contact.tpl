%import time
%import json

%# If got no element, bailout
%if not contact:
%rebase("layout", title='Invalid contact name')
%end

%helper = app.helper

%username = 'anonymous'
%if hasattr(contact, 'alias') and contact.alias != 'none':
%username = contact.alias
%else:
%username = contact.contact_name
%end

%rebase("layout", title='Contact ' + username, breadcrumb=[ ['All contacts', '/contacts'], [username, '/contact/'+username] ])

%#Contact currently in downtime ?
%in_scheduled_downtime=False
%for dt in contact.downtimes:
%if dt.is_in_effect:
%in_scheduled_downtime=True
%end
%end

%# Contact is linked to hosts/services
%my_hosts = []
%for item in app.datamgr.get_hosts(user):
   %for item_contact in item.contacts:
      %if item_contact.contact_name == contact.contact_name:
         %my_hosts.append(item)
      %end
   %end
%end
%my_services = []
%for item in app.datamgr.get_services(user):
   %for item_contact in item.contacts:
      %if item_contact.contact_name == contact.contact_name:
         %my_services.append(item)
      %end
   %end
%end
%my_contactgroups = []
%for item in app.datamgr.get_contactgroups(user):
  %for item_contact in item.members:
    %if item_contact.contact_name == contact.contact_name:
      %my_contactgroups.append(item)
    %end
  %end
%end


<div class="row">
   <div class="col-sm-12">
      <div class="panel panel-default">
         <div class="panel-heading">
            <h2 class="panel-title">Contact</h2>
         </div>
         <div class="panel-body">
            <!-- User image / user name / user category -->
            <div class="user-header bg-light-blue">
               <img src="{{app.user_picture}}" class="img-circle user-logo" alt="{{username}}" title="Photo: {{username}}">

               <p class="username">
                 {{username}}
               </p>
               %if app.manage_acl:
               <p class="usercategory">
                  <small>{{'Administrator' if contact.is_admin else 'User'}}</small>
               </p>
               %end
            </div>

            <div class="user-body">
               %if contact.downtimes:
               <table class="table table-condensed col-sm-12" style="table-layout: fixed; word-wrap: break-word;">
                  <colgroup>
                     <col style="width: 30%" />
                     <col style="width: 70%" />
                  </colgroup>
                  <thead>
                     <tr>
                       <th>Author</th>
                       <th>Reason</th>
                       <th>Period</th>
                       <th></th>
                     </tr>
                  </thead>
                  <tbody style="font-size:x-small;">
                        %for dt in sorted(contact.downtimes, key=lambda dt: dt.entry_time, reverse=True):
                           <tr>
                              <td>{{dt.author}}</td>
                           </tr>
                        %end
                        %for dt in sorted(contact.downtimes, key=lambda dt: dt.entry_time, reverse=True):
                           <tr>
                              <td>{{dt.author}}</td>
                              <td>{{dt.comment}}</td>
                              <td>{{helper.print_date(dt.start_time)}} - {{helper.print_date(dt.end_time)}}</td>
                              <td>
                                 <button class="{{'disabled' if not app.can_action() else ''}} btn btn-primary btn-sm"
                                       data-type="action" action="delete-downtime"
                                       data-toggle="tooltip" data-placement="bottom" title="Delete the downtime '{{dt.id}}' for this {{elt_type}}"
                                       data-element="{{helper.get_uri_name(contact)}}" data-downtime="{{dt.id}}"
                                       >
                                    <i class="fa fa-trash-o"></i>
                                 </button>
                              </td>
                           </tr>
                        %end
                  </tbody>
               </table>
               %end

               <!--
               <button class="{{'disabled' if not app.can_action() else ''}} btn btn-primary btn-sm"
                       data-type="action" action="schedule-downtime"
                       data-toggle="tooltip" data-placement="bottom" title="Schedule a downtime for this contact"
                       data-element="{{contact.contact_name}}"
                       >
                    <i class="fa fa-plus"></i> Schedule a downtime
               </button>
               %if contact.downtimes:
               <button class="{{'disabled' if not app.can_action() else ''}} btn btn-primary btn-sm"
                       data-type="action" action="delete-downtimes"
                       data-toggle="tooltip" data-placement="bottom" title="Delete all the downtimes of this contact"
                       data-element="{{contact.contact_name}}"
                       >
                    <i class="fa fa-minus"></i> Delete all downtimes
               </button>
               %end
               -->

               <table class="table table-condensed col-sm-12" style="table-layout: fixed; word-wrap: break-word;">
                  <colgroup>
                     <col style="width: 30%" />
                     <col style="width: 70%" />
                  </colgroup>
                  <thead>
                     <tr>
                        <th colspan="2"></th>
                     </tr>
                  </thead>
                  <tbody style="font-size:x-small;">
                     <tr>
                        <td><strong>Identification:</strong></td>
                        <td>{{"%s (%s)" % (contact.alias, contact.contact_name) if contact.alias != 'none' else contact.contact_name}}</td>
                     </tr>
                     <tr>
                        <td><strong>Commands authorized:</strong></td>
                        <td>{{! app.helper.get_on_off(app.can_action(contact.contact_name), "Is this contact allowed to launch commands from Web UI?")}}</td>
                     </tr>
                     <tr>
                        <td><strong>Active:</strong></td>
                        <td>{{! app.helper.get_on_off(not in_scheduled_downtime, "Is this contact available (else in scheduled downtime)?")}}</td>
                     </tr>
                     <tr>
                        <td><strong>Mail:</strong></td>
                        <td>{{contact.email}}</td>
                     </tr>
                     <tr>
                        <td><strong>Pager:</strong></td>
                        <td>{{contact.pager}}</td>
                     </tr>
                     %if contact.address1 != 'none':
                     <tr>
                        <td><strong>Address:</strong></td>
                        <td>{{contact.address1}}</td>
                     </tr>
                     %end
                     %if contact.address2 != 'none':
                     <tr>
                        <td><strong></strong></td>
                        <td>{{contact.address2 if contact.address2 else ''}}</td>
                     </tr>
                     %end
                     %if contact.address3 != 'none':
                     <tr>
                        <td><strong></strong></td>
                        <td>{{contact.address3 if contact.address3 else ''}}</td>
                     </tr>
                     %end
                     %if contact.address4 != 'none':
                     <tr>
                        <td><strong></strong></td>
                        <td>{{contact.address4 if contact.address4 else ''}}</td>
                     </tr>
                     %end
                     %if contact.address5 != 'none':
                     <tr>
                        <td><strong></strong></td>
                        <td>{{contact.address5 if contact.address5 else ''}}</td>
                     </tr>
                     %end
                     %if contact.address6 != 'none':
                     <tr>
                        <td><strong></strong></td>
                        <td>{{contact.address6 if contact.address6 else ''}}</td>
                     </tr>
                     %end
                  </tbody>
               </table>

               <table class="table table-condensed col-sm-12" style="table-layout: fixed; word-wrap: break-word;">
                  <colgroup>
                     <col style="width: 30%" />
                     <col style="width: 70%" />
                  </colgroup>
                  <thead>
                     <tr>
                        <th colspan="2">Configuration:</td>
                     </tr>
                  </thead>
                  <tbody style="font-size:x-small;">
                     <tr>
                        <td><strong>Tags:</strong></td>
                        <td>
                           %if len(contact.tags) > 0:
                           <div id="contact_tags" class="btn-group pull-left">
                              <script>
                              %j=0
                              %for t in sorted(contact.tags):
                              var b{{j}} = $('<a href="/all?search=ctag:{{t}}"/>').appendTo($('#contact_tags'));
                              $('<img />')
                                 .attr({ 'src': '/static/images/tags/{{t.lower()}}.png', 'alt': '{{t.lower()}}', 'title': 'Tag: {{t.lower()}}' })
                                 .css({height: "24px"})
                                 .load(function() {
                                 })
                                 .error(function() {
                                    $(this).remove();
                                    $("<span/>").attr({ 'class': 'btn btn-default btn-primary btn-xs '}).append('{{t}}').appendTo(b{{j}});
                                 })
                                 .appendTo(b{{j}});
                              var span = $("<span/>").append('&nbsp;').appendTo($('#contact_tags'));
                              %j=j+1
                              %end
                              </script>
                           </div>
                           %end
                        </td>
                     </tr>
                     %i=1
                     %for nw in contact.notificationways:
                     <tr>
                        <td><strong>{{"Notification way:" if i==1 else "Notification way %d:"%i}}</strong></td>
                        <td>{{nw.notificationway_name}}</td>
                     </tr>
                     <tr>
                        <td><strong>&raquo;&nbsp;Minimum business impact:</strong></td>
                        <td>{{nw.min_business_impact}} - {{app.helper.get_business_impact_text(nw.min_business_impact, True)}}</td>
                     </tr>

                     <tr>
                        <td colspan="2"><strong>&raquo;&nbsp;Hosts notifications:</strong>&nbsp;{{! app.helper.get_on_off(not in_scheduled_downtime, "Are hosts notifications sent to this contact?")}}</td>
                     </tr>
                     %if nw.host_notifications_enabled:
                     <tr>
                        <td><strong>&nbsp;&ndash;&nbsp;period:</strong></td>
                        <td name="{{"host_notification_period%s" % i}}" class="popover-dismiss" data-html="true" data-toggle="popover" data-trigger="hover" title="Host notification period" data-placement="top" data-content="...">{{! app.helper.get_on_off(nw.host_notification_period.is_time_valid(time.time()), "Is notification period currently active?")}}
                           <a href="/timeperiods">{{nw.host_notification_period.alias}}</a>
                           <script>
                              %tp=app.datamgr.get_timeperiod(nw.host_notification_period.get_name())
                              $('td[name="{{"host_notification_period%s" % i}}"]')
                                .attr('title', '{{tp.alias if hasattr(tp, "alias") else tp.timeperiod_name}}')
                                .attr('data-content', '{{! app.helper.get_timeperiod_html(tp)}}')
                                .popover();
                           </script>
                        </td>
                     </tr>

                     %if nw.host_notification_options != '':
                     %options = nw.host_notification_options
                     %message = {}
                     %# [d,u,r,f,s,n]
                     %message['d'] = 'Down'
                     %message['u'] = 'Unreachable'
                     %message['r'] = 'Recovery'
                     %message['f'] = 'Flapping'
                     %message['s'] = 'Downtimes'
                     %message['n'] = 'None'
                     <tr>
                        <td><strong>&nbsp;&ndash;&nbsp;options:</strong></td>
                        <td>
                        %for m in message:
                           {{! app.helper.get_on_off(m in options, '', message[m]+'&nbsp;')}}
                        %end
                        </td>
                     </tr>
                     %end

                     %i=0
                     %for command in nw.host_notification_commands:
                       %i += 1
                       <tr>
                           <td><strong>&nbsp;&ndash;&nbsp;command:</strong></td>
                           <td name="host_command{{i}}" class="popover-dismiss" data-html="true" data-toggle="popover" data-trigger="hover" title="Host notification command" data-placement="top" data-content="...">
                              <a href="/commands#{{command.get_name()}}">{{command.get_name()}}</a>
                              <script>
                              $('td[name="host_command{{i}}"]')
                                .attr('title', '{{command.get_name()}}')
                                .attr('data-content', '{{json.dumps(command.command.command_line)}}')
                                .popover();
                              </script>
                           </td>
                        </tr>
                     %end
                     %end
                     %# If host notifications enabled ...


                     <tr>
                        <td colspan="2"><strong>&raquo;&nbsp;Services notifications:</strong>&nbsp;{{! app.helper.get_on_off(nw.service_notifications_enabled, "Are services notifications sent to this contact?")}}</td>
                     </tr>
                     %if nw.service_notifications_enabled:
                     <tr>
                        <td><strong>&nbsp;&ndash;&nbsp;period:</strong></td>
                        <td name="{{"service_notification_period%s" % i}}" class="popover-dismiss" data-html="true" data-toggle="popover" data-trigger="hover" title="service notification period" data-placement="top" data-content="...">{{! app.helper.get_on_off(nw.service_notification_period.is_time_valid(time.time()), "Is notification period currently active?")}}
                           <a href="/timeperiods">{{nw.service_notification_period.alias}}</a>
                           <script>
                            %tp=app.datamgr.get_timeperiod(nw.service_notification_period.get_name())
                            $('td[name="{{"service_notification_period%s" % i}}"]')
                              .attr('title', '{{tp.alias if hasattr(tp, "alias") else tp.timeperiod_name}}')
                              .attr('data-content', '{{!app.helper.get_timeperiod_html(tp)}}')
                              .popover();
                           </script>
                        </td>
                     </tr>

                     %if nw.service_notification_options != '':
                     %options = nw.service_notification_options
                     %message = {}
                     %# [w,u,c,r,f,s,n]
                     %message['w'] = 'Warning'
                     %message['u'] = 'Unknown'
                     %message['c'] = 'Critical'
                     %message['r'] = 'Recovery'
                     %message['f'] = 'Flapping'
                     %message['s'] = 'Downtimes'
                     %message['n'] = 'None'
                     <tr>
                        <td><strong>&nbsp;&ndash;&nbsp;options:</strong></td>
                        <td>
                        %for m in message:
                           {{! app.helper.get_on_off(m in options, '', message[m]+'&nbsp;')}}
                        %end
                        </td>
                     </tr>
                     %end

                     %i=0
                     %for command in nw.service_notification_commands:
                        %i += 1
                        <tr>
                           <td><strong>&nbsp;&ndash;command:</strong></td>
                           <td name="service_command{{i}}" class="popover-dismiss" data-html="true" data-toggle="popover" data-trigger="hover" title="Service notification command" data-placement="top" data-content="...">
                              <a href="/commands#{{command.get_name()}}">{{command.get_name()}}</a>
                              <script>
                                 $('td[name="service_command{{i}}"]')
                                   .attr('title', '{{command.get_name()}}')
                                   .attr('data-content', '{{json.dumps(command.command.command_line)}}')
                                   .popover();
                              </script>
                           </td>
                        </tr>
                     %end
                     %end
                     %# If service notifications enabled ...


                  %i+=1
                  %end
                  %# For notificationways ...
                  </tbody>
               </table>

               %if contact.customs:
               <table class="table table-condensed col-sm-12" style="table-layout: fixed; word-wrap: break-word;">
                  <colgroup>
                     <col style="width: 30%" />
                     <col style="width: 70%" />
                  </colgroup>
                  <thead>
                     <tr>
                        <th colspan="2">Customs:</td>
                     </tr>
                  </thead>
                  <tbody style="font-size:x-small;">
                        %for var in sorted(contact.customs):
                           <tr>
                              <td>{{var}}</td>
                              <td>{{contact.customs[var]}}</td>
                              %if app.can_action():
                              <td>
                                 <button class="{{'disabled' if not app.can_action() else ''}} btn btn-primary btn-sm"
                                       data-type="action" action="change-variable"
                                       data-toggle="tooltip" data-placement="bottom" title="Change a custom variable for this {{elt_type}}"
                                       data-element="{{helper.get_uri_name(contact)}}" data-variable="{{var}}" data-value="{{contact.customs[var]}}"
                                       >
                                    <i class="fa fa-gears"></i> Change
                                 </button>
                              </td>
                              %end
                           </tr>
                        %end
                  </tbody>
               </table>
               %end

               <table class="table table-condensed col-sm-12" style="table-layout: fixed; word-wrap: break-word;">
                  <colgroup>
                     <col style="width: 30%" />
                     <col style="width: 70%" />
                  </colgroup>
                  <thead>
                     <tr>
                        <th colspan="2">Relations:</td>
                     </tr>
                  </thead>
                  <tbody style="font-size:x-small;">
                     <tr>
                        <td><strong>Hosts:</strong></td>
                        <td>
                        %i=1
                        %for item in my_hosts:
                          {{', ' if i!=1 else ''}}{{!app.helper.get_link(item, short=True)}}
                          %i+=1
                          %if i > 20:
                          <span title="Only the 20 first hosts are listed ... some more are related to this contact."> ... </span>
                          %break
                          %end
                        %end
                        {{!'<i class="glyphicon glyphicon-remove font-red"></i> Do not monitor any host' if i==1 else ''}}
                        </td>
                     </tr>
                     <tr>
                        <td><strong>Services:</strong></td>
                        <td>
                        %i=1
                        %for item in my_services:
                          {{', ' if i!=1 else ''}}{{!app.helper.get_link(item, short=False)}}
                          %i+=1
                          %if i > 50:
                          <span title="Only the 50 first services are listed ... some more are related to this contact."> ... </span>
                          %break
                          %end
                        %end
                        {{!'<i class="glyphicon glyphicon-remove font-red"></i> Do not monitor any service' if i==1 else ''}}
                        </td>
                     </tr>
                     <tr>
                        <td><strong>Contacts groups:</strong></td>
                        <td>
                        %i=1
                        %for item in my_contactgroups:
                          {{', ' if i!=1 else ''}}<a href="/all?search=cg:{{item.get_name()}}">{{item.alias if item.alias!='' else item.get_name()}}</a>
                          %i+=1
                          %if i > 20:
                          <span> ... </span>
                          %break
                          %end
                        %end
                        {{!'<i class="glyphicon glyphicon-remove font-red"></i> Do not belong to any group' if i==1 else ''}}
                        </td>
                     </tr>
                  </tbody>
               </table>
            </div>
         </div>
      </div>
   </div>
</div>
