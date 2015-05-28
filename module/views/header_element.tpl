%if not 'app' in locals(): app = None
%if not 'user' in locals(): user = None

%username = 'anonymous'
%if user is not None:
%if hasattr(user, 'alias') and user.alias != 'none':
%	username = user.alias
%else:
%	username = user.get_name()
%end
%end


<!-- Header -->
<header class="header">
   <a href="#about" data-toggle="modal" data-target="#about" class="logo">
      %if app.company_logo:
      <img src="/static/images/logo/{{app.company_logo}}" />
      %else:
      <img src="/static/images/logo/default_logo.png" alt="Logo" />
      %end
   </a>

   <!-- Header Navbar -->
   <nav class="navbar navbar-static-top" role="navigation">
      <!-- Sidebar toggle button-->
      <a href="#" class="navbar-btn sidebar-toggle" data-toggle="offcanvas" role="button">
         <span class="sr-only">Toggle navigation</span>
         <span class="icon-bar"></span>
         <span class="icon-bar"></span>
         <span class="icon-bar"></span>
      </a>

      <div class="col-sm-2 col-md-2 pull-left">
         <form id="host-search" class="navbar-form navbar-left" role="search">
            <div class="input-group">
               <div class="input-group-btn">
                  <button class="btn btn-default" type="submit"><i class="glyphicon glyphicon-search"></i></button>
               </div>
               <input type="text" class="form-control typeahead" placeholder="Search hosts ..." name="host-search">
            </div>
         </form>
      </div>

      <div class="navbar-left hidden-sm hidden-xs">
         <ul class="nav navbar-nav">
            <li class="pull-left"><a class="quickinfo" data-original-title='Currently' href="#">
               <span class="headClock">
                  <span class="date">&nbsp;</span> - <span class="time">&nbsp;</span>
               </span>
            </a></li>
         </ul>
      </div>
      <script type="text/javascript">
         $(document).ready(function(){
            // Date / time
            $('.headClock .time').jclock({ format: '%H:%M:%S' });
            $('.headClock .date').jclock({ format: '%d/%m/%Y' });
         });
      </script>

    <div class="navbar-right">
      <ul class="nav navbar-nav">

        <li class="pull-right dropdown user user-menu">
          <a href="#" class="dropdown-toggle" data-toggle="dropdown">
              <i class="fa fa-user"></i>
              <span><span class="username">{{username}}</span> <i class="caret"></i></span>
          </a>

          <ul class="dropdown-menu">
            <!-- User image / name -->
            <li class="user-header bg-light-blue">
              <p class="username">
                  {{username}}
              </p>
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
            
            <!-- Menu Footer-->
            <li class="user-footer">
              <div class="pull-left">
                <a href="https://shinken.readthedocs.org/en/latest/" target="_blank" class="btn btn-default btn-flat"><i class="fa fa-book"></i> </a>
                <a href="#settings" data-toggle="modal" class="btn btn-default btn-flat disabled"><span class="fa fa-gear"></span> </a>
                <a href="#profile" data-toggle="modal" class="btn btn-default btn-flat disabled"><span class="fa fa-pencil"></span> </a>
              </div>
              <div class="pull-right">
                  <a href="/user/logout" class="btn btn-default btn-flat" data-toggle="modal" data-target="/user/logout"><span class="fa fa-sign-out"></span> </a>
              </div>
            </li>
          </ul>
        </li>

        <li class="pull-right"><a class="quickinfo" data-original-title='Currently' href="/dashboard/currently"><i class="fa fa-eye"></i></a></li>

        %if app:
        %overall_state = app.get_overall_state(app.get_user_auth())
        <li class="pull-right"><a href="/impacts" class="quickinfo" data-original-title='Impacts'><i class="fa fa-bolt"></i><span class="pulsate badger badger-{{'ok' if overall_state == 0 else 'warning' if overall_state == 1 else 'critical'}}">{{app.get_overall_state_problems_count(app.get_user_auth())}}</span> </a></li>
        
        %overall_itproblem = app.get_overall_it_state(app.get_user_auth())
        <li class="pull-right"><a href="/problems" class="quickinfo" data-original-title='IT Problems'><i class="fa fa-ambulance"></i><span class="pulsate badger badger-{{'ok' if overall_itproblem == 0 else 'warning' if overall_itproblem == 1 else 'critical'}}">{{app.get_overall_it_problems_count(user, False)}}</span> </a></li>
        %end
      </ul>
    </div>
  </nav>
</header>
<script type="text/javascript">
  // Typeahead: builds suggestion engine
  var hosts = new Bloodhound({
    datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
    queryTokenizer: Bloodhound.tokenizers.whitespace,
    remote: {
      url: '/lookup/%QUERY',
      filter: function (hosts) {
        return $.map(hosts, function (host) { return { value: host }; });
      }
    }
  });
  hosts.initialize();

  var hostSubmittable = false;
  $( "#host-search" ).submit(function( event ) {
    if (hostSubmittable) {
      var hostname = $('input[name="host-search"]').val();
      window.location = '/host/'+hostname;
    }
    event.preventDefault();
  });

	/* Catch the key ENTER and launch the form
	 Will be link in the password field
	function submitenter(myfield,e){
	  var keycode;
	  if (window.event) keycode = window.event.keyCode;
	  else if (e) keycode = e.which;
	  else return true;

	  if (keycode == 13){
	    submitform();
	    return false;
	  }else
	   return true;
	}
	*/

  // On page loaded ...
  $(function() {
    // Typeahead: activation
    var typeahead = $('#host-search .typeahead').typeahead({
      hint: true,
      highlight: true,
      minLength: 1
    },
    {
      name: 'hosts',
      displayKey: 'value',
      source: hosts.ttAdapter(),
    });

    typeahead.on('typeahead:selected', function (eventObject, suggestionObject, suggestionDataset) {
      $('input[name="host-search"]').val(suggestionObject.value).html(suggestionObject.value);
      hostSubmittable = true;
    });
  });
</script>
