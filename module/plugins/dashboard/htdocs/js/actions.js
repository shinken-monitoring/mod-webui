// Add a widget
$('body').on("click", '[action="add-widget"]', function () {
    AddNewWidget($(this).data('wuri'), null, 'widget-place-1');
});

$('body').on("click", '.dashboard-widget', function () {
    // Display modal dialog box
    $('#modal .modal-title').html($(this).data('widget-title'));
    $('#modal .modal-body').html($(this).data('widget-description'));
    $('#modal').modal({
        keyboard: true,
        show: true,
        backdrop: 'static'
    });
});
