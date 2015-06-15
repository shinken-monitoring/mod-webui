
%import time
%now = time.time()
%helper = app.helper
%datamgr = app.datamgr

%rebase("widget")

%if len(pbs) == 0:
  <span>No IT problems! Congrats.</span>
%else:
  <table class="table table-condensed" style="margin:0;">
    <tbody style="border: none;">
      %for pb in pbs:
      <tr>
        <td align=center>
          {{!helper.get_fa_icon_state(pb)}}
        </td>
        
        <td style="font-size: x-small; font-weight: normal;">
          {{!helper.get_link(pb)}}
        </td>
        
        <td align="center" class="font-{{pb.state.lower()}}"><strong>
         {{ pb.state }}
        </strong></td>
        
        <td style="font-size: x-small; font-weight: normal; width: 15%;">
          {{!helper.get_business_impact_text(pb.business_impact)}}
        </td>
      </tr>
      %end
    </tbody>
  </table>
%end
