%rebase("fullscreen", js=['dashboard/js/screenfull.js'], css=['dashboard/css/dashboard-currently.css'], title='Shinken currently', print_header=False, print_menu=False, print_title=False, print_footer=False, refresh=True)

%helper = app.helper

<script type="text/javascript">
   $(document).ready(function(){
      // Date / time
      $('#clock').jclock({ format: '%H:%M:%S' });
      $('#date').jclock({ format: '%A, %B %d' });
   });
   $(function() {
      $(window).bind("load resize", function() {
         topOffset = 0;
         width = (this.window.innerWidth > 0) ? this.window.innerWidth : this.screen.width;

         height = ((this.window.innerHeight > 0) ? this.window.innerHeight : this.screen.height) - 1;
         height = height - topOffset;
         if (height < 1) height = 1;
         if (height > topOffset) {
            $("#page-wrapper").css("min-height", (height) + "px");
            $("section.content").css("min-height", (height-25) + "px");
         }
         
         $('#state-icons').each(function() {
            $(this).css('margin-top', (height - $('#back-home').height() - $('#date-time').height() - $(this).height() - 26) + "px");
         });
      });
   });
</script>

%setdefault('user', None)
%username = 'anonymous'
%if user is not None:
%if hasattr(user, 'alias'):
%  username = user.alias
%else:
%  username = user.get_name()
%end
%end


%if username != 'anonymous':
<div id="back-home">
   <ul class="nav nav-pills">
      <li> <a href="/dashboard" class="font-darkgrey"><i class="fa fa-home"></i></a> </li>
   </ul>
</div>
%end
<div id="date-time">
   <div id="clock"></div>
   <div id="date"></div>
</div>

<div id="state-icons" class="col-xs-12">
   <div class="col-xs-6 col-sm-3">
      %if username != 'anonymous':
      <a href="/all?search=type:host isnot:OK" class="btn btn-sm">
      %end
         <div>
            %host_state = app.get_percentage_hosts_state(app.get_user_auth(), False)
            <span class="badger-big badger-left">{{app.get_nb_hosts(app.get_user_auth())}}</span>
            <span class="badger-big badger-right alert-{{'critical' if host_state <= 33 else 'warning' if host_state <= 66 else 'ok'}}">{{host_state}}%</span>
         </div>
         
         <i class="fa fa-5x fa-server font-white"></i>
         <p class="icon_title hosts">&nbsp;Hosts DOWN</p>
         
      %if username != 'anonymous':
      </a>
      %end
   </div>

   <div class="col-xs-6 col-sm-3">
      %if username != 'anonymous':
      <a href="/all?search=type:service isnot:OK" class="btn btn-sm">
      %end
         <div>
            %service_state = app.get_percentage_service_state(app.get_user_auth(), False)
            <span class="badger-big badger-left">{{app.get_nb_services(app.get_user_auth())}}</span>
            <span class="badger-big badger-right alert-{{'critical' if service_state <= 33 else 'warning' if service_state <= 66 else 'ok'}}">{{service_state}}%</span>
         </div>

         <i class="fa fa-5x fa-bars font-white"></i>
         <p class="icon_title services">&nbsp;Services KO</p>

      %if username != 'anonymous':
      </a>
      %end
   </div>

   <div class="col-xs-6 col-sm-3">
      %if username != 'anonymous':
      <a href="/problems" class="btn btn-sm">
      %end
         <div>
            %overall_itproblem = app.get_overall_it_state(app.get_user_auth())
            <span title="Number of not acknowledged IT problems." class="badger-big alert-{{'ok' if overall_itproblem == 0 else 'warning' if overall_itproblem == 1 else 'critical'}}">{{app.get_overall_it_problems_count(app.get_user_auth(), False)}}</span>
         </div>

         <i class="fa fa-5x fa-exclamation-triangle font-white"></i>
         <p class="icon_title itproblem">&nbsp;IT Problems</p>
         
      %if username != 'anonymous':
      </a>
      %end
   </div>

   <div class="col-xs-6 col-sm-3">
      %if username != 'anonymous':
      <a href="/impacts" class="slidelink btn btn-sm">
      %end
         <div>
            %overall_state = app.get_overall_state(app.get_user_auth())
            <span title="Number of not acknownledged IT problems." class="badger-big alert-{{'ok' if overall_state == 0 else 'warning' if overall_state == 1 else 'critical'}}">{{app.get_overall_state_problems_count(app.get_user_auth())}}</span>
         </div>
         
         <i class="fa fa-5x fa-flash font-white"></i>
         <p class="icon_title impacts">&nbsp;Impacts</p>
         
      %if username != 'anonymous':
      </a>
      %end
   </div>
</div>
