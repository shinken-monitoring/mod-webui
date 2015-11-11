#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright (C) 2009-2014:
#   Gabes Jean, naparuba@gmail.com
#   Gerhard Lausser, Gerhard.Lausser@consol.de
#   Gregory Starck, g.starck@gmail.com
#   Hartmut Goebel, h.goebel@goebel-consult.de
#   Frederic Mohier, frederic.mohier@gmail.com
#   Guillaume Subiron, maethor@subiron.org
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


import hashlib

from shinken.objects import Contact
from shinken.log import logger


class User(Contact):
    picture = None

    @classmethod
    def from_contact(cls, contact, picture="", use_gravatar=False):
        user = contact
        try:
            user.__class__ = User
        except Exception:
            raise Exception(user)
        if not picture:
            user.picture = '/static/photos/%s' % user.contact_name
            if use_gravatar:
                gravatar = cls.get_gravatar(user.email)
                if gravatar:
                    user.picture = gravatar

        return user

    @staticmethod
    def get_gravatar(email, size=64, default='404'):
        logger.debug("[WebUI] get Gravatar, email: %s, size: %d, default: %s",
                     email, size, default)

        try:
            import urllib2
            import urllib

            parameters = {'s': size, 'd': default}
            url = "https://secure.gravatar.com/avatar/%s?%s" % (
                hashlib.md5(email.lower()).hexdigest(), urllib.urlencode(parameters)
            )
            ret = urllib2.urlopen(url)
            if ret.code == 200:
                return url
        except:
            pass

        return None
