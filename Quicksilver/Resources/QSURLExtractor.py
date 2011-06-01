#!/usr/bin/env python
# -*- encoding: utf-8 -*-
"""
QSURLExtractor.py

Created by Rob McBroom on 2011-06-01.

output tab separated lines with the following fields:
    0 url
    1 text
    2 shortcut
    3 imageurl
"""

from os import path
from BeautifulSoup import BeautifulSoup
import fileinput
from sys import stdout
import codecs
streamWriter = codecs.lookup('utf-8')[-1]
stdout = streamWriter(stdout)

if __name__ == '__main__':
    page = ''.join([line for line in fileinput.input()])
    soup = BeautifulSoup(page)
    for link in soup.findAll('a', href=True):
        ## initialize the link
        thisLink = {
            'url': link['href'],
            'title': link.string,
            'shortcut': '',
            'image': '',
        }
        ## see if the link contains an image
        img = link.find('img', src=True)
        if img:
            thisLink['image'] = img['src']
            if thisLink['title'] == None:
                # look for a title here if none exists
                if img.has_key('title'):
                    thisLink['title'] = img['title']
                elif img.has_key('alt'):
                    thisLink['title'] = img['alt']
                else:
                    thisLink['title'] = path.basename(img['src'])
        ## if there's *still* no title (empty <a></a> tag), fall back to the URL
        if thisLink['title'] == None:
            thisLink['title'] = path.basename(link['href'])
        ## print the result
        print '%s\t%s\t%s\t%s' % (thisLink['url'], thisLink['title'], thisLink['shortcut'], thisLink['image'])
