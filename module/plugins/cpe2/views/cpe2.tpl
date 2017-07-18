<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css" >
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap-theme.min.css" >



  </head>
<body>


  <h1>Timeline</h1>
  <div id="timeline"></div>

  <h2 id="msg">MSG</h2>

  <script src="http://code.jquery.com/jquery-latest.min.js"></script>
  <script src="http://d3js.org/d3.v3.min.js" charset="utf-8"></script>
  <script src="/static/cpe2/js/d3-timeline.js"></script>
  <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js" ></script>
  <script>
  SHINKEN_COLORS = ['#5bb75b','#faa732', '#da4f49','#49afcd', '#777']
  function shinken_state_id_to_color(id) {
    return SHINKEN_COLORS[id];
  }

  function random_rgba() {
      var o = Math.round, r = Math.random, s = 255;
      return 'rgba(' + o(r()*s) + ',' + o(r()*s) + ',' + o(r()*s) + ',' + r().toFixed(1) + ')';
  }

  var timelineData = {}
  var timelineData2 = []

  var global_starting_time = {{mintime * 1000}};
  var global_ending_time = {{maxtime * 1000}};

  window.onload = function() {
    timelineData["host"] = {};
    timelineData["host"]["times"] = [{'color': 'orange', 'starting_time': {{mintime*1000}}, 'ending_time': {{maxtime*1000}}  }],
    timelineData["host"]["last_time"] = {{mintime * 1000}},
%for service in cpe.services:
      timelineData["{{service.display_name}}"] = {};
      timelineData["{{service.display_name}}"]["times"] = [],
      timelineData["{{service.display_name}}"]["last_time"] = {{mintime * 1000}},
%end

    $.getJSON('/timeline/{{cpe.host_name}}', function(data){


      $.each(data,function(service, result){

            $.each(result.times,function(k,value){

              console.log(value.start)
              timelineData[service].times.push({
                'color': shinken_state_id_to_color(value.state),
                'starting_time': value.start * 1000,
                'ending_time': value.end * 1000,
                'message': value.message
              });

            }); //push
            //timelineData[result.service].last_time = result.timestamp * 1000;


       }); //forEach

       console.log(timelineData)


       $.each(timelineData, function(k,v){
         timelineData2.push({
           label: k,
           times: v.times
         })
       });

       console.log(timelineData)

       createTimeline(timelineData2);

     }); //getJSON

      //createTimeline();




    //createTimeline();

  }

  var width = 800;

  function createTimeline(data) {
    var chart = d3.timeline()
      .tickFormat({
            format: function(d) { return d3.time.format("%x")(d) },
            tickTime: d3.time.hours,
            tickInterval: 60,
            tickSize: 15,
      })
      .width(width * 4)
      .stack().background('#fff')
      .margin({left:70, right:30, top:0, bottom:0})
      .hover(function (d, i, datum) {
      // d is the current rendering object
      // i is the index during d3 rendering
      // datum is the id object

        $('#msg').html("MSG:" + d.message)

      })
      .click(function (d, i, datum) {
        alert(datum.label);
      })
      .scroll(function (x, scale) {
        console.log(scale.invert(x) + " to " + scale.invert(x+width));
      });

      var svg = d3.select("#timeline").append("svg").attr("width", width).datum(data).call(chart);
  }
</script>
</body>
</html>
