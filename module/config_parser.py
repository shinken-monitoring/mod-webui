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
                            self.options[option] = [value] + [old_value]
                        else:
                            self.options[option] += [value]
                    else:
                        self.options[option] = value
                else:
                    self.options[option] = value
        config_file.close()
        return self.options
        

# Test module   
# try:
    # scp = SimpleConfigParser('#', '=')
    # params = scp.parse_config('log_test.cfg')
    # print params
# except Exception, exp:
    # print "Requested configuration file does not exist !", exp
