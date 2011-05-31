#!/usr/bin/env python
# encoding: utf-8
"""
QSURLExtractor.py

Created by Rob McBroom on 2010-04-13.
"""

import sys
import os
from HTMLParser import HTMLParser, HTMLParseError

class ExtractLinks(HTMLParser):
    def __init__(self):
        HTMLParser.__init__(self)
        self.insideLinkTag = False
    
    def handle_starttag(self,tag,attrs):
        # print 'start', tag, self.insideLinkTag
        if tag == 'a':
            if self.insideLinkTag:
                # the previously started tag must not have been closed properly
                # send it out and move on
                self.printLink(self.thisLink)
            self.thisLink = {
                'url': str(),
                'title': str(),
                'image': str(),
            }
            self.insideLinkTag = True
            for name, value in attrs:
                if name == 'href':
                    self.thisLink['url'] = value
        if tag == 'img':
            # look for URL and title of linked images
            if self.insideLinkTag:
                for name, value in attrs:
                    if name == 'src':
                        self.thisLink['image'] = value
                    if name == 'title':
                        self.thisLink['title'] = value
                        break
                    if name == 'alt':
                        self.thisLink['title'] = value
    
    def handle_data(self, data):
        # if there's anything other than whitespace
        # and we're inside a link
        if data.strip() and self.insideLinkTag:
            self.thisLink['title'] = data
    
    def handle_endtag(self,tag):
        # print 'end', tag, self.insideLinkTag
        if tag == 'a' and self.insideLinkTag:
            self.printLink(self.thisLink)
            self.thisLink = {
                'url': str(),
                'title': str(),
                'image': str(),
            }
            self.insideLinkTag = False
    
    def printLink(self, thisLink):
        """print tab separated link attributes"""
        print '{0}\t{1}\t\t{2}'.format(thisLink['url'], thisLink['title'], thisLink['image'])

if __name__ == '__main__':
    import fileinput
    page = ''.join([line for line in fileinput.input()])
    parser = ExtractLinks()
    try:
        parser.feed(page)
    except HTMLParseError, e:
        pass
