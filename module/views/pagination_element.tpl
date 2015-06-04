%setdefault('div_class', "")
%setdefault('div_style', "margin-top:0; margin-bottom:0;")

%if navi is not None:
   %from urllib import urlencode

   <ul class="pagination {{div_class}}" style={{div_style}}"">
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
               <li class=""><a href='/{{page}}?{{query_string}}' >{{name}}</a></li>
            %end
         %end
   </ul>
%end
