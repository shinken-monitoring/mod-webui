%import json

%username = 'anonymous'
%if user is not None:
%if hasattr(user, 'alias') and user.alias != 'none':
%	username = user.alias
%else:
%	username = user.get_name()
%end
%end

%rebase("layout", user=user, app=app, refresh=True, css=['user/css/user.css'], breadcrumb=[ ['User preferences', '/user/pref'] ], title='User preferences')

%setdefault('app', None)
%setdefault('user', None)

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
                  %if app is not None and app.gravatar:
                  $('<img src="{{app.get_gravatar(user.email, 32)}}" class="img-circle user-logo" alt="{{username}}" title="Photo: {{username}}" style="display:none">')
                     .load(function() { $(this).show(); })
                     .error(function() { 
                        $(this).remove(); 
                        $('<img src="/static/images/logo/default_user.png" class="img-circle user-logo" alt="{{username}}" title="Photo: {{username}}" style="display:none">')
                           .load(function() { $(this).show(); })
                           .error(function() { $(this).remove(); })
                           .prependTo('div.user-header');
                     })
                     .prependTo('div.user-header');
                  %else:
               $('<img src="/static/images/logo/{{user.get_name()}}.png" class="img-circle user-logo" alt="{{username}}" title="Photo: {{username}}" style="display:none">')
                  .load(function() { $(this).show(); })
                  .error(function() { 
                     $(this).remove(); 
                     $('<img src="/static/images/logo/default_user.png" class="img-circle user-logo" alt="{{username}}" title="Photo: {{username}}" style="display:none">')
                        .load(function() { $(this).show(); })
                        .error(function() { $(this).remove(); })
                        .prependTo('div.user-header');
                  })
                  .prependTo('div.user-header');
                  %end
               </script>
            
               <p class="username">
                 {{username}}
               </p>
               %if app.manage_acl:
               <p class="usercategory">
                  <small>{{'Administrator' if user.is_admin else 'User'}}</small>
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
                <tr>
                  <th colspan="2"></td>
                </tr>
              </thead>
              <tbody style="font-size:x-small;">
                <tr>
                  <td><strong>Identification:</strong></td>
                  <td>{{"%s (%s)" % (user.alias, user.contact_name) if user.alias != 'none' else user.contact_name}}</td>
                </tr>
                <tr>
                  <td><strong>Commands authorized:</strong></td>
                  <td>{{! app.helper.get_on_off(app.helper.can_action(user), "Is this contact allowed to launch commands from Web UI?")}}</td>
                </tr>
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
              </tbody>
            </table>
            
          </div>
         </div>
      </div>
   </div>
</div>
%end
