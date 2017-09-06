%if user.is_administrator() and elt.customs:
<div class="tab-pane fade" id="configuration">
  <div class="panel panel-default" style="border-top:none; border-radius:0;">
    <div class="panel-body">
      <table class="table table-condensed table-bordered">
        <colgroup>
          %if app.can_action():
          <col style="width: 30%" />
          <col style="width: 60%" />
          <col style="width: 10%" />
          %else:
          <col style="width: 40%" />
          <col style="width: 60%" />
          %end
        </colgroup>
        <thead>
          <tr>
            <th colspan="3">Customs:</th>
          </tr>
        </thead>
        <tbody style="font-size:x-small;">
          %for var in sorted(elt.customs):
          <tr>
            <td>{{var}}</td>
            <td>{{elt.customs[var]}}</td>
            %# ************
            %# Remove the Change button because Shinken does not take care of the external command!
            %# Issue #224
            %# ************
            %if app.can_action() and False:
            <td>
              <button class="{{'disabled' if not app.can_action() else ''}} btn btn-primary btn-sm"
                data-type="action" action="change-variable"
                data-toggle="tooltip" data-placement="bottom" title="Change a custom variable for this {{elt_type}}"
                data-element="{{helper.get_uri_name(elt)}}" data-variable="{{var}}" data-value="{{elt.customs[var]}}"
                >
                <i class="fa fa-gears"></i> Change
              </button>
            </td>
            %end
          </tr>
          %end
        </tbody>
      </table>
    </div>
  </div>
</div>
%end
