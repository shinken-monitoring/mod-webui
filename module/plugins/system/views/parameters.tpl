%rebase("layout", breadcrumb=[ ['System parameters', '/system-parameters'] ], title='System parameters')

<div class="panel panel-default">
%if not configs:
<center>
  <h3>No system information is available.</h3>
</center>
%else:
%for config in configs:
<table class="table table-condensed" style="table-layout: fixed; word-wrap: break-word;">
  <colgroup>
    <col style="width: 30%" />
    <col style="width: 70%" />
  </colgroup>
  %if config.get('instance_name', None):
  <thead>
    <tr>
       <th colspan="2">Scheduler {{config.get('instance_name')}}</th>
    </tr>
  </thead>
  %end
  <tbody style="font-size:small;">
    %for key in sorted(config.keys()):
    %if key in ['id', 'uuid', 'instance_id', 'instance_name']:
    %continue
    %end
    %value=config[key]
    <tr>
      <td>{{key}}</td>
      <td>
        %if isinstance(value, bool):
        {{! app.helper.get_on_off(value)}}
        %else:
        {{value}}
        %end
      </td>
    </tr>
    %end
  </tbody>
</table>
%end
%end
</div>
