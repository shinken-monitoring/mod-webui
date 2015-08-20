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

%crit_level = elt.customs.get('_SLA_CRIT', 95.0)
%warn_level = elt.customs.get('_SLA_WARN', 99.0)

<div class="availability-gage col-md-4" title="Down {{t_1}} seconds" data-duration={{t_1}} id="{{title.replace(" ", "_")}}" data-title="{{title}}" data-value="{{100-p_1}}" data-crit="{{crit_level}}" data-warn="{{warn_level}}"></div>

<script>
  var $elem = $('#{{title.replace(" ", "_")}}')
  if ($elem.data('duration') == 0) {
    $elem.attr('title', "{{ elt.__class__.my_type }} has been UP all the time (accuracy {{100-p_4}}%)")
  } else {
    $elem.attr('title', "{{ elt.__class__.my_type }} has been down during " + eval('moment.duration(' + $elem.data('duration') + ', "seconds").humanize();') + " (accuracy {{100-p_4}}%)");
  }
</script>
