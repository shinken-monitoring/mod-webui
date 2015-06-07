%setdefault('app', None)
%setdefault('user', None)
%username = 'anonymous'
%if user is not None:
%if hasattr(user, 'alias'):
%  username = user.alias
%else:
%  username = user.get_name()
%end
%end

%# Fetch sidebar preference for user, default is 'show'
%sidebar_pref = app.get_user_preference(user, 'sidebar', 'show')
<div class="sidebar-nav">
   <div class="navbar navbar-default" role="navigation">
      <div class="navbar-header">
         <button type="button" class="navbar-toggle" data-toggle="collapse" data-target=".sidebar-navbar-collapse">
            <span class="sr-only">Toggle navigation</span>
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
         </button>
         <span class="visible-xs navbar-brand">Sidebar menu</span>
      </div>
      <div class="navbar-collapse collapse sidebar-navbar-collapse">
         <ul class="nav navbar-nav">
         %if app:
            %# Anyway, at least a Dashboard entry ...
            %if app.sidebar_menu is None: 
                <li class="active">
                  <a href="/dashboard">
                    <span class="fa fa-dashboard"></span> Dashboard 
                  </a>
                </li>
            %else:
            %for (menu) in app.sidebar_menu: 
            %menu = [item.strip() for item in menu.split(',')]
            %if len(menu) >= 2:
                <li>
                  <a href="/{{menu[0]}}">
            %if len(menu) >= 3:
                    <span class="fa fa-{{menu[2]}}"></span> {{menu[1]}}
            %else:
                    <span class="fa"></span> {{menu[1]}}
            %end
                  </a>
                </li>
            %end
            %end
            %end
            
            %other_uis = app.get_ui_external_links()
            %if len(other_uis) > 0:
            <hr style="width: 90%"/>
            %end
            %for c in other_uis:
            <li>
              <a href="{{c['uri']}}" target="_blank">
                <i class="fa fa-rocket"></i> {{c['label']}}
              </a>
            </li>
            %end
         %end
         </ul>
      </div><!--/.nav-collapse -->
   </div>
</div>
<script>
   <!-- @todo@, change layout ... -->
   <!-- Should work but does not ... because of whole page reloading on every link ... -->
   $(".sidebar-nav a").on("click", function(){
      $(".sidebar-nav").find(".active").removeClass("active");
      $(this).parent().addClass("active");
   });
</script>