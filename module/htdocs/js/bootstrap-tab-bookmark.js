function bootstrap_tab_bookmark (selector) {
    if (selector == undefined) {
        selector = "";
    }

    var bookmark_switch = function () {
        url = document.location.href.split('#');
        if(url[1] != undefined) {
            $(selector + '[href=#'+url[1]+']').tab('show');
        }
    }

    /* Automagically jump on good tab based on anchor */
    $(document).ready(bookmark_switch);
    $(window).bind('hashchange', bookmark_switch);

    var update_location = function (event) {
        document.location.hash = this.getAttribute("href");
    }

    /* Update hash based on tab */
    $(selector + "[data-toggle=pill]").click(update_location);
    $(selector + "[data-toggle=tab]").click(update_location);
}
