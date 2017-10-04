%if elt.customs:
<div class="tab-pane fade" id="configuration">
  <div class="panel panel-default" style="border-top:none; border-radius:0;">
    <div class="panel-body">
      <table class="table table-condensed table-bordered">
        <colgroup>
          <col style="width: 40%" />
          <col style="width: 60%" />
        </colgroup>
        <thead>
          <tr>
            <th colspan="2">Customs:</th>
          </tr>
        </thead>
        <tbody style="font-size:x-small;">
          %for var in sorted(elt.customs):
          <tr>
            <td>{{var}}</td>
            <td>{{elt.customs[var]}}</td>
          </tr>
          %end
        </tbody>
      </table>
    </div>
  </div>
</div>
%end
