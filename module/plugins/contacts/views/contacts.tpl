%rebase("layout", title='All contacts (%d contacts)' % len(contacts))

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
             {{ !helper.get_contact_avatar(contact) }}
             %if contact.is_admin:
             <i class="fa font-warning fa-star" title="This user is admin"></i>
             %elif app.can_action(contact.contact_name):
             <i class="fa font-ok fa-star" title="This user is allow to launch commands"></i>
             %end
           </td>
           <td><strong>{{ contact.alias if contact.alias != "none" else "" }}</strong></td>
           <td>
             %if contact.email != "none":
             <a href="mailto:{{contact.email}}?subject=Sent from Shinken WebUI">{{contact.email}}</a>
             %end
           </td>
           <td>
             %for nw in contact.notificationways:
             {{ nw.notificationway_name }}
             %end
           </td>
         </tr>
         %end
      </tbody>
   </table>
</div>
