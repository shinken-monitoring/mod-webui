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


	$("a.switcher").bind("click", function(e){
		e.preventDefault();
		
		var theid = $(this).attr("id");
		var thegroups = $("ul#groups");
		var classNames = $(this).attr('class').split(' ');
		
		var gridthumb = "images/groups/grid-default-thumb.png";
		var listthumb = "images/groups/list-default-thumb.png";
		
		if($(this).hasClass("active")) {
			// if currently clicked button has the active class
			// then we do nothing!
			return false;
		} else {
			// otherwise we are clicking on the inactive button
			// and in the process of switching views!

  			if(theid == "gridview") {
				$(this).addClass("active");
				$("#listview").removeClass("active");
			
				$("#listview").children("img").attr("src","images/list-view.png");
			
				var theimg = $(this).children("img");
				theimg.attr("src","images/grid-view-active.png");
			
				// remove the list class and change to grid
				thegroups.removeClass("list");
				thegroups.addClass("grid");
			
				// update all thumbnails to larger size
				$("img.thumb").attr("src",gridthumb);
			}
			
			else if(theid == "listview") {
				$(this).addClass("active");
				$("#gridview").removeClass("active");
					
				$("#gridview").children("img").attr("src","images/grid-view.png");
					
				var theimg = $(this).children("img");
				theimg.attr("src","images/list-view-active.png");
					
				// remove the grid view and change to list
				thegroups.removeClass("grid")
				thegroups.addClass("list");
				// update all thumbnails to smaller size
				$("img.thumb").attr("src",listthumb);
			} 
		}

	});
});