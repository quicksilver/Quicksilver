#!/usr/bin/env python
# -*- encoding: utf-8 -*-

import urllib2

if __name__ == '__main__':
    array = u"tldArray = [[NSArray arrayWithObjects:"
    for line in urllib2.urlopen('http://data.iana.org/TLD/tlds-alpha-by-domain.txt'):
        if line[0] == '#':
            continue
        array += u''.join([u'@"',line.strip(),u'",'])
    # remove the last comma
    array = u''.join([array,u'nil] retain];'])
    print "Drop the following line into QSObject_StringHandling.m to update the TLDs Quicksilver registers\n" 
    print array
        
    