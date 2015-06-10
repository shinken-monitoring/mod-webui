%setdefault('app', None)
%setdefault('user', None)

%username = 'anonymous'
%if user is not None:
%if hasattr(user, 'alias') and user.alias != 'none':
%	username = user.alias
%else:
%	username = user.get_name()
%end
%end


<!-- Header Navbar -->
<nav class="header navbar navbar-default navbar-static-top" style="margin-bottom:0px;">
      <div class="navbar-header">
         <button type="button" class="navbar-toggle collapsed" data-toggle="collapse" data-target="#bs-example-navbar-collapse-1">
           <span class="sr-only">Toggle navigation</span>
           <span class="icon-bar"></span>
           <span class="icon-bar"></span>
           <span class="icon-bar"></span>
         </button>
         <a href="#about" data-toggle="modal" data-target="#about" class="logo navbar-brand">
            %if app.company_logo:
            <img src="/static/images/logo/{{app.company_logo}}" alt="Logo" />
            %else:
            <img src="/static/images/logo/default_logo.png" alt="Logo" />
            %end
         </a>
      </div>
      <!-- Collect the nav links, forms, and other content for toggling -->
         <ul class="nav navbar-nav">
            <!-- Host search ... -->
           
            %include("_filters.tpl")

            <!-- Clock ... -->
            <p class="navbar-text hidden-sm hidden-xs">
               <span class="headClock">
                  <span class="date">&nbsp;</span> - <span class="time">&nbsp;</span>
               </span>
            </p>
         </ul>
         
         <!-- Right buttons ... -->
         <ul class="nav navbar-top-links navbar-right">
            <li><a class="quickinfo" data-original-title='Currently' href="/dashboard/currently"><i class="fa fa-eye"></i></a></li>

            <!-- :TODO:maethor:150608: badgers mess up with the display of the navbar -->
            %if app:
            %overall_state = app.get_overall_state(app.get_user_auth())
            <!--<li><a href="/impacts" class="quickinfo" data-original-title='Impacts'><i class="fa fa-bolt"></i><span class="pulsate badger badger-{{'ok' if overall_state == 0 else 'warning' if overall_state == 1 else 'critical'}}">{{app.get_overall_state_problems_count(app.get_user_auth())}}</span> </a></li>-->
           
            %overall_itproblem = app.get_overall_it_state(app.get_user_auth())
            <!--<li><a href="/problems" class="quickinfo" data-original-title='IT Problems'><i class="fa fa-ambulance"></i><span class="pulsate badger badger-{{'ok' if overall_itproblem == 0 else 'warning' if overall_itproblem == 1 else 'critical'}}">{{app.get_overall_it_problems_count(user, False)}}</span> </a></li>-->
            %end
           
            <!-- User info -->
            <li class="dropdown user user-menu">
               <a href="#" class="dropdown-toggle" data-toggle="dropdown">
                  <i class="fa fa-user"></i>
                  <span><span class="username">{{username}}</span> <i class="caret"></i></span>
               </a>

               <ul class="dropdown-menu">
                  <li class="user-header">
                     <div class="panel panel-info" id="user_info">
                        <div class="panel-heading">User information</div>
                        <div class="panel-body panel-default">
                           <!-- User image / name -->
                           <p class="username">{{username}}</p>
                           %if app.manage_acl and helper.can_action(user):
                           <p class="usercategory">
                              <small>{{'Administrator' if user.is_admin else 'User'}}</small>
                           </p>
                           %end
                           <script>
                              %if app is not None and app.gravatar:
                              $('<img src="{{app.get_gravatar(user.email, 32)}}" class="img-circle user-logo" alt="{{username}}" title="Photo: {{username}}" style="display:none">')
                                 .load(function() { $(this).show(); })
                                 .error(function() { 
                                    $(this).remove(); 
                                    $('<img src="/static/images/logo/default_user.png" class="img-circle user-logo" alt="{{username}}" title="Photo: {{username}}" style="display:none">')
                                       .load(function() { $(this).show(); })
                                       .error(function() { $(this).remove(); })
                                       .appendTo('li.user-header div.panel-body');
                                 })
                                 .appendTo('li.user-header div.panel-body');
                              %else:
                              $('<img src="/static/images/logo/{{user.get_name()}}.png" class="img-circle user-logo" alt="{{username}}" title="Photo: {{username}}" style="display:none">')
                                 .load(function() { $(this).show(); })
                                 .error(function() { 
                                    $(this).remove(); 
                                    $('<img src="/static/images/logo/default_user.png" class="img-circle user-logo" alt="{{username}}" title="Photo: {{username}}" style="display:none">')
                                       .load(function() { $(this).show(); })
                                       .error(function() { $(this).remove(); })
                                       .appendTo('li.user-header div.panel-body');
                                 })
                                 .appendTo('li.user-header div.panel-body');
                              %end
                           </script>
                        </div>
                        <div class="panel-footer">
                           <!-- User actions -->
                           <div class="btn-group" role="group">
                              <a href="https://shinken.readthedocs.org/en/latest/" target="_blank" class="btn btn-default btn-flat"><i class="fa fa-book"></i> </a>
                           </div>
                           <div class="btn-group" role="group">
                              <a href="#actions" data-toggle="modal" class="btn btn-default btn-flat disabled"><span class="fa fa-gear"></span> </a>
                              <a href="/user/pref" data-toggle="modal" class="btn btn-default btn-flat"><span class="fa fa-pencil"></span> </a>
                           </div>
                           <div class="btn-group" role="group">
                              <a href="/user/logout" class="btn btn-default btn-flat" data-toggle="modal" data-target="/user/logout"><span class="fa fa-sign-out"></span> </a>
                           </div>
                        </div>
                     </div>
                  </li>
               </ul>
            </li>
         </ul>


      <!--SIDEBAR-->
      <!-- :TODO:maethor:150608: Regroup some items in dropdowns -->
      <div class="navbar-default sidebar" role="navigation">
        <div class="sidebar-nav navbar-collapse">
          <ul class="nav" id="side-menu">
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

            <li>
              <a href="index.html"><i class="fa fa-dashboard fa-fw"></i> Dashboard</a>
            </li>
          </ul>
        </div>
        <!-- /.sidebar-collapse -->
      </div>
      <!-- /.navbar-static-side -->
</nav>

<script type="text/javascript">
   // Typeahead: builds suggestion engine
   var mainHostsSearch = new Bloodhound({
      datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
      queryTokenizer: Bloodhound.tokenizers.whitespace,
      remote: {
         url: '/lookup/%QUERY',
         filter: function (mainHostsSearch) {
            return $.map(mainHostsSearch, function (host) { return { value: host }; });
         }
      }
   });
   mainHostsSearch.initialize();

   var hostSubmittable = false;
   $("#frmSearch").submit(function( event ) {
      console.log('sumit ...');
      if (hostSubmittable) {
         var hostname = $('input[name="hosts-search"]').val();
         window.location = '/host/'+hostname;
      }
      event.preventDefault();
   });

   // On page loaded ...
   $(function() {
      // Date / time
      $('.headClock .time').jclock({ format: '%H:%M:%S' });
      $('.headClock .date').jclock({ format: '%d/%m/%Y' });
      
      // Typeahead: activation
      var typeahead = $('#frmSearch .typeahead').typeahead({
         hint: true,
         highlight: true,
         minLength: 1
      },
      {
         name: 'mainHostsSearch',
         displayKey: 'value',
         source: mainHostsSearch.ttAdapter(),
      });

      typeahead.on('typeahead:selected', function (eventObject, suggestionObject, suggestionDataset) {
         $('input[name="hosts-search"]').val(suggestionObject.value).html(suggestionObject.value);
         hostSubmittable = true;
      });
   });
</script>
