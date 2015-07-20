var bookmarks = [];
var bookmarksro = [];

function add_new_bookmark(){
   var f = document.forms['bookmark_save'];
   var name = f.bookmark_name.value;
   if (name=='') return;

   var uri = window.location.pathname + window.location.search;

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
      location.reload();
   } else { 
      alert('This bookmark already exists !');
   }
}

function save_bookmarks(){
   save_user_preference('bookmarks', JSON.stringify(bookmarks), function () {
      refresh_bookmarks();
   });
}

function save_bookmarksro(){
   save_common_preference('bookmarks', JSON.stringify(bookmarksro), function () {
      refresh_bookmarksro();
   });
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
      delete_bookmark(name);
      save_bookmarksro();
   } else { 
      alert('This Common bookmark name already exists !');
   }
}


function declare_bookmark(name, uri){
   bookmarks.push({'name' : name, 'uri' : uri});
}

function declare_bookmarksro(name, uri){
   bookmarksro.push({'name' : name, 'uri' : uri});
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
