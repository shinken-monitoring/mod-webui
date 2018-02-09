%import time
%import re
%import ast
%import json
%from shinken.misc.perfdata import PerfDatas
%now = int(time.time())
%helper = app.helper

{{!helper.print_aggregation_tree(helper.get_host_service_aggregation_tree(cpe, app), helper.get_html_id(cpe), show_output=True)}}

<!-- OUTPUT -->

<!---

-->
