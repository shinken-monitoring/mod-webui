/*  */

function normalize_float(a) {
    return a;
    //if (!a) { return 0 }
    //if (a > 100) { return toFixed(a, 0) }
    //if (a > 10) { return toFixed(a, 1) }
    //return toFixed(a, 2)
}

function normalize_tick(b) {
    var a = (Math.round(b * 100) / 100).toString(10);
    var c = a.lastIndexOf(".");
    if (c != -1 && c < a.length - 2) {
        a = a.substr(0, c + 3)
    }
    return a
}

function humanBytes(fileSizeInBytes) {

    var i = -1;
    var byteUnits = ['kb', 'Mb', 'Gb', 'Tb', 'Pb', 'Eb', 'Zb', 'Yb'];
    do {
        fileSizeInBytes = fileSizeInBytes / 1024;
        i++;
    } while (fileSizeInBytes > 1024);

    return Math.max(fileSizeInBytes, 0.1).toFixed(1) + byteUnits[i];
};

function formatBPS(c) {
    var a, b;
    if (Math.round(c) < 1000) {
        b = "bps";
        a = 0
    } else {
        if (Math.round(c / 1000) < 1000) {
            c = c / 1000;
            b = "kbps";
            a = 1
        } else {
            c = c / 1000 / 1000;
            b = "Mbps";
            a = 2
        }
    }
    c = normalize_float(c);
    return [c, b, a, "" + c + b]
}

function toHHMMSS(num) {
    var sec_num = parseInt(num, 10); // don't forget the second param
    var days    = Math.floor(sec_num / (3600 * 24));
    var hours   = Math.floor((sec_num / 3600) % 24);
    var minutes = Math.floor((sec_num / 60) % 60);
    var seconds = sec_num % 60;

    if (days    >  1) {days    = days + "d " } else { days = ""}
    if (hours   < 10) {hours   = "0"+hours;}
    if (minutes < 10) {minutes = "0"+minutes;}
    if (seconds < 10) {seconds = "0"+seconds;}
    return days+hours+':'+minutes+':'+seconds;
};

var plots = {}
var plotOptions = {}

plotOptions['bw'] = {
  series: {  shadowSize: 0 },
  yaxis: {
    min: 0,
    ticks: 8,
    tickFormatter: function(d) { ;return (d != 0) ? humanBytes(normalize_tick(d)) : 'bps' + " 0" }
  },
  xaxis: {
    show: false
  },
  legend: {
      position: "ne",
      backgroundOpacity: 0.4
  }
}

plotOptions['rx']  = {
  series: {  shadowSize: 0 },
  yaxis: {
    min: -127,
    max: 0,
    ticks: 8,
    tickFormatter: function(d) { ;return (d != 0) ? normalize_tick(d) : 'dbm' + " 0" }
  },
  xaxis: {
    show: false
  },
  legend: {
      position: "ne",
      backgroundOpacity: 0.4
  }
}

plotOptions['ccq']  = {
  series: {  shadowSize: 0 },
  yaxis: {
    min: 0,
    max: 100,
    ticks: 8,
    tickFormatter: function(d) { ;return d }
  },
  xaxis: {
    show: false
  },
  legend: {
      position: "ne",
      backgroundOpacity: 0.4
  }
}


var plotData = {
  'bw': [
      {data: [], color: "#2389C6"},
      {data: [], color: "#C68923"}
    ],
  'rx': [
      {data: [], color: "#8923C6"},
      {data: [], color: "#C62389"}
    ],
  'ccq': [
      {data: [], color: "#3F51B5"},
      {data: [], color: "#2196F3"},
      {data: [], color: "#F50057"},
      {data: [], color: "#D500F9"}
    ],
}


$( function(){
  if( $("#plot_bw").length ) {
    plots['bw']  = $.plot("#plot_bw",  plotData['bw'],  plotOptions['bw']);
  }

  if( $("#plot_rx").length ) {
    plots['rx']  = $.plot("#plot_rx",  plotData['rx'],  plotOptions['rx']);
  }

  if( $("#plot_ccq").length ) {
    plots['ccq'] = $.plot("#plot_ccq", plotData['ccq'], plotOptions['ccq']);
  }
});


function updateGraphs(data) {
  console.log(data)

  if (data.dnbw_d && data.upbw_d) {
    plotData.bw[0].data.push([ Date.now() , parseInt(data.dnbw_d) ])
    plotData.bw[0].label = "DnBw: " + humanBytes(data.dnbw_d)
    plotData.bw[1].data.push([ Date.now() , parseInt(data.upbw_d) ])
    plotData.bw[1].label = "UpBw: " + humanBytes(data.upbw_d)
  } else if (data.dnbw && data.upbw) {
    plotData.bw[0].data.push([ Date.now() , parseInt(data.dnbw) ])
    plotData.bw[0].label = "DnBw: " + humanBytes(data.dnbw)
    plotData.bw[1].data.push([ Date.now() , parseInt(data.upbw) ])
    plotData.bw[1].label = "UpBw: " + humanBytes(data.upbw)
  }

  if (typeof data.dnrx != 'undefined' && typeof data.uptx != 'undefined') {
    plotData.rx[0].data.push([ Date.now() , data.dnrx ])
    plotData.rx[0].label = "DnRx: " + data.dnrx + " dbm"
    plotData.rx[1].data.push([ Date.now() , data.uptx ])
    plotData.rx[1].label = "UpTx: " + data.uptx + " dbm"
  }

  if (typeof data.dnrx != 'undefined' && typeof data.uprx != 'undefined') {
    plotData.rx[0].data.push([ Date.now() , data.dnrx ])
    plotData.rx[0].label = "DnRx: " + data.dnrx + " dbm"
    plotData.rx[1].data.push([ Date.now() , data.uprx ])
    plotData.rx[1].label = "UpRx: " + data.uprx + " dbm"
  }

  if (typeof data.ccq != 'undefined') {
    plotData.ccq[0].data.push([ Date.now(), data.ccq ])
    plotData.ccq[0].label = "CCQ: " + data.ccq + "%"
  }

  if (typeof data.dncorr != 'undefined' && typeof data.dnko != 'undefined') {
    plotData.ccq[0].data.push([ Date.now(), data.dncorr ])
    plotData.ccq[0].label = "dncorr: " + data.dncorr + "%"
    plotData.ccq[1].data.push([ Date.now(), data.dnko ])
    plotData.ccq[1].label = "dnko: " + data.dnko + "%"
  }

  if (typeof data.upcorr != 'undefined' && typeof data.upko != 'undefined') {
    plotData.ccq[2].data.push([ Date.now(), data.upcorr ])
    plotData.ccq[2].label = "upcorr: " + data.upcorr + "%"
    plotData.ccq[3].data.push([ Date.now(), data.upko ])
    plotData.ccq[3].label = "upko: " + data.upko + "%"
  }

  for (var key in plots) {
    plots[key].setData(plotData[key]);
    plots[key].setupGrid()
    plots[key].draw();
  }


}

$(window).bind('resize', function(event, ui) {
    for (var key in plots) {
        plots[key].resize();
        plots[key].setupGrid();
        plots[key].draw();
    }
});
