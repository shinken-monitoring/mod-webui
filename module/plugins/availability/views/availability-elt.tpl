%if not records:
  <center>
    <h3>No availability records found.</h3>
    You should install the <strong>mongo-logs</strong> Shinken module to collect hosts availability data.
  </center>
%else:
      %for title, log in records.items():
        %if log is not None:
          %include("_availability_graph.tpl", elt=elt, title=title, log=log)
        %end
      %end
%end

<script type="text/javascript">
  function moment_render_date(elem) {
      $(elem).text(eval('moment.unix("' + $(elem).data('timestamp') + '").' + $(elem).data('format') + ';'));
      $(elem).removeClass('moment-date').show();
  }
  function moment_render_duration(elem) {
      $(elem).attr('title', eval('moment.duration(' + $(elem).data('duration') + ', "seconds").humanize();'));
      $(elem).removeClass('moment-duration').show();
  }
  function moment_render_all() {
    $('.moment-date').each(function() {
      moment_render_date(this);
    })
    $('.moment-duration').each(function() {
      moment_render_duration(this);
    })
  }
  $(document).ready(function() {
    moment_render_all();
  });
</script>

<script type="text/javascript">
    function justgage_render(elem) {
        var value = $(elem).data('value');
        if (value == 100) {
          var decimals = 0;
        } else if (value > 99.95) {
          var decimals = 3;
        } else if (value > 99.9) {
          var decimals = 2;
        } else if (value > 99) {
          var decimals = 1;
        } else if (value > 90) {
          var decimals = 0;
        }
        var g = new JustGage({
          id: $(elem).attr('id'),
          value: value,
          min: 0,
          max: 100,
          title: $(elem).data('title'),
          label: "%",
          decimals: decimals,
          customSectors: [{
            color: "#ff0000",
            lo: 0,
            hi: $(elem).data('crit'),
          },{
            color: "#f9c802",
            lo: $(elem).data('crit'),
            hi: $(elem).data('warn'),
          },{
            color: "#a9d70b",
            lo: $(elem).data('warn'),
            hi: 100,
          }],
          counter: true,
        });
        $(elem).removeClass('availability-gage').show();
    }
    function justgage_render_all() {
      $('.availability-gage').each(function() {
        justgage_render(this);
      })
    }
    $(document).ready(function() {
      justgage_render_all();
    });
</script>
