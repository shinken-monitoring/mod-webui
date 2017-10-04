%user = app.get_user()
%rebase("widget")

%js=['eltdetail/js/bootstrap-switch.min.js', 'notifications/js/notifications.js']
%css=['eltdetail/css/bootstrap-switch.min.css']

<table class="table">
    <colgroup>
        <col style="width: 70%" />
        <col style="width: 30%" />
    </colgroup>
    <tr>
        <td class="text-left">
            Toggle Notifications:
        </td>
        <td class="text-right">
            <input type="checkbox" {{'checked' if is_enabled else ''}} {{'' if user.is_admin else 'disabled'}}
            class="js-toggle-all-notifications">
        </td>
    </tr>
</table>

<div class="alert alert-{{'success' if is_enabled else 'danger'}} text-center" role="alert">
    <span class="glyphicon glyphicon-{{'ok' if is_enabled else 'remove'}}" aria-hidden="true"></span>
    Notifications are currently: <strong>{{'ENABLED' if is_enabled else 'DISABLED'}}</strong>
</div>
