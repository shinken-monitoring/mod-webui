<!-- Problems table -->
%import time
%setdefault('commands', True)

%helper = app.helper

%rebase("widget")

%if not pbs:
   <span>No problems!</span>
%else:
   <table class="table table-condensed" style="table-layout:fixed; width:100%;">
      <tbody>
        %for pb in pbs:
        <tr>
          <td width="120px" title="{{pb.get_name()}} - {{pb.output}} - Since {{helper.print_duration(pb.last_state_change)}} - Last check: {{helper.print_duration(pb.last_chk)}}"
            class="font-{{pb.state.lower()}} text-center">
            <div style="display: table-cell; vertical-align: middle; padding-right: 10px;">
              {{!helper.get_fa_icon_state(pb, useTitle=False)}}
            </div>
            <div style="display: table-cell; vertical-align: middle;">
              <small>
                <strong>{{ pb.state }}</strong><br>
                <span title="Since {{time.strftime("%d %b %Y %H:%M:%S", time.localtime(pb.last_state_change))}}">
                  %if pb.state_type == 'HARD':
                  {{!helper.print_duration(pb.last_state_change, just_duration=True, x_elts=2)}}
                  %else:
                  soft {{pb.attempt}}/{{pb.max_check_attempts}}
                  <!--soft state-->
                  %end
                </span>
              </small>
            </div>
          </td>
          <td width="100%">
            <!--<div class="pull-right">-->
              <!--{{!helper.get_perfdata_pies(pb)}}&nbsp;-->
            <!--</div>-->
            <div class="ellipsis output">
              <div>
                <a href="/host/{{pb.host_name}}" title="{{title}}">
                  %if pb.__class__.my_type == 'service':
                  %if pb.host:
                  {{pb.host.get_name() if pb.host.display_name == '' else pb.host.display_name}}:
                  %else:
                  {{pb.host_name}}:
                  %end
                  %else:
                  {{pb.get_name() if pb.display_name == '' else pb.display_name}}:
                  %end
                </a>
                %if pb.__class__.my_type == 'service':
                {{!helper.get_link(pb, short=True)}}
                %end
               <small>{{!helper.get_business_impact_text(pb.business_impact)}}</small>
              </div>

              <!--<br>-->

              <small><samp class="text-muted">{{! pb.output}}</samp></small>
            </div>
          </td>
        </tr>
        %end
      </tbody>
   </table>
%end
