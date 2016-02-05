%import json
%import time

%narrow=False

%if not tickets:
   <center>
      <h3>No helpdesk records (tickets) found.</h3>
      <p>If you installed the <strong>glpi-helpdesk</strong> Shinken module, your request did not return any results.</p>
      <p>If the <strong>glpi-helpdesk</strong> Shinken module is not installed, you should install it to get helpdesk data from Glpi database.</p>
   </center>
%else:
   %include("_helpdesk")
%end
