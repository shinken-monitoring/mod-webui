var eltdetail_logs=false;

// Add a comment
$('body').on("click", '[action="add-comment"]', function () {
    var elt = $(this).data('element');
    if (eltdetail_logs) console.debug("Add a comment for: ", elt);
    display_modal("/forms/comment/add/"+elt);
});

// Delete a comment
$('body').on("click", '[action="delete-comment"]', function () {
    var elt = $(this).data('element');
    var comment = $(this).data('comment');
    if (eltdetail_logs) console.debug("Delete comment '"+comment+"' for: ", elt);
    display_modal("/forms/comment/delete/"+elt+"?comment="+comment);
});

// Delete all comments
$('body').on("click", '[action="delete-comments"]', function () {
    var elt = $(this).data('element');
    if (eltdetail_logs) console.debug("Delete all comments for: ", elt);
    display_modal("/forms/comment/delete_all/"+elt);
});

// Schedule a downtime ...
$('body').on("click", '[action="schedule-downtime"]', function () {
    var elt = $(this).data('element');
    if (eltdetail_logs) console.debug("Schedule a downtime for: ", elt);
    display_modal("/forms/downtime/add/"+elt);
});

// Delete a downtime
$('body').on("click", '[action="delete-downtime"]', function () {
    var elt = $(this).data('element');
    var downtime = $(this).data('downtime');
    if (eltdetail_logs) console.debug("Delete downtime '"+downtime+"' for: ", elt);
    display_modal("/forms/downtime/delete/"+elt+"?downtime="+downtime);
});

// Delete all downtimes
$('body').on("click", '[action="delete-all-downtimes"]', function () {
    var elt = $(this).data('element');
    if (eltdetail_logs) console.debug("Delete all downtimes for: ", elt);
    display_modal("/forms/downtime/delete_all/"+elt);
});

// Add an acknowledge
$('body').on("click", '[action="add-acknowledge"]', function () {
    var elt = $(this).data('element');
    if (eltdetail_logs) console.debug("Button - add an acknowledge for: ", elt);
    display_modal("/forms/acknowledge/add/"+elt);
});

// Delete an acknowledge
$('body').on("click", '[action="remove-acknowledge"]', function () {
    var elt = $(this).data('element');
    if (eltdetail_logs) console.debug("Delete an acknowledge for: ", elt);
    display_modal("/forms/acknowledge/remove/"+elt);
});

// Recheck
$('body').on("click", '[action="recheck"]', function () {
    var elt = $(this).data('element');
    if (eltdetail_logs) console.debug("Recheck for: ", elt);
    recheck_now(elt);
});

// Check result
$('body').on("click", '[action="check-result"]', function () {
    var elt = $(this).data('element');
    if (eltdetail_logs) console.debug("Submit a check result for: ", elt);
    display_modal("/forms/submit_check/"+elt);
});

// Event handler
$('body').on("click", '[action="event-handler"]', function () {
    var elt = $(this).data('element');
    if (eltdetail_logs) console.debug("Try to fix: ", elt);
    try_to_fix(elt);
});

// Create a ticket ...
$('body').on("click", '[action="create-ticket"]', function () {
    var elt = $(this).data('element');
    if (eltdetail_logs) console.debug("Create a ticket for: ", elt);
    display_modal("/helpdesk/ticket/add/"+elt);
});

// Create a ticket follow-up...
$('body').on("click", '[action="create-ticket-followup"]', function () {
    var elt = $(this).data('element');
    var ticket = $(this).data('ticket');
    var status = $(this).data('status');
    if (eltdetail_logs) console.debug("Create a ticket follow-up for: ", elt, 'ticket #', ticket);
    display_modal("/helpdesk/ticket_followup/add/"+elt+'?ticket='+ticket+'&status='+status);
});
