function add_new_bookmark(page){
   var f = document.forms['bookmark_save'];
   var name = f.bookmark_name.value;
   if (name=='') return;

   var uri = get_current_search(page);

   var b = {'name' : name, 'uri' : uri};
   
   // Do not save the bm if there is already one with this name
   var names = new Array();
   $.each(bookmarks, function(idx, bm){
      names.push(bm.name);
   });
   if (names.indexOf(name)==-1) {
      // Ok we can save bookmarks in our preferences
      bookmarks.push(b);
      save_bookmarks();
   } else { 
      alert('This bookmark already exists !');
   }
}

function save_bookmarks(){
   $.post("/user/save_pref", { 'key' : 'bookmarks', 'value' : JSON.stringify(bookmarks)});

   // And refresh it
   refresh_bookmarks();
}

function save_bookmarksro(){
   $.post("/user/save_common_pref", { 'key' : 'bookmarks', 'value' : JSON.stringify(bookmarksro)});

   // And refresh it
   refresh_bookmarksro();
}

function push_to_common_bookmarks(name,uri) {
   var b = {'name' : name, 'uri' : uri};
   // Do not save the bm if there is already one with this name
   var names = new Array();
   $.each(bookmarksro, function(idx, bm){
      names.push(bm.name);
   });
   if (names.indexOf(name)==-1) {
      // Ok we can save bookmarks in our preferences
      bookmarksro.push(b);
      save_bookmarksro();
   } else { 
      alert('This Common bookmark name already exists !');
   }
}


function declare_bookmark(name, uri){
   var b = {'name' : name, 'uri' : uri};
   bookmarks.push(b);
}

function declare_bookmarksro(name, uri){
   var b = {'name' : name, 'uri' : uri};
   bookmarksro.push(b);
}


// Refresh bookmarks in HTML
function refresh_bookmarks(){
   if (bookmarks.length == 0){
      $('#bookmarks').html('<ul class="list-group"><li class="list-group-item list-group-item-danger">No user bookmarks</li></ul>');
      return;
   }

   s = 'Your bookmarks: <ul class="list-group">';
   $.each(bookmarks, function(idx, b){
      l = '<span><a href="'+b.uri+'"><i class="fa fa-tag"></i> '+b.name+'</a></span>';
      fun = "delete_bookmark('"+b.name+"');";
      c = '<span><a href="javascript:'+fun+'" class="close">&times;</a></span>';
      fun2 = "push_to_common_bookmarks('"+b.name+"','"+b.uri+"');";
      c2 = '<span><a href="javascript:'+fun2+'" class="close">&plus;</a></span>';

      s+= '<li class="list-group-item">'+l+c+c2+'</li>';
   });
   s += '</ul>';
   
   $('#bookmarks').html(s);
}

function refresh_bookmarksro(){
   if (bookmarksro.length == 0) {
      $('#bookmarksro').html('<ul class="list-group"><li class="list-group-item list-group-item-danger">No common bookmarks</li></ul>');
      return;
   }

   sro = 'Common bookmarks: <ul class="list-group">';
   $.each(bookmarksro, function(idx, b) {
      l = '<span><a href="'+b.uri+'"><i class="fa fa-tag"></i> '+b.name+'</a></span>';
      fun = "delete_bookmarkro('"+b.name+"');";
      c = '<span><a href="javascript:'+fun+'" class="close">&times;</a></span>';
      sro+= '<li class="list-group-item">'+l+c+'</li>';
   });
   sro += '</ul>';
   
   $('#bookmarksro').html(sro);
}



// Delete a specific bookmark by its name
function delete_bookmark(name){
   new_bookmarks = [];
   $.each(bookmarks, function(idx, b){
      if (b.name != name) {
         new_bookmarks.push(b);
      }
   });
   bookmarks = new_bookmarks;
   save_bookmarks();
}

function delete_bookmarkro(name){
   new_bookmarksro = [];
   $.each(bookmarksro, function(idx, b){
      if (b.name != name) {
         new_bookmarksro.push(b);
      }
   });
   bookmarksro = new_bookmarksro;
   save_bookmarksro();
}

// On page loaded ... 
$(document).ready(function(){
   // Refresh bookmarks
   refresh_bookmarks(); 
   refresh_bookmarksro();
});
