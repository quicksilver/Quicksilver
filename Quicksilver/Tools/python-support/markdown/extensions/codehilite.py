#!/usr/bin/python

"""
CodeHilite Extension for Python-Markdown
========================================

Adds code/syntax highlighting to standard Python-Markdown code blocks.

Copyright 2006-2008 [Waylan Limberg](http://achinghead.com/).

Project website: <http://www.freewisdom.org/project/python-markdown/CodeHilite>
Contact: markdown@freewisdom.org

License: BSD (see ../docs/LICENSE for details)

Dependencies:
* [Python 2.3+](http://python.org/)
* [Markdown 2.0+](http://www.freewisdom.org/projects/python-markdown/)
* [Pygments](http://pygments.org/)

"""

import markdown
try:
    from pygments import highlight
    from pygments.lexers import get_lexer_by_name, guess_lexer, TextLexer
    from pygments.formatters import HtmlFormatter
    pygments = True
except ImportError:
    pygments = False

# ------------------ The Main CodeHilite Class ----------------------
class CodeHilite:
    """
    Determine language of source code, and pass it into the pygments hilighter.

    Basic Usage:
        >>> code = CodeHilite(src = 'some text')
        >>> html = code.hilite()

    * src: Source string or any object with a .readline attribute.

    * linenos: (Boolen) Turn line numbering 'on' or 'off' (off by default).

    * guess_lang: (Boolen) Turn language auto-detection 'on' or 'off' (on by default).

    * css_class: Set class name of wrapper div ('codehilite' by default).

    Low Level Usage:
        >>> code = CodeHilite()
        >>> code.src = 'some text' # String or anything with a .readline attr.
        >>> code.linenos = True  # True or False; Turns line numbering on or of.
        >>> html = code.hilite()

    """

    def __init__(self, src=None, linenos=False, guess_lang=True,
                css_class="codehilite", lang=None, style='default',
                noclasses=False, tab_length=4):
        self.src = src
        self.lang = lang
        self.linenos = linenos
        self.guess_lang = guess_lang
        self.css_class = css_class
        self.style = style
        self.noclasses = noclasses
        self.tab_length = tab_length

    def hilite(self):
        """
        Pass code to the [Pygments](http://pygments.pocoo.org/) highliter with
        optional line numbers. The output should then be styled with css to
        your liking. No styles are applied by default - only styling hooks
        (i.e.: <span class="k">).

        returns : A string of html.

        """

        self.src = self.src.strip('\n')

        if self.lang is None:
            self._getLang()

        if pygments:
            try:
                lexer = get_lexer_by_name(self.lang)
            except ValueError:
                try:
                    if self.guess_lang:
                        lexer = guess_lexer(self.src)
                    else:
                        lexer = TextLexer()
                except ValueError:
                    lexer = TextLexer()
            formatter = HtmlFormatter(linenos=self.linenos,
                                      cssclass=self.css_class,
                                      style=self.style,
                                      noclasses=self.noclasses)
            return highlight(self.src, lexer, formatter)
        else:
            # just escape and build markup usable by JS highlighting libs
            txt = self.src.replace('&', '&amp;')
            txt = txt.replace('<', '&lt;')
            txt = txt.replace('>', '&gt;')
            txt = txt.replace('"', '&quot;')
            classes = []
            if self.lang:
                classes.append('language-%s' % self.lang)
            if self.linenos:
                classes.append('linenums')
            class_str = ''
            if classes:
                class_str = ' class="%s"' % ' '.join(classes) 
            return '<pre class="%s"><code%s>%s</code></pre>\n'% \
                        (self.css_class, class_str, txt)

    def _getLang(self):
        """
        Determines language of a code block from shebang line and whether said
        line should be removed or left in place. If the sheband line contains a
        path (even a single /) then it is assumed to be a real shebang line and
        left alone. However, if no path is given (e.i.: #!python or :::python)
        then it is assumed to be a mock shebang for language identifitation of a
        code fragment and removed from the code block prior to processing for
        code highlighting. When a mock shebang (e.i: #!python) is found, line
        numbering is turned on. When colons are found in place of a shebang
        (e.i.: :::python), line numbering is left in the current state - off
        by default.

        """

        import re

        #split text into lines
        lines = self.src.split("\n")
        #pull first line to examine
        fl = lines.pop(0)

        c = re.compile(r'''
            (?:(?:::+)|(?P<shebang>[#]!))	# Shebang or 2 or more colons.
            (?P<path>(?:/\w+)*[/ ])?        # Zero or 1 path
            (?P<lang>[\w+-]*)               # The language
            ''',  re.VERBOSE)
        # search first line for shebang
        m = c.search(fl)
        if m:
            # we have a match
            try:
                self.lang = m.group('lang').lower()
            except IndexError:
                self.lang = None
            if m.group('path'):
                # path exists - restore first line
                lines.insert(0, fl)
            if m.group('shebang'):
                # shebang exists - use line numbers
                self.linenos = True
        else:
            # No match
            lines.insert(0, fl)

        self.src = "\n".join(lines).strip("\n")



# ------------------ The Markdown Extension -------------------------------
class HiliteTreeprocessor(markdown.treeprocessors.Treeprocessor):
    """ Hilight source code in code blocks. """

    def run(self, root):
        """ Find code blocks and store in htmlStash. """
        blocks = root.getiterator('pre')
        for block in blocks:
            children = block.getchildren()
            if len(children) == 1 and children[0].tag == 'code':
                code = CodeHilite(children[0].text,
                            linenos=self.config['force_linenos'],
                            guess_lang=self.config['guess_lang'],
                            css_class=self.config['css_class'],
                            style=self.config['pygments_style'],
                            noclasses=self.config['noclasses'],
                            tab_length=self.markdown.tab_length)
                placeholder = self.markdown.htmlStash.store(code.hilite(),
                                                            safe=True)
                # Clear codeblock in etree instance
                block.clear()
                # Change to p element which will later
                # be removed when inserting raw html
                block.tag = 'p'
                block.text = placeholder


class CodeHiliteExtension(markdown.Extension):
    """ Add source code hilighting to markdown codeblocks. """

    def __init__(self, configs):
        # define default configs
        self.config = {
            'force_linenos' : [False, "Force line numbers - Default: False"],
            'guess_lang' : [True, "Automatic language detection - Default: True"],
            'css_class' : ["codehilite",
                           "Set class name for wrapper <div> - Default: codehilite"],
            'pygments_style' : ['default', 'Pygments HTML Formatter Style (Colorscheme) - Default: default'],
            'noclasses': [False, 'Use inline styles instead of CSS classes - Default false']
            }

        # Override defaults with user settings
        for key, value in configs:
            # convert strings to booleans
            if value == 'True': value = True
            if value == 'False': value = False
            self.setConfig(key, value)

    def extendMarkdown(self, md, md_globals):
        """ Add HilitePostprocessor to Markdown instance. """
        hiliter = HiliteTreeprocessor(md)
        hiliter.config = self.getConfigs()
        md.treeprocessors.add("hilite", hiliter, "<inline")

        md.registerExtension(self)


def makeExtension(configs={}):
  return CodeHiliteExtension(configs=configs)

