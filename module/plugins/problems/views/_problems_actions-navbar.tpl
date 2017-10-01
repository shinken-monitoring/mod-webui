<li>
  <h4 class="navbar-text">
    <span id="js-nb-selected-elts"></span> selected elements
  </h4>
</li>
%if app.can_action():
<li>
  <button class="btn btn-ico btn-action js-recheck-elts" title="Recheck">
    <i class="fa fa-refresh"></i>
  </button>
</li>
<li>
  <button class="btn btn-ico btn-action js-add-acknowledge-elts" title="Acknowledge">
    <i class="fa fa-check"></i>
  </button>
</li>
<li>
  <button class="btn btn-ico btn-action js-schedule-downtime-elts" title="Schedule a one day downtime">
    <i class="fa fa-ambulance"></i>
  </button>
</li>
<li>
  <button class="btn btn-ico btn-action js-try-to-fix-elts" title="Try to fix">
    <i class="fa fa-magic"></i>
  </button>
</li>
<li>
  <button class="btn btn-ico btn-action js-submit-ok-elts" title="Set to OK/UP">
    <i class="fa fa-share"></i>
  </button>
</li>
%s = app.datamgr.get_services_synthesis(user=user, elts=all_pbs)
%h = app.datamgr.get_hosts_synthesis(user=user, elts=all_pbs)
%if s and s['nb_ack']:
<li>
  <button class="btn btn-ico btn-action js-remove-acknowledge-elts" title="Remove all acknowledges">
    <i class="fa fa-check text-danger"></i>
  </button>
</li>
%end
%if s and s['nb_downtime']:
<li>
  <button class="btn btn-ico btn-action js-delete-all-downtimes-elts" title="Remove all downtimes">
    <i class="fa fa-ambulance text-danger"></i>
  </button>
</li>
%end
%end
