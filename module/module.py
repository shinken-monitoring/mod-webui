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
import hashlib
import json
import re
import itertools

from shinken.basemodule import BaseModule
from shinken.message import Message
from shinken.misc.regenerator import Regenerator
# from webui_regenerator import WebUIRegenerator
from shinken.log import logger
from shinken.modulesctx import modulesctx
from shinken.modulesmanager import ModulesManager
from shinken.daemon import Daemon
from shinken.util import safe_print, to_bool
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
        self.company_logo = getattr(modconf, 'company_logo', 'default_company')
        if self.company_logo=='':
            # Set a dummy value if webui.cfg value is empty to force using the default logo ...
            self.company_logo = 'abcdef'
        # TODO : common preferences
        self.gravatar = to_bool(getattr(modconf, 'gravatar', '0'))
        # TODO : common preferences
        self.allow_html_output = to_bool(getattr(modconf, 'allow_html_output', '0'))
        # TODO : common preferences
        self.max_output_length = int(getattr(modconf, 'max_output_length', '100'))
        # TODO : common preferences
        self.refresh_period = int(getattr(modconf, 'refresh_period', '60'))
        # Use element tag as image or use text
        self.tag_as_image = bool(getattr(modconf, 'tag_as_image', False))
        
        # Manage user's ACL
        self.manage_acl = to_bool(getattr(modconf, 'manage_acl', '1'))
        self.allow_anonymous = to_bool(getattr(modconf, 'allow_anonymous', '0'))
        
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
        self.photo_dir = getattr(modconf, 'photos_dir', 'photos')
        self.photo_dir = os.path.abspath(self.photo_dir)
        logger.info("[WebUI] Photo dir: %s", self.photo_dir)
        
        self.user_picture = ''

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

        # Visual alerting thresholds
        # Used in the dashboard view to select background color for percentages
        self.hosts_states_warning       = int(getattr(modconf, 'hosts_states_warning', '95'))
        self.hosts_states_critical      = int(getattr(modconf, 'hosts_states_critical', '90'))
        self.services_states_warning    = int(getattr(modconf, 'services_states_warning', '95'))
        self.services_states_critical   = int(getattr(modconf, 'services_states_critical', '90'))

        # Web UI information
        self.app_version = getattr(modconf, 'about_version', WEBUI_VERSION)
        self.app_copyright = getattr(modconf, 'about_copyright', WEBUI_COPYRIGHT)
        self.app_release = getattr(modconf, 'about_release', WEBUI_RELEASENOTES)
        
        # We will save all widgets
        self.widgets = {}
        
        # We need our regenerator now (before main) so if we are in a scheduler,
        # rg will be able to skip some broks
        # self.rg = WebUIRegenerator()
        self.rg = Regenerator()
        
        # Mu bottle object ...
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

        # We check if we have an availability module
        self.get_availability = None
        if not self.has_availability_module():
            logger.warning("[WebUI] No availability module configured. You should configure the module 'mongo-logs' in your broker and the module 'mongodb' in webui.cfg file to get hosts availability information.")

        # We check if we have an history module
        self.get_history = None
        if not self.has_history_module():
            logger.warning("[WebUI] No history module configured. You should configure the module 'mongo-logs' in your broker and the module 'mongodb' in webui.cfg file to get hosts history information.")

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

            # Load plugin configuration
            f = getattr(m, 'load_config', None)
            if f and callable(f):
                logger.debug("[WebUI] calling plugin %s, load configuration", fdir)
                f(self)
                
            logger.info("[WebUI] loaded plugin %s", fdir)

        except Exception, exp:
            logger.error("[WebUI] loading plugin %s, exception: %s", fdir, str(exp))
    
    
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
            # If the file really exist, give it. If not, give a dummy image.
            if os.path.exists(os.path.join(self.photo_dir, path+'.png')):
                return static_file(path+'.png', root=self.photo_dir)
            else:
                return static_file('images/default_user.png', root=htdocs_dir)

        @route('/static/logo/:path#.+#')
        def give_logo(path):
            # If the file really exist, give it. If not, give a dummy image.
            if os.path.exists(os.path.join(self.photo_dir, path+'.png')):
                return static_file(path+'.png', root=self.photo_dir)
            else:
                return static_file('images/default_company.png', root=htdocs_dir)

        @route('/tag/:path#.+#')
        def give_tag(path):
            # TODO: Should be more logical to locate tags images in tags directory !
            # tag_path = "/images/tags/%s" % path
            # BUT: implies modifications in all Shinken packages ...
            
            # If a tag image (tag.png) exists in the share dir, give it ...
            tag_path = "%s/images/sets/%s" % (self.share_dir, path)
            logger.debug("[WebUI] searching tag: %s", os.path.join(tag_path, 'tag.png'))
            if os.path.exists(os.path.join(tag_path, 'tag.png')):
                return static_file('tag.png', root=tag_path)
            else:
                # Default tags icons are located in images/tags directory ...
                tag_path = "%s/images/tags/%s" % (htdocs_dir, path)
                logger.debug("[WebUI] searching for: %s", os.path.join(tag_path, 'tag.png'))
                if os.path.exists(os.path.join(tag_path, 'tag.png')):
                    return static_file('tag.png', root=tag_path)
                else:
                    return static_file('images/default_tag.png', root=htdocs_dir)

        # Route static files css files
        @route('/static/:path#.+#')
        def server_static(path):
            # By default give from the root in bottle_dir/htdocs. If the file is missing,
            # search in the share dir
            # TODO: should be more logical to search in share_dir first ?
            root = htdocs_dir
            p = os.path.join(root, path)
            if not os.path.exists(p):
                root = self.share_dir
            return static_file(path, root=root)

        # And add the favicon ico too
        @route('/favicon.ico')
        def give_favicon():
            return static_file('favicon.ico', root=os.path.join(htdocs_dir, 'images'))

        # And add the opensearch xml
        @route('/opensearch.xml')
        def give_opensearch():
            base_url = self.request.url.replace('opensearch.xml', '')
            response.headers['Content-Type'] = 'text/xml'
            return template('opensearch', base_url=base_url)

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
        self.user_picture = None
        
        c = self.get_contact(username)
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
                        
                        # Define user picture
                        self.user_picture = '/static/photos/%s' % username
                        if self.gravatar:
                            gravatar = self.get_gravatar(c.email, 32)
                            if gravatar is not None:
                                self.user_picture = gravatar
                        logger.info("[WebUI] User picture: %s", self.user_picture)
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
        # First we look for the user sid
        # so we bail out if it's a false one
        username = self.request.get_cookie("user", secret=self.auth_secret)

        # If we cannot check the cookie, bailout ... 
        if not allow_anonymous and not username:
            return None
            
        # Allow anonymous access if requested and anonymous contact exists ...
        if allow_anonymous:
            if not self.allow_anonymous:
                return None
                
            c = self.get_contact('anonymous')
            if c:
                return c

        c = self.get_contact(username)

        # Set user picture
        if c is not None and self.user_picture == '':
            self.user_picture = '/static/photos/%s' % username
            if self.gravatar and c.email:
                gravatar = self.get_gravatar(c.email, 32)
                if gravatar is not None:
                    self.user_picture = gravatar
            
        return c

    ##
    # Check if a user is currently logged in
    ##
    def check_user_authentication(self):
        user = self.get_user_auth()
        if not user:
            self.bottle.redirect("/user/login")
        else:
            return user
            
    ##
    # Current user can launch commands ?
    # If username is provided, check for the specified user ...
    ##
    def can_action(self, username=None):
        if not self.manage_acl:
            return true
            
        if username is None:
            user = self.get_user_auth()
            if not user:
                self.bottle.redirect("/user/login")
            else:
                return user.is_admin or user.can_submit_commands
        
        c = self.get_contact(username)
        return c.is_admin or c.can_submit_commands

    ##
    # Get user Gravatar picture if defined
    ##
    def get_gravatar(self, email, size=64, default='404'):
        logger.debug("[WebUI], get Gravatar, email: %s, size: %d, default: %s", email, size, default)
        
        try:
            import urllib2
            parameters = { 's' : size, 'd' : default}
            url = "https://secure.gravatar.com/avatar/%s?%s" % (hashlib.md5(email.lower()).hexdigest(), urllib.urlencode(parameters))
            ret = urllib2.urlopen(url)
            if ret.code == 200:
                return url
            else:
                return None
        except:
            return None
            
        return None


    # ------------------------------------------------------------------------------------------
    # Manage embedded graphs
    # ------------------------------------------------------------------------------------------
    # Try to got for an element the graphs uris from modules
    # The source variable describes the source of the calling. Are we displaying 
    # graphs for the element detail page (detail), or a widget in the dashboard (dashboard) ?
    def get_graph_uris(self, elt, graphstart, graphend, source = 'detail'):
        logger.debug("[WebUI] Fetching graph URIs for %s (%s)", elt.host_name, source)

        uris = []
        for mod in self.modules_manager.get_internal_instances():
            try:
                logger.debug("[WebUI] module %s, get_graph_uris", mod)
                f = getattr(mod, 'get_graph_uris', None)
                if f and callable(f):
                    r = f(elt, graphstart, graphend, source)
                    logger.debug("[WebUI] Fetched: %s", r)
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
    # Manage external availability logs
    # ------------------------------------------------------------------------------------------
    ##
    # Check if an availability storage module is declared in webui.cfg
    ##
    def has_availability_module(self):
        logger.debug("[WebUI] searching external module for availability ...")
        self.get_availability = None
        for mod in self.modules_manager.get_internal_instances():
            f = getattr(mod, 'get_ui_availability', None)
            if f and callable(f):
                logger.info("[WebUI] Found availability module: %s", mod.get_name())
                self.get_availability = f
                return True
        return False


    # ------------------------------------------------------------------------------------------
    # Manage external shinken logs
    # ------------------------------------------------------------------------------------------
    ##
    # Check if a logs storage module is declared in webui.cfg
    ##
    def has_history_module(self):
        logger.debug("[WebUI] searching external module for history ...")
        self.get_history = None
        for mod in self.modules_manager.get_internal_instances():
            f = getattr(mod, 'get_ui_logs', None)
            if f and callable(f):
                logger.info("[WebUI] Found history module: %s", mod.get_name())
                self.get_history = f
                return True
        return False


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

    ##
    # Get/set user's bookmarks
    ##
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
    ##
    # Get only user relevant items for the user
    ##
    def only_related_to(self, lst, user):
        # if the user is an admin, show all
        if user is None or user.is_admin:
            return lst

        # Ok the user is a simple user, we should filter
        r = set()
        for item in lst:
            # May be the user is a direct contact
            if hasattr(item, 'contacts') and user in item.contacts:
                r.add(item)
                continue
            # TODO: add a notified_contact pass

            # May be it's a contact of a linked elements (source problems or impacts)
            found = False
            if hasattr(item, 'source_problems'): 
                for s in item.source_problems:
                    if user in s.contacts:
                        r.add(item)
                        found = True
            # Ok skip this object now
            if found:
                continue

            # May be it's a contact of a sub element ...
            found = False
            if item.__class__.my_type == 'hostgroup':
                for h in item.get_hosts():
                    if user in h.contacts:
                        r.add(item)
                        found = True
            # Ok skip this object now
            if found:
                continue
                
            # May be it's a contact of a sub element ...
            found = False
            if item.__class__.my_type == 'servicegroup':
                for s in item.get_services():
                    if user in s.contacts:
                        r.add(item)
                        found = True
            # Ok skip this object now
            if found:
                continue
                
            # Now impacts related maybe?
            if hasattr(item, 'impacts'): 
                for imp in item.impacts:
                    if user in imp.contacts:
                        r.add(item)
            
        return list(r)
        
        
    ##
    # Hosts
    ##
    def get_nb_hosts(self, user=None):
        return len(self.get_hosts(user))
        
    def get_hosts(self, user=None):
        items=self.datamgr.get_hosts()
        if user is not None:
            return self.only_related_to(items,user)

        return items
                  
    def get_host(self, hname):
        hname = hname.decode('utf8', 'ignore')
        return self.rg.hosts.find_by_name(hname)

    # Get number of all Hosts
    # problem=False, returns number of hosts not in problems
    # problem=True, returns number of hosts in problems
    def get_number_hosts_state(self, user=None, problem=False):
        """
        Get number of hosts

        :param user: concerned user
        :type user: shinken.objects.Contact
        :param problem: True to get number of problem hosts, else False 
        :type problem: Boolean
        :return:
          * number of problem hosts if problem=True
          * number of non problem hosts if problem=False
        """
        all_hosts = self.get_hosts(user)
        if len(all_hosts) == 0:
            return 0
            
        problem_hosts = []
        problem_hosts.extend([h for h in all_hosts if h.state not in ['UP', 'PENDING'] and not h.is_impact])
        
        if problem:
            return len(problem_hosts)
        else:
            return len(all_hosts) - len(problem_hosts)

    # Get percentage of all Hosts
    # problem=False, returns % of hosts not in problems
    # problem=True, returns % of hosts in problems
    def get_percentage_hosts_state(self, user=None, problem=False):
        all_hosts = self.get_hosts(user)
        if len(all_hosts) == 0:
            return 0
            
        problem_hosts = []
        problem_hosts.extend([h for h in all_hosts if h.state not in ['UP', 'PENDING'] and not h.is_impact])
        
        if problem:
            return int((len(problem_hosts) * 100) / float(len(all_hosts)))
        else:
            return int(100 - (len(problem_hosts) * 100) / float(len(all_hosts)))


    ##
    # Services
    ##
    def get_nb_services(self, user=None):
        return len(self.get_services(user))
        
    def get_services(self, user=None):
        items=self.datamgr.get_services()
        if user is not None:
            return self.only_related_to(items,user)

        return items

    def get_service(self, hname, sdesc):
        hname = hname.decode('utf8', 'ignore')
        sdesc = sdesc.decode('utf8', 'ignore')
        return self.rg.services.find_srv_by_name_and_hostname(hname, sdesc)

    # Get number of all Services
    # problem=False, returns number of services not in problems
    # problem=True, returns number of services in problems
    def get_number_service_state(self, user=None, problem=False):
        """
        Get the number of services

        :param user: concerned user
        :type user: shinken.objects.Contact
        :param problem: True to get number of problem hosts, else False 
        :type problem: Boolean
        :returns: number of problem / non problem services

        """
        all_services = self.get_services(user)
        if len(all_services) == 0:
            return 0

        problem_services = []
        problem_services.extend([s for s in all_services if s.state not in ['OK', 'PENDING'] and not s.is_impact])
        
        if problem:
            return len(problem_services)
        else:
            return len(all_services) - len(problem_services)

    # Get percentage of all Services
    # problem=False, returns % of services not in problems
    # problem=True, returns % of services in problems
    def get_percentage_service_state(self, user=None, problem=False):
        all_services = self.get_services(user)
        if len(all_services) == 0:
            return 0

        problem_services = []
        problem_services.extend([s for s in all_services if s.state not in ['OK', 'PENDING'] and not s.is_impact])
        
        if problem:
            return int((len(problem_services) * 100) / float(len(all_services)))
        else:
            return int(100 - (len(problem_services) * 100) / float(len(all_services)))


    ##
    # Hosts and services
    ##
    def get_all_hosts_and_services(self, user=None, get_impacts=True):
        """
        Get a list of all hosts and services

        :user: concerned user
        :get_impacts: should impact hosts/services be included in the list ?
        :returns: list of all hosts and services

        """
        all = []
        if get_impacts:
            all.extend(self.get_hosts(user))
            all.extend(self.get_services(user))
        else:
            all.extend([h for h in self.get_hosts(user) if not h.is_impact])
            all.extend([s for s in self.get_services(user) if not s.is_impact])
        return all

    def get_all_hosts(self, user=None, get_impacts=True):
        """
        Get a list of all hosts

        :user: concerned user
        :get_impacts: should impact hosts be included in the list ?
        :returns: list of all hosts

        """
        all = []
        if get_impacts:
            all.extend(self.get_hosts(user))
        else:
            all.extend([h for h in self.get_hosts(user) if not h.is_impact])
        return all



    def search_hosts_and_services(self, search, user=None, get_impacts=True, hosts_only=False):
        """@todo: Docstring for search_hosts_and_services.

        :search: @todo
        :user: @todo
        :get_impacts: @todo
        :returns: @todo

        """
        if hosts_only:
            items = self.get_all_hosts(user, get_impacts=False)
        else:
            items = self.get_all_hosts_and_services(user, get_impacts=False)

        logger.debug("[%s] problems", self.name)
        for i in items:
            logger.debug("[%s] problems, item: %s", self.name, i.get_full_name())

        search = [s for s in search.split(' ')]

        for s in search:
            s = s.strip()
            if not s:
                continue

            logger.debug("[%s] problems, searching for: %s in %d items", self.name, s, len(items))

            elts = s.split(':', 1)
            t = 'hst_srv'
            if len(elts) > 1:
                t = elts[0]
                s = elts[1]

            logger.debug("[%s] problems, searching for type %s, pattern: %s", self.name, t, s)

            if t == 'hst_srv':
                pat = re.compile(s, re.IGNORECASE)
                new_items = []
                for i in items:
                    if pat.search(i.get_full_name()):
                        new_items.append(i)
                    else:
                        for j in (i.impacts + i.source_problems):
                            if pat.search(j.get_full_name()):
                                new_items.append(i)

                if not new_items:
                    for i in items:
                        if pat.search(i.output):
                            new_items.append(i)
                        else:
                            for j in (i.impacts + i.source_problems):
                                if pat.search(j.output):
                                    new_items.append(i)

                items = new_items

            if (t == 'hg' or t == 'hgroup') and s != 'all':
                group = self.get_hostgroup(s)
                if not group:
                    return []  # :TODO:maethor:150716: raise an error
                items = [i for i in items if group in i.get_hostgroups()]

            if (t == 'sg' or t == 'sgroup') and s != 'all':
                group = self.get_servicegroup(s)
                if not group:
                    return []  # :TODO:maethor:150716: raise an error
                items = [i for i in items if group in i.get_servicegroups()]

            if (t == 'cg' or t == 'cgroup') and s != 'all':
                group = self.get_contactgroup(s)
                if not group:
                    return []  # :TODO:maethor:150716: raise an error
                contacts = [c for c in self.get_contacts() if c in group.members]
                items = list(set(itertools.chain(*[self.only_related_to(items, c) for c in contacts])))

            if t == 'realm':
                r = self.get_realm(s)
                if not r:
                    return []  # :TODO:maethor:150716: raise an error
                items = [i for i in items if i.get_realm() == r]

            if t == 'htag' and s != 'all':
                items = [i for i in items if s in i.get_host_tags()]

            if t == 'stag' and s != 'all':
                items = [i for i in items if i.__class__.my_type == 'service' and s in i.get_service_tags()]

            if t == 'ctag' and s != 'all':
                contacts = [c for c in self.get_contacts() if s in c.tags]
                items = list(set(itertools.chain(*[self.only_related_to(items, c) for c in contacts])))

            if t == 'type':
                items = [i for i in items if i.__class__.my_type == s]

            if t == 'bp' or t == 'bi':
                if s.startswith('>='):
                    items = [i for i in items if i.business_impact >= int(s[2:])]
                elif s.startswith('<='):
                    items = [i for i in items if i.business_impact <= int(s[2:])]
                elif s.startswith('>'):
                    items = [i for i in items if i.business_impact > int(s[1:])]
                elif s.startswith('<'):
                    items = [i for i in items if i.business_impact < int(s[1:])]
                else:
                    if s.startswith('='):
                        s = s[1:]
                    items = [i for i in items if i.business_impact == int(s)]

            if t == 'is':
                if s.lower() == 'ack':
                    items = [i for i in items if i.__class__.my_type == 'service' or i.problem_has_been_acknowledged]
                    items = [i for i in items if i.__class__.my_type == 'host' or (i.problem_has_been_acknowledged or i.host.problem_has_been_acknowledged)]
                elif s.lower() == 'downtime':
                    items = [i for i in items if i.__class__.my_type == 'service' or i.in_scheduled_downtime]
                    items = [i for i in items if i.__class__.my_type == 'host' or (i.in_scheduled_downtime or i.host.in_scheduled_downtime)]
                else:
                    if len(s) == 1:
                        items = [i for i in items if i.state_id == int(s)]
                    else:
                        items = [i for i in items if i.state == s.upper()]

            if t == 'isnot':
                if s.lower() == 'ack':
                    items = [i for i in items if i.__class__.my_type == 'service' or not i.problem_has_been_acknowledged]
                    items = [i for i in items if i.__class__.my_type == 'host' or (not i.problem_has_been_acknowledged and not i.host.problem_has_been_acknowledged)]
                elif s.lower() == 'downtime':
                    items = [i for i in items if i.__class__.my_type == 'service' or not i.in_scheduled_downtime]
                    items = [i for i in items if i.__class__.my_type == 'host' or (not i.in_scheduled_downtime and not i.host.in_scheduled_downtime)]
                else:
                    if len(s) == 1:
                        items = [i for i in items if i.state_id != int(s)]
                    else:
                        items = [i for i in items if i.state != s.upper()]

            # :COMMENT:maethor:150616: Legacy filters, kept for bookmarks compatibility
            if t == 'ack':
                if s == 'false' or s == 'no':
                    search.append("isnot:ack")
                if s == 'true' or s == 'yes':
                    search.append("is:ack")
            if t == 'downtime':
                if s == 'false' or s == 'no':
                    search.append("isnot:downtime")
                if s == 'true' or s == 'yes':
                    search.append("is:downtime")
            if t == 'crit':
                search.append("is:critical")

            logger.debug("[%s] problems, found %d elements for type %s, pattern: %s", self.name, len(items), t, s)

        logger.debug("[%s] problems after search filtering", self.name)
        for i in items:
            logger.debug("[%s] problems, item: %s, %d, %d", self.name, i.get_full_name(), i.business_impact, i.state_id)

        return items


    ##
    # Timeperiods
    ##
    def get_timeperiods(self):
        return self.datamgr.rg.timeperiods
                  
    def get_timeperiod(self, name):
        return self.datamgr.rg.timeperiods.find_by_name(name)
    
    ##
    # Commands
    ##
    def get_commands(self):
        return self.datamgr.rg.commands
                  
    def get_command(self, name):
        name = name.decode('utf8', 'ignore')
        return self.datamgr.rg.commands.find_by_name(name)

    ##
    # Contacts
    ##
    def get_contacts(self, user=None):
        items=self.datamgr.rg.contacts
        if user is not None:
            return self.only_related_to(items,user)

        return items
                  
    def get_contact(self, name):
        name = name.decode('utf8', 'ignore')
        return self.datamgr.rg.contacts.find_by_name(name)

    ##
    # Contacts groups
    ##
    def get_contactgroups(self, user=None):
        items=self.datamgr.rg.contactgroups
        if user is not None:
            return self.only_related_to(items,user)

        return items
        # return self.datamgr.rg.contactgroups
                  
    def get_contactgroup(self, name):
        name = name.decode('utf8', 'ignore')
        return self.datamgr.rg.contactgroups.find_by_name(name)

    def get_contactgroupmembers(self, name):
        name = name.decode('utf8', 'ignore')
        cg = self.datamgr.rg.contactgroups.find_by_name(name)
        
        contacts=[]
        [contacts.append(item.alias if item.alias else item.get_name()) for item in cg.members if item not in contacts]
        
        return contacts

    ##
    # Hosts groups
    ##
    def set_hostgroups_level(self, user=None):
        logger.debug("[WebUI] set_hostgroups_level")
        
        # All known hostgroups are level 0 groups ...
        for group in self.get_hostgroups(user=user):
            if not hasattr(group, 'level'):
                self.set_hostgroup_level(group, 0, user)
        
    def set_hostgroup_level(self, group, level, user=None):
        logger.debug("[WebUI] set_hostgroup_level, group: %s, level: %d", group.hostgroup_name, level)
        logger.debug("[WebUI] set_hostgroup_level, group: %s", group)
        
        setattr(group, 'level', level)
                
        # Search hostgroups referenced in another group
        if group.has('hostgroup_members'):
            for g in sorted(group.get_hostgroup_members()):
                try:
                    child_group = self.get_hostgroup(g)
                    logger.debug("[WebUI] set_hostgroup_level, , group: %s, level: %d", child_group.hostgroup_name, group.level + 1)
                    self.set_hostgroup_level(child_group, level + 1, user)
                except AttributeError:
                    pass
        
    def get_hostgroups(self, user=None, parent=None):
        if parent:
            group = self.datamgr.rg.hostgroups.find_by_name(parent)
            if group.has('hostgroup_members'):
                items = [self.get_hostgroup(g) for g in group.get_hostgroup_members()]
            else:
                return None
        else:
            items=self.datamgr.rg.hostgroups
            
        if user is not None:
            return self.only_related_to(items,user)

        return items

    def get_hostgroup(self, name):
        return self.datamgr.rg.hostgroups.find_by_name(name)
    
    ##
    # Services groups
    ##
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
        
    def get_servicegroups(self, user=None, parent=None):
        if parent:
            group = self.datamgr.rg.servicegroups.find_by_name(parent)
            if group.has('servicegroup_members'):
                items = [self.get_servicegroup(g) for g in group.get_servicegroup_members()]
            else:
                return None
        else:
            items = self.datamgr.rg.servicegroups
            
        if user is not None:
            return self.only_related_to(items,user)

        return items

    def get_servicegroup(self, name):
        return self.datamgr.rg.servicegroups.find_by_name(name)
                  
    ##
    # Hosts tags
    ##
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

    ##
    # Services tags
    ##
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
    # Realms
    ##
    def get_realms(self):
        return self.datamgr.rg.realms

    def get_realm(self, r):
        if r in self.datamgr.rg.realms:
            return r
        return None

    ##
    # Shinken program
    ##
    def get_configs(self):
        return self.datamgr.rg.configs.values()

    def get_schedulers(self):
        return self.datamgr.rg.schedulers

    def get_pollers(self):
        return self.datamgr.rg.pollers

    def get_brokers(self):
        return self.datamgr.rg.brokers

    def get_receivers(self):
        return self.datamgr.rg.receivers

    def get_reactionners(self):
        return self.datamgr.rg.reactionners

    def get_program_start(self):
        for c in self.datamgr.rg.configs.values():
            return c.program_start
        return None

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
    def get_overall_it_state(self, user=None, get_acknowledged=False, id=False):
        '''
        Get the worst state of IT problems for the current user if specified.
        If get_acknowledged is True, count problems even if acknowledged ...
        If id is True, state id are returned else state texts are returned
        '''
        logger.debug("[WebUI] get_overall_it_state, user: %s, get_acknowledged: %d", user.contact_name, get_acknowledged)
        
        state = { 'host': 
                    {   0: 'UP',
                        2: 'DOWN',
                        1: 'UNREACHABLE',
                        3: 'UNKNOWN' },
                  'service': 
                    {   0: 'OK',
                        2: 'CRITICAL',
                        1: 'WARNING',
                        3: 'UNKNOWN' }
                }
                
        if not get_acknowledged:
            h_states = [h.state_id for h in self.get_hosts(user) if h.state_id in [1, 2] and not h.problem_has_been_acknowledged]
            s_states = [s.state_id for s in self.get_services(user) if s.state_id in [1, 2] and not s.problem_has_been_acknowledged]
        else:
            h_states = [h.state_id for h in self.get_hosts(user) if h.state_id in [1, 2]]
            s_states = [s.state_id for s in self.get_services(user) if s.state_id in [1, 2]]
        
        logger.info("[WebUI] get_overall_it_state, h_states: %d, s_states: %d", h_states, s_states)

        if len(h_states) == 0:
            h_state = state['host'].get(0, 'UNKNOWN') if not id else 0
        else:
            h_state = state['host'].get(max(h_states), 'UNKNOWN') if not id else max(h_states)
        
        if len(s_states) == 0:
            s_state = state['service'].get(0, 'UNKNOWN') if not id else 0
        else:
            s_state = state['service'].get(max(s_states), 'UNKNOWN') if not id else max(s_states)
            
        logger.debug("[WebUI] get_overall_it_state, h_state: %s, s_state: %s", h_state, s_state)
        return h_state, s_state

    # Get the number of all problems, even the ack ones
    def get_overall_it_problems_count(self, user=None, type='all', get_acknowledged=False):
        '''
        Get the number of IT problems for the current user if specified.
        If get_acknowledged is True, count problems even if acknowledged ...
        
        If type is 'host', only count hosts problems
        If type is 'service', only count services problems
        '''
        logger.debug("[WebUI] get_overall_it_problems_count, user: %s, type: %s, get_acknowledged: %d", user.contact_name, type, get_acknowledged)
        
        if not get_acknowledged:
            h_states = [h for h in self.get_hosts(user) if h.state not in ['UP', 'PENDING'] and not h.is_impact and not h.problem_has_been_acknowledged]
            s_states = [s for s in self.get_services(user) if s.state not in ['OK', 'PENDING'] and not s.is_impact and not s.problem_has_been_acknowledged and not s.host.problem_has_been_acknowledged]
        else:
            h_states = [h for h in self.get_hosts(user) if h.state not in ['UP', 'PENDING'] and not h.is_impact]
            s_states = [s for s in self.get_services(user) if s.state not in ['OK', 'PENDING'] and not s.is_impact]
            
        logger.debug("[WebUI] get_overall_it_problems_count, hosts: %d, services: %d", len(h_states), len(s_states))
        
        if type == 'all':
            return len(h_states) + len(s_states)
        elif type == 'host':
            return len(h_states)
        elif type == 'service':
            return len(s_states)
        else:
            return -1
