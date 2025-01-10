%rebase("layout", title='%d contacts' % len(contacts))

%setdefault('fmwk', 'Shinken')

%user = app.get_user()
%helper = app.helper

<div id="contacts" class="panel panel-default">

   <table class="table table-hover table-striped table-condensed">
      <!--<colgroup>-->
         <!--<col style="width: 20%;"></col>-->
         <!--<col style="width: 20%;"></col>-->
         <!--<col style="width: 60%;"></col>-->
      <!--</colgroup>-->
      <thead>
        <tr>
          <th></th>
          <th>Name</th>
          <th>Min business impact</th>
          <th>Notifications</th>
          <th>Email</th>
          <th>Notification way</th>
          <th></th>
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
           </td>
           <td>
             <a href="/contact/{{ contact.contact_name }}">
               {{ !helper.get_contact_avatar(contact, with_name=False, with_link=False) }}
               &nbsp;&nbsp;&nbsp;
               {{ contact.contact_name }}
               {{ "(alias "+contact.alias+")" if contact.alias != "none" else "" }}
             </a>
           </td>
           <td>{{ contact.min_business_impact }}</td>
           <td>
           %if not contact.host_notifications_enabled and not contact.service_notifications_enabled:
           None
           %else:
           {{ 'hosts' if contact.host_notifications_enabled else '' }} - {{ 'services' if contact.service_notifications_enabled else ''}}
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
           <td>
             %if user.is_administrator():
             <a class='btn btn-xs btn-default' title='Login as {{ contact.contact_name }}' href='/user/login_as/{{ contact.contact_name }}'><i class="fas fa-sign-in-alt"></i></a>
             %end
           </td>
         </tr>
         %end
      </tbody>
   </table>
</div>
