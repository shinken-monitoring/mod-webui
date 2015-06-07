/*Copyright (C) 2009-2013 :
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

/***************************************************************************/

/**
 * Some browser do NOT have indexOf for arrays... so we add it!
**/
if(!Array.indexOf){
    Array.prototype.indexOf = function(obj){
        for(var i=0; i<this.length; i++){
            if(this[i]==obj){
                return i;
            }
        }
        return -1;
    }
}

/**
 * Save current user preference value: 
 * - key / value
 * - callback function called after data are posted
**/
function save_user_preference(key, value, callback) {
   $.post("/user/save_pref", { 'key' : key, 'value' : value}, function() {
      raise_message_ok("User parameter "+key+" set to "+value);
      if (callback)
         window[callback]();
   });
}

/**
 * Save common preference value
 * - key / value
 * - callback function called after data are posted
**/
function save_common_preference(key, value, callback) {
   $.post("/user/save_common_pref", { 'key' : key, 'value' : value}, function() {
      raise_message_ok("Common parameter "+key+" set to "+value);
      if (callback)
         window[callback]();
   });
}
