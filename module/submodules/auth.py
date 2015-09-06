#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: ai ts=4 sts=4 et sw=4 nu

import traceback
import crypt
from ..lib.md5crypt import apache_md5_crypt, unix_md5_crypt

from shinken.log import logger

from .metamodule import MetaModule

class AuthMetaModule(MetaModule):

    _functions = ['check_auth']

    def check_auth(self, user, password):
        ''' Check user/password. If there is submodules, this methods call them
            one by one until one of them returns True. If no submodule can
            check user/password, then we return False.
            If not, the method calls a default check_auth method. '''
        logger.info("[WebUI] Authenticating user '%s'", user)
        if self.modules:
            for mod in self.modules:
                try:
                    logger.info("[WebUI] Authenticating user '%s' with %s", user, mod.get_name())
                    if mod.check_auth(user, password):
                        logger.info("[WebUI] User '%s' is authenticated by %s", user, mod.get_name())
                        return True
                except Exception as exp:
                    logger.warning("[WebUI] The mod %s raised an exception: %s, I'm tagging it to restart later", mod.get_name(), str(exp))
                    logger.warning("[WebUI] Exception type: %s", type(exp))
                    logger.warning("Back trace of this kill: %s" % (traceback.format_exc()))
                    self.app.modules_manager.set_to_restart(mod)

        logger.info("[WebUI] Embedded authentication for '%s'", user)
        if self.check_cfg_password_auth(user, password):
            logger.info("[WebUI] User '%s' is authenticated by internal contact password", user)
            return True

        if self.app.htpasswd_file and self.check_apache_htpasswd_auth(user, password):
            logger.info("[WebUI] User '%s' is authenticated by htpasswd password", user)
            return True

    def is_available(self):
        ''' Always returns True because this MetaModule have a default behavior. '''
        return True

    def check_cfg_password_auth(self, user, password):
        ''' Embedded authentication with password stored in contact definition.
            Function imported from auth-cfg-password module.
        '''
        logger.info("[WebUI-auth-cfg-password] Authenticating user '%s'", user)
        
        c = self.app.datamgr.get_contact(user)
        if not c:
            logger.error("[WebUI-auth-cfg-password] You need to have a contact having the same name as your user: %s", user)
            return False
        p = None
        if isinstance(c, dict):
            p = c.get('password', None)
        else:
            p = c.password

        if p == password:
            logger.info("[WebUI-auth-cfg-password] Authenticated")
            return True
            
        logger.warning("[WebUI-auth-cfg-password] Authentication failed")
        return False
        
        
    def check_apache_htpasswd_auth(self, user, password):
        ''' Embedded authentication with password in Apache htpasswd file.
            Function imported from auth-htpasswd module.
        '''
        logger.info("[WebUI-auth-htpasswd] Authenticating user '%s'", user)
        
        try:
            f = open(self.app.htpasswd_file, 'r')
            for line in f.readlines():
                line = line.strip()
                # By pass bad lines
                if not ':' in line:
                    continue
                if line.startswith('#'):
                    continue
                elts = line.split(':')
                name = elts[0]
                hash = elts[1]
                if hash[:5] == '$apr1' or hash[:3] == '$1$':
                    h = hash.split('$')
                    magic = h[1]
                    salt = h[2]
                else:
                    magic = None
                    salt = hash[:2]

                # If we match the user, look at the crypt
                if name == user:
                    if magic == 'apr1':
                        compute_hash = apache_md5_crypt(password, salt)
                    elif magic == '1':
                        compute_hash = unix_md5_crypt(password, salt)
                    else:
                        compute_hash = crypt.crypt(password, salt)
                    if compute_hash == hash:
                        logger.info("[WebUI-auth-htpasswd] Authenticated")
                        return True
                else:
                    logger.debug("[WebUI-auth-htpasswd] Authentication failed, invalid name: %s / %s", name, user)
        except Exception as exp:
            logger.info("[WebUI-auth-htpasswd] Authentication against apache passwd file failed, exception: %s", str(exp))
        finally:
            try:
                f.close()
            except:
                pass

        return False
