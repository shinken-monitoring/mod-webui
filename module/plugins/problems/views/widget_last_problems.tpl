
%helper = app.helper

%rebase("widget")

%if not pbs:
   <span>No problems!</span>
%else:
   <table class="table table-condensed" style="margin:0;">
      <tbody style="border: none;">
      %for pb in pbs:
         <tr>
            <td align=center>
               {{!helper.get_fa_icon_state(pb)}}
            </td>

            <td>
               <small>{{!helper.get_link(pb)}}</small>
            </td>

            <td class="hidden-sm hidden-xs hidden-md">
               <small>{{!helper.get_business_impact_text(pb.business_impact)}}</small>
            </td>

            <!--
            <td class="hidden-sm hidden-xs hidden-md font-{{pb.state.lower()}}" align="center">
               <small>{{ pb.state }}</small>
            </td>
            -->
         </tr>
      %end
      </tbody>
   </table>
%end
