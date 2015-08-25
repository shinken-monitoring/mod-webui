
%helper = app.helper

%rebase("widget")

%if not impacts:
   <span>No impacts!</span>
%else:
   <table class="table table-condensed">
      <tbody>
      %for imp_id in impacts:
      %impact = impacts[imp_id]
         <tr>
            <td class="align-center">
               {{! helper.get_fa_icon_state(obj=impact)}}
            </td>
        
            <td >
               <small>{{!helper.get_link(impact)}}</small>
            </td>
        
            <td class="hidden-sm hidden-xs hidden-md">
               <small>{{!helper.get_business_impact_text(impact.business_impact)}}</small>
            </td>
        
            <!--
            <td class="hidden-sm hidden-xs hidden-md font-{{impact.state.lower()}}" align="center">
               <small>{{impact.state}}</small>
            </td>
            -->
         </tr>
      %end
      </tbody>
   </table>
%end

