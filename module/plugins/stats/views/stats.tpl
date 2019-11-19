%rebase("layout", css=['logs/css/logs.css'], js=['logs/js/history.js', 'js/Chart.min.js'], title='Alert Statistics on the last %s days' % days)

%total = sum(hosts.values())

<div class="col-lg-4">
  <div class="panel panel-default">
    %total = sum(hosts.values())
    <div class="panel-heading"><h3 class="panel-title">{{ total }} host alerts</h3></div>
    %if total:
    <table class="table table-striped table-condensed">
      %for l in hosts.most_common(15):
      <tr><td width="160px">{{ l[1] }} ({{ round((l[1] / float(total)) * 100, 1) }}%)</td><td><a href="/stats/host/{{ l[0] }}?days={{ days }}">{{ l[0] }}</a></td></tr>
      %end
      %other = sum((h[1] for h in hosts.most_common()[15:]))
      <tr><td>{{ other }} ({{ round((other / float(total)) * 100, 1) }}%)</td><td><strong>Others</strong></td></tr>
    </table>
    %end
  </div>
</div>

<div class="col-lg-4">
  <div class="panel panel-default">
    %total = sum(services.values())
    <div class="panel-heading"><h3 class="panel-title">{{ total }} services alerts</h3></div>
    %if total:
    <table class="table table-striped table-condensed">
      %for l in services.most_common(15):
      <tr><td width="160px">{{ l[1] }} ({{ round((l[1] / float(total)) * 100, 1) }}%)</td><td><a href="/stats/service/{{ l[0] }}?days={{ days }}">{{ l[0] }}</a></td></tr>
      %end
      %other = sum((s[1] for s in services.most_common()[15:]))
      <tr><td>{{ other }} ({{ round((other / float(total)) * 100, 1) }}%)</td><td><strong>Others</strong></td></tr>
    </table>
    %end
  </div>
</div>

<div class="col-lg-4">
  <div class="panel panel-default">
    %total = sum(hostsservices.values())
    <div class="panel-heading"><h3 class="panel-title">{{ total }} hosts/services alerts</h3></div>
    %if total:
    <table class="table table-striped table-condensed">
      %for l in hostsservices.most_common(15):
      <tr><td width="160px">{{ l[1] }} ({{ round((l[1] / float(total)) * 100, 1) }}%)</td><td>{{ l[0] }}</td></tr>
      %end
      %other = sum((h[1] for h in hostsservices.most_common()[15:]))
      <tr><td>{{ other }} ({{ round((other / float(total)) * 100, 1) }}%)</td><td><strong>Others</strong></td></tr>
    </table>
    %end
  </div>
</div>

<div class="col-lg-12">
  <div class="panel panel-default">
    <div class="panel-body">
      <canvas id="timeseries" height=40px></canvas>
      <script>
        $(document).ready(function() {
          var ctx = document.getElementById('timeseries').getContext('2d');
          var myChart = new Chart(ctx, {
            type: 'line',
            data: {
              datasets : [{
                label: "# of alerts",
                data: {{! graph }},
              }]
            },
            options: {
              scales: {
                xAxes: [{
                  //gridLines: {
                  //  offsetGridLines: true
                  //},
                  type: 'time',
                  distribution: 'linear',
                  time: {
                    minUnit: 'day',
                    tooltipFormat: 'll HH'
                  }
                }],
              }
            }
          });
        });
      </script>
    </div>
  </div>
</div>

<div class="col-xs-12">
  <div class="panel panel-default">
    <div class="panel-body">
      <div id="inner_history" data-logclass="3" data-commandname="{%22$regex%22:%22notify-service-by-slack%22}">
      </div>

      <div class="text-center" id="loading-spinner">
        <h3><i class="fas fa-spinner fa-spin"></i> Loading history data…</h3>
      </div>
    </div>
  </div>
</div>
