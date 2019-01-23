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
   <li>
     <button class="btn btn-ico btn-action js-add-acknowledge" title="Acknowledge">
       <i class="fas fa-check"></i>
     </button>
   </li>
   <li>
     <div class="dropdown" style="display: inline; padding: 0; margin: 0;">
       <button class="btn btn-ico btn-action dropdown-toggle" type="button" id="dropdown-downtime" data-toggle="dropdown" title="Schedule a downtime">
         <i class="far fa-clock"></i>
       </button>
       <ul class="dropdown-menu dropdown-menu-right" aria-labelledby="dropdown-downtime" style="margin-top: 15px;">
         <li class="dropdown-header">Set a downtime for…</li>
         <li><a href="#" class="js-schedule-downtime" data-duration="60">1 hour</a></li>
         <li><a href="#" class="js-schedule-downtime" data-duration="180">3 hours</a></li>
         <li><a href="#" class="js-schedule-downtime" data-duration="720">12 hours</a></li>
         <li><a href="#" class="js-schedule-downtime" data-duration="1440">24 hours</a></li>
         <li><a href="#" class="js-schedule-downtime" data-duration="2160">3 days</a></li>
         <li><a href="#" class="js-schedule-downtime" data-duration="5040">7 days</a></li>
         <li><a href="#" class="js-schedule-downtime" data-duration="21600">30 days</a></li>
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
