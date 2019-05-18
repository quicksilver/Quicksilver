#!/usr/bin/env python
# -*- encoding: utf-8 -*-

import urllib2

if __name__ == '__main__':
    tld_list = [u'@"LOCAL"']
    for line in urllib2.urlopen('http://data.iana.org/TLD/tlds-alpha-by-domain.txt'):
        if line[0] == '#':
            continue
        line = u'@"{0}"'.format(line.strip())
        tld_list.append(line)
    print "Drop the following line into QSObject_StringHandling.m to update the TLDs Quicksilver registers\n"
    print u'tldArray = @[{0}];'.format(u', '.join(tld_list))
    