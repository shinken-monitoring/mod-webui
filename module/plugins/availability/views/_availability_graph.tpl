%setdefault('debug', False)
%setdefault('crit_level', 95.0)
%setdefault('warn_level', 99.0)

%interval = log['last_check_timestamp'] - log['first_check_timestamp']
%t_0=int(log['daily_0'])
%t_1=int(log['daily_1'])
%t_2=int(log['daily_2'])
%t_3=int(log['daily_3'])
%t_4 = interval - t_0 - t_1 - t_2 - t_3

%p_0=round(100.0 * t_0 / (interval-t_4), 2) if t_4 != interval else 0
%p_1=round(100.0 * t_1 / (interval-t_4), 2) if t_4 != interval else 0
%p_2=round(100.0 * t_2 / (interval-t_4), 2) if t_4 != interval else 0
%p_3=round(100.0 * t_3 / (interval-t_4), 2) if t_4 != interval else 0
%p_4=round(100.0 * t_4 / (interval), 2) if t_4 != interval else 0

%# UP and OK states
%elt_available = t_0
%pct_elt_available = round(100.0 * t_0 / (interval-t_4), 2) if t_4 != interval else 0
%# DOWN / UNREACHABLE and WARNING / CRITICAL states
%elt_not_available = t_1 + t_2
%pct_elt_not_available = round(100.0 * (t_1 + t_2) / (interval-t_4), 2) if t_4 != interval else 0
%# UNKNOWN
%elt_unknown = t_3 + t_4
%pct_elt_unknown = round(100.0 * (t_3 + t_4) / (interval-t_4), 2) if t_4 != interval else 0

%elt_type = elt.__class__.my_type
<div id="{{title.replace(" ", "_")}}" class="col-sm-4">
   <div
      id="gauge_{{title.replace(' ', '_')}}"
      class="availability-gauge"
      data-duration={{elt_not_available}}
      data-title="{{title}}"
      data-value="{{pct_elt_available}}"
      data-crit="{{crit_level}}"
      data-warn="{{warn_level}}">
   </div>
   <div class="availability-legend text-center" style="margin-top: -25px;"><small><em>
      <span></span>
   </em></small></div>
   %if debug:
   <div class="debug"><small><em>
      <span></span>
   </em></small></div>
   %end
</div>

<script>
   %if elt_available == 0:
      $('#{{title.replace(" ", "_")}} > div.availability-gauge').attr('title', "{{ elt_type }} has never been available during this period (accuracy {{p_4}}%)")
      $('#{{title.replace(" ", "_")}} > div.availability-legend span').html('Never available');
   %elif elt_not_available == 0:
      $('#{{title.replace(" ", "_")}} > div.availability-gauge').attr('title', "{{ elt_type }} has been available during during this period (accuracy {{p_4}}%)")
      $('#{{title.replace(" ", "_")}} > div.availability-legend span').html('Always available');
   %else:
      $('#{{title.replace(" ", "_")}} > div.availability-gauge').attr('title', "{{ elt_type }} has been unavailable during " + moment.duration({{ elt_not_available }}, "seconds").humanize() + " (accuracy {{p_4}}%)");
      $('#{{title.replace(" ", "_")}} > div.availability-legend span').html('Available ' + moment.duration({{ elt_available }}, "seconds").humanize() + ' ({{pct_elt_available}} %)');
   %end
   $('#{{title.replace(" ", "_")}} > div.debug span').html('{{"interval: %s s, t_0:%s s, t_1:%s s, t_2:%s s, t_3:%s s, t_4:%s s" % (interval, t_0, t_1, t_2, t_3, t_4)}}');
/*
   if ($elem.data('duration') == 0) {
   } else {
      var available = moment.duration($elem.data('duration'), "seconds").humanize();
      var unavailable = moment.duration($elem.data('duration'), "seconds").humanize();
      $elem.attr('title', "{{ elt_type }} has been unavailable during " + moment.duration($elem.data('duration'), "seconds").humanize() + " (accuracy {{p_4}}%)");
   }
*/
</script>
