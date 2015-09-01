%import time
%now = time.time()

%rebase("widget", css=['graphs/css/widget_graphs.css'])

%if not elt:
   <span>No element selected!</span>
%else:

   <!-- Reduce the time range of the dashboard graph to last hour
   and specify the source as dashboard !
   -->
   %uris = app.graphs_module.get_graph_uris(elt, duration=duration, source='dashboard')
   %if len(uris) == 0:
      <span>No graph for this element.</span>
   %else:
      <div id='{{graphsId}}'>
      </div>
      <script>
         %for g in uris:
            %#(img_src, link) = app.get_graph_img_src(g['img_src'], g['link'])
            
           // Adjust image width / height parameter ... width is sized to container, and height is 1/3
            var img_width = $('.widget-content').width() - 5
            var img_src = "{{g['img_src']}}".replace("'","\'")
            img_src = img_src.replace(/(width=).*?(&)/,'$1' + img_width + '$2');
            img_src = img_src.replace(/(height=).*?(&)/,'$1' + (img_width / 3) + '$2');
            
            $('#{{graphsId}}').append('<p class="widget-graph"><a href="{{g['link']}}" target="_blank"><img width="'+img_width+'" src="'+img_src+'"></a></p>');
         %end
      </script>
   %end
%end
