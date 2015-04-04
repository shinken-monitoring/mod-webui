
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

    // Inner circle
    draw_arc(ctx, 80, 80, 32, 0, 2*Math.PI, true, main_color, 40, 0.5);
    draw_arc(ctx, 80, 80, 33, 0, 2*Math.PI, true, huge_color, 2, 0.5);

    // Middle one
    draw_arc(ctx, 80, 80, 45, 0, 2*Math.PI, true, main_color, 2, 0.3);
    draw_arc(ctx, 80, 80, 46, 0, 2*Math.PI, true, main_color, 2, 0.3);
    // The left part of the middle
    draw_arc(ctx, 80, 80, 44, 0.7*Math.PI, 1.1*Math.PI, false, huge_color, 4, 0.5);
    //Top rigth art of the middle
    draw_arc(ctx, 80, 80, 44, 1.5*Math.PI, 2*Math.PI, false, huge_color, 4, 0.5);
  

    // Before last one
    // Middle one
    draw_arc(ctx, 80, 80, 60, Math.PI, 0.4*Math.PI, false, main_color, 2, 0.5);
    draw_arc(ctx, 80, 80, 61, Math.PI, 0.4*Math.PI, false, main_color, 2, 0.5);
    // The left part of the before last 
    draw_arc(ctx, 80, 80, 59, Math.PI, 1.7*Math.PI, false, huge_color, 5);
    //Top rigth art of the middle
    draw_arc(ctx, 80, 80, 59, 0, 0.4*Math.PI, false, huge_color, 5);


    /////////////// The status icon
    var img_status = document.createElement('img');
    img_status.onload=function(){
      // Image ratio
      var f = img_status.width / img_status.height;
      var newHeight = 128;
      var newWidth = newHeight * f;
      ctx.drawImage(img_status, 48, 48, newWidth, newHeight);
    };
    img_status.src = imgSrc+host_canvas.data('host-state-image');
    
    //////////////// Lines part
    // Now the line from the left part to down, in 3 parts
    draw_line(ctx, 20, 80, 20, 100, line_color, 1, 0.5);
    draw_line(ctx, 20, 100, 50, 140, line_color, 1, 0.5);
    draw_line(ctx, 50, 140, 50, 200, line_color, 1, 0.5);


    /////////////// The network icon
	var linePos = 190;
	var posNetwork = linePos;
	if (host_canvas.data('host-network-state') != 'unknown') {
		// Now a small step down
		draw_line(ctx, 50, linePos, 50, linePos+150, line_color, 1, 0.5);
		linePos += 150;
		posNetwork = linePos-50;

		draw_line(ctx, 50, linePos, 100, linePos, line_color, 1, 0.5);

		var img_network = document.createElement('img');
		img_network.onload=function(){
			ctx.drawImage(img_network, 75, posNetwork, 64, 64);
		};
		img_network.src = imgSrc+host_canvas.data('host-network-image');
		
		var ip = host_canvas.data('host-network-address');
		ctx.font      = "bold 10px Verdana";
		ctx.fillStyle = "#555";
		ctx.textAlign = 'center';
		ctx.fillText(ip, 105, linePos+25);
	}

    /////////////// The printer icon
	var posPrinter = linePos;
	if (host_canvas.data('host-printer-state') != 'unknown') {
		// Now a small step down
		draw_line(ctx, 50, linePos, 50, linePos+100, line_color, 1, 0.5);
		linePos += 100;
		posPrinter = linePos-50;

		draw_line(ctx, 50, linePos, 100, linePos, line_color, 1, 0.5);

		var img_printer = document.createElement('img');
		img_printer.onload=function(){
			ctx.drawImage(img_printer, 75, posPrinter, 64, 64);
		};
		img_printer.src = imgSrc+host_canvas.data('host-printer-image');
		
		var pages = host_canvas.data('host-printer-pages');
		ctx.font      = "bold 10px Verdana";
		ctx.fillStyle = "#555";
		ctx.textAlign = 'center';
		ctx.fillText(pages + " pages", 105, linePos+25);
	}


	if (all_disks.length != 0) {
		// Now a small step on the right, before disks
		draw_line(ctx, 50, 200, 70, 200, line_color, 1, 0.5);
		// And a small vertical line for disks
		draw_line(ctx, 70, 180, 70, 220, line_color, 1, 0.5);

		/////////////// The disks part ...
		var img_disks = document.createElement('img');
		var dsk_x = 75;
		var dsk_y = 210 - (25 * all_disks.length / 2);
		img_disks.onload=function(){
			for(var i=0; i<all_disks.length; i++){
				ctx.drawImage(img_disks, 0, 0, 70, 18, dsk_x, dsk_y, 70, 18);
				var d_name = all_disks[i][0];
				var d_value = all_disks[i][1]/100;
				var offset = 70*d_value;
				ctx.drawImage(img_disks, 0, 18, offset, 18, dsk_x, dsk_y, offset, 18);

				// And draw the disk name
				d_name=d_name+' '+(d_value*100)+'%';
				ctx.font      = "bold 10px Verdana";
				ctx.textAlign = 'left';
				ctx.fillStyle = "#222";
				ctx.fillText(d_name, dsk_x + 5, dsk_y + 13);

				// Now prepare the next disk
				dsk_y += 25;
			}
		};
		// An img for disks image background ...
		img_disks.src = imgSrc+'bar_horizontal.png';

		// And a small vertical line for disks
		draw_line(ctx, 150, 180, 150, 220, line_color, 1, 0.5);
	
		// Now a small line to go to the sub-systems
		draw_line(ctx, 150, 200, 170, 200, line_color, 1, 0.5);
	} else {
		// Now a large step on the right
		draw_line(ctx, 50, 200, 170, 200, line_color, 1, 0.5);
	}
	
	// A line that go to the CPU on the top
	draw_line(ctx, 170, 200, 200, 160, line_color, 1, 0.5);

	// A line that go to the Memory on the bottom
	draw_line(ctx, 170, 200, 200, 240, line_color, 1, 0.5);

	if (all_services && all_services.length != 0) {
		// Now a big line to the right
		draw_line(ctx, 170, 200, 340, 200, line_color, 1, 0.5);

		// And a vertical line for peripherals
		draw_line(ctx, 340, 10, 340, 600, line_color, 1, 0.5);
		
		// Draw the services.
		var sources = {
			ok:				    imgSrc+'/service_ok.png',
			warning:		  imgSrc+'/service_warning.png',
			critical:		  imgSrc+'/service_critical.png',
			unknown:		  imgSrc+'/service_unknown.png',
			pending:		  imgSrc+'/service_pending.png',
			downtime:		  imgSrc+'/service_downtime.png',
			flapping:		  imgSrc+'/service_flapping.png',
			uninstalled:	imgSrc+'/service_uninstalled.png'
		};
		function loadImages(sources, callback) {
			var images = {};
			var loadedImages = 0;
			var numImages = 0;
			// get num of sources
			for(var src in sources) {
				numImages++;
			}
			for(var src in sources) {
				images[src] = new Image();
				images[src].onload = function() {
					if(++loadedImages >= numImages) {
						callback(images);
					}
				};
				images[src].src = sources[src];
			}
		}
		
		var dev_x = 360;
		var dev_y = 10;
		var img_size = 64;
		var img_spacing = 100;
		var packagesPerColumn = 6;
		loadImages(sources, function(images){
			for (var i=0, column=1, line=1; i<all_services.length; i++, line++){
				var p_name = all_services[i][0];
				var p_state = all_services[i][1];
				// console.log(p_name+" is "+p_state);

				// Next column for the package 
				if ((column != 0) && (line % (packagesPerColumn+1) == 0)) {
					column += 1; line = 1;
					dev_x += img_spacing;
					dev_y = 10;
				}
				
				// Draw service icon
				ctx.drawImage(images[p_state.toLowerCase()], dev_x, dev_y, img_size, img_size);
				
				// And draw the service name
				ctx.font      = "bold 10px Verdana";
				ctx.fillStyle = "#000";
				ctx.textAlign = 'center';
				wrapText(ctx, p_name, dev_x + (img_size/2), dev_y, 20, 15)

				var span = $(document.createElement('span'));
				span.html('');
				span.attr('name', p_name);
				span.css('width', img_size+'px');
				span.css('height',img_size+'px');
				span.css('display','inline-block');
				span.css('position', 'absolute');
				span.css('left', dev_x);
				span.css('top', dev_y);
				span.css('cursor', 'pointer');
				span.css('border', 'red');
				span.on('click', function(){
					window.location.href="/service/"+host_canvas.data('name')+"/"+$(this).attr('name');
				});
				$('#'+customView).append(span);

				// Now prepare the next package
				dev_y += img_spacing;
			}
		});
	}
	
    // Terminate with the host name and the IP address
    var hname = host_canvas.data('name');
    if (hname.length>=20) hname = hname.substr(0, 17)+'...';
    ctx.font      = "bold 22px Verdana";
    ctx.fillStyle = "#555";
	ctx.textAlign = 'left';
    ctx.fillText(hname, 120, 30);
});