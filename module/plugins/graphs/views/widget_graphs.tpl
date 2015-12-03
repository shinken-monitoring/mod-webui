%import time
%now = time.time()

%rebase("widget", css=['graphs/css/widget_graphs.css'])

%if not elt and not url:
    <span>No URL nor element selected!</span>
%else:

%if not url:
    <!-- Reduce the time range of the dashboard graph to last hour
    and specify the source as dashboard !
    -->
    %uris = app.graphs_module.get_graph_uris(elt, duration=duration, source='dashboard')
%else:
    %uris=[{'img_src': url, 'link': url}]
%end
    %if len(uris) == 0:
        <span>No graphs for this element.</span>
    %else:
        <div id='{{graphsId}}'>
        </div>
        <script>
        %for g in uris:
            %#(img_src, link) = app.get_graph_img_src(g['img_src'], g['link'])

            var img_width = $('#{{graphsId}}').width();
            var img_src = "{{g['img_src']}}".replace("'","\'")

            $('#{{graphsId}}').append('<p class="widget-graph"><a href="{{g['link']}}" target="_blank"><img width="'+img_width+'" src="'+img_src+'"></a></p>');
        %end

            // On window resize ... resizes graphs.
            $(window).bind('resize', function () {
                var img_width = $('#{{graphsId}}').width();

                $.each($('#{{graphsId}} img'), function (index, value) {
                    $(this).css("width", img_width);
                });
            });
        </script>
    %end
%end
