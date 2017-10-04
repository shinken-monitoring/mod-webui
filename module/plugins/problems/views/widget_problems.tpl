<!-- Problems table -->
%import time
%setdefault('commands', True)

%helper = app.helper

%rebase("widget")

%if not pbs:
   <span>No problems!</span>
%else:
  %include('_problems_table.tpl')
%end
