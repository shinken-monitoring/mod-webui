%import json
%import time

%#date_format='%Y-%m-%d %H:%M:%S'
%date_format='%H:%M:%S'
%states = ['Up', 'down', 'unreachable', 'unknown', 'unchecked']

%if not tickets:
   <center>
      <h3>No helpdesk records (tickets) found.</h3>
      <p>You should install the <strong>glpi-helpdesk</strong> Shinken module in WebUI to get helpdesk data from Glpi database.</p>
      <p>If you installed the <strong>glpi-helpdesk</strong> Shinken module, your host is probably not known in Glpi database.</p>
   </center>
%else:
   <table class="table table-condensed">
      <thead>
         %# List all possible keys
         <!-- Ticket fields:
         {'waiting_duration': '0', 'tasks': [], 'solutiontypes_id': '0', 'slalevels_name': '', 'impact_name': 'Medium', 'slalevels_next_name': '', 'slas_id': '1', 'date_mod': '2015-06-03 07:32:13', 'satisfaction': [], 'slalevels_next_id': 0, 'locations_id': '0', 'closedate': '', 'id': '11', 'impact': '3', 'priority': '3', 'followups': [], 'documents': [], 'slalevels_next_date': '', 'global_validation': '1', 'type_name': 'Incident', 'validation_percent': '0', 'priority_name': 'Medium', 'content': 'test ticket', 'close_delay_stat': '0', 'solutiontypes_name': '', 'users_name_lastupdater': 'glpi', 'ticketcategories_name': 'Communication borne', 'type': '1', 'events': [{'display_history': True, 'datatype': 'dropdown', 'date_mod': '2015-06-03 07:32', 'field': 'Last edit by', 'user_name': 'glpi (2)', 'id': '21337', 'change': 'Change shinken (9) by glpi (2)'}, {'display_history': True, 'datatype': 'dropdown', 'date_mod': '2015-06-03 07:32', 'field': 'SLA', 'user_name': 'glpi (2)', 'id': '21336', 'change': 'Change (0) by Test de Fred (1)'}, {'display_history': True, 'datatype': 'datetime', 'date_mod': '2015-06-03 07:32', 'field': 'Due date', 'user_name': 'glpi (2)', 'id': '21335', 'change': 'Change by 2015-06-05 06:50'}, {'display_history': True, 'datatype': '', 'date_mod': '2015-06-03 06:50', 'field': '', 'user_name': 'shinken (9)', 'id': '21300', 'change': 'Add the item'}, {'display_history': True, 'datatype': '', 'date_mod': '2015-06-03 06:50', 'field': 'User', 'user_name': 'shinken (9)', 'id': '21299', 'change': 'Add a link with an item: shinken (9)'}, {'display_history': True, 'datatype': '', 'date_mod': '2015-06-03 06:50', 'field': 'Computer', 'user_name': 'shinken (9)', 'id': '21297', 'change': 'Add a link with an item: kiosk-0001 (9)'}], 'status': '1', 'due_date': '2015-06-05 06:50:21', 'solve_delay_stat': '0', 'actiontime': '0', 'solvedate': '', 'users': {'assign': [], 'observer': [], 'requester': [{'users_id': '9', 'use_notification': '1', 'users_name': 'Administrateur Shinken', 'id': '11', 'alternative_email': ''}]}, 'entities_name': 'Root entity &gt; AJ Consulting &gt; Dubai Airport 1 &gt; Desk 1', 'begin_waiting_date': '', 'users_id_recipient': '9', 'sla_waiting_duration': '0', 'users_id_lastupdater': '2', 'slalevels_id': '0', 'itemtype_name': '', 'itilcategories_id': '1', 'items_name': 'General', 'date': '2015-06-03 06:50:21', 'requesttypes_name': 'Monitoring', 'slas_name': 'Test de Fred', 'validations': [], 'requesttypes_id': '8', 'groups': {'assign': [], 'observer': [], 'requester': []}, 'is_deleted': '0', 'name': 'test ticket', 'status_name': 'New', 'suppliers': {'assign': []}, 'global_validation_name': 'Not subject to approval', 'urgency_name': 'Medium', 'solution': '', 'entities_id': '6', 'locations_name': '', 'users_name_recipient': 'Administrateur Shinken', 'takeintoaccount_delay_stat': '0', 'urgency': '3'}
         -->
         %#my_keys = ['id', 'date', 'due_date', 'solvedate', 'closedate', 'date_mod', 'name', 'content', 'priority_name', 'urgency_name', 'impact_name', 'solutiontypes_name', 'ticketcategories_name', 'slas_name', 'requesttypes_name', 'status_name', 'users_name_recipient', 'global_validation_name']
         %my_keys = [ 
         %     {'id':'id',                      'active': True,  'title': '#'},
         %     {'id':'type_name',               'active': True,  'title': 'Type'},
         %     {'id':'status_name',             'active': True,  'title': 'Status'},
         %     {'id':'date',                    'active': True,  'title': 'Opened date', 'date': 'beginning'},
         %     {'id':'users_name_recipient',    'active': True,  'title': 'Author'},
         %     {'id':'name',                    'active': True,  'title': 'Name'},
         %     {'id':'content',                 'active': True,  'title': 'Content'},
         %     {'id':'due_date',                'active': True,  'title': 'Due date', 'date': 'due'},
         %     {'id':'solvedate',               'active': True,  'title': 'Solved date', 'date': 'end'},
         %     {'id':'closedate',               'active': False, 'title': 'Closed date'},
         %     {'id':'date_mod',                'active': False, 'title': 'Modified date'},
         %     {'id':'priority_name',           'active': False, 'title': 'Priority'},
         %     {'id':'urgency_name',            'active': False, 'title': 'Emergency'},
         %     {'id':'impact_name',             'active': False, 'title': 'Impact'},
         %     {'id':'solutiontypes_name',      'active': False, 'title': 'Solution'},
         %     {'id':'ticketcategories_name',   'active': True,  'title': 'Category'},
         %     {'id':'slas_name',               'active': False, 'title': 'SLA'},
         %     {'id':'requesttypes_name',       'active': True,  'title': 'Source'},
         %     {'id':'global_validation_name',  'active': False, 'title': 'Validation'}
         %  ]
         %my_arrays = [ 
         %     {'id':'tasks',          'active': True,  'title': 'Tasks',  'fields': [
         %           { 'id': 'id',                  'active': False, 'width': 'col-md-1', 'title': '#' }, 
         %           { 'id': 'is_private',          'active': False, 'width': 'col-md-1', 'title': 'Private' }, 
         %           { 'id': 'date',                'active': True,  'width': 'col-md-1', 'title': 'Date' },
         %           { 'id': 'users_name',          'active': True,  'width': 'col-md-1', 'title': 'User' }, 
         %           { 'id': 'content',             'active': True,  'width': 'col-md-1', 'title': 'Content' }, 
         %           { 'id': 'state',               'active': True,  'width': 'col-md-1', 'title': 'State' }, 
         %           { 'id': 'taskcategories_name', 'active': True,  'width': 'col-md-1', 'title': 'Category' }, 
         %           { 'id': 'begin',               'active': True,  'width': 'col-md-1', 'title': 'Begin' }, 
         %           { 'id': 'end',                 'active': True,  'width': 'col-md-1', 'title': 'End' }, 
         %           { 'id': 'actiontime',          'active': True,  'width': 'col-md-1', 'title': 'Duration' }
         %           ],
         %     },
         %     {'id':'followups',      'active': True, 'width': 'col-md-1', 'title': 'Follow ups',  'fields': [
         %           { 'id': 'id',                  'active': False, 'width': 'col-md-1', 'title': '#' }, 
         %           { 'id': 'is_private',          'active': False, 'width': 'col-md-1', 'title': 'Private' }, 
         %           { 'id': 'date',                'active': True,  'width': 'col-md-1', 'title': 'Date' },
         %           { 'id': 'content',             'active': True,  'width': 'col-md-1', 'title': 'Content' }, 
         %           { 'id': 'requesttypes_name',   'active': True,  'width': 'col-md-1', 'title': 'Source' }
         %           ],
         %     },
         %     {'id':'events',         'active': True, 'width': 'col-md-1', 'title': 'Events',  'fields': [
         %           { 'id': 'id',                  'active': False, 'width': 'col-md-1', 'title': '#' }, 
         %           { 'id': 'date_mod',            'active': True,  'width': 'col-md-1', 'title': 'Date' }, 
         %           { 'id': 'user_name',           'active': True,  'width': 'col-md-1', 'title': 'User' }, 
         %           { 'id': 'field',               'active': True,  'width': 'col-md-1', 'title': 'Field' }, 
         %           { 'id': 'change',              'active': True,  'width': 'col-md-1', 'title': 'Change' }
         %           ],
         %     }
         %  ]
         <tr>
            %columns=0
            %date_start=None
            %date_end=None
            %date_due=None
            %for key in my_keys:
            %if key['active']:
            %if 'date' in key:
               %if key['date']=='beginning':
                  %date_start=key['id']
               %elif key['date']=='end':
                  %date_end=key['id']
               %elif key['date']=='due':
                  %date_due=key['id']
               %end
            %end
            <th>{{key['title']}}</th>
            %columns = columns+1
            %end
            %end
         </tr>
      </thead>
      <tbody style="font-size:x-small;">
         %idx=0
         %for ticket in tickets:
            %# Is ticket correct ?
            %ticket_class='active'
            
            %if ticket[date_end]:
               %#Solved ticket
               
               %if ticket[date_due]:
                  %ts_date_due=time.mktime(time.strptime(ticket[date_due], "%Y-%m-%d %H:%M:%S"))
                  %ts_date_end=time.mktime(time.strptime(ticket[date_end], "%Y-%m-%d %H:%M:%S"))
                  %if ts_date_due > ts_date_end:
                     %ticket_class='success'
                  %else:
                     %ticket_class='danger'
                  %end
               %else:
                  %ticket_class='info'
               %end

            %else:
               %#No end date ... proceeding.

               %if ticket[date_due]:
                  %ts_date_due=time.mktime(time.strptime(ticket[date_due], "%Y-%m-%d %H:%M:%S"))
                  %if ts_date_due < time.time():
                     %ticket_class='danger'
                  %else:
                     %ticket_class='warning'
                  %end
               %else:
                  %ticket_class='warning'
               %end
            %end
            %# One row per ticket ...
            <tr class="{{ticket_class}}" data-toggle="collapse" data-target="#arrays-{{idx}}">
               %first=True
               %for key in my_keys:
               %if key['active']:
               %if key['id'] in ticket:
               <td>{{ticket[key['id']]}} {{!'<span class="caret"></span>' if first else ''}}</td>
               %first=False
               %end
               %end
               %end
            </tr>
            
            %#One table for all arrays in the ticket ...
            <tr class="collapse" id="arrays-{{idx}}">
               <td colspan="{{columns}}" class="hiddenRow">
                  <div class="panel panel-default">
                  <div class="panel-body" style="background:#ccc;">
                     %for array in my_arrays:
                     %if array['active'] and array['id'] in ticket and ticket[array['id']]:
                     <div class="table-responsive">
                     <table class="table table-bordered table-condensed" style="table-layout: fixed; word-wrap: break-word;">
                        <colgroup>
                           %i=0
                           %for element in array['fields']:
                           %if element['active']:
                           %i=i+1
                           %end
                           %end
                           %for element in array['fields']:
                           %if element['active']:
                           <col class="{{element['width']}}">
                           %end
                           %end
                        </colgroup>
                        <thead>
                           %i=0
                           %for element in array['fields']:
                           %if element['active']:
                           %i=i+1
                           %end
                           %end
                           <tr>
                           <th colspan="{{i}}">{{array['title']}}</th>
                           </tr>
                           %#One sub-row per array in the ticket ...
                           <tr>
                           %for element in array['fields']:
                           %if element['active']:
                           <th>{{element['title']}}</th>
                           %end
                           %end
                           </tr>
                        </thead>
                        <tbody style="font-size:x-small;">
                           %# Each element in the array ...
                           %for item in ticket[array['id']]:
                           <tr>
                           %for element in array['fields']:
                           %if element['id'] in item and element['active']:
                           %struct_time = time.strptime("30 Nov 00", "%d %b %y")
                           <td>{{ item[element['id']] }}</td>
                           %end
                           %end
                           </tr>
                           %end
                        </tbody>
                     </table>
                     </div>
                     %end
                     %end
                  </div>
                  </div>
               </td>
            </tr>
            %idx=idx+1
         %end
      </tbody>
   </table>
%end
