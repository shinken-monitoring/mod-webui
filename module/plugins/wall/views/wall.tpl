%rebase("layout", css=['wall/css/jquery.bxslider.css'], js=['wall/js/jquery.bxslider.min.js', 'wall/js/wall.js'], title='Wall view')
%# Use bxslider : http://bxslider.com/

<div id="wall">
   %if impacts:
   <h3>{{len(impacts)}} impacts:</h3>
   <ul id="wall-impacts" class="bxslider" style="position: relative;">
      %ind = -1
      %for imp in impacts:
      %ind += 1
      %x,y = divmod(ind, 20)
      %if y==0:
      <li>
      %end
      <center class="col-sm-3 pull-left">
         <div style="margin: 5px;">
            <a href="{{app.helper.get_link_dest(imp)}}" class='btn' title="Details">
               <div class="font-{{imp.state.lower()}}">{{imp.get_full_name()}}</div>
               <div>{{! app.helper.get_fa_icon_state(imp, label='title')}}</div>
            </a>
         </div>
      </center>
      %if y==19:
      </li>
      %end
      %end
   </ul>
   %else:
   <h3>No impacts</h3>
   %end
   
   %if problems:
   <h3>{{len(problems)}} IT problems:</h3>
   <ul id="wall-problems" class="bxslider" style="position: relative;">
      %ind = -1
      %for pb in problems:
      %ind += 1
      %x,y = divmod(ind, 20)
      %if y==0:
      <li>
      %end
      <center class="col-sm-4 pull-left">
         <div style="margin: 5px;">
            <a href="{{app.helper.get_link_dest(pb)}}" class='btn' title="Details">
               <div class="font-{{pb.state.lower()}}">{{pb.get_full_name()}}</div>
               <div class="font-{{pb.state.lower()}}">{{! app.helper.get_fa_icon_state(pb, label='title')}} since {{app.helper.print_duration(pb.last_state_change, just_duration=True, x_elts=2)}}</div>
            </a>
         </div>
      </center>
      %if y==19:
      </li>
      %end
      %end
   </ul>
   %else:
   <h3>No IT problems</h3>
   %end
   
   %if last_problems:
   <h3>{{len(last_problems)}} new IT problems in the last hour:</h3>
   <ul id="wall-last-problems" class="bxslider" style="position: relative;">
      %ind = -1
      %for pb in last_problems:
      %ind += 1
      %x,y = divmod(ind, 20)
      %if y==0:
      <li>
      %end
      <center class="col-sm-4 pull-left">
         <div style="margin: 5px;">
            <a href="{{app.helper.get_link_dest(pb)}}" class='btn' title="Details">
               <div class="font-{{pb.state.lower()}}">{{pb.get_full_name()}}</div>
               <div class="font-{{pb.state.lower()}}">{{! app.helper.get_fa_icon_state(pb, label='title')}} since {{app.helper.print_duration(pb.last_state_change, just_duration=True, x_elts=2)}}</div>
            </a>
         </div>
      </center>
      %if y==19:
      </li>
      %end
      %end
   </ul>
   %else:
   <h3>No new IT problems in the last hour</h3>
   %end
</div>
