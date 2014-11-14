$(document).ready(function(){
    // enable / disable refresh 
            $("#togglerefresh").on("click",function(){ 
                    if (refresh_enabled) { 
                            $("#labelrefresh").text(" Disable refresh"); 
                    }else{ 
                            $("#labelrefresh").text(" Enable refresh"); 
                    } 
                    refresh_enabled = !refresh_enabled;
                    reinit_refresh();
            }); 
});