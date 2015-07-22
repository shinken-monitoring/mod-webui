%import json

%username = 'anonymous'
%if user is not None:
%if hasattr(user, 'alias') and user.alias != 'none':
%	username = user.alias
%else:
%	username = user.get_name()
%end
%end

%rebase("layout", css=['user/css/user.css'], breadcrumb=[ ['System parameters', '/system-parameters'] ], title='System parameters')

<div class="row">
   <div class="col-sm-12">
      <div class="panel panel-default">
         <div class="panel-heading">
            <h2 class="panel-title">Parameters</h2>
         </div>
         <div class="panel-body">
            <table class="table table-condensed col-sm-12" style="table-layout: fixed; word-wrap: break-word;">
               <colgroup>
                  <col style="width: 30%" />
                  <col style="width: 70%" />
               </colgroup>
               <tbody style="font-size:x-small;">
               %for config in configs:
                  %for key, value in vars(config).iteritems():
                  <tr>
                     <td>{{key}}</td>
                     <td>{{value}}</td>
                  </tr>
                  %end
               %end
               </tbody>
            </table>
         </div>
      </div>
   </div>
</div>
%end
