%setdefault('parameter', 'enable_event_handlers')
%setdefault('title', 'Event handlers')
%setdefault('command_enable', 'ENABLE_EVENT_HANDLERS')
%setdefault('command_disable', 'DISABLE_EVENT_HANDLERS')


%enabled = app.datamgr.get_configuration_parameter(parameter)
<tr>
   <td><strong>{{title}} are currently {{'enabled' if enabled else 'disabled'}}:</strong></td>
   <td>
      <div class="form-check" title="{{'Globally disable' if enabled else 'Globally enable'}}">
         <input type="checkbox" class="form-check-input js-external-command" value=""
            id="ck_{{parameter}}" {{'disabled' if not app.can_action() else ''}}
            {{'checked' if enabled else ''}}
            data-command="{{command_disable if enabled else command_enable}}">

         <label class="form-check-label" for="ck_{{parameter}}">
            <em>Click to {{'enable' if not enabled else 'disable'}}</em>
         </label>
      </div>
   </td>
</tr>
