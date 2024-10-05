$("body").on("click", ".js-set-user-show-deprecated-views", function () {
    save_user_preference('show_deprecated_views', $(this).prop('checked'));
    location.reload();
});

$("body").on("click", ".js-set-user-show-wip-views", function () {
    save_user_preference('show_wip_views', $(this).prop('checked'));
    location.reload();
});
