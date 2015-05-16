%import time
%import json

%# If got no element, bailout
%if not contact:
%rebase layout title='Invalid contact name'

%else:

%username = 'anonymous'
%if user is not None: 
%if hasattr(contact, 'alias'):
%	username = contact.alias
%else:
%	username = contact.get_name()
%end
%end

%rebase layout title='Contact ' + username, user=user, app=app, refresh=True, css=['contacts/css/contacts.css'], breadcrumb=[ ['All contacts', '/contacts'], [username, '/contact/'+username] ]

%#Contact currently in downtime ?
%in_scheduled_downtime=False
%for dt in contact.downtimes:
%if dt.is_in_effect:
%in_scheduled_downtime=True
%end
%end

%# Contact is linked to hosts/services
%items=[]
%for item in app.get_hosts():
   %for item_contact in item.contacts:
      %if item_contact.contact_name == contact.contact_name and item not in items:
         %items.append(item)
      %end
   %end
%end
%my_hosts = [i for i in items if i.my_type == 'host']
%for item in app.get_services():
   %for item_contact in item.contacts:
      %if item_contact.contact_name == contact.contact_name and item not in items:
         %items.append(item)
      %end
   %end
%end
%my_services = [i for i in items if i.my_type == 'service']
%for item in app.get_contactgroups():
  %for item_contact in item.members:
    %if item_contact.contact_name == contact.contact_name and item not in items:
      %items.append(item)
    %end
  %end
%end
%my_contactgroups = [i for i in items if i.my_type == 'contactgroup']


%if not 'app' in locals(): app = None
%if not 'user' in locals(): user = None

<div class="row">
   <div class="col-sm-12 col-md-6">
      <div class="panel panel-default">
         <div class="panel-heading">
            <h2 class="panel-title">Contact</h2>
         </div>
         <div class="panel-body">
            <!-- User image -->
            <div class="user-header bg-light-blue">
               <script>
                  %if app is not None and app.gravatar:
                  $('<img src="{{app.get_gravatar(contact.email, 32)}}" class="img-circle user-logo" alt="{{username}}" title="Photo: {{username}}" style="display=none">')
                     .load(function() { $(this).show(); })
                     .error(function() { 
                        $(this).remove(); 
                        $('<img src="/static/images/logo/default_user.png" class="img-circle user-logo" alt="{{username}}" title="Photo: {{username}}" style="display=none">')
                           .load(function() { $(this).show(); })
                           .error(function() { $(this).remove(); })
                           .prependTo('div.user-header');
                     })
                     .prependTo('div.user-header');
                  %else:
               $('<img src="/static/images/logo/{{user.get_name()}}.png" class="img-circle user-logo" alt="{{username}}" title="Photo: {{username}}" style="display=none">')
                  .load(function() { $(this).show(); })
                  .error(function() { 
                     $(this).remove(); 
                     $('<img src="/static/images/logo/default_user.png" class="img-circle user-logo" alt="{{username}}" title="Photo: {{username}}" style="display=none">')
                        .load(function() { $(this).show(); })
                        .error(function() { $(this).remove(); })
                        .prependTo('div.user-header');
                  })
                  .prependTo('div.user-header');
                  %end
               </script>
            
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
               <table class="table table-condensed col-sm-12" style="table-layout: fixed; word-wrap: break-word;">
                  <colgroup>
                     <col style="width: 30%" />
                     <col style="width: 70%" />
                  </colgroup>
                  <thead>
                <tr>
                  <th colspan="2"></td>
                </tr>
              </thead>
              <tbody style="font-size:x-small;">
                <tr>
                  <td><strong>Identification:</strong></td>
                  <td>{{"%s (%s)" % (contact.alias, contact.contact_name) if contact.alias != 'none' else contact.contact_name}}</td>
                </tr>
                <tr>
                  <td><strong>Commands authorized:</strong></td>
                  <td><span class="{{'glyphicon glyphicon-ok font-green' if app.helper.can_action(contact) else 'glyphicon glyphicon-remove font-red'}}"></span></td>
                </tr>
                <tr>
                  <td><strong>Active:</strong></td>
                  <td><span class="{{'glyphicon glyphicon-ok font-green' if not in_scheduled_downtime else 'glyphicon glyphicon-remove font-red'}}"></span></td>
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
                <tr>
                  <td><strong></strong></td>
                  <td>{{contact.address2 if contact.address2 else ''}}</td>
                </tr>
                <tr>
                  <td><strong></strong></td>
                  <td>{{contact.address3 if contact.address3 else ''}}</td>
                </tr>
                <tr>
                  <td><strong></strong></td>
                  <td>{{contact.address4 if contact.address4 else ''}}</td>
                </tr>
                <tr>
                  <td><strong></strong></td>
                  <td>{{contact.address5 if contact.address5 else ''}}</td>
                </tr>
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
                    <div id="contact_tags" class="btn-group pull-right">
                      <script>
                        %j=0
                        %for t in sorted(contact.tags):
                        var b{{j}} = $('<a href="/all?search=stag:{{t}}"/>').appendTo($('#contact_tags'));
                        $('<img />')
                          .attr({ 'src': '/static/images/tags/{{t.lower()}}.png', 'alt': '{{t.lower()}}', 'title': 'Tag: {{t.lower()}}' })
                          .css({height: "24px"})
                          .load(function() {
                          })
                          .error(function() {
                            $(this).remove();
                            $("<span/>").attr({ 'class': 'btn btn-default btn-xs bg-contact'}).append('{{t}}').appendTo(b{{j}});
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
                    <td><strong>&raquo;Minimum business impact:</strong></td>
                    <td>{{nw.min_business_impact}}</td>
                  </tr>
                  
                  <tr>
                    <td><strong>&raquo;Hosts notifications:</strong></td>
                    <td><span class="{{'glyphicon glyphicon-ok font-green' if contact.host_notifications_enabled else 'glyphicon glyphicon-remove font-red'}}"></span></td>
                  </tr>
                  %if nw.host_notifications_enabled:
                  <tr>
                    <td><strong>&nbsp;&ndash;period:</strong></td>
                    <td name="{{"host_notification_period%s" % i}}" class="popover-dismiss" data-html="true" data-toggle="popover" title="Host notification period" data-placement="top" data-content="...">{{nw.host_notification_period.get_name()}}</td>
                    <script>
                      %tp=app.get_timeperiod(nw.host_notification_period.get_name())
                      $('td[name="{{"host_notification_period%s" % i}}"]')
                        .attr('title', '{{tp.alias if hasattr(tp, "alias") else tp.timeperiod_name}}')
                        .attr('data-content', '{{!app.helper.get_timeperiod_html(tp)}}')
                        .popover();
                    </script>
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
                    <td><strong>&nbsp;&ndash;options:</strong></td>
                    <td>
                    %for m in message:
                      <span class="{{'glyphicon glyphicon-ok font-green' if m in options else 'glyphicon glyphicon-remove font-red'}}">{{message[m]}}&nbsp;</span>
                    %end
                    </td>
                  </tr>
                  %end
                  
                  %i=0
                  %for command in nw.host_notification_commands:
                    %i += 1
                    <tr>
                      <td><strong>&nbsp;&ndash;command:</strong></td>
                      <td name="host_command{{i}}" class="popover-dismiss" data-html="true" data-toggle="popover" title="Service notification command" data-placement="top" data-content="...">{{command.get_name()}}</td>
                      <script>
                        $('td[name="host_command{{i}}"]')
                          .attr('title', '{{command.get_name()}}')
                          .attr('data-content', {{json.dumps(command.command.command_line)}})
                          .popover();
                      </script>
                    </tr>
                  %end
                  %end
                  %# If host notifications enabled ...
                  
                
                  <tr>
                    <td><strong>&raquo;Services notifications:</strong></td>
                    <td><span class="{{'glyphicon glyphicon-ok font-green' if contact.service_notifications_enabled else 'glyphicon glyphicon-remove font-red'}}"></span></td>
                  </tr>
                  %if nw.service_notifications_enabled:
                  <tr>
                    <td><strong>&nbsp;&ndash;period:</strong></td>
                    <td name="{{"service_notification_period%s" % i}}" class="popover-dismiss" data-html="true" data-toggle="popover" title="service notification period" data-placement="top" data-content="...">{{nw.service_notification_period.get_name()}}</td>
                    <script>
                      %tp=app.get_timeperiod(nw.service_notification_period.get_name())
                      $('td[name="{{"service_notification_period%s" % i}}"]')
                        .attr('title', '{{tp.alias if hasattr(tp, "alias") else tp.timeperiod_name}}')
                        .attr('data-content', '{{!app.helper.get_timeperiod_html(tp)}}')
                        .popover();
                    </script>
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
                    <td><strong>&nbsp;&ndash;options:</strong></td>
                    <td>
                    %for m in message:
                      <span class="{{'glyphicon glyphicon-ok font-green' if m in options else 'glyphicon glyphicon-remove font-red'}}">{{message[m]}}&nbsp;</span>
                    %end
                    </td>
                  </tr>
                  %end
                  
                  %i=0
                  %for command in nw.service_notification_commands:
                    %i += 1
                    <tr>
                      <td><strong>&nbsp;&ndash;command:</strong></td>
                      <td name="service_command{{i}}" class="popover-dismiss" data-html="true" data-toggle="popover" title="Service notification command" data-placement="top" data-content="...">{{command.get_name()}}</td>
                      <script>
                        $('td[name="service_command{{i}}"]')
                          .attr('title', '{{command.get_name()}}')
                          .attr('data-content', {{json.dumps(command.command.command_line)}})
                          .popover();
                      </script>
                    </tr>
                  %end
                  %end
                  %# If service notifications enabled ...
                  
                
                %i+=1
                %end
                %# For notificationways ...
              </tbody>
            </table>
            
            <table class="table table-condensed col-sm-12" style="table-layout: fixed; word-wrap: break-word;">
              <colgroup>
                <col style="width: 30%" />
                <col style="width: 70%" />
              </colgroup>
              <thead>
                <tr>
                  <th colspan="2">Links:</td>
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
                    <span> ... </span>
                    %break
                    %end
                  %end
                  {{!'<span class="glyphicon glyphicon-remove font-red"></span> Do not monitor any host' if i==1 else ''}}
                  </td>
                </tr>
                <tr>
                  <td><strong>Services:</strong></td>
                  <td>
                  %i=1
                  %for item in my_services:
                    {{', ' if i!=1 else ''}}{{!app.helper.get_link(item, short=True)}}
                    %i+=1
                    %if i > 20:
                    <span> ... </span>
                    %break
                    %end
                  %end
                  {{!'<span class="glyphicon glyphicon-remove font-red"></span> Do not monitor any service' if i==1 else ''}}
                  </td>
                </tr>
                <tr>
                  <td><strong>Contacts groups:</strong></td>
                  <td>
                  %i=1
                  %for item in my_contactgroups:
                    {{', ' if i!=1 else ''}}{{item.alias if item.alias!='' else item.get_name()}}
                    %i+=1
                    %if i > 20:
                    <span> ... </span>
                    %break
                    %end
                  %end
                  {{!'<span class="glyphicon glyphicon-remove font-red"></span> Do not belong to any group' if i==1 else ''}}
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
			</div>
		</div>
	</div>
</div>
%end
