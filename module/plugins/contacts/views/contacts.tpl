%rebase("layout", title='All contacts (%d contacts)' % len(contacts))

<div id="contacts">

   <table class="table table-condensed">
      <colgroup>
         <col style="width: 20%;"></col>
         <col style="width: 20%;"></col>
         <col style="width: 60%;"></col>
      </colgroup>
      <thead>
         <tr>
         <th colspan="2"></td>
         </tr>
      </thead>
      <tbody style="font-size:x-small;">
         %for contact in contacts:
            <tr>
               <td><strong>{{contact.contact_name}}</strong></td>
               <td><strong>{{"%s (%s)" % (contact.alias, contact.contact_name) if contact.alias != 'none' else contact.contact_name}}</strong></td>
               <td><a href="mailto:{{contact.email}}?subject=Sent from Shinken WebUI">{{contact.email}}</a></td>
               <td><a href="/contact/{{contact.contact_name}}" >Detail</a></td>
            </tr>
         %end
      </tbody>
   </table>
</div>
