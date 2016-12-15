%#Set this variable to True will display some more information in the page ... useful for debugging ;)
%debug = False
%crit_level = elt.customs.get('_SLA_CRIT', 95.0)
%warn_level = elt.customs.get('_SLA_WARN', 99.0)

%if not records:
   <center>
      <h3>No availability records found.</h3>
      You should install the <strong>mongo-logs</strong> Shinken module to collect hosts and services availability data.
   </center>
%else:
      %for title, log in records.items():
        %if log is not None:
          %include("_availability_graph.tpl", debug=debug, elt=elt, title=title, log=log, crit_level=crit_level, warn_level=warn_level)
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
      var decimals = 0;
      if (value == 100) {
         var decimals = 0;
      } else if (value > 99.95) {
         var decimals = 3;
      } else if (value > 99.9) {
         var decimals = 2;
      } else if (value > 99) {
         var decimals = 1;
      }

      var valueColor = "#DA4F49";
      if (value > {{crit_level}}) {
         var valueColor = "#5BB75B";
      } else if (value > {{warn_level}}) {
         var valueColor = "#FAA732";
      }

      var g = new JustGage({
         id: $(elem).attr('id'),
         value: value,
         min: 0,
         max: 100,
         title: $(elem).data('title'),
         valueFontColor: valueColor,
         symbol: "%",
         //label: "%",
         decimals: decimals,
         customSectors: [{
            color: "#DA4F49",
            lo: 0,
            hi: $(elem).data('crit'),
         },{
            color: "#FAA732",
            lo: $(elem).data('crit'),
            hi: $(elem).data('warn'),
         },{
            color: "#5BB75B",
            lo: $(elem).data('warn'),
            hi: 100,
         }],
         counter: true,
      });
      $(elem).removeClass('availability-gauge').show();
   }
   function justgage_render_all() {
      $('.availability-gauge').each(function() {
         justgage_render(this);
      })
   }
   $(document).ready(function() {
      justgage_render_all();
   });
</script>
