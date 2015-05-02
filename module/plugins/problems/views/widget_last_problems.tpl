
%import time
%now = time.time()
%helper = app.helper
%datamgr = app.datamgr

%rebase widget globals()

%if len(pbs) == 0:
  <span>No IT problems! Congrats.</span>
%else:
  <table class="table table-condensed" style="margin:0;">
    <tbody style="border: none;">
      %for pb in pbs:
      <tr>
        <td>
          <div class='img_status'>
          <span class="medium-pulse aroundpulse pull-left">
            %# " We put a 'pulse' around the elements if it's an important one "
            %if pb.business_impact > 2 and pb.state_id in [1, 2, 3]:
              <span class="medium-pulse pulse"></span>
            %end
            <img class="medium-pulse" src="{{helper.get_icon_state(pb)}}" />
          </span>
          </div>
        </td>
        
        <td style="font-size: x-small; font-weight: normal;">
          {{!helper.get_link(pb)}}
        </td>
        
        <td style="font-size: x-small; font-weight: normal; text-align:center; width: 10%;" class="background-{{pb.state.lower()}}">
          <span class='txt_status'> {{pb.state}}</span>
        </td>
        
        <td style="font-size: x-small; font-weight: normal; width: 15%;">
          %for j in range(0, pb.business_impact-2):
          <img src='/static/images/star.png' alt="star">
          %end
        </td>
      </tr>
      %end
    </tbody>
  </table>
%end
