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

### Will be populated by the UI with it's own value
app = None

from shinken.log import logger
import bottle


def user_login():
    err = app.request.GET.get('error', None)
    if err:
        logger.warning("[WebUI] login page with error message: %s", err)

    if app.request.get_cookie("user", secret=app.auth_secret):
        bottle.redirect(app.get_url("Dashboard"))
    elif app.remote_user_enable in ['1', '2']:
        if not err:
            user_name=None
            if app.remote_user_variable in app.request.headers and app.remote_user_enable == '1':
                user_name = app.request.headers[app.remote_user_variable]
            elif app.remote_user_variable in app.request.environ and app.remote_user_enable == '2':
                user_name = app.request.environ[app.remote_user_variable]
            if not user_name:
                logger.warning("[WebUI] remote user enabled but no user name found")
                bottle.redirect(app.get_url("GetLogin"))
            c = app.datamgr.get_contact(user_name)
            if c:
                app.response.set_cookie('user', user_name, secret=app.auth_secret, path='/')
                bottle.redirect(app.get_url("Dashboard"))

    return {'msg_text': err, 'login_text': app.login_text, 'company_logo': app.company_logo}
    # return bottle.template('login', msg_text=err, login_text=app.login_text, company_logo=app.company_logo)


def user_logout():
    # To delete it, send the same, with different date
    user_name = app.request.get_cookie("user", secret=app.auth_secret)
    if user_name:
        app.response.set_cookie('user', False, secret=app.auth_secret, path='/')
    else:
        app.response.set_cookie('user', '', secret=app.auth_secret, path='/')

    logger.info("[WebUI]  user '%s' signed out", user_name)
    bottle.redirect(app.get_url("GetLogin"))
    return {}


def user_auth():
    login = app.request.forms.get('login', '')
    password = app.request.forms.get('password', '')
    logger.info("[WebUI]  user '%s' is signing in ...", login)

    # Tries to authenticate user
    is_authenticated = app.check_authentication(login, password)
    if is_authenticated:
        app.response.set_cookie('user', login, secret=app.auth_secret, path='/')
        logger.info("[WebUI]  user '%s' signed in", login)
        bottle.redirect(app.get_url("Dashboard"))
    else:
        logger.warning("[WebUI]  user '%s' access denied, redirection to: %s", login, app.get_url("GetLogin") + "?error=Invalid user or Password")
        bottle.redirect(app.get_url("GetLogin") + "?error=Invalid user or Password")

    return {'is_auth': is_authenticated}


# manage the /. If the user is known, go to home page.
# Should be /dashboard in the future. If not, go login :)
def get_root():
    bottle.redirect(app.get_url("Dashboard"))


pages = {
    user_login: {
        'name': 'GetLogin', 'route': '/user/login', 'view': 'login', 'static': True
    },
    user_auth: {
        'name': 'SetLogin', 'route': '/user/auth', 'method': 'POST', 'static': True
    },
    user_logout: {
        'name': 'Logout', 'route': '/user/logout', 'static': True
    },
    get_root: {
        'name': 'Root', 'route': '/', 'static': True
    }
}
