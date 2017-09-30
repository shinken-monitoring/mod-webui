%rebase("layout", title='All commands (%d commands)' % len(commands))

<div id="commands" class="panel panel-default">

   <table class="table table-condensed table-responsive table-hover">
      <tbody style="font-size:x-small;">
         %for command in commands:
            %if hasattr(command, 'command_line'):
            <tr>
            <td><a name="{{command.command_name}}"></a><strong>{{command.command_name}}</strong></td>
            <td><samp>{{command.command_line}}</samp></td>
            </tr>
            %end
         %end
      </tbody>
   </table>
</div>
