/* We keep an array of all selected elements */
var selected_elements = [];
var eltdetail_logs=false;

// Schedule a downtime ...
$('body').on("click", '.js-schedule-downtime-elts', function () {
    var duration = $(this).data('duration');
    if (duration) {
        var downtime_start = moment().seconds(0).format('X');
        var downtime_stop = moment().seconds(0).add('minutes', duration).format('X');
        var comment = $(this).text() + " downtime scheduled from WebUI by " + user;
        if (selected_elements.length == 1) {
            var elt = selected_elements[0];
            do_schedule_downtime(elt, downtime_start, downtime_stop, user, comment, shinken_downtime_fixed, shinken_downtime_trigger, shinken_downtime_duration);
        } else {
            $.each(selected_elements, function(idx, name){
                do_schedule_downtime(name, downtime_start, downtime_stop, user, comment, shinken_downtime_fixed, shinken_downtime_trigger, shinken_downtime_duration);
            });
        }
    } else {
        if (selected_elements.length == 1) {
            var elt = selected_elements[0];
            display_modal("/forms/downtime/add/"+elt);
        } else {
            // :TODO:maethor:171008: 
            alert("Sadly, you cannot define a custom timeperiod on multiple elements at once. This is not implemented yet.");
        }
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
