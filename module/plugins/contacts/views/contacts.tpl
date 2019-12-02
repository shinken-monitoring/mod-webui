%rebase("layout", title='All contacts (%d contacts)' % len(contacts))

%setdefault('fmwk', 'Shinken')

%user = app.get_user()
%helper = app.helper

<div id="contacts" class="panel panel-default">

   <table class="table table-hover">
      <!--<colgroup>-->
         <!--<col style="width: 20%;"></col>-->
         <!--<col style="width: 20%;"></col>-->
         <!--<col style="width: 60%;"></col>-->
      <!--</colgroup>-->
      <thead>
        <tr>
          <th>Name</th>
          <th>Alias</th>
          <th>Business impact</th>
          <th>Notifications</th>
          <th>Email</th>
          <th>Notification way</th>
        </tr>
         <!--<tr>-->
         <!--<th colspan="2"></th>-->
         <!--</tr>-->
      </thead>
      <tbody>
         %for contact in contacts:
         <tr>
           <td>
             %if contact.is_admin:
             <i class="fas fa-fw font-black fa-eye" title="This user is an administrator"></i>
             %elif app.can_action(contact.contact_name):
             <i class="fas fa-fw font-black fa-bullhorn" title="This user is allowed to launch commands"></i>
             %else:
             <i class="fas fa-fw font-black fa-" title="This user is allowed to launch commands"></i>
             %end
             {{ !helper.get_contact_avatar(contact) }}
           </td>
           <td><strong>{{ contact.alias if contact.alias != "none" else "" }}</strong></td>
           <td><strong>{{ contact.min_business_impact }}</strong></td>
           <td>
           %if not contact.host_notifications_enabled and not contact.service_notifications_enabled:
           None
           %else:
           <strong>
           {{ 'hosts' if contact.host_notifications_enabled else '' }} - {{ 'services' if contact.service_notifications_enabled else ''}}
           </strong>
           %end
           </td>
           <td>
             %if contact.email != "none":
             <a href="mailto:{{contact.email}}?subject=Sent from {{fmwk}} WebUI">{{contact.email}}</a>
             %end
           </td>
           <td>
             %for nw in contact.notificationways:
             %if isinstance(nw, dict):
             {{ nw['notificationway_name'] }}
             %else:
             {{ nw.get_name() }}
             %end
             %end
           </td>
         </tr>
         %end
      </tbody>
   </table>
</div>
