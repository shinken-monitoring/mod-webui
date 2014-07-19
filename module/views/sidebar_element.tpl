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
    <li>
      <a href="/problems">
        <i class="fa fa-ambulance"></i> Problems
      </a>
    </li>
    <li>
      <a href="/impacts">
        <i class="fa fa-bolt"></i> Impacts
      </a>
    </li>
    <li>
      <a href="/hostgroups">
        <i class="fa fa-sitemap"></i> Hosts groups
      </a>
    </li>
    <li>
      <a href="/servicegroups">
        <i class="fa fa-sitemap"></i> Services groups
      </a>
    </li>
    <li>
      <a href="/hosts-tags">
        <i class="fa fa-sitemap"></i> Hosts tags
      </a>
    </li>
    <li>
      <a href="/services-tags">
        <i class="fa fa-sitemap"></i> Services tags
      </a>
    </li>
    <li>
      <a href="/minemaps">
        <i class="fa fa-table"></i> Minemap
      </a>
    </li>
    <li>
      <a href="/worldmap">
        <i class="fa fa-globe"></i> Worldmap
      </a>
    </li>
    <li>
      <a href="/wall">
        <i class="fa fa-th-large"></i> Wall
      </a>
    </li>
    <li>
      <a href="/system">
        <i class="fa fa-gears"></i> System
      </a>
    </li>
    <li>
      <a href="/system/logs">
        <i class="fa fa-th-list"></i> Logs
      </a>
    </li>
    
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
