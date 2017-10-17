%setdefault('app', None)
%user = app.get_user()

%import json

%username = 'anonymous'
%if user is not None:
%username = user.get_name()
%end

%rebase("layout", css=['user/css/user.css'], breadcrumb=[ ['User preferences', '/user/pref'] ], title='User preferences')

      <div class="panel panel-default">
         <div class="panel-heading">
           <h2 class="panel-title">
             {{ username }}
             %if app.manage_acl:
             <i class="font-warning fa fa-star" title="Administrator"></i>
             %end
           </h2>
         </div>
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

                     %for attr, value in user.__dict__.iteritems():
                     <tr>
                        <td><strong>{{attr}}:</strong></td>
                        <td>{{value}}</td>
                     </tr>
                     %end

                  %if app.prefs_module.is_available():
                  %for preference in app.prefs_module.get_ui_user_preference(user, default=[]):
                  %if preference in ['_id']:
                  %continue
                  %end
                     <tr>
                        <td>{{preference}}</td>
                        <td>{{app.prefs_module.get_ui_user_preference(user, preference)}}</td>
                     </tr>
                  %end
                  %else:
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
%end
