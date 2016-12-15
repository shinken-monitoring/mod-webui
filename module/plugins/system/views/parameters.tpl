%rebase("layout", breadcrumb=[ ['System parameters', '/system-parameters'] ], title='System parameters')

<div class="row">
   <div class="col-sm-12">
      <div class="panel panel-default">
         <div class="panel-heading">
            <h2 class="panel-title">Parameters:</h2>
         </div>
         <div class="panel-body">
            %if not configs:
            <center>
              <h3>No system information is available.</h3>
            </center>
            %else:
            <table class="table table-condensed col-sm-12" style="table-layout: fixed; word-wrap: break-word;">
               <colgroup>
                  <col style="width: 30%" />
                  <col style="width: 70%" />
               </colgroup>
               <tbody style="font-size:x-small;">
                  %for key, value in configs:
                  <tr>
                     <td>{{key}}</td>
                     <td>{{value}}</td>
                  </tr>
                  %end
               </tbody>
            </table>
            %end
         </div>
      </div>
   </div>
</div>
%end
