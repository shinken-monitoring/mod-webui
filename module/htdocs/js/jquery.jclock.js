/*
* jQuery jclock - Clock plugin - v 3.0.0
* http://plugins.jquery.com/project/jclock
*
* Copyright (c) 2007-2014 Doug Sparling <http://www.dougsparling.com>
* Copyright (c) 2016 François-Xavier Choinière <fx@efficks.com>
* 
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:

* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.

* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

/*
* Use options as defined in the Intl.DateTimeFormat parameters
* https://developer.mozilla.org/fr/docs/Web/JavaScript/Reference/Objets_globaux/DateTimeFormat
* This library use the browser default by default.
*/
(function($) {

  $.fn.jclock = function(options) {
    var version = '3.0.0';

    // options
    var opts = $.extend({}, $.fn.jclock.defaults, options);

    return this.each(function() {
      var $this = $(this);
      $this.timerID = null;
      $this.running = false;

      // Record keeping for seeded clock
      $this.increment = 0;
      $this.lastCalled = new Date().getTime();

      var o = $.meta ? $.extend({}, opts, $this.data()) : opts;

      $this.intl = new Intl.DateTimeFormat(o.locale,o);
      $this.seedTime = o.seedTime;
      $this.timeout = o.timeout;

      $this.css({
        fontFamily: o.fontFamily,
        fontSize: o.fontSize,
        backgroundColor: o.background,
        color: o.foreground
      });

      $.fn.jclock.startClock($this);

    });
  };

  $.fn.jclock.startClock = function(el) {
    $.fn.jclock.stopClock(el);
    $.fn.jclock.displayTime(el);
  };

  $.fn.jclock.stopClock = function(el) {
    if(el.running)
      clearTimeout(el.timerID);
    el.running = false;
  };

  /* if the frequency is "once every minute" then we have to make sure this happens
   * when the minute changes. */
  // got this idea from digiclock http://www.radoslavdimov.com/jquery-plugins/jquery-plugin-digiclock/
  function getDelay(timeout) {
    if (timeout == 60000) {
      var now = new Date();
      timeout = 60000 - now.getSeconds() * 1000; // number of seconds before the next minute
    }
    return timeout;
  }

  $.fn.jclock.displayTime = function(el) {
    var time = $.fn.jclock.currentTime(el);
    var formatted_time = el.intl.format(time);
    el.attr('currentTime', time.getTime());
    el.html(formatted_time);
    el.timerID = setTimeout(function(){$.fn.jclock.displayTime(el)}, getDelay(el.timeout));
  };

  $.fn.jclock.currentTime = function(el) {
    if(typeof(el.seedTime) == 'undefined') {
      // Seed time not being used, use current time
      var now = new Date();
    } else {
      // Otherwise, use seed time with increment
      el.increment += new Date().getTime() - el.lastCalled;
      var now = new Date(el.seedTime + el.increment);
      el.lastCalled = new Date().getTime();
    }

    return now;
  };

  // plugin defaults (24-hour)
  $.fn.jclock.defaults = {
    fontFamily: '',
    fontSize: '',
    foreground: '',
    background: '',
	locale: undefined, // Locale string as defined in Intl.DateTimeFormat constructor (https://developer.mozilla.org/fr/docs/Web/JavaScript/Reference/Objets_globaux/DateTimeFormat)
    seedTime: undefined,
    timeout: 1000 // 1000 = one second, 60000 = one minute
  };

})(jQuery);