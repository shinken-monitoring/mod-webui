<div class="tab-pane fade" id="downtimes">
  <div class="panel panel-default" style="border-top:none; border-radius:0;">
    <div class="panel-body">
      %if elt.downtimes:

      %include("_eltdetail_downtime_table.tpl", downtimes=elt.downtimes)

      <div class="text-right">
        <button class="{{'disabled' if not app.can_action() else ''}} btn btn-default btn-sm js-delete-all-downtimes"
          title="Delete all the downtimes of this {{elt_type}}"
          data-element="{{helper.get_uri_name(elt)}}"
          >
          <i class="fas fa-minus"></i> Delete all downtimes
        </button>
      </div>

      %else:
      <div class="page-header">
        <h4 class="page-header">No downtimes for this {{ elt_type }}</h4>
      </div>

      <button class="{{'disabled' if not app.can_action() else ''}} btn btn-primary btn-sm js-schedule-downtime"
        title="Schedule a downtime for this {{elt_type}}"
        data-element="{{helper.get_uri_name(elt)}}"
        >
        <i class="fas fa-plus"></i> Schedule a downtime
      </button>
      %end

      %if elt_type=='host' and elt.services:
      %servicedowntimes = [d for sublist in [s.downtimes for s in elt.services] for d in sublist]
      %if servicedowntimes:
      <br/><br/>
      <h4 class="page-header">Downtimes on {{ elt.get_name() }} services</h4>
      %include("_eltdetail_downtime_table.tpl", downtimes=servicedowntimes, with_service_name=True)
      %end
      %end
    </div>

  </div>
</div>
