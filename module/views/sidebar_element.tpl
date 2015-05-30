%setdefault('app', None)
%setdefault('user', None)
%username = 'anonymous'
%if user is not None:
%if hasattr(user, 'alias'):
%	username = user.alias
%else:
%	username = user.get_name()
%end
%end

<!-- Sidebar menu -->
<div>
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
    %if app:
		%# Anyway, at least a Dashboard entry ...
		%if app.sidebar_menu is None: 
			 <li class="active">
				<a href="/dashboard">
				  <i class="fa fa-dashboard"></i> Dashboard 
				</a>
			 </li>
		%else:
		%for (menu) in app.sidebar_menu: 
		%menu = [item.strip() for item in menu.split(',')]
		%if len(menu) >= 2:
			 <li>
				<a href="/{{menu[0]}}">
		%if len(menu) >= 3:
				  <i class="fa fa-{{menu[2]}}"></i> {{menu[1]}}
		%else:
				  <i class="fa"></i> {{menu[1]}}
		%end
				</a>
			 </li>
		%end
		%end
		%end
		
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
