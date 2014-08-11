%title='All known contacts (%d contacts)' % len(contacts)
%rebase layout globals(), css=['contacts/css/contacts.css'], js=['contacts/js/contacts-overview.js'], title=title, refresh=True

%helper = app.helper
%datamgr = app.datamgr

<div class="row">
  <div class="pull-right col-sm-2">
    <span class="btn-group pull-right">
      <a href="#" id="listview" class="btn btn-small switcher pull-right active" data-original-title='List'> <i class="fa fa-align-justify"></i> </a>
      <a href="#" id="gridview" class="btn btn-small switcher pull-right" data-original-title='Grid'> <i class="fa fa-th"></i> </a>
    </span>
  </div>
</div>
<div class="row">
  <ul id="contacts" class="list row col-sm-10 pull-right">
    %even=''
    %for contact in contacts:
      %if even =='':
        %even='alt'
      %else:
        %even=''
      %end

      %username = 'anonymous'
      %if hasattr(contact, 'alias') and contact.alias != '':
      %	username = contact.alias
      %else:
      %	username = contact.get_name()
      %end
      %username = contact.alias if hasattr(contact, 'alias') and contact.alias != 'none' else contact.get_name()
      <li class="clearfix {{even}} ">
        <section class="left col-sm-6">
          <a href="/contact/{{contact.get_name()}}"><h3>{{"%s (%s)" % (contact.alias, contact.contact_name) if contact.alias != 'none' else contact.contact_name}}</h3></a>
          <div class="meta">
            <table class="table table-condensed pull-left" style="table-layout: fixed; word-wrap: break-word;">
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
                  <td><strong>Mail:</strong></td>
                  <td><a href="mailto:{{contact.email}}?subject=Sent from Shinken WebUI">{{contact.email}}</a></td>
                </tr>
                %if contact.pager!='none':
                <tr>
                  <td><strong>Pager:</strong></td>
                  <td>{{contact.pager}}</td>
                </tr>
                %end
              </tbody>
            </table>
          </div>
        </section>

        <section class="right">
          <span class="darkview">
            <a href="/contact/{{contact.get_name()}}" class="firstbtn"><i class="fa fa-angle-double-down"></i> Detail</a>
          </span>
        </section>
      </li>
    %end
  </ul>
</div>
