%setdefault('id', 'c')
%setdefault('title', 'Title')
%setdefault('dump_dict', None)
%setdefault('icon', 'cog')

<div class="panel-group" style="margin: 10x">
   <div class="panel panel-default">
      <div class="panel-heading">
         <h4 class="panel-title">
            <a data-toggle="collapse" href="#collapse_{{id}}"><i class="fa fa-{{icon}}"></i> {{title}}</a>
         </h4>
      </div>
      <div id="collapse_{{id}}" class="panel-collapse collapse">
         <dl class="dl-horizontal" >
            %for k in sorted(dump_dict.keys()):
               %if k in ['id', 'uuid', 'instance_id', 'instance_name'] or isinstance(dump_dict[k], dict):
               %continue
               %end
               %v = dump_dict.get(k, 'XxX')
               <dt>{{k}}</dt>
               %if isinstance(v, bool):
                  <dd>{{! app.helper.get_on_off(v)}}</dd>
               %elif isinstance(v, list):
                  <dd>
                  <ul>
                  %for item in v:
                     <li>{{item}}</li>
                  %end
                  </ul>
                  </dd>
               %else:
                  <dd>{{v}}</dd>
               %end
            %end
         </dl>
         <dl class="dl-horizontal" >
            %# All dictionary values
            %for k in sorted(dump_dict.keys()):
               %if not isinstance(dump_dict[k], dict):
               %continue
               %end
               %v = dump_dict.get(k)
               <dt>{{k}}</dt>
               <dd>
               %for item_k in sorted(v.keys()):
                  %item_v = v[item_k]
                  %if isinstance(item_v, bool):
                     {{item_k}} = {{! app.helper.get_on_off(item_v)}}<br>
                  %elif isinstance(item_v, list):
                  {{item_k}} =
                     <ul>
                     %for item in item_v:
                        <li>{{item}}</li>
                     %end
                     </ul>
                  %elif isinstance(item_v, dict):
                  {{item_k}} =
                     <ul>
                     %for item, value in item_v.items():
                        <li>{{item}} = {{value}}</li>
                     %end
                     </ul>
                  %else:
                  {{item_k}} = {{item_v}}<br>
                  %end
               %end
               </dd>
            %end
         </dl>
      </div>
   </div>
</div>
