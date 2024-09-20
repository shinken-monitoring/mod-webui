$.fn.tooltip.Constructor.DEFAULTS.placement = 'auto';

function tooltips(){
   $('#page-content [title]').tooltip({
       html: 'true'
   });
}

tooltips();
