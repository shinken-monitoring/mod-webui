%if not 'app' in locals(): app = None
%if not 'user' in locals(): user = None

%username = 'anonymous'
%if user is not None: 
%if hasattr(user, 'alias'):
%	username = user.alias
%else:
%	username = user.get_name()
%end
%end


<!-- Header -->
<header class="header">
  <a href="#about" data-toggle="modal" data-target="#about" class="logo">
    <img src="/static/images/logo/logo.png" alt="Logo" />
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
              <i class="ion ion-person"></i>
              <span><span class="username">{{username}}</span> <i class="caret"></i></span>
          </a>
          
          <ul class="dropdown-menu">
            <!-- User image -->
            <li class="user-header bg-light-blue">
              %if app is not None and app.company_logo:
              <img src="/static/images/logo/{{app.company_logo}}" class="img-circle" alt="User logo" />
              %else:
              <img src="/static/images/logo/logo_small.png" class="img-circle" alt="User logo" />
              %end
              <p class="username">
                  {{username}}
              </p>
              %if app.manage_acl and helper.can_action(user):
                <p class="usercategory">
                    <small>Administrator</small>
                </p>
              %end
            </li>
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
        %overall_itproblem = app.datamgr.get_overall_it_state()
        %if overall_itproblem == 0:
        <li class="pull-right"><a href="/problems" class="quickinfo" data-original-title='IT Problems'><i class="fa fa-ambulance"></i><span class="pulsate badger badger-ok">OK!</span> </a></li>
        %elif overall_itproblem == 1:
        <li class="pull-right"><a href="/problems" class="quickinfo" data-original-title='IT Problems'><i class="fa fa-ambulance"></i><span class="pulsate badger badger-warning">{{app.datamgr.get_nb_all_problems(app.get_user_auth())}}</span> </a></li>
        %elif overall_itproblem == 2:
        <li class="pull-right"><a href="/problems" class="quickinfo" data-original-title='IT Problems'><i class="fa fa-ambulance"></i><span class="pulsate badger badger-critical">{{app.datamgr.get_nb_all_problems(app.get_user_auth())}}</span> </a></li>
        %end

        %overall_state = app.datamgr.get_overall_state()
        %if overall_state == 2:
        <li class="pull-right"><a href="/impacts" class="quickinfo" data-original-title='Impacts'><i class="fa fa-bolt"></i><span class="pulsate badger badger-critical">{{app.datamgr.get_len_overall_state()}}</span> </a></li>
        %elif overall_state == 1:
        <li class="pull-right"><a href="/impacts" class="quickinfo" data-original-title='Impacts'><i class="fa fa-bolt"></i><span class="pulsate badger badger-warning">{{app.datamgr.get_len_overall_state()}}</span> </a></li>
        %end
        %end
      </ul>
    </div>
  </nav>
</header>
