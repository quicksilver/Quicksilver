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
from bs4 import BeautifulSoup
import fileinput
from sys import stdout
import codecs
streamWriter = codecs.lookup('utf-8')[-1]
stdout = streamWriter(stdout)

## a place to store the links we find
links = []

if __name__ == '__main__':
    page = ''.join([line for line in fileinput.input()])
    soup = BeautifulSoup(page)
    for link in soup.findAll('a', href=True):
        ## skip useless links
        if link['href'] == '' or link['href'].startswith('#'):
            continue
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
            if thisLink['title'] is None:
                # look for a title here if none exists
                if img.has_key('title'):
                    thisLink['title'] = img['title']
                elif img.has_key('alt'):
                    thisLink['title'] = img['alt']
                else:
                    thisLink['title'] = path.basename(img['src'])
            
        if thisLink['title'] is None:
            ## check for text inside the link
            if len(link.contents):
                thisLink['title'] = ' '.join(link.stripped_strings)
        if thisLink['title'] is None:
            ## if there's *still* no title (empty tag), skip it
            continue
        ## convert to something immutable for storage
        hashableLink = (thisLink['url'].strip(),
                        thisLink['title'].strip(),
                        thisLink['shortcut'].strip(),
                        thisLink['image'].strip())
        ## store the result
        if hashableLink not in links:
            links.append(hashableLink)

## print the results
for link in links:
    stdout.write('\t'.join(link) + '\n')
