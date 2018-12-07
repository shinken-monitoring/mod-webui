%setdefault('app', None)
%user = app.get_user()

%import json

%username = 'anonymous'
%if user is not None:
%username = user.contact_name
%end

%helper=app.helper

%rebase("layout", css=['user/css/user.css'], breadcrumb=[ ['User preferences', '/user/pref'] ], title='User preferences')

      <div class="panel panel-default">
         <div class="panel-heading">
           <h2 class="panel-title">
             {{ !helper.get_contact_avatar(user, with_name=False, with_link=False) }}
             {{ user.get_name() }}
             %if user.is_admin:
             <i class="fa font-warning fa-star" title="This user is an administrator"></i>
             %elif app.can_action(username):
             <i class="fa font-ok fa-star" title="This user is allowed to launch commands"></i>
             %end
           </h2>
         </div>
         <div class="panel-body">
               <table class="table table-condensed" style="table-layout: fixed; word-wrap: break-word;">
                  <colgroup>
                     <col style="width: 30%" />
                     <col style="width: 70%" />
                  </colgroup>
                  <tbody style="font-size:small;">
                     <tr>
                        <td><strong>Identification:</strong></td>
                        <td>{{"%s (%s)" % (user.alias, user.contact_name) if user.alias != 'none' else user.contact_name}}</td>
                     </tr>
                     <tr>
                        <td><strong>Commands authorized:</strong></td>
                        <td>{{! app.helper.get_on_off(app.can_action(), "Is this contact allowed to launch commands from Web UI?")}}</td>
                     </tr>
                     <tr>
                        <td><strong>Minimum business impact:</strong></td>
                        <td>{{!helper.get_business_impact_text(user.min_business_impact, text=True)}}</td>
                     </tr>

                     <tr>
                        <td colspan="2"><h3>User attributes:</h3></td>
                     </tr>
                     %for attr, value in sorted(user.__dict__.iteritems()):
                     %if attr not in ['address1', 'address2', 'address3', 'address4', 'address5', 'address6', 'alias', 'can_submit_commands', 'customs', 'email', 'host_notifications_enabled', 'host_notification_options', 'host_notification_period', 'min_business_impact', 'pager', 'service_notifications_enabled', 'service_notification_options', 'service_notification_period']:
                     %continue
                     %end
                     <tr>
                        <td><strong>{{attr}}:</strong></td>
                        <td>{{value}}</td>
                     </tr>
                     %end

                  %if app.prefs_module.is_available():
                     <tr>
                        <td colspan="2"><h3>User preferences:</h3></td>
                     </tr>
                     %for preference in app.prefs_module.get_ui_user_preference(user, default=[]):
                     %if preference in ['_id', 'uuid']:
                     %continue
                     %end
                     <tr>
                        <td>{{preference}}</td>
                        <td>{{app.prefs_module.get_ui_user_preference(user, preference)}}</td>
                     </tr>
                     %end

                     <tr>
                        <td>toolbar</td>
                        <td>{{app.prefs_module.get_ui_user_preference(user, 'toolbar')}}</td>
                     </tr>
                     <tr>
                        <td>bookmarks</td>
                        <td>{{app.prefs_module.get_ui_user_preference(user, 'bookmarks')}}</td>
                     </tr>
                     <tr>
                        <td>elts_per_page</td>
                        <td>{{app.prefs_module.get_ui_user_preference(user, 'elts_per_page')}}</td>
                     </tr>
                  %end
                  </tbody>
               </table>
         </div>
      </div>
%end
