%rebase("layout", css=['logs/css/logs.css'], js=['logs/js/history.js'], title='Alert Statistics on the last 30 days for ' + service)

%total = sum(hosts.values())

<div class="col-lg-4">
  <div class="panel panel-default">
    <div class="panel-heading"><h3 class="panel-title">{{ total }} {{ service }} alerts</h3></div>
    <table class="table table-striped table-condensed">
      %for l in hosts.most_common(15):
      <tr><td>{{ l[1] }} ({{ round((l[1] / float(total)) * 100, 1) }}%)</td><td><a href="/stats/host/{{ l[0] }}">{{ l[0] }}</a></td></tr>
      %end
      %other = sum((h[1] for h in hosts.most_common()[15:]))
      <tr><td>{{ other }} ({{ round((other / float(total)) * 100, 1) }}%)</td><td><strong>Others</strong></td></tr>
    </table>
  </div>
</div>

<div class="col-xs-12">
  <div class="panel panel-default">
    <div class="panel-body">
      <div id="inner_history" data-service='{{ service }}' data-logclass="3" data-commandname="{%22$regex%22:%22notify-service-by-slack%22}">
      </div>

      <div class="text-center" id="loading-spinner">
        <h3><i class="fas fa-spinner fa-spin"></i> Loading history data…</h3>
      </div>
    </div>
  </div>
</div>
