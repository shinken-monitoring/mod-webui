%setdefault('debug', False)

%rebase("layout", title='Contacts groups overview')

%helper = app.helper

<div id="contactsgroups">
   <!-- Groups list -->
   <ul id="groups" class="list-group">
      %if level==0:
         %all_contacts = sorted(app.datamgr.get_contacts(user=user), key=lambda c: c.contact_name)
         %nContacts=len(all_contacts)
         %nGroups=len(contactgroups)
         <li class="all_groups list-group-item clearfix">
            <h3>
               <a role="menuitem" href="#">
                  All contacts
               </a>
            </h3>
            <section class="col-md-8 col-sm-6 col-xs-6">
               %contacts=[]
               %[contacts.append('<a href="/contact/%s">%s</a>' %(item.contact_name, item.alias if item.alias!='none' else item.contact_name)) for item in all_contacts]
               <div>{{!', '.join(contacts)}}</div>

               %if debug:
               <div>Contacts and their groups (only contacts in groups):<ul>
                  %for contact in all_contacts:
                  %if contact.get_groupnames():
                  <li>
                  Contact: <strong>{{contact.get_name()}}</strong> is member of:  {{contact.get_groupnames()}}
                  </li>
                  %end
                  %end
               </ul></div>
               %end
            </section>

            <section class="col-md-4 col-sm-6 col-xs-6">
               <section class="col-sm-12 col-xs-12">
               </section>

               <section class="col-sm-12 col-xs-12">
                  <div class="btn-group btn-group-justified" role="group" aria-label="Minemap" title="View minemap for hosts related with all contacts">
                     <a class="btn btn-default" href="/minemap?search=type:host"><i class="fa fa-table"></i> <span class="hidden-xs">Minemap</span></a>
                  </div>

                  <div class="btn-group btn-group-justified" role="group" aria-label="Resources" title="View resources for hosts related with all contacts">
                     <a class="btn btn-default" href="/all?search=type:host"><i class="fa fa-ambulance"></i> <span class="hidden-xs">Resources</span></a>
                  </div>

                  <ul class="list-group">
                     <li class="list-group-item">
                        {{!'<span class="badge">%s</span>Services' % (len(contacts)) if len(contacts) else '<small><em>No members</em></small>'}}
                     </li>
                     <li class="list-group-item">
                        {{!'<span class="badge">%s</span>Groups' % (nGroups) if nGroups else '<small><em>No sub-groups</em></small>'}}
                     </li>
                  </ul>
               </section>
            </section>
         </li>
      %end

      %for group in contactgroups:
         <li class="group list-group-item clearfix">
            <h3>
               <a role="menuitem" href="/all?search=cg:{{'"%s"' % group.get_name()}}">
                  {{group.alias if group.alias else group.get_name()}}
               </a>
            </h3>
            <section class="col-md-8 col-sm-6 col-xs-6">
               <div>
                  %groupcontacts=group.members
                  %contacts=[]
                  %[contacts.append('<a href="/contact/%s">%s</a>' %(item.contact_name, item.alias if item.alias!='none' else item.contact_name)) for item in groupcontacts]
                  <div>{{!', '.join(contacts)}}</div>
               </div>
            </section>

            <section class="col-md-4 col-sm-6 col-xs-6">
               <section class="col-sm-12 col-xs-12">
               </section>

               <section class="col-sm-12 col-xs-12">
                  <div class="btn-group btn-group-justified" role="group" aria-label="Minemap" title="View minemap for hosts related with this contact group">
                     <a class="btn btn-default" href="/minemap?search=type:host cg:{{'"%s"' % group.get_name()}}"><i class="fa fa-table"></i> <span class="hidden-xs">Minemap</span></a>
                  </div>

                  <div class="btn-group btn-group-justified" role="group" aria-label="Resources" title="View resources for hosts related with this contact group">
                     <a class="btn btn-default" href="/all?search=type:host cg:{{'"%s"' % group.get_name()}}"><i class="fa fa-ambulance"></i> <span class="hidden-xs">Resources</span></a>
                  </div>

                  <ul class="list-group">
                     <li class="list-group-item">
                        {{!'<span class="badge">%s</span>Services' % (len(contacts)) if len(contacts) else '<small><em>No members</em></small>'}}
                     </li>
                     <li class="list-group-item">
                        {{!'<span class="badge">%s</span>Groups' % (nGroups) if nGroups else '<small><em>No sub-groups</em></small>'}}
                     </li>
                  </ul>
               </section>
            </section>
         </li>
         %#end
      %end
   </ul>
</div>
