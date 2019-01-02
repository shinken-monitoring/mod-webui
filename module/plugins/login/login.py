#!/usr/bin/python

# -*- coding: utf-8 -*-

# Copyright (C) 2009-2014:
#    Gabes Jean, naparuba@gmail.com
#    Gerhard Lausser, Gerhard.Lausser@consol.de
#    Gregory Starck, g.starck@gmail.com
#    Hartmut Goebel, h.goebel@goebel-consult.de
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

from shinken.log import logger
import bottle

# Will be populated by the UI with it's own value
app = None


def user_login():
    logger.debug("[WebUI] user login request, remote user enabled: %s: %s",
                 app.remote_user_enable, app.remote_user_variable)
    for header in app.request.headers:
        logger.debug("[WebUI] X request header: %s = %s", header, app.request.headers[header])

    err = app.request.GET.get('error', None)
    if err:
        logger.warning("[WebUI] login page with error message: %s", err)

    cookie_value = app.request.get_cookie(app.session_cookie, secret=app.auth_secret)
    if cookie_value:
        logger.info("[WebUI] user login request, existing cookie found: %s", cookie_value)
        bottle.redirect(app.get_url("Dashboard"))

    elif app.remote_user_enable in ['1', '2']:
        logger.debug("[WebUI] user login request, no existing cookie found")
        if not err:
            user_name = None
            if app.remote_user_enable == '1':
                logger.debug("[WebUI] search %s in request headers", app.remote_user_variable)
                if app.remote_user_variable in app.request.headers:
                    user_name = app.request.headers[app.remote_user_variable]
                    logger.debug("[WebUI] remote user found in request headers: %s", user_name)

            if app.remote_user_enable == '2':
                logger.debug("[WebUI] search %s in WSGI environment", app.remote_user_variable)
                if app.remote_user_variable in app.request.environ:
                    user_name = app.request.environ[app.remote_user_variable]
                    logger.debug("[WebUI] remote user found in WSGI environment: %s", user_name)

            if not user_name:
                logger.warning("[WebUI] remote user is enabled but no authenticated "
                               "user name was found")
                bottle.redirect(app.get_url("GetLogin"))

            c = app.datamgr.get_contact(name=user_name)
            if c:
                cookie_value = {
                    'login': user_name,
                    'session': app.user_session,
                    'info': app.user_info
                }
                app.response.set_cookie(str(app.session_cookie), cookie_value,
                                        secret=app.auth_secret, path='/')
                bottle.redirect(app.get_url("Dashboard"))

    logger.debug("[WebUI] session user message - get: %s",
                 app.request.environ.get('MSG', 'None...'))

    return {'msg_text': err, 'login_text': app.login_text, 'company_logo': app.company_logo}


def user_logout():
    # To delete the cookie, send the same, with different date
    cookie_value = app.request.get_cookie(app.session_cookie, secret=app.auth_secret)
    if cookie_value:
        app.response.set_cookie(app.session_cookie, False, secret=app.auth_secret, path='/')
    else:
        app.response.set_cookie(app.session_cookie, '', secret=app.auth_secret, path='/')

    contact_name = cookie_value.get('login', cookie_value)
    logger.info("[WebUI] user '%s' signed out", contact_name)
    bottle.redirect(app.get_url("GetLogin"))
    return {}


def user_auth():
    login = app.request.forms.get('login', '')
    password = app.request.forms.get('password', '')
    logger.info("[WebUI]  user '%s' is signing in ...", login)

    # Tries to authenticate user
    is_authenticated = app.check_authentication(login, password)
    if is_authenticated:
        logger.debug("[WebUI]  setting cookie '%s' for %s", app.session_cookie, login)
        cookie_value = {
            'login': login,
            'session': app.user_session,
            'info': app.user_info
        }
        try:
            app.response.set_cookie(str(app.session_cookie), cookie_value,
                                    secret=app.auth_secret, path='/')
        except ValueError:
            logger.error("[WebUI]  cookie value error (too long > 4096 bytes!): %s", cookie_value)
            is_authenticated = False
        else:
            logger.debug("[WebUI]  user '%s' signed in: %s", login, cookie_value)
            bottle.redirect(app.get_url("Dashboard"))
    else:
        logger.debug("[WebUI]  user '%s' access denied, redirection to: %s", login, app.get_url("GetLogin"))

        logger.info("[WebUI] refused login message: %s", app.request.environ.get('MSG', ''))
        bottle.redirect(app.get_url("GetLogin") + "?error=%s" % app.request.environ.get('MSG', ''))

    return {'is_auth': is_authenticated}


def get_root():
    """Navigating to the root is redirecting to the Dashboard view"""
    bottle.redirect(app.get_url("Dashboard"))


pages = {
    user_login: {
        'name': 'GetLogin', 'route': '/user/login', 'view': 'login'
    },
    user_auth: {
        'name': 'SetLogin', 'route': '/user/auth', 'method': 'POST'
    },
    user_logout: {
        'name': 'Logout', 'route': '/user/logout'
    },
    get_root: {
        'name': 'Root', 'route': '/'
    }
}
