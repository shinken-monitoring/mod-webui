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

# config_parser
class config_parser(object):
 
    def __init__(self, comment_char = '#', option_char = '=', allow_duplicates = False, strip_quotes = True):
        self.comment_char = comment_char
        self.option_char = option_char
        self.allow_duplicates = allow_duplicates
        self.strip_quotes = True
 
    def parse_config(self, filename):
        self.options = {}
        config_file = open(filename)
        for line in config_file:
            if self.comment_char in line:
                line, comment = line.split(self.comment_char, 1)
            if self.option_char in line:
                option, value = line.split(self.option_char, 1)
                option = option.strip()
                value = value.strip()
                value = value.strip('"\'')
                if self.allow_duplicates:
                    if option in self.options:
                        if not type(self.options[option]) == list:
                            old_value = self.options[option]
                            self.options[option] = [old_value] + [value]
                        else:
                            self.options[option] += [value]
                    else:
                        self.options[option] = value
                else:
                    self.options[option] = value
        config_file.close()
        return self.options
 
