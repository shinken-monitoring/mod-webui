//Loads the correct sidebar on window load,
//collapses the sidebar on window resize.
// Sets the min-height of #page-wrapper to window size
$(function() {
    $(window).bind("load resize", function() {
        topOffset = 50;
        width = (this.window.innerWidth > 0) ? this.window.innerWidth : this.screen.width;
        if (width < 768) {
            $('div.navbar-collapse').addClass('collapse');
            $('#search').hide();
            $('#sidebar-search').show();
            topOffset = 100; // 2-row-menu
        } else {
            if (width < 992) {
                reduce_sidebar();
            } else {
                expand_sidebar();
            }
            $('div.navbar-collapse').removeClass('collapse');
            $('#search').show();
            $('#sidebar-search').hide();
        }

        height = ((this.window.innerHeight > 0) ? this.window.innerHeight : this.screen.height) - 1;
        height = height - topOffset;
        if (height < 1) height = 1;
        if (height > topOffset) {
            $("#page-wrapper").css("min-height", (height) + "px");
        }
    });

    var url = window.location;
    var element = $('#sidebar-menu a').filter(function() {
        if (this.href.indexOf('#', this.href.length - '#'.length) !== -1) {
            return false;
        }
        return this.href == url || url.href.indexOf(this.href + '?') == 0;
    }).addClass('active').parent().parent().addClass('in').parent();
    if (element.is('li')) {
        element.addClass('active');
    }
});

function toggle_sidebar() {
    if ($("#wrapper").hasClass("sidebar-reduced")) {
        expand_sidebar();
    } else {
        reduce_sidebar();
    }
}

function reduce_sidebar() {
    $('#wrapper').addClass('sidebar-reduced');

    $('.js-sidebar-toggle .fas').addClass('fa-arrow-right').removeClass('fa-arrow-left');
}

function expand_sidebar() {
    $('#wrapper').removeClass('sidebar-reduced');

    $('.js-sidebar-toggle .fas').addClass('fa-arrow-left').removeClass('fa-arrow-right');
}

$(document).ready(reduce_sidebar());

//$("#sidebar-menu a").on("click", function() {
    //console.log($("#sidebar-menu li.active"));
    //if ($("#sidebar-menu li.active").length > 0) {
        //expand_sidebar();
    //} else {
        //reduce_sidebar();
    //}
//});
