$(document).ready(function(){

    // enable / disable refresh 
            refreshactive=true; 
            $("#togglerefresh").on("click",function(){ 
                    if (refreshactive) { 
                            refreshactive = false; 
                            $("#labelrefresh").text(" Enable refresh"); 
                            clearInterval("check_refresh();"); 
                    }else{ 
                            refreshactive = false; 
                            $("#labelrefresh").text(" Disable refresh"); 
                            setInterval("check_refresh();",1000); 
                    } 
            }); 

});