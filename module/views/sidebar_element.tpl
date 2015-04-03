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

<!-- Sidebar menu -->
<div class="visible-md visible-lg">
  <!-- Sidebar clock -->
  <div class="sideClock visible-sm visible-xs">
    <span class="date">&nbsp;</span>
    <span class="time">&nbsp;</span>
  </div>
  <script type="text/javascript">
  $(document).ready(function(){
    // Date / time
    $('.sideClock .time').jclock({ format: '%H:%M:%S' });
    $('.sideClock .date').jclock({ format: '%d/%m/%Y' });

    $('.nav.sidebar-menu li a').click(function () {
/*
      window.setTimeout(function() { 
        $('.left-side').toggleClass("collapse-left");
        $(".right-side").toggleClass("strech");
      }, 1000);
*/
    });
    
/*
    window.setTimeout(function() { 
      $('.left-side').toggleClass("collapse-left");
      $(".right-side").toggleClass("strech");
    }, 10);
*/
  });
  </script>

  <ul class="nav sidebar-menu">
    <li class="active">
      <a href="/dashboard">
        <i class="fa fa-dashboard"></i> Dashboard 
      </a>
    </li>
%if 'problems' in app.menu: 
    <li>
      <a href="/problems">
        <i class="fa fa-ambulance"></i> Problems
      </a>
    </li>
%end
%if 'impacts' in app.menu: 
    <li>
      <a href="/impacts">
        <i class="fa fa-bolt"></i> Impacts
      </a>
    </li>
%end
%if 'hosts-groups' in app.menu: 
    <li>
      <a href="/hosts-groups">
        <i class="fa fa-sitemap"></i> Hosts groups
      </a>
    </li>
%end
%if 'services-groups' in app.menu: 
    <li>
      <a href="/services-groups">
        <i class="fa fa-sitemap"></i> Services groups
      </a>
    </li>
%end
%if 'hosts-tags' in app.menu: 
    <li>
      <a href="/hosts-tags">
        <i class="fa fa-tags"></i> Hosts tags
      </a>
    </li>
%end
%if 'services-tags' in app.menu: 
    <li>
      <a href="/services-tags">
        <i class="fa fa-tags"></i> Services tags
      </a>
    </li>
%end
%if 'contacts' in app.menu: 
    <li>
      <a href="/contacts">
        <i class="fa fa-users"></i> Contacts
      </a>
    </li>
%end
%if 'commands' in app.menu: 
    <li>
      <a href="/commands">
        <i class="fa fa-terminal"></i> Commands
      </a>
    </li>
%end
%if 'timeperiods' in app.menu: 
    <li>
      <a href="/timeperiods">
        <i class="fa fa-calendar"></i> Timeperiods
      </a>
    </li>
%end
%if 'minemaps' in app.menu: 
    <li>
      <a href="/minemaps">
        <i class="fa fa-table"></i> Minemap
      </a>
    </li>
%end
%if 'worldmap' in app.menu: 
    <li>
      <a href="/worldmap">
        <i class="fa fa-globe"></i> Worldmap
      </a>
    </li>
%end
%if 'wall' in app.menu: 
    <li>
      <a href="/wall">
        <i class="fa fa-th-large"></i> Wall
      </a>
    </li>
%end
%if 'system' in app.menu: 
    <li>
      <a href="/system">
        <i class="fa fa-gears"></i> System
      </a>
    </li>
%end
%if 'logs' in app.menu: 
    <li>
      <a href="/logs">
        <i class="fa fa-th-list"></i> Logs
      </a>
    </li>
%end
    %if app:
    %other_uis = app.get_external_ui_link()
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
    <hr style="width: 90%"/>
    %end
  </ul>
</div>
