%import time

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

%rebase layout title='Contact ' + username, user=user, app=app, refresh=True, css=['contacts/css/contacts.css']

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
            %if app is not None and app.company_logo:
            <img src="/static/images/logo/{{app.company_logo}}" class="img-circle" alt="User logo" />
            %else:
            <img src="/static/images/logo/logo_small.png" class="img-circle" alt="User logo" />
            %end
            
            <p class="username">
              {{username}}
            </p>
            <p class="usercategory">
              <small>{{'Administrator' if app.manage_acl and app.helper.can_action(contact) else 'Guest'}}</small>
            </p>
          </div>
          
          <div class="user-body">
            <table class="table table-condensed col-sm-12" style="table-layout: fixed; word-wrap: break-word;">
              <colgroup>
                <col style="width: 40%" />
                <col style="width: 60%" />
              </colgroup>
              <thead>
                <tr>
                  <th colspan="2"></td>
                </tr>
              </thead>
              <tbody style="font-size:x-small;">
                <tr>
                  <td><strong>Identification:</strong></td>
                  <td>{{contact.alias}} ({{contact.contact_name}})</td>
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
                <col style="width: 40%" />
                <col style="width: 60%" />
              </colgroup>
              <thead>
                <tr>
                  <th colspan="2">Configuration:</td>
                </tr>
              </thead>
              <tbody style="font-size:x-small;">
                <tr>
                  <td><strong>Minimum business impact:</strong></td>
                  <td>{{contact.min_business_impact}}</td>
                </tr>
                <tr>
                  <td><strong>Notification way:</strong></td>
                  <td><span class="{{contact.notificationways}}"></span></td>
                </tr>
                <tr>
                  <td><strong>Host notifications:</strong></td>
                  <td><span class="{{'glyphicon glyphicon-ok font-green' if contact.host_notifications_enabled else 'glyphicon glyphicon-remove font-red'}}"></span></td>
                </tr>
                %if contact.host_notifications_enabled:
                <tr>
                  <td><strong>Period:</strong></td>
                  <td>{{contact.host_notification_period if hasattr(contact, 'host_notification_period') else 'Not set'}}</td>
                </tr>
                <tr>
                  <td><strong>Options:</strong></td>
                  <td>{{', '.join(contact.host_notification_options)}}</td>
                </tr>
                <tr>
                  <td><strong>Command:</strong></td>
                  <td>{{contact.host_notification_commands if hasattr(contact, 'host_notification_commands') else 'Not set'}}</td>
                </tr>
                %end
                <tr>
                  <td><strong>Service notifications:</strong></td>
                  <td><span class="{{'glyphicon glyphicon-ok font-green' if contact.service_notifications_enabled else 'glyphicon glyphicon-remove font-red'}}"></span></td>
                </tr>
                %if contact.service_notifications_enabled:
                <tr>
                  <td><strong>Period:</strong></td>
                  <td>{{contact.service_notification_period if hasattr(contact, 'service_notification_period') else 'Not set'}}</td>
                </tr>
                <tr>
                  <td><strong>Options:</strong></td>
                  <td>{{', '.join(contact.service_notification_options)}}</td>
                </tr>
                <tr>
                  <td><strong>Command:</strong></td>
                  <td>{{contact.service_notification_commands if hasattr(contact, 'service_notification_commands') else 'Not set'}}</td>
                </tr>
                %end
              </tbody>
            </table>
          </div>
          
<!--
          <div class="user-footer">
            <div class="pull-left">
              <a href="https://shinken.readthedocs.org/en/latest/" target="_blank" class="btn btn-default btn-flat"><i class="fa fa-book"></i> </a>
              <a href="#settings" data-toggle="modal" class="btn btn-default btn-flat disabled"><span class="fa fa-gear"></span> </a>
              <a href="#profile" data-toggle="modal" class="btn btn-default btn-flat disabled"><span class="fa fa-pencil"></span> </a>
            </div>
            <div class="pull-right">
                <a href="/user/logout" class="btn btn-default btn-flat" data-toggle="modal" data-target="/user/logout"><span class="fa fa-sign-out"></span> </a>
            </div>
          </div>
-->
			</div>
		</div>
	</div>
</div>
%end
