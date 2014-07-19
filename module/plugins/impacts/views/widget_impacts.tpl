%helper = app.helper
%datamgr = app.datamgr

%rebase widget globals()

%impacts = impacts.values()
%in_pb = [i for i in impacts if i.state_id in [1, 2, 3]]

%if len(impacts) == 0:
<span> You don't have any business apps. Maybe you should define some?</span>
%end

%if len(impacts) !=0 and len(in_pb) == 0:
<span>No business impacts! Congrats.</span>
%else:
  <table class="table table-condensed" style="margin:0;">
    <tbody style="border: none;">
      %for impact in impacts:
      <tr>
        <th style="width: 2%;">
          <div class='img_status'>
          <span class="medium-pulse aroundpulse pull-left">
            %# " We put a 'pulse' around the elements if it's an important one "
            %if impact.business_impact > 2 and impact.state_id in [1, 2, 3]:
              <span class="medium-pulse pulse"></span>
            %end
            <img src="{{helper.get_icon_state(impact)}}" />
          </span>
          </div>
        </th>
        
        <th style="font-size: small; font-weight: normal;">
          {{!helper.get_link(impact)}}
        </th>
        
        <th style="font-size: small; font-weight: normal; width: 10%;" class="background-{{impact.state.lower()}}">
          <span class='txt_status'> {{impact.state}}</span>
        </th>
        
        <th style="font-size: small; font-weight: normal; width: 15%;">
          %for j in range(0, impact.business_impact-2):
          <img src='/static/images/star.png' alt="star">
          %end
        </th>
      </tr>
      %end
    </tbody>
  </table>
%end
