function display_charts(){
    $(".piechart").sparkline('html', {
        enableTagOptions: true,
        disableTooltips: true,
        offset: -90
    });
}

display_charts();
