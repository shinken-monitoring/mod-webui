%setdefault('app', None)
%setdefault('user', None)

%import json

%username = 'anonymous'
%if user is not None:
%username = user.get_name()
%end

%rebase("layout", css=['user/css/user.css'], breadcrumb=[ ['User preferences', '/user/pref'] ], title='User preferences')

<div class="row">
   <div class="col-sm-12">
      <div class="panel panel-default">
         <div class="panel-heading">
            <h2 class="panel-title">Contact</h2>
         </div>
         <div class="panel-body">
            <!-- User image -->
            <div class="user-header bg-light-blue">
               <script>
                  $('<img src="{{app.user_picture}}" class="img-circle user-logo" alt="{{username}}" title="Photo: {{username}}" style="display:none">')
                     .load(function() { $(this).show(); })
                     .error(function() {
                        $(this).remove();
                        $('<img src="/static/images/logo/default_user.png" class="img-circle user-logo" alt="{{username}}" title="Photo: {{username}}" style="display:none">')
                           .load(function() { $(this).show(); })
                           .error(function() { $(this).remove(); })
                           .prependTo('div.user-header');
                     })
                     .prependTo('div.user-header');
               </script>

               <p class="username">
                 {{username}}
               </p>
               %if app.manage_acl:
               <p class="usercategory">
                  <small>{{'Administrator' if user.is_administrator() else 'User'}}</small>
               </p>
               %end
            </div>

            <div class="user-body">
               <table class="table table-condensed col-sm-12" style="table-layout: fixed; word-wrap: break-word;">
                  <colgroup>
                     <col style="width: 30%" />
                     <col style="width: 70%" />
                  </colgroup>
                  <thead>
                     <tr><th colspan="2"></td></tr>
                  </thead>
                  <tbody style="font-size:x-small;">
                     <tr>
                        <td><strong>Identification:</strong></td>
                        <td>{{"%s (%s)" % (user.alias, user.contact_name) if user.alias != 'none' else user.contact_name}}</td>
                     </tr>
                     <tr>
                        <td><strong>Commands authorized:</strong></td>
                        <td>{{! app.helper.get_on_off(app.can_action(), "Is this contact allowed to launch commands from Web UI?")}}</td>
                     </tr>
                  </tbody>
               </table>

               <table class="table table-condensed col-sm-12" style="table-layout: fixed; word-wrap: break-word;">
                  <colgroup>
                     <col style="width: 30%" />
                     <col style="width: 70%" />
                  </colgroup>
                  <thead>
                     <tr><th colspan="2"></td></tr>
                  </thead>
                  <tbody style="font-size:x-small;">
                     %for attr, value in user.__dict__.iteritems():
                     <tr>
                        <td><strong>{{attr}}:</strong></td>
                        <td>{{value}}</td>
                     </tr>
                     %end
                  </tbody>
               </table>

               <table class="table table-condensed col-sm-12" style="table-layout: fixed; word-wrap: break-word;">
                  <colgroup>
                     <col style="width: 30%" />
                     <col style="width: 70%" />
                  </colgroup>
                  <thead>
                     <tr>
                        <th colspan="2">Preferences:</td>
                     </tr>
                  </thead>
                  <tbody style="font-size:x-small;">
                  %if app.prefs_module.is_available():
                  %for preference in app.prefs_module.get_ui_user_preference(user):
                  %if preference in ['_id']:
                  %continue
                  %end
                  <script>
                     value = '{{json.dumps(app.prefs_module.get_ui_user_preference(user, preference))}}';
/*
                     $.each(value, function( index, value ) {
                        <tr>
                           <td></td>
                           <td></td>
                        </tr>
                     });
*/
                  </script>
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
         </div>
      </div>
   </div>
</div>
%end
