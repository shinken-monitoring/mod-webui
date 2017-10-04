<div class="tab-pane fade" id="downtimes">
  <div class="panel panel-default" style="border-top:none; border-radius:0;">
    <div class="panel-body">
      %if elt.downtimes:
      <table class="table table-condensed table-hover">
        <thead>
          <tr>
            <th>Author</th>
            <th>Reason</th>
            <th>Period</th>
            <th></th>
          </tr>
        </thead>
        <tbody>
          %for dt in sorted(elt.downtimes, key=lambda dt: dt.entry_time, reverse=True):
          <tr>
            <td>{{dt.author}}</td>
            <td>{{dt.comment}}</td>
            <td>{{helper.print_date(dt.start_time)}} - {{helper.print_date(dt.end_time)}}</td>
            <td>
              <button class="{{'disabled' if not app.can_action() else ''}} btn btn-primary btn-sm js-delete-downtime"
                title="Delete the downtime '{{dt.id}}' for this {{elt_type}}"
                data-element="{{helper.get_uri_name(elt)}}" data-downtime="{{dt.id}}"
                >
                <i class="fa fa-trash-o"></i>
              </button>
            </td>
          </tr>
          %end
        </tbody>
      </table>
      %else:
      <div class="alert alert-info">
        <p class="font-blue">No downtimes available.</p>
      </div>
      %end

      <button class="{{'disabled' if not app.can_action() else ''}} btn btn-primary btn-sm js-schedule-downtime"
        title="Schedule a downtime for this {{elt_type}}"
        data-element="{{helper.get_uri_name(elt)}}"
        >
        <i class="fa fa-plus"></i> Schedule a downtime
      </button>
      %if elt.downtimes:
      <button class="{{'disabled' if not app.can_action() else ''}} btn btn-primary btn-sm js-delete-all-downtimes"
        title="Delete all the downtimes of this {{elt_type}}"
        data-element="{{helper.get_uri_name(elt)}}"
        >
        <i class="fa fa-minus"></i> Delete all downtimes
      </button>
      %end

      %if elt_type=='host' and elt.services:
      <br/><br/>
      <h4>Current host services downtimes:</h4>
      <table class="table table-condensed table-hover">
        <thead>
          <tr>
            <th>Service</th>
            <th>Author</th>
            <th>Reason</th>
            <th>Period</th>
            <th></th>
          </tr>
        </thead>
        <tbody>
          %for s in elt.services:
          %for dt in sorted(s.downtimes, key=lambda dt: dt.entry_time, reverse=True):
          <tr>
            <td>{{s.get_name()}}</td>
            <td>{{dt.author}}</td>
            <td>{{dt.comment}}</td>
            <td>{{helper.print_date(dt.start_time)}} - {{helper.print_date(dt.end_time)}}</td>
            <td>
              <button class="{{'disabled' if not app.can_action() else ''}} btn btn-primary btn-sm js-delete-downtime"
                title="Delete this downtime"
                data-element="{{helper.get_uri_name(s)}}" data-downtime="{{dt.id}}"
                >
                <i class="fa fa-trash-o"></i>
              </button>
            </td>
          </tr>
          %end
          %end
        </tbody>
      </table>
      %end
    </div>
  </div>
</div>
