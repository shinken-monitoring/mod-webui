<table class="table table-condensed" style="table-layout:fixed; width:100%;">
  <tbody>
    %for pb in pbs:
    <tr>
    %if isinstance(pb, unicode):
      <td width="110px">
      {{pb}}
      </td>
    %else:
      <td width="130px" title="{{pb.get_name()}} - {{pb.state}}<br> Since {{helper.print_date(pb.last_state_change, format="%d %b %Y %H:%M:%S")}}<br> Last check {{helper.print_duration(pb.last_chk)}}<br> Next check {{helper.print_duration(pb.next_chk)}}"
        class="font-{{pb.state.lower()}} text-center">
        <div style="display: table-cell; vertical-align: middle; padding-right: 10px;">
          {{!helper.get_fa_icon_state(pb, use_title=False)}}
        </div>
        <div style="display: table-cell; vertical-align: middle;">
          <small>
            <strong>{{ pb.state }}</strong><br>
            %if pb.state_type == 'HARD':
            {{!helper.print_duration(pb.last_state_change, just_duration=True, x_elts=2)}}
            %else:
            soft {{pb.attempt}}/{{pb.max_check_attempts}}
            <!--soft state-->
            %end
          </small>
        </div>
      </td>
      <td class="text-muted" width="20px">
        %if pb.problem_has_been_acknowledged:
        <i class="fas fa-check" title="Acknowledged"></i><br>
        %end
        %if pb.in_scheduled_downtime:
        <i class="far fa-clock" title="In scheduled downtime"></i><br>
        %end
      </td>
      <td width="100%">
        <div class="ellipsis output">
          <div>
            <a href="/host/{{pb.host_name}}">
              %if pb.__class__.my_type == 'service':
              %if pb.host:
              {{pb.host.get_name() if pb.host.display_name == '' else pb.host.display_name}}
              %else:
              {{pb.host_name}}
              %end
              %else:
              {{pb.get_name() if pb.display_name == '' else pb.display_name}}
              %end
            </a>
            %if pb.__class__.my_type == 'service':
            / {{!helper.get_link(pb, short=True)}}
            %end
            <small>{{!helper.get_business_impact_text(pb.business_impact)}}</small>
          </div>

          <!--<br>-->

          <small><samp class="text-muted">{{! pb.output}}</samp></small>
        </div>
      </td>
    </tr>
    %end
    %end
  </tbody>
</table>
