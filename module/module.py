#!/usr/bin/python

# -*- coding: utf-8 -*-

# Copyright (C) 2009-2014:
#   Gabes Jean, naparuba@gmail.com
#   Gerhard Lausser, Gerhard.Lausser@consol.de
#   Gregory Starck, g.starck@gmail.com
#   Hartmut Goebel, h.goebel@goebel-consult.de
#   Frederic Mohier, frederic.mohier@gmail.com
#
# This file is part of Shinken.
#
# Shinken is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Shinken is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with Shinken.  If not, see <http://www.gnu.org/licenses/>.


WEBUI_VERSION = "2.0 alpha"
WEBUI_COPYRIGHT = "(c) 2009-2015 - License GNU AGPL as published by the FSF, minimum version 3 of the License."
WEBUI_RELEASENOTES = "Bootstrap 3 User Interface"


"""
This Class is a plugin for the Shinken Broker. It is in charge
to get brok and recreate real objects, and propose a Web interface :)
"""

import traceback
import sys
import os
import time
import traceback
import select
import threading
import base64
import cPickle
import imp
import urllib
import hashlib
import json

from shinken.basemodule import BaseModule
from shinken.message import Message
from shinken.misc.regenerator import Regenerator
from shinken.log import logger
from shinken.modulesctx import modulesctx
from shinken.modulesmanager import ModulesManager
from shinken.daemon import Daemon
from shinken.util import safe_print, to_bool
from shinken.misc.filter  import only_related_to
from shinken.misc.sorter import hst_srv_sort, last_state_change_earlier

# Local import
from shinken.misc.datamanager import datamgr
from helper import helper
from config_parser import config_parser
from lib.bottle import Bottle, run, static_file, view, route, request, response, template, redirect

# Debug
import lib.bottle as bottle
bottle.debug(True)

# Import bottle lib to make bottle happy
bottle_dir = os.path.abspath(os.path.dirname(bottle.__file__))
sys.path.insert(0, bottle_dir)

# Look at the webui module root dir too
webuimod_dir = os.path.abspath(os.path.dirname(__file__))
htdocs_dir = os.path.join(webuimod_dir, 'htdocs')

properties = {
    'daemons': ['broker', 'scheduler'],
    'type': 'webui',
    'phases': ['running'],
    'external': True,
    }


# called by the plugin manager to get an instance
def get_instance(plugin):
    # Only add template if we CALL webui
    bottle.TEMPLATE_PATH.append(os.path.join(webuimod_dir, 'views'))
    bottle.TEMPLATE_PATH.append(webuimod_dir)

    instance = Webui_broker(plugin)
    logger.info("[WebUI] got an instance for plugin: %s", plugin.get_name())
    return instance


# Class for the WebUI Broker
class Webui_broker(BaseModule, Daemon):
    def __init__(self, modconf):
        BaseModule.__init__(self, modconf)

        self.plugins = []

        # Web server configuration
        self.host = getattr(modconf, 'host', '0.0.0.0')
        self.port = int(getattr(modconf, 'port', '7767'))
        self.auth_secret = getattr(modconf, 'auth_secret', 'secret').encode('utf8', 'replace')
        
        # TODO : common preferences
        self.play_sound = to_bool(getattr(modconf, 'play_sound', '0'))
        # TODO : common preferences
        self.login_text = getattr(modconf, 'login_text', None)
        # TODO : common preferences
        self.company_logo = getattr(modconf, 'company_logo', 'logo.png')
        # TODO : common preferences
        self.gravatar = to_bool(getattr(modconf, 'gravatar', '0'))
        # TODO : common preferences
        self.allow_html_output = to_bool(getattr(modconf, 'allow_html_output', '0'))
        # TODO : common preferences
        self.max_output_length = int(getattr(modconf, 'max_output_length', '100'))
        # TODO : common preferences
        self.refresh_period = int(getattr(modconf, 'refresh_period', '60'))
        
        # Manage user's ACL
        self.manage_acl = to_bool(getattr(modconf, 'manage_acl', '1'))
        
        # Advanced options
        self.http_backend = getattr(modconf, 'http_backend', 'auto')
        self.remote_user_enable = getattr(modconf, 'remote_user_enable', '0')
        self.remote_user_variable = getattr(modconf, 'remote_user_variable', 'X_REMOTE_USER')
        self.serveropts = {}
        umask = getattr(modconf, 'umask', None)
        if umask != None: 
            self.serveropts['umask'] = int(umask)
        bindAddress = getattr(modconf, 'bindAddress', None)
        if bindAddress:
            self.serveropts['bindAddress'] = str(bindAddress)

        # Load the config dir and make it an absolute path
        self.config_dir = getattr(modconf, 'config_dir', 'share')
        self.config_dir = os.path.abspath(self.config_dir)
        logger.info("[WebUI] Config dir: %s", self.config_dir)

        # Load the share dir and make it an absolute path
        self.share_dir = getattr(modconf, 'share_dir', 'share')
        self.share_dir = os.path.abspath(self.share_dir)
        logger.info("[WebUI] Share dir: %s", self.share_dir)
        
        # Load the photo dir and make it an absolute path
        self.photo_dir = getattr(modconf, 'photo_dir', 'photos')
        self.photo_dir = os.path.abspath(self.photo_dir)
        logger.info("[WebUI] Photo dir: %s", self.photo_dir)

        self.embeded_graph = to_bool(getattr(modconf, 'embeded_graph', '0'))

        # Look for an additional pages dir
        self.additional_plugins_dir = getattr(modconf, 'additional_plugins_dir', '')
        if self.additional_plugins_dir:
            self.additional_plugins_dir = os.path.abspath(self.additional_plugins_dir)
        
        self.timezone = getattr(modconf, 'timezone', 'Europe/Paris')
        if self.timezone:
            logger.info("[WebUI] Setting our timezone to %s", self.timezone)
            os.environ['TZ'] = self.timezone
            time.tzset()
        logger.info("[WebUI] parameter timezone: %s", self.timezone)

        # Hosts filtering
        self.hosts_filter = []
            
        # Web UI information
        self.app_version = getattr(modconf, 'about_version', WEBUI_VERSION)
        self.app_copyright = getattr(modconf, 'about_copyright', WEBUI_COPYRIGHT)
        self.app_release = getattr(modconf, 'about_release', WEBUI_RELEASENOTES)
        
        # We will save all widgets
        self.widgets = {}
        # We need our regenerator now (before main) so if we are in a scheduler,
        # rg will be able to skip some broks
        self.rg = Regenerator()

        self.bottle = bottle
    
    
    # Called by Broker so we can do init stuff
    def init(self):
        logger.info("[WebUI] Initializing ...")
        self.rg.load_external_queue(self.from_q)


    # This is called only when we are in a scheduler
    # and just before we are started. So we can gain time, and
    # just load all scheduler objects without fear :) (we
    # will be in another process, so we will be able to hack objects
    # if need)
    def hook_pre_scheduler_mod_start(self, sched):
        print "pre_scheduler_mod_start::", sched.__dict__
        self.rg.load_from_scheduler(sched)


    # In a scheduler we will have a filter of what we really want as a brok
    def want_brok(self, b):
        return self.rg.want_brok(b)


    def main(self):
        self.set_proctitle(self.name)

        # self.log = logger
        # self.log.load_obj(self)

        # Daemon like init
        self.debug_output = []
        self.modules_dir = modulesctx.get_modulesdir()
        self.modules_manager = ModulesManager('webui', self.find_modules_path(), [])
        self.modules_manager.set_modules(self.modules)
        # We can now output some previously silenced debug output
        self.do_load_modules()
        for inst in self.modules_manager.instances:
            f = getattr(inst, 'load', None)
            if f and callable(f):
                f(self)
        for s in self.debug_output:
            print s
        del self.debug_output

        # Check if the Bottle view dir really exist
        if not os.path.exists(bottle.TEMPLATE_PATH[0]):
            logger.error("[WebUI] The view path do not exist at %s" % bottle.TEMPLATE_PATH)
            sys.exit(2)

        # Check directories
        # We check if the photo directory exists. If not, try to create it
        logger.debug("[WebUI] Checking photo dir: %s", self.photo_dir)
        if not os.path.exists(self.photo_dir):
            try:
                os.mkdir(self.photo_dir)
                logger.info("[WebUI] Created photo dir: %s", self.photo_dir)
            except Exception, exp:
                logger.error("[WebUI] Photo dir creation failed: %s", exp)


        # We check if the share directory exists. If not, try to create it
        logger.debug("[WebUI] Checking share dir: %s", self.share_dir)
        if not os.path.exists(self.share_dir):
            try:
                os.mkdir(self.share_dir)
                logger.info("[WebUI] Created share dir: %s", self.share_dir)
            except Exception, exp:
                logger.error("[WebUI] Share dir creation failed: %s", exp)


        # We check if the config directory exists. If not, try to create it
        logger.debug("[WebUI] Checking config dir: %s", self.config_dir)
        if not os.path.exists(self.config_dir):
            try:
                os.mkdir(self.config_dir)
                logger.info("[WebUI] Created config dir: %s", self.config_dir)
            except Exception, exp:
                logger.error("[WebUI] Config dir creation failed: %s", exp)
        
        
        # We check if we have an user authentication module
        if not self.has_user_authentication_module():
            logger.error("[WebUI] No user authentication module configured. Please configure at least 'modules auth-cfg-password' in webui.cfg file")
            sys.exit(2)
                        
        # We check if we have an user preference module
        if not self.has_user_preference_module():
            logger.warning("[WebUI] No user preference module configured. Preferences will be stored in %s directory. Else, you may configure 'modules mongodb' or 'modules SQLitedb' in webui.cfg file", self.config_dir)
                        
        # Data manager
        self.datamgr = datamgr
        datamgr.load(self.rg)
        self.helper = helper

        self.request = request
        self.response = response
        self.template_call = template
        
        try:
            self.do_main()
        except Exception, exp:
            msg = Message(id=0, type='ICrash', data={'name': self.get_name(), 'exception': exp, 'trace': traceback.format_exc()})
            self.from_q.put(msg)
            # wait 2 sec so we know that the broker got our message, and die
            time.sleep(2)
            raise


    # A plugin send us en external command. We just put it
    # in the good queue
    def push_external_command(self, e):
        logger.info("[WebUI] Got an external command: %s", e.__dict__)
        try:
            self.from_q.put(e)
        except Exception, exp:
            logger.error("[WebUI] External command push, exception: %s", str(exp))


    # Real main function
    def do_main(self):
        # I register my exit function
        self.set_exit_handler()

        # We will protect the operations on
        # the non read+write with a lock and
        # 2 int
        self.global_lock = threading.RLock()
        self.nb_readers = 0
        self.nb_writers = 0

        self.data_thread = None

        # First load the additional plugins so they will have the lead on
        # URI routes
        if self.additional_plugins_dir:
            self.load_plugins(self.additional_plugins_dir)

        # Modules can also override some views if need
        for inst in self.modules_manager.instances:
            f = getattr(inst, 'get_webui_plugins_path', None)
            if f and callable(f):
                mod_plugins_path = os.path.abspath(f(self))
                self.load_plugins(mod_plugins_path)
                

        # Then look at the plugins into core and load all we can there
        core_plugin_dir = os.path.join(os.path.abspath(os.path.dirname(__file__)), 'plugins')
        self.load_plugins(core_plugin_dir)

        # Declare the whole app static files AFTER the plugin ones
        self.declare_common_static()

        # Launch the data thread"
        self.data_thread = threading.Thread(None, self.manage_brok_thread, 'datathread')
        self.data_thread.start()
        # TODO: look for alive and killing

        # Ok, you want to know why we are using a data thread instead of
        # just call for a select with q._reader, the underlying file
        # handle of the Queue()? That's just because under Windows, select
        # only manage winsock (so network) file descriptor! What a shame!
        logger.info("[WebUI] starting Web UI server ...")
        srv = run(host=self.host, port=self.port, server=self.http_backend, **self.serveropts)

        # ^ IMPORTANT ^
        # We are not managing the lock at this
        # level because we got 2 types of requests:
        # static images/css/js: no need for lock
        # pages: need it. So it's managed at a
        # function wrapper at loading pass


    # It will say if we can launch a page rendering or not.
    # We can only if there is no writer running from now
    def wait_for_no_writers(self):
        can_run = False
        while True:
            self.global_lock.acquire()
            # We will be able to run
            if self.nb_writers == 0:
                # Ok, we can run, register us as readers
                self.nb_readers += 1
                self.global_lock.release()
                break
            # Oups, a writer is in progress. We must wait a bit
            self.global_lock.release()
            # Before checking again, we should wait a bit
            # like 1ms
            time.sleep(0.001)


    # It will say if we can launch a brok management or not
    # We can only if there is no readers running from now
    def wait_for_no_readers(self):
        start = time.time()
        while True:
            self.global_lock.acquire()
            # We will be able to run
            if self.nb_readers == 0:
                # Ok, we can run, register us as writers
                self.nb_writers += 1
                self.global_lock.release()
                break
            # Ok, we cannot run now, wait a bit
            self.global_lock.release()
            # Before checking again, we should wait a bit
            # like 1ms
            time.sleep(0.001)
            # We should warn if we cannot update broks
            # for more than 30s because it can be not good
            if time.time() - start > 30:
                print "WARNING: we are in lock/read since more than 30s!"
                start = time.time()


    # We want a lock manager version of the plugin functions
    def lockable_function(self, f):
        def lock_version(**args):
            self.wait_for_no_writers()
            try:
                return f(**args)
            finally:
                # We can remove us as a reader from now. It's NOT an atomic operation
                # so we REALLY not need a lock here (yes, I try without and I got
                # a not so accurate value there....)
                self.global_lock.acquire()
                self.nb_readers -= 1
                self.global_lock.release()
                
        return lock_version


    # It's the thread function that will get broks
    # and update data. Will lock the whole thing
    # while updating
    def manage_brok_thread(self):
        logger.debug("[WebUI] manage_brok_thread start ...")

        while True:
            l = self.to_q.get()

            # try to relaunch dead module (like mongo one when mongo is not available at startup for example)
            self.check_and_del_zombie_modules()

            logger.debug("[WebUI] manage_brok_thread got %d broks", len(l))
            for b in l:
                b.prepare()
                self.wait_for_no_readers()
                try:
                    self.rg.manage_brok(b)

                    for mod in self.modules_manager.get_internal_instances():
                        try:
                            mod.manage_brok(b)
                        except Exception, exp:
                            logger.warning("[WebUI] The mod %s raise an exception: %s, I'm tagging it to restart later", mod.get_name(), str(exp))
                            logger.debug("[WebUI] Exception type: %s", self.name, type(exp))
                            logger.debug("[WebUI] Back trace of this kill: %s", traceback.format_exc())
                            self.modules_manager.set_to_restart(mod)
                except Exception, exp:
                    logger.error("[WebUI] manage_brok_thread exception")
                    msg = Message(id=0, type='ICrash', data={'name': self.get_name(), 'exception': exp, 'trace': traceback.format_exc()})
                    self.from_q.put(msg)
                    # wait 2 sec so we know that the broker got our message, and die
                    time.sleep(2)
                    # No need to raise here, we are in a thread, exit!
                    os._exit(2)
                finally:
                    logger.debug("[WebUI] manage_brok_thread finally")
                    # We can remove us as a writer from now. It's NOT an atomic operation
                    # so we REALLY not need a lock here (yes, I try without and I got
                    # a not so accurate value there....)
                    self.global_lock.acquire()
                    self.nb_writers -= 1
                    self.global_lock.release()

        logger.debug("[WebUI] manage_brok_thread end ...")


    # Here we will load all plugins (pages) under the webui/plugins
    # directory. Each one can have a page, views and htdocs dir that we must
    # route correctly
    def load_plugins(self, plugin_dir):
        logger.info("[WebUI] load plugins directory: %s", plugin_dir)

        # Load plugin directories
        if not os.path.exists(plugin_dir):
            logger.error("[WebUI] load plugins directory does not exist: %s", plugin_dir)
            return
        
        plugin_dirs = [fname for fname in os.listdir(plugin_dir)
                       if os.path.isdir(os.path.join(plugin_dir, fname))]

        sys.path.append(plugin_dir)
        
        # Try to import all found plugins
        for fdir in plugin_dirs:
            self.load_plugin(fdir, plugin_dir)
    

    # Load a WebUI plugin
    def load_plugin(self, fdir, plugin_dir):
        logger.debug("[WebUI] loading plugin %s ...", fdir)
        try:
            # Put the full qualified path of the module we want to load
            # for example we will give  webui/plugins/eltdetail/
            mod_path = os.path.join(plugin_dir, fdir)
            # Then we load the eltdetail.py inside this directory
            m = imp.load_module('%s' % (fdir), *imp.find_module(fdir, [mod_path]))
            m_dir = os.path.abspath(os.path.dirname(m.__file__))
            sys.path.append(m_dir)

            logger.debug("[WebUI] loaded plugin %s", fdir)
            pages = m.pages
            for (f, entry) in pages.items():
                routes = entry.get('routes', None)
                v = entry.get('view', None)
                static = entry.get('static', False)
                widget_lst = entry.get('widget', [])
                widget_desc = entry.get('widget_desc', None)
                widget_name = entry.get('widget_name', None)
                widget_picture = entry.get('widget_picture', None)

                # IMPORTANT: apply VIEW BEFORE route!
                if v:
                    f = view(v)(f)

                # Maybe there is no route to link, so pass
                if routes:
                    for r in routes:
                        method = entry.get('method', 'GET')

                        # Ok, we will just use the lock for all
                        # plugin page, but not for static objects
                        # so we set the lock at the function level.
                        lock_version = self.lockable_function(f)
                        f = route(r, callback=lock_version, method=method)

                # If the plugin declare a static entry, register it
                # and remember: really static! because there is no lock
                # for them!
                if static:
                    self.add_static_route(fdir, m_dir)

                # It's a valid widget entry if it got all data, and at least one route
                # ONLY the first route will be used for Add!
                #print "Should I load a widget?",widget_name, widget_desc, widget_lst!=[], routes
                if widget_name and widget_desc and widget_lst != [] and routes:
                    for place in widget_lst:
                        if place not in self.widgets:
                            self.widgets[place] = []
                        w = {'widget_name': widget_name, 'widget_desc': widget_desc, 'base_uri': routes[0],
                             'widget_picture': widget_picture}
                        self.widgets[place].append(w)

            # And we add the views dir of this plugin in our TEMPLATE
            # PATH
            bottle.TEMPLATE_PATH.append(os.path.join(m_dir, 'views'))

            # And finally register me so the pages can get data and other
            # useful stuff
            m.app = self


        except Exception, exp:
            logger.error("[WebUI] loading plugin %s, exception: %s", fdir, exp)
    
    
    # Add static route in the Web server
    def add_static_route(self, fdir, m_dir):
        logger.debug("[WebUI] add static route: %s", fdir)
        static_route = '/static/' + fdir + '/:path#.+#'

        def plugin_static(path):
            return static_file(path, root=os.path.join(m_dir, 'htdocs'))
        route(static_route, callback=plugin_static)


    def declare_common_static(self):
        @route('/static/photos/:path#.+#')
        def give_photo(path):
            # TODO: check if ok, return default Shinken user photo
            # If the file really exist, give it. If not, give a dummy image.
            if os.path.exists(os.path.join(self.photo_dir, path+'.png')):
                return static_file(path+'.png', root=self.photo_dir)
            else:
                return static_file('images/user.png', root=htdocs_dir)

        # Route static files css files
        @route('/static/:path#.+#')
        def server_static(path):
            # By default give from the root in bottle_dir/htdocs. If the file is missing,
            # search in the share dir
            root = htdocs_dir
            p = os.path.join(root, path)
            if not os.path.exists(p):
                root = self.share_dir
            return static_file(path, root=root)

        # And add the favicon ico too
        @route('/favicon.ico')
        def give_favicon():
            return static_file('favicon.ico', root=os.path.join(htdocs_dir, 'images'))

    # --------------------------------------------------------------------------------
    # User authentication / management
    # --------------------------------------------------------------------------------
    # Do we have an user authentication module
    def has_user_authentication_module(self):
        for mod in self.modules_manager.get_internal_instances():
            f = getattr(mod, 'check_auth', None)
            if f and callable(f):
                return True
        return False
        

    ##
    # Check if provided username/password is accepted for login the Web UI
    #
    # Several steps:
    # 1/ username must be in the known contacts of Shinken
    # 2/ one of the WebUI modules providing a 'check_auth' 
    #   method must accept the username/password couple
    ##
    def check_authentication(self, username, password):
        logger.info("[WebUI] Checking authentication for user: %s", username)
        c = self.datamgr.get_contact(username)
        if not c:
            logger.error("[WebUI] You need to have a contact having the same name as your user: %s", username)
            return False

        is_ok = False
        for mod in self.modules_manager.get_internal_instances():
            try:
                f = getattr(mod, 'check_auth', None)
                logger.debug("[WebUI] Check auth with: %s, for %s", mod.get_name(), username)
                if f and callable(f):
                    r = f(username, password)
                    if r:
                        is_ok = True
                        # No need for other modules
                        logger.info("[WebUI] User '%s' is authenticated by %s", username, mod.get_name())
                        break
            except Exception, exp:
                print exp.__dict__
                logger.warning("[WebUI] The mod %s raise an exception: %s, I'm tagging it to restart later", mod.get_name(), str(exp))
                logger.debug("[WebUI] Exception type: %s", type(exp))
                logger.debug("Back trace of this kill: %s" % (traceback.format_exc()))
                self.modules_manager.set_to_restart(mod)

        # Ok if we got a real contact, and if a module auth it
        return (is_ok and c is not None)

    ##
    # Return currently logged in user
    #
    # If anonymous is requested and anonymous contact exists, 
    # returns the anonymous contact
    ##
    def get_user_auth(self, allow_anonymous=False):
        """
        Given an email, returns a gravatar url for that email.
        
        From : https://fr.gravatar.com/site/implement/images/

        :param basestring email:
        :rtype: basestring
        :return: The gravatar url for the given email.
        """
        # First we look for the user sid
        # so we bail out if it's a false one
        user_name = self.request.get_cookie("user", secret=self.auth_secret)

        # If we cannot check the cookie, bailout ... 
        if not allow_anonymous and not user_name:
            return None
            
        # Allow anonymous access if requested and anonymous contact exists ...
        if allow_anonymous:
            c = self.get_contact('anonymous')
            if c:
                return c

        c = self.get_contact(user_name)
        return c

    ##
    # Check if a user is currently logged in
    ##
    def check_user_authentication(self):
        """
        Given an email, returns a gravatar url for that email.
        
        From : https://fr.gravatar.com/site/implement/images/

        :param basestring email:
        :rtype: basestring
        :return: The gravatar url for the given email.
        """
        user = self.get_user_auth()
        if not user:
            self.bottle.redirect("/user/login")
        else:
            return user
            
    def get_gravatar(self, email, size=64, default='404'):
        """
        Given an email, returns a gravatar url for that email.
        
        From : https://fr.gravatar.com/site/implement/images/

        :param basestring email:
        :rtype: basestring
        :return: The gravatar url for the given email.
        """
        parameters = { 's' : size, 'd' : default}
        url = "https://secure.gravatar.com/avatar/%s?%s" % (hashlib.md5(email.lower()).hexdigest(), urllib.urlencode(parameters))
        return url


    # ------------------------------------------------------------------------------------------
    # Manage embedded graphs
    # ------------------------------------------------------------------------------------------
    # Try to got for an element the graphs uris from modules
    # The source variable describes the source of the calling. Are we displaying 
    # graphs for the element detail page (detail), or a widget in the dashboard (dashboard) ?
    def get_graph_uris(self, elt, graphstart, graphend, source = 'detail'):
        logger.debug("[WebUI] Fetching graph URIs ...")

        uris = []
        for mod in self.modules_manager.get_internal_instances():
            try:
                logger.debug("[WebUI] module %s, get_graph_uris", mod)
                f = getattr(mod, 'get_graph_uris', None)
                #safe_print("Get graph uris ", f, "from", mod.get_name())
                if f and callable(f):
                    r = f(elt, graphstart, graphend, source)
                    uris.extend(r)
            except Exception, exp:
                logger.warning("[WebUI] The mod %s raise an exception: %s, I'm tagging it to restart later", mod.get_name(), str(exp))
                logger.debug("[WebUI] Exception type: %s", type(exp))
                logger.debug("Back trace of this kill: %s", traceback.format_exc())
                self.modules_manager.set_to_restart(mod)

        return uris

    def get_graph_img_src(self,uri,link):
        url=uri
        lk=link
        if self.embeded_graph:
            data = urllib.urlopen(uri, 'rb').read().encode('base64').replace('\n', '')
            url="data:image/png;base64,{0}".format(data)
            lk=''
        return (url,lk)
        
    # ------------------------------------------------------------------------------------------
    # Manage common / user's preferences
    # ------------------------------------------------------------------------------------------
    ##
    # Check if a user preference storage module is declared in webui.cfg
    ##
    def has_user_preference_module(self):
        for mod in self.modules_manager.get_internal_instances():
            f = getattr(mod, 'get_ui_user_preference', None)
            if f and callable(f):
                return True
        return False
        

    ##
    # Get all user preferences 
    ##
    def get_user_preferences(self):
        logger.debug("[WebUI] Fetching all user preferences ...")

        return self.get_user_preference(self.get_user_auth())
        
    ##
    # Get a user preference by name 
    ##
    def get_user_preference(self, user, key=None, default=None):
        logger.debug("[WebUI] Fetching user preference for: %s / %s", user.get_name(), key)

        if not self.has_user_preference_module():
            result = {} if key is None else default
            # Preferences are stored in self.config_dir/user.get_name()/key
            for subdir, dirs, files in os.walk("%s/%s" % (self.config_dir, user.get_name())):
                for file in files:
                    logger.debug("[WebUI] found %s file, key = %s", file, key)
                    try:
                        f=open("%s/%s/%s" % (self.config_dir, user.get_name(), file), 'r')
                        lines=f.read()
                        f.close()
                    except:
                        pass

                    if key is not None and file == "%s"%key:
                        logger.debug("[WebUI] found key = %s", lines)
                        return lines
                    elif key is None:
                        # result.append( { file: lines } )
                        result[file] = lines
        
            logger.debug("[WebUI] User preference %s, returning: %s", key, result)
            return result
        
        for mod in self.modules_manager.get_internal_instances():
            try:
                logger.debug("[WebUI] Trying to get preference %s from %s", key, mod.get_name())
                f = getattr(mod, 'get_ui_user_preference', None)
                if f and callable(f):
                    r = f(user, key)
                    logger.debug("[WebUI] Found '%s', %s = %s", user.get_name(), key, r)
                    if r is not None:
                        return r
            except Exception, exp:
                logger.warning("[WebUI] The mod %s raise an exception: %s, I'm tagging it to restart later", mod.get_name(), str(exp))
                logger.warning("[WebUI] Exception type: %s", type(exp))
                logger.warning("Back trace of this kill: %s", traceback.format_exc())
                self.modules_manager.set_to_restart(mod)
                
        logger.debug("[WebUI] No user preferences found, returning default value: %s", default)
        return default

    ##
    # Set a user preference by name / value 
    ##
    def set_user_preference(self, user, key, value):
        logger.debug("[WebUI] Saving user preference for: %s / %s", user.get_name(), key)

        if not self.has_user_preference_module():
            dir = "%s/%s" % (self.config_dir, user.get_name())
            if not os.path.exists(dir):
                try:
                    os.mkdir(dir)
                    logger.debug("[WebUI] Created user preferences directory: %s", dir)
                except Exception, exp:
                    logger.error("[WebUI] User preference directory creation failed: %s", exp)
                    
            # Preferences are stored in self.config_dir/user.get_name()/key
            f=open("%s/%s" % (dir, key),'w')
            f.write(value)
            f.close()
            logger.debug("[WebUI] Updated '%s', %s = %s", user.get_name(), key, value)
        
        else:
            for mod in self.modules_manager.get_internal_instances():
                try:
                    f = getattr(mod, 'set_ui_user_preference', None)
                    if f and callable(f):
                        f(user, key, value)
                        logger.debug("[WebUI] Updated '%s', %s = %s", user.get_name(), key, value)
                except Exception, exp:
                    logger.warning("[WebUI] The mod %s raise an exception: %s, I'm tagging it to restart later", mod.get_name(), str(exp))
                    logger.warning("[WebUI] Exception type: %s", type(exp))
                    logger.warning("Back trace of this kill: %s", traceback.format_exc())
                    self.modules_manager.set_to_restart(mod)

    ##
    # Get a common preference by name 
    ##
    def get_common_preference(self, key, default=None):
        logger.debug("[WebUI] Fetching common preference for: %s", key)

        if not self.has_user_preference_module():
            result = [] if key is None else default
            # Preferences are stored in self.config_dir/user.get_name()/key
            for subdir, dirs, files in os.walk("%s/%s" % (self.config_dir, 'common')):
                for file in files:
                    logger.debug("[WebUI] found %s file, key = %s", file, key)
                    try:
                        f=open("%s/%s/%s" % (self.config_dir, 'common', file), 'r')
                        lines=f.read()
                        f.close()
                    except:
                        pass

                    if key is not None and file == "%s"%key:
                        logger.debug("[WebUI] found key = %s", lines)
                        return lines
                    elif key is None:
                        result.append(lines)
        
            logger.debug("[WebUI] No common preferences found for %s, returning default value: %s", key, default)
            return result
        
        for mod in self.modules_manager.get_internal_instances():
            try:
                logger.debug("[WebUI] Trying to get common preference %s from %s", key, mod.get_name())
                f = getattr(mod, 'get_ui_common_preference', None)
                if f and callable(f):
                    r = f(key)
                    logger.debug("[WebUI] Found 'common', %s = %s", key, r)
                    if r is not None:
                        return r
            except Exception, exp:
                logger.warning("[WebUI] The mod %s raise an exception: %s, I'm tagging it to restart later", mod.get_name(), str(exp))
                logger.warning("[WebUI] Exception type: %s", type(exp))
                logger.warning("Back trace of this kill: %s", traceback.format_exc())
                self.modules_manager.set_to_restart(mod)
                
        logger.debug("[WebUI] No common preferences found, returning default value: %s", default)
        return default

    ##
    # Set a common preference by name / value
    ##
    def set_common_preference(self, key, value):
        logger.debug("[WebUI] Saving common preference: %s = %s", key, value)

        if not self.has_user_preference_module():
            dir = "%s/common" % (self.config_dir)
            if not os.path.exists(dir):
                try:
                    os.mkdir(dir)
                    logger.debug("[WebUI] Created common preferences directory: %s", dir)
                except Exception, exp:
                    logger.error("[WebUI] Common preference directory creation failed: %s", exp)
                    
            # Preferences are stored in self.config_dir/user.get_name()/key
            f=open("%s/%s" % (dir, key),'w')
            f.write(value)
            f.close()
            logger.debug("[WebUI] Updated '%s', %s = %s", 'common', key, value)
        
        else:
            for mod in self.modules_manager.get_internal_instances():
                try:
                    f = getattr(mod, 'set_ui_common_preference', None)
                    if f and callable(f):
                        f(key, value)
                        logger.debug("[WebUI] Updated 'common', %s = %s", key, value)
                except Exception, exp:
                    logger.warning("[WebUI] The mod %s raise an exception: %s, I'm tagging it to restart later", mod.get_name(), str(exp))
                    logger.warning("[WebUI] Exception type: %s", type(exp))
                    logger.warning("Back trace of this kill: %s", traceback.format_exc())
                    self.modules_manager.set_to_restart(mod)


    def get_user_bookmarks(self, user):
        ''' Returns the user bookmarks. '''
        return json.loads(self.get_user_preference(user, 'bookmarks') or '[]')


    def get_common_bookmarks(self):
        ''' Returns the common bookmarks. '''
        return json.loads(self.get_common_preference('bookmarks') or '[]')


    # TODO : move this function to dashboard plugin
    # For a specific place like dashboard we return widget lists
    def get_widgets_for(self, place):
        return self.widgets.get(place, [])


    ##
    # External UI links for other modules
    # ------------------------------------------------------------------------------------------
    # Web UI modules may implement a 'get_external_ui_link' function to provide an extra menu
    # in the Web UI. This function must return: 
    # {'label': 'Menu item', 'uri': 'http://...'}
    ##
    def get_ui_external_links(self):
        logger.debug("[WebUI] Fetching UI external links ...")

        lst = []
        for mod in self.modules_manager.get_internal_instances():
            try:
                f = getattr(mod, 'get_external_ui_link', None)
                if f and callable(f):
                    r = f()
                    lst.append(r)
            except Exception, exp:
                logger.warning("[WebUI] Warning: The mod %s raise an exception: %s, I'm tagging it to restart later", mod.get_name(), str(exp))
                logger.debug("[WebUI] Exception type: %s", type(exp))
                logger.debug("Back trace of this kill: %s", traceback.format_exc())
                self.modules_manager.set_to_restart(mod)

        return lst


    ##
    # Relocate those function in a dedicated datamanager ... 
    # WebUI has some kind of abstraction layer when accessing to Shinken data model!
    ##
    def get_hosts(self, user=None):
        items=self.datamgr.get_hosts()
        r = set()
        for h in items:
            filtered = False
            for filter in self.hosts_filter:
                if h.host_name.startswith(filter):
                    filtered = True
            if not filtered:
                    r.add(h)
                    
        if user is not None:
            r=only_related_to(r,user)

        return r
                  
    def get_services(self, user=None):
        items=self.datamgr.get_services()
        if user is not None:
            return only_related_to(items,user)

        return items

    def get_host(self, hname):
        hname = hname.decode('utf8', 'ignore')
        return self.rg.hosts.find_by_name(hname)

    def get_service(self, hname, sdesc):
        hname = hname.decode('utf8', 'ignore')
        sdesc = sdesc.decode('utf8', 'ignore')
        return self.rg.services.find_srv_by_name_and_hostname(hname, sdesc)

    def get_all_hosts_and_services(self, user=None, get_impacts=True):
        all = []
        if get_impacts:
            all.extend(self.get_hosts())
            all.extend(self.get_services())
        else:
            all.extend([h for h in self.get_hosts() if not h.is_impact])
            all.extend([s for s in self.get_services() if not s.is_impact])
        return all

    def get_timeperiods(self):
        return self.datamgr.rg.timeperiods
                  
    def get_timeperiod(self, name):
        return self.datamgr.rg.timeperiods.find_by_name(name)
    
    def get_commands(self):
        return self.datamgr.rg.commands
                  
    def get_command(self, name):
        name = name.decode('utf8', 'ignore')
        return self.datamgr.rg.commands.find_by_name(name)

    def get_contacts(self):
        return self.datamgr.rg.contacts
                  
    def get_contact(self, name):
        name = name.decode('utf8', 'ignore')
        return self.datamgr.rg.contacts.find_by_name(name)

    def get_contactgroups(self):
        # return self.datamgr.get_contactgroups()
        return self.datamgr.rg.contactgroups
                  
    def get_contactgroup(self, name):
        name = name.decode('utf8', 'ignore')
        return self.datamgr.rg.contactgroups.find_by_name(name)

    def set_hostgroups_level(self, user=None):
        logger.debug("[WebUI] set_hostgroups_level")
        
        # All known hostgroups are level 0 groups ...
        for group in self.get_hostgroups(user=user):
            self.set_hostgroup_level(group, 0, user)
        
    def set_hostgroup_level(self, group, level, user=None):
        logger.debug("[WebUI] set_hostgroup_level, group: %s, level: %d", group.hostgroup_name, level)
        
        setattr(group, 'level', level)
                
        # Search hostgroups referenced in another group
        if group.has('hostgroup_members'):
            for g in sorted(group.get_hostgroup_members()):
                logger.debug("[WebUI] set_hostgroups_level, group: %s, level: %d", g, group.level + 1)
                child_group = self.get_hostgroup(g)
                self.set_hostgroup_level(child_group, level + 1, user)
        
    def get_hostgroups(self, user=None):
        items=self.datamgr.rg.hostgroups
        
        r = set()
        for g in items:
            filtered = False
            for filter in self.hosts_filter:
                if g.hostgroup_name.startswith(filter):
                    filtered = True
            if not filtered:
                    r.add(g)
                    
        if user is not None:
            r=only_related_to(r,user)

        return r

    def get_hostgroup(self, name):
        return self.datamgr.rg.hostgroups.find_by_name(name)
                  
    def set_servicegroups_level(self, user=None):
        logger.debug("[WebUI] set_servicegroups_level")
        
        # All known hostgroups are level 0 groups ...
        for group in self.get_servicegroups(user=user):
            self.set_servicegroup_level(group, 0, user)
        
    def set_servicegroup_level(self, group, level, user=None):
        logger.debug("[WebUI] set_servicegroup_level, group: %s, level: %d", group.servicegroup_name, level)
        
        setattr(group, 'level', level)
                
        # Search hostgroups referenced in another group
        if group.has('servicegroup_members'):
            for g in sorted(group.get_servicegroup_members()):
                logger.debug("[WebUI] set_servicegroups_level, group: %s, level: %d", g, group.level + 1)
                child_group = self.get_servicegroup(g)
                self.set_servicegroup_level(child_group, level + 1, user)
        
    def get_servicegroups(self, user=None):
        items = self.datamgr.rg.servicegroups
        
        r = set()
        for g in items:
            filtered = False
            for filter in self.services_filter:
                if g.servicegroup_name.startswith(filter):
                    filtered = True
            if not filtered:
                    r.add(g)
                    
        if user is not None:
            r=only_related_to(r,user)

        return r

    def get_servicegroup(self, name):
        return self.datamgr.rg.servicegroups.find_by_name(name)
                  
    # Get the hosts tags sorted by names, and zero size in the end
    def get_host_tags_sorted(self):
        r = []
        names = self.datamgr.rg.tags.keys()
        names.sort()
        for n in names:
            r.append((n, self.datamgr.rg.tags[n]))
        return r

    # Get the hosts tagged with a specific tag
    def get_hosts_tagged_with(self, tag):
        r = []
        for h in self.get_hosts():
            if tag in h.get_host_tags():
                r.append(h)
        return r

    # Get the services tags sorted by names, and zero size in the end
    def get_service_tags_sorted(self):
        r = []
        names = self.datamgr.rg.services_tags.keys()
        names.sort()
        for n in names:
            r.append((n, self.datamgr.rg.services_tags[n]))
        return r

    # Get the services tagged with a specific tag
    def get_services_tagged_with(self, tag):
        r = []
        for s in self.get_services():
            if tag in s.get_service_tags():
                r.append(s)
        return r

    ##
    # Problems management
    ##
    # Returns all problems
    # TODO: Not really useful ... to be confirmed !
    def get_all_problems(self, user=None, to_sort=True, get_acknowledged=False):
        res = []
        if not get_acknowledged:
            res.extend([s for s in self.get_services(user) if s.state not in ['OK', 'PENDING'] and not s.is_impact and not s.problem_has_been_acknowledged and not s.host.problem_has_been_acknowledged])
            res.extend([h for h in self.get_hosts(user) if h.state not in ['UP', 'PENDING'] and not h.is_impact and not h.problem_has_been_acknowledged])
        else:
            res.extend([s for s in self.get_services(user) if s.state not in ['OK', 'PENDING'] and not s.is_impact])
            res.extend([h for h in self.get_hosts(user) if h.state not in ['UP', 'PENDING'] and not h.is_impact])

        if to_sort:
            res.sort(hst_srv_sort)
        return res

    # Return the number of problems
    def get_nb_problems(self, user=None, to_sort=True, get_acknowledged=False):
        return len(self.get_all_problems(user, to_sort, get_acknowledged))
        
    # For all business impacting elements, and give the worse state
    # if warning or critical
    def get_overall_state(self, user=None):
        h_states = [h.state_id for h in self.get_hosts(user) if h.business_impact > 2 and h.is_impact and h.state_id in [1, 2]]
        s_states = [s.state_id for s in self.get_services(user) if s.business_impact > 2 and s.is_impact and s.state_id in [1, 2]]
        if len(h_states) == 0:
            h_state = 0
        else:
            h_state = max(h_states)
        if len(s_states) == 0:
            s_state = 0
        else:
            s_state = max(s_states)

        return max(h_state, s_state)

     # For all business impacting elements, and give the worse state
    # if warning or critical
    def get_overall_state_problems_count(self, user=None):
        h_states = [h.state_id for h in self.get_hosts(user) if h.business_impact > 2 and h.is_impact and h.state_id in [1, 2]]
        logger.debug("[WebUI] get_overall_state_problems_count, hosts: %d", len(h_states))
        s_states = [s.state_id for s in self.get_services(user) if  s.business_impact > 2 and s.is_impact and s.state_id in [1, 2]]
        logger.debug("[WebUI] get_overall_state_problems_count, hosts+services: %d", len(s_states))
        
        return len(h_states) + len(s_states)

   # Same but for pure IT problems
    def get_overall_it_state(self, user=None):
        h_states = [h.state_id for h in self.get_hosts(user) if h.is_problem and h.state_id in [1, 2]]
        s_states = [s.state_id for s in self.get_services(user) if s.is_problem and s.state_id in [1, 2]]
        if len(h_states) == 0:
            h_state = 0
        else:
            h_state = max(h_states)
        if len(s_states) == 0:
            s_state = 0
        else:
            s_state = max(s_states)
            
        return max(h_state, s_state)

    # Get the number of all problems, even the ack ones
    def get_overall_it_problems_count(self, user=None, get_acknowledged=False):
        logger.debug("[WebUI] get_overall_it_problems_count, user: %s, get_acknowledged: %d", user.contact_name, get_acknowledged)
        
        if not get_acknowledged:
            h_states = [h for h in self.get_hosts(user) if h.state not in ['UP', 'PENDING'] and not h.is_impact and not h.problem_has_been_acknowledged]
            s_states = [s for s in self.get_services(user) if s.state not in ['OK', 'PENDING'] and not s.is_impact and not s.problem_has_been_acknowledged and not s.host.problem_has_been_acknowledged]
        else:
            h_states = [h for h in self.get_hosts(user) if h.state not in ['UP', 'PENDING'] and not h.is_impact]
            s_states = [s for s in self.get_services(user) if s.state not in ['OK', 'PENDING'] and not s.is_impact]
            
        logger.debug("[WebUI] get_overall_it_problems_count, hosts: %d", len(h_states))
        logger.debug("[WebUI] get_overall_it_problems_count, services: %d", len(s_states))
        
        return len(h_states) + len(s_states)

    # Get percentage of all Services
    def get_percentage_service_state(self, user=None):
        all_services = self.get_services(user)
        problem_services = []
        problem_services.extend([s for s in all_services if s.state not in ['OK', 'PENDING'] and not s.is_impact])
        if len(all_services) == 0:
            res = 0
        else:
            res = int(100-(len(problem_services) *100)/float(len(all_services)))
        return res
              
    # Get percentage of all Hosts
    def get_percentage_hosts_state(self, user=None):
        all_hosts = self.get_hosts(user)
        problem_hosts = []
        problem_hosts.extend([s for s in all_hosts if s.state not in ['UP', 'PENDING'] and not s.is_impact])
        if len(all_hosts) == 0:
            res = 0
        else:
            res = int(100-(len(problem_hosts) *100)/float(len(all_hosts)))
        return res
