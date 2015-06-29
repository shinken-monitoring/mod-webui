
$(function(){
   if (! customView) {
      console.error('Custom view identifier should be defined in tpl Template file !');
      return;
   }
   if (! imgSrc) {
      var imgSrc = '/static/'+customView+'/img/';
   }
    
   var host_canvas = $('#'+customView+' canvas[name="host_canvas"]');
   var ctx = host_canvas[0].getContext('2d');

   // Purple : '#c1bad9', '#a79fcb'
   // Green  : '#A6CE8D', '#81BA6B'
   // Blue   : '#DEF3F5', '#89C3C6'
   // Red    : '#dc4950', '#e05e65'
   // Orange : '#F1B16E', '#EC9054'
   var main_colors = {'UNKNOWN' : '#c1bad9', 'OK' : '#A6CE8D', 'UP' : '#A6CE8D', 'WARNING' : '#F1B16E', 'CRITICAL' : '#dc4950', 'DOWN' : '#dc4950'};
   var huge_colors = {'UNKNOWN' : '#a79fcb', 'OK' : '#81BA6B', 'UP' : '#81BA6B', 'WARNING' : '#EC9054', 'CRITICAL' : '#e05e65', 'DOWN' : '#e05e65'};

   var global_state = host_canvas.data('global-state');
   var main_color = main_colors[global_state];
   var huge_color = huge_colors[global_state];
   var line_color = huge_color;



   /////////////// The status icon
   //////////////// Lines part
});