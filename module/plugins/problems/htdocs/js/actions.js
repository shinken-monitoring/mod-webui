/* We keep an array of all selected elements */
var selected_elements = [];
var eltdetail_logs=false;

// Schedule a downtime ...
$('body').on("click", '.js-schedule-downtime-elts', function () {
    if (selected_elements.length == 1) {
        var elt = selected_elements[0];
        if (eltdetail_logs) console.debug("Schedule a downtime for: ", elt);
        display_modal("/forms/downtime/add/"+elt);
    } else {
        // Default downtime scheduling...
        // Initial start/stop for downtime, do not consider seconds ...
        var downtime_start = moment().seconds(0);
        var downtime_stop = moment().seconds(0).add('day', 1);

        $.each(selected_elements, function(idx, name){
            if (eltdetail_logs) console.debug("Schedule a downtime for: ", name);
            do_schedule_downtime(name, downtime_start.format('X'), downtime_stop.format('X'), user, 'One day downtime scheduled by '+user, shinken_downtime_fixed, shinken_downtime_trigger, shinken_downtime_duration);
        });
    }
    flush_selected_elements();
});

// Delete all downtimes
$('body').on("click", '.js-delete-all-downtimes-elts', function () {
    $.each(selected_elements, function(idx, name){
        if (eltdetail_logs) console.debug("Delete all downtimes for: ", name);
        delete_all_downtimes(name);
    });
    flush_selected_elements();
});

// Add an acknowledge
$('body').on("click", '.js-add-acknowledge-elts', function () {
    $.each(selected_elements, function(idx, name){
        if (eltdetail_logs) console.debug("Add acknowledge for: ", name);
        do_acknowledge(name, 'Acknowledged by '+user, user, default_ack_sticky, default_ack_notify, default_ack_persistent);
    });
    flush_selected_elements();
});

// Delete an acknowledge
$('body').on("click", '.js-remove-acknowledge-elts', function () {
    $.each(selected_elements, function(idx, name){
        if (eltdetail_logs) console.debug("Delete acknowledge for: ", name);
        delete_acknowledge(name);
    });
    flush_selected_elements();
});

// Recheck
$('body').on("click", '.js-recheck-elts', function () {
    $.each(selected_elements, function(idx, name){
        if (eltdetail_logs) console.debug("Recheck for: ", name);
        recheck_now(name);
    });
    flush_selected_elements();
});

// Check result
$('body').on("click", '.js-submit-ok-elts', function () {
    $.each(selected_elements, function(idx, name){
        if (eltdetail_logs) console.debug("Submit check for: ", name);
        submit_check(name, '0', 'Forced OK/UP by '+user);
    });
    flush_selected_elements();
});

// Event handler
$('body').on("click", '.js-try-to-fix-elts', function () {
    $.each(selected_elements, function(idx, name){
        if (eltdetail_logs) console.debug("Try to fix for: ", name);
        try_to_fix(name);
    });
    flush_selected_elements();
});
