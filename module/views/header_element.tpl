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
<nav class="header navbar navbar-default navbar-fixed-top">
   <div class="container-fluid">
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
      <div class="collapse navbar-collapse" id="bs-example-navbar-collapse-1">
         <ul class="nav navbar-nav">
            <!-- Sidebar toggle button-->
            <a href="#" class="navbar-btn sidebar-toggle" data-toggle="sidebar" role="button">
               <span class="sr-only">Toggle sidebar menu</span>
               <span class="icon-bar"></span>
               <span class="icon-bar"></span>
               <span class="icon-bar"></span>
            </a>

            <!-- Host search ... -->
            <form id="frmSearch" class="navbar-form navbar-left hidden-xs" role="search">
               <div class="form-group">
                  <label class="sr-only" for="hosts-search">Hosts search</label>
                  <div class="input-group">
                     <input type="search" placeholder="Search hosts..." class="form-control typeahead" id="hosts-search" name="hosts-search" />
                  </div>
                  <input type="submit" value="Submit" class="sr-only">
               </div>
            </form>

            <!-- Clock ... -->
            <p class="navbar-text hidden-sm hidden-xs">
               <span class="headClock">
                  <span class="date">&nbsp;</span> - <span class="time">&nbsp;</span>
               </span>
            </p>
         </ul>
         
         <!-- Right buttons ... -->
         <ul class="nav navbar-nav navbar-right">
            <li><a class="quickinfo" data-original-title='Currently' href="/dashboard/currently"><i class="fa fa-eye"></i></a></li>

            %if app:
            %overall_state = app.get_overall_state(app.get_user_auth())
            <li><a href="/impacts" class="quickinfo" data-original-title='Impacts'><i class="fa fa-bolt"></i><span class="pulsate badger badger-{{'ok' if overall_state == 0 else 'warning' if overall_state == 1 else 'critical'}}">{{app.get_overall_state_problems_count(app.get_user_auth())}}</span> </a></li>
           
            %overall_itproblem = app.get_overall_it_state(app.get_user_auth())
            <li><a href="/problems" class="quickinfo" data-original-title='IT Problems'><i class="fa fa-ambulance"></i><span class="pulsate badger badger-{{'ok' if overall_itproblem == 0 else 'warning' if overall_itproblem == 1 else 'critical'}}">{{app.get_overall_it_problems_count(user, False)}}</span> </a></li>
            %end
           
            <!-- User info -->
            <li class="dropdown user user-menu">
               <a href="#" class="dropdown-toggle" data-toggle="dropdown">
                  <i class="fa fa-user"></i>
                  <span><span class="username">{{username}}</span> <i class="caret"></i></span>
               </a>

               <ul class="dropdown-menu">
                  <!-- User image / name -->
                  <li class="user-header">
                     <p class="username">{{username}}</p>
                     %if app.manage_acl and helper.can_action(user):
                     <p class="usercategory">
                        <small>{{'Administrator' if user.is_admin else 'User'}}</small>
                     </p>
                     %end
                  </li>
                  <script>
                     %if app is not None and app.gravatar:
                     $('<img src="{{app.get_gravatar(user.email, 32)}}" class="img-circle user-logo" alt="{{username}}" title="Photo: {{username}}" style="display:none">')
                        .load(function() { $(this).show(); })
                        .error(function() { 
                           $(this).remove(); 
                           $('<img src="/static/images/logo/default_user.png" class="img-circle user-logo" alt="{{username}}" title="Photo: {{username}}" style="display:none">')
                              .load(function() { $(this).show(); })
                              .error(function() { $(this).remove(); })
                              .appendTo('li.user-header');
                        })
                        .appendTo('li.user-header');
                     %else:
                     $('<img src="/static/images/logo/{{user.get_name()}}.png" class="img-circle user-logo" alt="{{username}}" title="Photo: {{username}}" style="display:none">')
                        .load(function() { $(this).show(); })
                        .error(function() { 
                           $(this).remove(); 
                           $('<img src="/static/images/logo/default_user.png" class="img-circle user-logo" alt="{{username}}" title="Photo: {{username}}" style="display:none">')
                              .load(function() { $(this).show(); })
                              .error(function() { $(this).remove(); })
                              .appendTo('li.user-header');
                        })
                        .appendTo('li.user-header');
                     %end
                  </script>
               
                  <!-- User footer-->
                  <li class="user-footer">
                     <div class="pull-left">
                        <a href="https://shinken.readthedocs.org/en/latest/" target="_blank" class="btn btn-default btn-flat"><i class="fa fa-book"></i> </a>
                        <a href="/user/pref" data-toggle="modal" class="btn btn-default btn-flat"><span class="fa fa-gear"></span> </a>
                        <a href="#profile" data-toggle="modal" class="btn btn-default btn-flat disabled"><span class="fa fa-pencil"></span> </a>
                     </div>
                     <div class="pull-right">
                        <a href="/user/logout" class="btn btn-default btn-flat" data-toggle="modal" data-target="/user/logout"><span class="fa fa-sign-out"></span> </a>
                     </div>
                  </li>
               </ul>
            </li>
         </ul>
      </div>
   </div>
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
