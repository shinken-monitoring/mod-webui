%setdefault('div_class', "")
%setdefault('div_style', "margin-top:5; margin-bottom:5;")

<div class="row">
   <div class="center-block" style="{{div_style}}">
      %if navi is not None:
         <ul class="pull-left pagination pagination-sm" style="margin-top:0; margin-bottom: 0;" >
            %from urllib import urlencode

            %for name, start, end, is_current in navi:
               %if is_current:
                  <li class="active"><a href="#">{{name}}</a></li>
               %elif start == None or end == None:
                  <li class="disabled"> <a href="#">...</a> </li>
               %else:
                  %# Include other query parameters like search and global_search
                  %query = app.request.query
                  %query['start'] = start
                  %query['end'] = end
                  %query_string = urlencode(query)
                  <li><a href="{{page}}?{{query_string}}">{{name}}</a></li>
               %end
            %end
         </ul>
      %end
   </div>
</div>
