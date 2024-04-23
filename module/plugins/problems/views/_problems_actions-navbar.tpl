<ul class='nav navbar-nav hidden' id='nav-actions'>
   <li class="hidden-xs">
     <h4 class="navbar-text">
       <span id="js-nb-selected-elts"></span> <span class="hidden-sm">selected </span>elements
     </h4>
   </li>
   %if app.can_action():
   <li>
     <button class="btn btn-ico btn-action js-recheck" title="Recheck">
       <i class="fas fa-sync"></i>
     </button>
   </li>
   %from datetime import datetime, date, timedelta
   %from time import mktime
   %now=datetime.now()
   %today=datetime(now.year, now.month, now.day)
   %today9 = int(mktime((today + timedelta(hours=9)).timetuple()))
   %today14 = int(mktime((today + timedelta(hours=14)).timetuple()))
   %nextmonday = int(mktime((today + timedelta(days=-today.weekday(), weeks=1, hours=8)).timetuple()))
   %nextmonth = datetime(now.year, now.month+1, 1, 8)
   %if nextmonth.weekday() > 4:
   %nextmonth = nextmonth + timedelta(days=7-nextmonth.weekday())
   %end
   %nextmonth = int(mktime(nextmonth.timetuple()))
   %nextyear = datetime(now.year+1, 1, 2, 8)
   %if nextyear.weekday() > 4:
   %nextyear = nextyear + timedelta(days=7-nextyear.weekday())
   %end
   %nextyear = int(mktime(nextyear.timetuple()))
   %tomorrow8 = int(mktime((today + timedelta(days=1, hours=8)).timetuple()))
   %tomorrow9 = int(mktime((today + timedelta(days=1, hours=9)).timetuple()))
   %in3days8 = int(mktime((today + timedelta(days=3, hours=8)).timetuple()))
   %in7days8 = int(mktime((today + timedelta(days=7, hours=8)).timetuple()))
   %in30days8 = int(mktime((today + timedelta(days=30, hours=8)).timetuple()))
   <li>
     <div class="dropdown" style="display: inline; padding: 0; margin: 0;">
       <button class="btn btn-ico btn-action dropdown-toggle" type="button" id="dropdown-ack" data-toggle="dropdown" title="Acknowledge">
         <i class="fa fa-check"></i>
       </button>
       <ul class="dropdown-menu dropdown-menu-right" aria-labelledby="dropdown-ack" style="margin-top: 15px;">
         <li class="dropdown-header">Acknowledge for…</li>
         <li><a href="#" class="js-add-acknowledge" data-duration="60">1 hour</a></li>
         <!--<li><a href="#" class="js-add-acknowledge" data-duration="180">3 hours</a></li>-->
         <!--<li><a href="#" class="js-add-acknowledge" data-duration="720">12 hours</a></li>-->
         <!--<li><a href="#" class="js-add-acknowledge" data-duration="1440">24 hours</a></li>-->
         <li><a href="#" class="js-add-acknowledge" data-until="{{ in3days8 }}">3 days</a></li>
         <li><a href="#" class="js-add-acknowledge" data-until="{{ in7days8 }}">7 days</a></li>
         <li><a href="#" class="js-add-acknowledge" data-until="{{ in30days8 }}">30 days</a></li>
         <li class="dropdown-header">or until…</li>
         %if datetime.now().hour < 9:
         <li><a href="#" class="js-add-acknowledge" data-until="{{ today9 }}">Today 9am</a></li>
         %end
         %if datetime.now().hour < 14:
         <li><a href="#" class="js-add-acknowledge" data-until="{{ today14 }}">Today 14pm</a></li>
         %end
         <li><a href="#" class="js-add-acknowledge" data-until="{{ tomorrow8 }}">Tomorrow 8am</a></li>
         %if datetime.now().hour > 18:
         <li><a href="#" class="js-add-acknowledge" data-until="{{ tomorrow9 }}">Tomorrow 9am</a></li>
         %end
         <li><a href="#" class="js-add-acknowledge" data-until="{{ nextmonday }}">Next monday 8am</a></li>
         <li class="divider"></li>
         <li><a href="#" class="js-add-acknowledge">without expiration</a></li>
       </ul>
     </div>
   </li>
   <li>
     <div class="dropdown" style="display: inline; padding: 0; margin: 0;">
       <button class="btn btn-ico btn-action dropdown-toggle" type="button" id="dropdown-downtime" data-toggle="dropdown" title="Schedule a downtime">
         <i class="far fa-clock"></i>
       </button>
       <ul class="dropdown-menu dropdown-menu-right" aria-labelledby="dropdown-downtime" style="margin-top: 15px;">
         <li class="dropdown-header">Set a downtime for…</li>
         <li><a href="#" class="js-schedule-downtime" data-duration="60">1 hour</a></li>
         <!--<li><a href="#" class="js-schedule-downtime" data-duration="180">3 hours</a></li>-->
         <!--<li><a href="#" class="js-schedule-downtime" data-duration="720">12 hours</a></li>-->
         <!--<li><a href="#" class="js-schedule-downtime" data-duration="1440">24 hours</a></li>-->
         <li><a href="#" class="js-schedule-downtime" data-until="{{ in3days8 }}">3 days</a></li>
         <li><a href="#" class="js-schedule-downtime" data-until="{{ in7days8 }}">7 days</a></li>
         <li><a href="#" class="js-schedule-downtime" data-until="{{ in30days8 }}">30 days</a></li>
         <li class="dropdown-header">or until…</li>
         %if datetime.now().hour < 9:
         <li><a href="#" class="js-schedule-downtime" data-until="{{ today9 }}">Today 9am</a></li>
         %end
         %if datetime.now().hour < 14:
         <li><a href="#" class="js-schedule-downtime" data-until="{{ today14 }}">Today 14pm</a></li>
         %end
         <li><a href="#" class="js-schedule-downtime" data-until="{{ tomorrow8 }}">Tomorrow 8am</a></li>
         %if datetime.now().hour > 18:
         <li><a href="#" class="js-schedule-downtime" data-until="{{ tomorrow9 }}">Tomorrow 9am</a></li>
         %end
         <li><a href="#" class="js-schedule-downtime" data-until="{{ nextmonday }}">Next monday 8am</a></li>
         <li class="dropdown-header">…</li>
         <li><a href="#" class="js-schedule-downtime" data-until="{{ nextmonth }}">First of next month</a></li>
         <li><a href="#" class="js-schedule-downtime" data-until="{{ nextyear }}">First of next year</a></li>
         <li class="divider"></li>
         <li><a href="#" class="js-schedule-downtime">Custom timeperiod</a></li>
       </ul>
     </div>
   </li>
   <li>
     <button class="btn btn-ico btn-action js-try-to-fix" title="Try to fix">
       <i class="fas fa-magic"></i>
     </button>
   </li>
   <li>
     <button class="btn btn-ico btn-action js-submit-ok" title="Set to OK/UP">
       <i class="fas fa-share"></i>
     </button>
   </li>
   %s = app.datamgr.get_services_synthesis(user=user, elts=all_pbs)
   %h = app.datamgr.get_hosts_synthesis(user=user, elts=all_pbs)
   %if s and s['nb_ack']:
   <li>
     <button class="btn btn-ico btn-action js-remove-acknowledge" title="Remove all acknowledges">
       <i class="fas fa-check text-danger"></i>
     </button>
   </li>
   %end
   %if s and s['nb_downtime']:
   <li>
     <button class="btn btn-ico btn-action js-delete-all-downtimes" title="Remove all downtimes">
       <i class="far fa-clock text-danger"></i>
     </button>
   </li>
   %end
   %end
</ul>
