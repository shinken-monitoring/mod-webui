%title='All commands (%d commands)' % len(commands)
%rebase("layout", title=title, refresh=True)

<div id="commands">

   <table class="table table-condensed">
      <colgroup>
         <col style="width: 20%;" />
         <col style="width: 60%" />
      </colgroup>
      <thead>
         <tr>
         <th colspan="2"></td>
         </tr>
      </thead>
      <tbody style="font-size:x-small;">
         %for command in commands:
            %if hasattr(command, 'command_line'):
            <tr>
            <td><strong>{{command.command_name}}</strong></td>
            <td>{{command.command_line}}</td>
            </tr>
            %else:
            <tr>
            <td colspan="2"><strong>No command line defined!</strong></td>
            </tr>
            %end
         %end
      </tbody>
   </table>
</div>
