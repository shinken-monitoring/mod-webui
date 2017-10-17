var history_offset = 0;

function more_history() {
    disable_refresh();

    if ($(window).data('ajaxready') == false) return;

    $(window).data('ajaxready', false);

    $("#loading-spinner").fadeIn(400);
    var url = '/logs/inner';
    url = url +'?limit=100&offset='+history_offset;
    if ($('#inner_history').data('service') !== undefined) {
        var url = url + '&service=' + $('#inner_history').data('service');
    }
    if ($('#inner_history').data('host') !== undefined) {
        var url = url + '&host=' + $('#inner_history').data('host');
    }
    if ($('#inner_history').data('logclass') !== undefined) {
        var url = url + '&logclass=' + $('#inner_history').data('logclass');
    }
    if ($('#inner_history').data('commandname') !== undefined) {
        var url = url + '&commandname=' + $('#inner_history').data('commandname');
    }

    $.get(url, function(data){
        if (data.indexOf('table') !== -1) {
            $("#inner_history").append(data);
            history_offset+=100;
            $(window).data('ajaxready', true);
        }
        $("#loading-spinner").fadeOut(400);
    });
}

more_history();

$(window).data('ajaxready', true);

$(window).scroll(function() {
    if ($(window).data('ajaxready') == false) return;

    if(($(window).scrollTop() + $(window).height() + 150) > $(document).height()) {
        more_history();
    }
});


