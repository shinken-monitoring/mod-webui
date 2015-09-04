/* Copyright (C) 2009-2014 :
     Gabes Jean, naparuba@gmail.com
     Gerhard Lausser, Gerhard.Lausser@consol.de
     Gregory Starck, g.starck@gmail.com
     Hartmut Goebel, h.goebel@goebel-consult.de
     Andreas Karfusehr, andreas@karfusehr.de
     Frederic Mohier, frederic.mohier@gmail.com

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

var bkm_logs=false;

var bookmarks = [];
var bookmarksro = [];

// Save bookmarks lists
function save_bookmarks(){
   save_user_preference('bookmarks', JSON.stringify(bookmarks), function () {
      refresh_bookmarks(search_string);
   });
}

function save_bookmarksro(){
   save_common_preference('bookmarks', JSON.stringify(bookmarksro), function () {
      refresh_bookmarks(search_string);
   });
}

// Create bookmaks lists ...
function declare_bookmark(name, uri){
   var exists=false;
   $.each(bookmarks, function(idx, bm){
      if (bm.name == name) {
         exists=true;
         return false;
      }
   });
   if (! exists)  {
      if (bkm_logs) console.debug('Declaring user bookmark:', name, uri);
      bookmarks.push({'name' : name, 'uri' : uri});
      return true;
   }
   return false;
}

function declare_bookmarksro(name, uri){
   var exists=false;
   $.each(bookmarksro, function(idx, bm){
      if (bm.name == name) {
         exists=true;
         return false;
      }
   });
   if (! exists)  {
      if (bkm_logs) console.debug('Declaring global bookmark:', name, uri);
      bookmarksro.push({'name' : name, 'uri' : uri});
      return true;
   }
   return false;
}

// Refresh bookmarks in HTML
function refresh_bookmarks(_search_string){
   $('ul [aria-labelledby="bookmarks_menu"]').empty();
   if (bookmarks.length == 0 && bookmarksro.length == 0) {
      $('ul [aria-labelledby="bookmarks_menu"]').append('<li role="presentation" class="dropdown-header">No defined bookmarks</li>');
   }

   if (bookmarks.length) {
      $('ul [aria-labelledby="bookmarks_menu"]').append('<li role="presentation" class="dropdown-header"><strong>User bookmarks:</strong></li>');
      $.each(bookmarks, function(idx, bkm){
         $('ul [aria-labelledby="bookmarks_menu"]').append('<li role="presentation"><a role="menuitem" tabindex="-1" href="/all?search=' + bkm.uri + '"><i class="fa fa-bookmark"></i> ' + bkm.name + '</a></li>');
         if (bkm_logs) console.debug('Display user bookmark:', bkm.name);
      });
   }
   if (bookmarksro.length) {
      $('ul [aria-labelledby="bookmarks_menu"]').append('<li role="presentation" class="dropdown-header"><strong>Global bookmarks:</strong></li>');
      $.each(bookmarksro, function(idx, bkm){
         $('ul [aria-labelledby="bookmarks_menu"]').append('<li role="presentation"><a role="menuitem" tabindex="-1" href="/all?search=' + bkm.uri + '"><i class="fa fa-bookmark"></i> ' + bkm.name + '</a></li>');
         if (bkm_logs) console.debug('Display global bookmark:', bkm.name);
      });
   }

   if (_search_string) {
      $('ul [aria-labelledby="bookmarks_menu"]').append('<li role="presentation" class="divider"></li>');
      $('ul [aria-labelledby="bookmarks_menu"]').append('<li role="presentation"><a role="menuitem" href="#" action="display-add-bookmark" data-filter="'+_search_string+'"><i class="fa fa-plus"></i> Bookmark the current filter</a></li>');
   }
   if (bookmarks.length || bookmarksro.length) {
      $('ul [aria-labelledby="bookmarks_menu"]').append('<li role="presentation" class="divider"></li>');
      $('ul [aria-labelledby="bookmarks_menu"]').append('<li role="presentation"><a role="menuitem" href="#" action="manage-bookmarks" data-filter="'+_search_string+'"><i class="fa fa-tags"></i> Manage bookmarks</a></li>');
   }
}

// Delete a specific bookmark by its name
function delete_bookmark(name){
   new_bookmarks = [];
   $.each(bookmarks, function(idx, bm){
      if (bm.name != name) {
         new_bookmarks.push(bm);
      }
   });
   bookmarks = new_bookmarks;
   save_bookmarks();
   if (bkm_logs) console.debug('Deleted user bookmark:', name);
}

function delete_bookmarkro(name){
   new_bookmarksro = [];
   $.each(bookmarksro, function(idx, bm){
      if (bm.name != name) {
         new_bookmarksro.push(bm);
      }
   });
   bookmarksro = new_bookmarksro;
   save_bookmarksro();
   if (bkm_logs) console.debug('Deleted global bookmark:', name);
}

var search_string='';
$(document).ready(function(){
   search_string = $('#search').val();
   refresh_bookmarks(search_string);
   
   // Display modal to add a new bookmark ...
   $('body').on("click", '[action="display-add-bookmark"]', function (e, data) {
      search_string = $(this).data('filter');
      display_modal('/modal/newbookmark');
   });

   // Add a new bookmark ...
   $('body').on("click", '[action="add-bookmark"]', function (e, data) {
      var bkm_type = $(this).data('bookmark_type');
      
      var name = $('#new_bookmark_name').val();
      if (name=='') return;

      // Do not save the bm if there is already one with this name
      var exists=false;
      $.each(bookmarks, function(idx, bm){
         if (bm.name == name) {
            exists=true;
         }
      });
      if (exists)  {
         alert('This bookmark name already exists !');
         return;
      }

      // Ok we can save bookmarks in our preferences
      declare_bookmark(name, search_string);
      save_bookmarks();
      
      // Refresh the bookmarks HTML
      $('#modal').modal('hide');
      refresh_bookmarks(search_string);
   });

   // Delete a bookmark ...
   $('body').on("click", '[action="delete-bookmark"]', function (e, data) {
      var bkm = $(this).data('bookmark');
      var bkm_type = $(this).data('bookmark_type');
      if (bkm && bkm_type) {
         if (bkm_type =='global') {
            delete_bookmarkro(bkm);
         } else {
            delete_bookmark(bkm);
         }
         location.reload();
      }
   });

   // Manage bookmarks ...
   $('body').on("click", '[action="manage-bookmarks"]', function (e, data) {
      display_modal('/modal/managebookmarks');
   });

   // Make a bookmark become global ...
   $('body').on("click", '[action="globalize-bookmark"]', function (e, data) {
      var bkm = $(this).data('bookmark');
      var bkm_type = $(this).data('bookmark_type');
      if (bkm && bkm_type == 'user') {
         var exists=false;
         var bookmark = null;
         $.each(bookmarks, function(idx, bm){
            if (bm.name == bkm) {
               exists=true;
               bookmark = bm;
               return false;
            }
         });
         if (exists)  {
            // Do not save the bookmark if there is already one with this name
            exists=false;
            $.each(bookmarksro, function(idx, bm){
               if (bm.name == bkm) {
                  exists=true;
                  return false;
               }
            });
            if (! exists) {
               // Ok we can save bookmarks in our preferences
               declare_bookmarksro(bookmark.name, bookmark.uri);
               delete_bookmark(bkm);
               save_bookmarksro();
            } else { 
               alert('This common bookmark name already exists!');
            }
         }
      }
      
      // Refresh the bookmarks HTML
      $('#modal').modal('hide');
      refresh_bookmarks(search_string);
   });
});
