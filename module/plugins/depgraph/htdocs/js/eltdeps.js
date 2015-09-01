/*Copyright (C) 2009-2011 :
     Gabes Jean, naparuba@gmail.com
     Gerhard Lausser, Gerhard.Lausser@consol.de
     Gregory Starck, g.starck@gmail.com
     Hartmut Goebel, h.goebel@goebel-consult.de
     Andreas Karfusehr, andreas@karfusehr.de
 
 This file is part of Shinken.
 
 Shinken is free software: you can redistribute it and/or modify
 it under the terms of the GNU Affero General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 Shinken is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU Affero General Public License for more details.
 
 You should have received a copy of the GNU Affero General Public License
 along with Shinken.  If not, see <http://www.gnu.org/licenses/>.
*/


var depgraph_logs=false;


var labelType, useGradients, nativeTextSupport, animate;

(function() {
   var ua = navigator.userAgent,
      iStuff = ua.match(/iPhone/i) || ua.match(/iPad/i),
      typeOfCanvas = typeof HTMLCanvasElement,
      nativeCanvasSupport = (typeOfCanvas == 'object' || typeOfCanvas == 'function'),
      textSupport = nativeCanvasSupport
      && (typeof document.createElement('canvas').getContext('2d').fillText == 'function');
      
   //I'm setting this based on the fact that ExCanvas provides text support for IE
   //and that as of today iPhone/iPad current text support is lame
   labelType = (!nativeCanvasSupport || (textSupport && !iStuff))? 'Native' : 'HTML';
   nativeTextSupport = labelType == 'Native';
   useGradients = nativeCanvasSupport;
   animate = !(iStuff || !nativeCanvasSupport);
})();



function dump(arr, level) {
   var dumped_text = "";
   if (!level) level = 0;

   // The padding given at the beginning of the line.
   var level_padding = "";
   for (var j=0;j<level+1;j++) 
      level_padding += "    ";

   if (typeof(arr) == 'object') {
      for (var item in arr) {
         var value = arr[item];

         if (typeof(value) == 'object') { //If it is an array,
            dumped_text += level_padding + "'" + item + "' ...\n";
            dumped_text += dump(value,level+1);
         } else {
            dumped_text += level_padding + "'" + item + "' => \"" + value + "\"\n";
         }
      }
   } else {
      dumped_text = "===>"+arr+"<===("+typeof(arr)+")";
   }
   return dumped_text;
}


var rgraph = null;


function change_rgraph_root(root){
   rgraph.onClick(root, {  
      Move: {  
      }
   });
}

function init_graph(root, jsgraph, width, height, inject) {
   if (depgraph_logs) console.log('depgraph - init_graph ...');
   
   if (typeof $jit === "undefined") {
      if (depgraph_logs) console.log('depgraph - Warning : there is no $jit, I postpone my init for 1s');
      // Still not load $jit? racing problems are a nightmare :)
      // Ok, we retry in the next second...
      setTimeout(function(){init_graph(root,jsgraph,width,height,inject)},1000);
   
      return;
   }

   if (depgraph_logs) console.log('depgraph - On load is ok!');
   //init data
   //If a node in this JSON structure
   //has the "$type" or "$dim" parameters
   //defined it will override the "type" and
   //"dim" parameters globally defined in the
   //RGraph constructor.

    
   /* Ok, for the circles, we need a particles system, and not recreate them too
   much, but only once by item, even when it moves! */
   var particles;
   var context;
   var particles = [];
   var particules_by_name = {};//new Hash();

   // Main printing loop for particles, graph is print only when need, 
   // but particles are printed at each loop
   function loop() {
      for (i = 0, len = particles.length; i < len; i++) {
         var particle = particles[i];

         // If the particle is disabled, bail out
         if (!particle.active) {
            continue;
         }

         var lp = { x: particle.position.x, y: particle.position.y };

         // Offset the angle to keep the spin going
         particle.angle += particle.speed;

         // Apply position
         particle.position.x = particle.shift.x + Math.cos(i + particle.angle) * (particle.orbit);
         particle.position.y = particle.shift.y + Math.sin(i + particle.angle) * (particle.orbit);

         pos2_x = particle.shift.x + Math.cos(i + particle.angle + 2*Math.PI/3) * (particle.orbit);
         pos2_y = particle.shift.y + Math.sin(i + particle.angle + 2*Math.PI/3 ) * (particle.orbit);

         pos3_x = particle.shift.x + Math.cos(i + particle.angle + 4*Math.PI/3) * (particle.orbit);
         pos3_y = particle.shift.y + Math.sin(i + particle.angle + 4*Math.PI/3 ) * (particle.orbit);


         // Compute the position of the cleaning arc
         var anti_x = particle.shift.x + Math.cos(i + particle.angle + Math.PI/3) * (particle.orbit);
         var anti_y = particle.shift.y + Math.sin(i + particle.angle + Math.PI/3) * (particle.orbit);

         // Compute the position of the cleaning arc
         var anti2_x = particle.shift.x + Math.cos(i + particle.angle + 3*Math.PI/3) * (particle.orbit);
         var anti2_y = particle.shift.y + Math.sin(i + particle.angle + 3*Math.PI/3) * (particle.orbit);


         var anti3_x = particle.shift.x + Math.cos(i + particle.angle + 5*Math.PI/3) * (particle.orbit);
         var anti3_y = particle.shift.y + Math.sin(i + particle.angle + 5*Math.PI/3) * (particle.orbit);


         // Compute a local size to make a up/down size effect
         var local_size = (Math.cos(particle.angle) - Math.sin(particle.angle) + 2 * particle.size) / 2;
         local_size = particle.size;


         // Number of cut we want in our orbital spinner
         var NB_PART=3;
         for(var j = 0; j < 2*NB_PART; j++){
            pos_x = particle.shift.x + Math.cos(i + particle.angle + j*Math.PI/NB_PART) * (particle.orbit);
            pos_y = particle.shift.y + Math.sin(i + particle.angle + j*Math.PI/NB_PART) * (particle.orbit);

            // If it's a odd value, print a color one
            if (j % 2 == 0){
               // Draw the color spiner
               context.beginPath();
               context.fillStyle = particle.fillColor;
               context.arc(pos_x, pos_y, local_size/2, 0, Math.PI*2, true);
               context.fill();
            } else { // print a cleaning particle
               context.beginPath();
               context.fillStyle = 'rgba(255,255,255,0.8)';
               context.arc(pos_x, pos_y, 4,  0, Math.PI*(2), true);
               context.fill();
            }
         }

      }
   }


   function clean_particule(name){
      if (particules_by_name[name] != undefined){
         p = particules_by_name[name];
         p.active = false;
      }
   }


   // We should NOT create 1000 particles again and again
   // but remember them to "translate" them if need (graph rewrite)
   function create_or_update_particule(name, x, y, color, size) {
      //alert(particules_by_name['name']);
      if (particules_by_name[name] != undefined){
         p = particules_by_name[name];
         p.position = {x: x, y: y};
         p.shift = {x: x, y: y};
         p.angle = 0;
         p.size = 1 * (1 + (size - 2 / 5));
         p.active = true;
      }else{ // New particule :) 
         var color_code = 'gray';
         if (color == 'red'){
            color_code = '#E60000';
         }
         if (color == 'orange'){
            color_code = '#E67E00';
         }

         var particle = {
            active : true,
            // position to print
            position: { x: x, y: y },
            // position of the center
            shift: { x: x, y: y },
            size: 1 * (1 + (size - 2 / 5)), // make the size large of the particule change too
            angle: 0,
            speed: 0.1,
            fillColor: color_code,
            orbit: 20 * (1 + ((size - 2) / 4 )) // make the orbit bigger for important elements
         };
   
         particles.push( particle );
         particules_by_name[name] = particle;
      }
   }


   // A node should be printed if it's a important one
   // like an host, or a service near or with a huge business
   // impact, or a root problem.
   function should_be_print(node){
      var b = true;
      var elt_type = 'service';
      var business_impact = 2;
      var state_id = 0;
      var is_problem = false;
      /* We can have some missing data, so just add dummy info */
      if (typeof(node.data.elt_type) != 'undefined'){
         elt_type = node.data.elt_type;
         business_impact = node.data.business_impact;
         state_id = node.data.state_id;
         is_problem = node.data.is_problem;
      }

      // For distant service, we should tag them with no label
      // but important one should be still tags of course.
      // should saw root problem too
      if (node._depth == 0) { 
      } else if(node._depth == 1 ){
      }else if(node._depth >= 2){  
         if (elt_type == 'service' && business_impact <= 2 ){
            if(state_id == 0 || !is_problem){
               b = false;
            }
         }
      }
      return b;
   }


   // Here we implement custom node rendering types for the RGraph
   // Using this feature requires some javascript and canvas experience.
   $jit.RGraph.Plot.NodeTypes.implement({
      'custom': {
         'render': function(node, canvas) {
            /*First we need to know where the node is, so we can draw 
            in the correct place for the GLOBAL canvas*/
            var pos = node.getPos().getc();
            var size = 16;

            var ctx = canvas.getCtx();

            // Look if we really need to render this node
            if (! should_be_print(node)){
               var color = node.data.circle;
               // Remember to clean the particule if need
               clean_particule(node.id);
               ctx.beginPath();
               ctx.fillStyle = color;
               ctx.arc(pos.x, pos.y, 1,  0, Math.PI*(2), true);
               ctx.fill();
               return;
            }


            // save it
            context = ctx;
            var img = new Image();
            
            img.onload = function () {
               // console.log ('Image loaded', img)
               var elt_type = 'service';
               /* We can have some missing data, so just add dummy info */
               if (typeof(node.data.elt_type) != 'undefined'){
                  elt_type = node.data.elt_type;
               }

               /* We scale the image. Thanks html5 canvas.*/
               img.width = size;
               img.height = size;
                  
               /* If we got a value for the circle */
               if (typeof(node.data.img_src) != 'undefined'){
                  color = node.data.circle;
                  if (color != 'none'){
                     create_or_update_particule(node.id, pos.x, pos.y, color, node.data.business_impact - 1);
                  } else {
                     // If we didn't print the circle, we can add one for the
                     // root, so the user will show it. 
                     // DO NOT PUT THE node.id here, because we need this particule to folow the root
                     // whatever its name is ;)
                     if(node.id == rgraph.root){
                        create_or_update_particule('graphrootforwebui', pos.x, pos.y, 'gray', node.data.business_impact - 1);
                     }
                  }
               }
                  
               //Ok, we draw the image, and we set it in the middle of the node :)
               ctx.drawImage(img, pos.x-size/2, pos.y-size/2, img.width, img.height);
            };
            /* We can have some missing data, so just add dummy info */
            if (typeof(node.data.img_src) == 'undefined'){
               img.src = '/static/images/state_ok.png';
            } else {
               img.src = node.data.img_src;
               size = size * (1 + (node.data.business_impact - 2) /  3);
            }
         }
      }
   });

   // init RGraph
   if (depgraph_logs) console.log('depgraph - init graph', inject, width, height);
   rgraph = new $jit.RGraph({
      'injectInto': /*'infovis'*/'infovis-'+inject,
      'width'     : width,
      'height'    : height,
      //Optional: Add a background canvas
      //that draws some concentric circles.
      'background': false,
      //Add navigation capabilities:
      //zooming by scrolling and panning.
      Navigation: {
         enable: true,
         panning: true,
         zooming: 20
      },
      //Nodes and Edges parameters
      //can be overridden if defined in
      //the JSON input data.
      //This way we can define different node
      //types individually.
      Node: {
         color: 'green',
         'overridable': true,
         type : 'custom'
      },
      Edge: {
         color: 'SeaGreen',
         lineWidth : 0.5,
         'overridable': true
      },
      
      //Add tooltips
      Tips: {
         enable: true,
         onShow: function(tip, node) {
            tip.innerHTML = "<div class=\"tip-title border\">" + node.data.infos + "</div>";
         }
      },
      
      //Set polar interpolation.
      //Default's linear.
      interpolation: 'polar',
      //Change the transition effect from linear
      //to elastic.
      //transition: $jit.Trans.Elastic.ea
      //Change other animation parameters.
      duration:1000,
      fps: 30,
      //Change father-child distance.
      levelDistance: 75,
      //This method is called right before plotting
      //an edge. This method is useful to change edge styles
      //individually.
      onBeforePlotLine: function(adj){
         src = adj.nodeFrom;
         dst = adj.nodeTo;

         // If one of the line border is a no print node
         // print this line in very few pixels
         if (!should_be_print(src) || !should_be_print(dst)){
            adj.data.$lineWidth = 0.3;
         } else {
            adj.data.$lineWidth = 2;
         }
      },

      onBeforeCompute: function(node){
         if (document.getElementById('log-'+inject))
            document.getElementById('log-'+inject).innerHTML = "Focusing on " + node.name + "...";
         
         $jit.id('inner-details-'+inject).innerHTML = node.data.infos;
      },
      
      //Add node click handler and some styles.
      //This method is called only once for each node/label crated.
      onCreateLabel: function(domElement, node){
         domElement.innerHTML = node.name;
         domElement.onclick = function () {
            rgraph.onClick(node.id, {
               hideLabels: false,
               onComplete: function() {
                  document.getElementById('log-'+inject).innerHTML = "";
               }
            });
         };
         var style = domElement.style;
         style.cursor = 'pointer';
         style.fontSize = "0.8em";
         style.color = "#000";
      },
      
      //This method is called when rendering/moving a label.
      //This is method is useful to make some last minute changes
      //to node labels like adding some position offset.
      onPlaceLabel: function(domElement, node){
         var style = domElement.style;
         var left = parseInt(style.left);
         var w = domElement.offsetWidth;
         style.left = (left - w / 2) + 'px';

         // If the node should not be print
         // do not print it :)
         if(!should_be_print(node)){
            style.display = 'none';
         }
      }
   });
   
   //load graph.
   rgraph.loadJSON(jsgraph, 1);
   rgraph.root = root;

   //compute positions and plot
   rgraph.refresh();
   rgraph.controller.onBeforeCompute(rgraph.graph.getNode(rgraph.root));

   setInterval(loop, 1000 / 60);
};
