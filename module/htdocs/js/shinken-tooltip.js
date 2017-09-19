$.fn.tooltip.Constructor.DEFAULTS.placement = 'auto';

function tooltips(){
   $('[title]').tooltip({
       html: 'true'
   });
}

tooltips();
