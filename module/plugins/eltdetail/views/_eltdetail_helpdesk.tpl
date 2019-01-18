%if app.helpdesk_module.is_available():
<div class="tab-pane fade" id="helpdesk">
  <div class="panel panel-default" style="border-top:none; border-radius:0;">
    <div class="panel-body">
      <div id="inner_helpdesk" data-element='{{elt.get_full_name()}}'>
      </div>

      <button class="{{'disabled' if not app.can_action() else ''}} btn btn-primary btn-sm js-create-ticket"
        title="Create a ticket for this {{elt_type}}"
        data-element="{{helper.get_uri_name(elt)}}"
        >
        <i class="fas fa-medkit"></i> Create a ticket
      </button>
    </div>
  </div>
</div>
%end
