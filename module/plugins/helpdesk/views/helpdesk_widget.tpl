%rebase("widget")

%import json
%import time

%narrow=True

%if not tickets:
   <center>
      <h3>No helpdesk records (tickets) found.</h3>
      <p>Your request did not return any results.</p>
   </center>
%else:
   %include("_helpdesk")
%end
