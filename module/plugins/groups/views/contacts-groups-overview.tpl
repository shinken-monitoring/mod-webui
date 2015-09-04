%rebase("layout", css=['groups/css/groups-overview.css'], title='Contacts groups overview')

%helper = app.helper

<div id="contactsgroups">
   <!-- Groups list -->
   <ul id="groups" class="list-group">
      %even='alt'
      %for group in contactgroups:
         %if even =='':
           %even='alt'
         %else:
           %even=''
         %end

         <li class="group list-group-item clearfix">
            <section class="left">
               <h3>
                  <a role="menuitem" href="/all?search=cg:{{group.get_name()}}"><i class="fa fa-angle-double-down"></i>
                     {{group.alias if group.alias else group.get_name()}}
                  </a>
               </h3>
               <div>
                  %groupcontacts=app.datamgr.get_contactgroup_contacts(group.get_name(), user)
                  %contacts=[]
                  %[contacts.append('<a href="/contact/'+item.contact_name+'">'+item.alias+'</a>' if item.alias else item.get_name()) for item in groupcontacts]
                  <div>{{!', '.join(contacts)}}</div>
               </div>
            </section>
         </li>
         %#end
      %end
   </ul>
</div>
