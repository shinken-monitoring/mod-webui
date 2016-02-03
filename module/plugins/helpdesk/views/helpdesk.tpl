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
         {'waiting_duration': '0', 'tasks': [{'users_name': u'Fr\xe9d\xe9ric MOHIER', 'users_id': '115', 'begin': '', 'actiontime': '1800', 'end': '', 'users_id_tech': '0', 'taskcategories_id': '0', 'tickets_id': '2569', 'content': u'Test de t\xe2che', 'state': '2', 'taskcategories_name': '', 'date': '2016-01-27 17:00:20', 'id': '2158', 'is_private': '0'}],
         'solutiontypes_id': '21',
         'slalevels_name': '', 'impact_name': 'Moyen', 'slalevels_next_name': '', 'slas_id': '4', 'date_mod': '2016-01-27 17:01:30', 'satisfaction': [], 'slalevels_next_id': 0, 'locations_id': '227', 'closedate': '2016-01-27 17:01:30', 'id': '2569', 'impact': '3', 'priority': '3', 'followups': [{'users_name': u'Fr\xe9d\xe9ric MOHIER', 'content': u'Approuv\xe9 par Fred.', 'requesttypes_id': '1', 'tickets_id': '2569', 'users_id': '115', 'date': '2016-01-27 17:01:30', 'requesttypes_name': 'Helpdesk', 'id': '1502', 'is_private': '0'}, {'users_name': u'Fr\xe9d\xe9ric MOHIER', 'content': 'Test de Fred pour un suivi', 'requesttypes_id': '1', 'tickets_id': '2569', 'users_id': '115', 'date': '2016-01-27 16:49:27', 'requesttypes_name': 'Helpdesk', 'id': '1501', 'is_private': '1'}], 'documents': [], 'itemtype': 'Computer', 'slalevels_next_date': '', 'global_validation': 'none', 'type_name': 'Incident', 'priority_name': 'Moyenne', 'content': u'Gros probl\xe8me ...\n ', 'close_delay_stat': '78270',
         'solutiontypes_name': u"D\xe9bourrage de l'imprimante",
         'users_name_lastupdater': u'Fr\xe9d\xe9ric MOHIER', 'ticketcategories_name': "Ticket d'incident > Borne injoignable", 'items_id': '572', 'type': '1', 'events': [{'display_history': True, 'datatype': '', 'date_mod': '27-01-2016 17:01', 'field': 'Suivi', 'user_name': u'Fr\xe9d\xe9ric MOHIER (115)', 'id': '5465242', 'change': u"Ajout de l'\xe9l\xe9ment : Suivi (1502)"}, {'display_history': True, 'datatype': 'datetime', 'date_mod': '27-01-2016 17:01', 'field': u'Date de cl\xf4ture', 'user_name': u'Fr\xe9d\xe9ric MOHIER (115)', 'id': '5465241', 'change': 'Changement de 27-01-2016 17:01 par 27-01-2016 17:01'}, {'display_history': True, 'datatype': 'specific', 'date_mod': '27-01-2016 17:01', 'field': 'Statut', 'user_name': u'Fr\xe9d\xe9ric MOHIER (115)', 'id': '5465240', 'change': u'Changement de R\xe9solu par Clos'}, {'display_history': True, 'datatype': 'datetime', 'date_mod': '27-01-2016 17:01', 'field': u'Date de r\xe9solution', 'user_name': u'Fr\xe9d\xe9ric MOHIER (115)', 'id': '5465239', 'change': 'Changement de -- par 27-01-2016 17:01'}, {'display_history': True, 'datatype': 'specific', 'date_mod': '27-01-2016 17:01', 'field': 'Statut', 'user_name': u'Fr\xe9d\xe9ric MOHIER (115)', 'id': '5465238', 'change': u'Changement de En cours (Attribu\xe9) par R\xe9solu'}, {'display_history': True, 'datatype': 'text', 'date_mod': '27-01-2016 17:01', 'field': 'Solution', 'user_name': u'Fr\xe9d\xe9ric MOHIER (115)', 'id': '5465237', 'change': 'Modification du champ'}, {'display_history': True, 'datatype': 'dropdown', 'date_mod': '27-01-2016 17:01', 'field': 'Type de solution', 'user_name': u'Fr\xe9d\xe9ric MOHIER (115)', 'id': '5465236', 'change': u"Changement de (0) par D\xe9bourrage de l'imprimante (21)"}, {'display_history': True, 'datatype': '', 'date_mod': '27-01-2016 17:00', 'field': u"T\xe2che d'un ticket", 'user_name': u'Fr\xe9d\xe9ric MOHIER (115)', 'id': '5465231', 'change': u"Ajout de l'\xe9l\xe9ment : T\xe2che d'un ticket (2158)"}, {'display_history': True, 'datatype': '', 'date_mod': '27-01-2016 16:49', 'field': 'Suivi', 'user_name': u'Fr\xe9d\xe9ric MOHIER (115)', 'id': '5465169', 'change': u"Ajout de l'\xe9l\xe9ment : Suivi (1501)"}, {'display_history': True, 'datatype': '', 'date_mod': '26-01-2016 19:19', 'field': '', 'user_name': u'Fr\xe9d\xe9ric MOHIER (115)', 'id': '5464180', 'change': u"Ajout de l'\xe9l\xe9ment"}, {'display_history': True, 'datatype': '', 'date_mod': '26-01-2016 19:19', 'field': 'Utilisateur', 'user_name': u'Fr\xe9d\xe9ric MOHIER (115)', 'id': '5464179', 'change': u"Ajout d'un lien avec un \xe9l\xe9ment : Fr\xe9d\xe9ric MOHIER (115)"}, {'display_history': True, 'datatype': 'timestamp', 'date_mod': '26-01-2016 19:19', 'field': u'D\xe9lai de prise en compte', 'user_name': u'Fr\xe9d\xe9ric MOHIER (115)', 'id': '5464178', 'change': 'Changement de 0 seconde par 2 minutes'}, {'display_history': True, 'datatype': '', 'date_mod': '26-01-2016 19:19', 'field': 'Utilisateur', 'user_name': u'Fr\xe9d\xe9ric MOHIER (115)', 'id': '5464177', 'change': u"Ajout d'un lien avec un \xe9l\xe9ment : Fr\xe9d\xe9ric MOHIER (99)"}], 'status': '6', 'due_date': '2016-01-28 17:00:00', 'solve_delay_stat': '78256', 'actiontime': '1800', 'solvedate': '2016-01-27 17:01:16', 'users': {'assign': [{'users_id': '115', 'use_notification': '1', 'users_name': u'Fr\xe9d\xe9ric MOHIER', 'id': '5464', 'alternative_email': ''}], 'observer': [], 'requester': [{'users_id': '99', 'use_notification': '1', 'users_name': u'Fr\xe9d\xe9ric MOHIER', 'id': '5463', 'alternative_email': ''}]}, 'entities_name': u'Entit\xe9 racine > IPM > R&D', 'begin_waiting_date': '2016-01-27 17:01:16', 'users_id_recipient': '115', 'sla_waiting_duration': '0', 'users_id_lastupdater': '115', 'slalevels_id': '0', 'itemtype_name': 'Ordinateur', 'itilcategories_id': '16', 'items_name': 'sim-0001', 'date': '2016-01-26 19:17:00', 'requesttypes_name': 'Helpdesk', 'slas_name': 'Maintenance curative', 'validations': [], 'requesttypes_id': '1', 'groups': {'assign': [], 'observer': [], 'requester': []}, 'is_deleted': '0', 'name': 'Incident', 'status_name': 'Clos', 'suppliers': {'assign': []}, 'global_validation_name': u'Non soumis \xe0 validation', 'urgency_name': 'Moyenne', 'solution': u'Ca y est ... \xe7a marche !', 'entities_id': '10', 'locations_name': 'Stock', 'users_name_recipient': u'Fr\xe9d\xe9ric MOHIER', 'takeintoaccount_delay_stat': '129', 'urgency': '3'}
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
         %     {'id':'solutiontypes_name',      'active': True,  'title': 'Solution'},
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
