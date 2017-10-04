%rebase("layout", title='All commands (%d commands)' % len(commands))

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
            <td><a name="{{command.command_name}}"></a><strong>{{command.command_name}}</strong></td>
            <td>{{command.command_line}}</td>
            </tr>
            %end
         %end
      </tbody>
   </table>
</div>
