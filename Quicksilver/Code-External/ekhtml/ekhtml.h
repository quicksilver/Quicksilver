/*
 * Copyright (c) 2002, Jon Travis
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef EKHTML_DOT_H
#define EKHTML_DOT_H

#include <stdio.h>

/*! 
 * \file ekhtml.h
 * \brief Main El-Kabong header file.
 *
 * This header defines everything that a program should need to use
 * the El-Kabong library.
 */

/**
 * A string object, which is not NUL terminated.
 * For speed reasons, El-Kabong does not deal with zero-terminated
 * strings.  
 */

typedef struct ekhtml_string_t {
    const char *str;    /**< Actual string data          */
    size_t      len;    /**< Length of the data in `str` */
} ekhtml_string_t;

/**
 * Attribute object, passed into callbacks.  
 * When ekhtml parses tags containing key/value attributes, it will pass 
 * this structure representing those values into the callbacks.  Note, for 
 * speed reasons, things such as the 'name' and 'value' fields are not 
 * terminated with '\0', and therefore have an associated length 
 * field (namelen, vallen).
 */

typedef struct ekhtml_attr_t {
    ekhtml_string_t       name;       /**< Name of the attribute             */
    ekhtml_string_t       val;        /**< Value of the attribute            */
    unsigned int          isBoolean;  /**< True of the attribute is boolean  */
    struct ekhtml_attr_t *next;  /**< Pointer to next attribute in the list  */
} ekhtml_attr_t;

/*
 * Typedefs for function callback types
 */

/**
 * The parser object.  
 * The parser object holds state information, such as which callbacks 
 * to invoke when reading tags, how much data is being processed, etc.
 */

typedef struct ekhtml_parser_t ekhtml_parser_t; 

/**
 * Callback for simple data.
 * Callback functions of this form are used to process data which is
 * not part of a start or end tag.  This callback may also be used
 * to process the body of comment tags.
 * 
 * I.e. <FOO>data_to_process</FOO>  
 * The data passed into the callback function will be "data_to_process"
 *
 * @param cbdata Callback data, as previously set by ekhtml_parser_cbdata_set
 * @param data   A pointer to the data in-between tags.
 *              
 * @see ekhtml_parser_cbdata_set()
 * @see ekhtml_parser_datacb_set()
 */

typedef void (*ekhtml_data_cb_t)(void *cbdata, ekhtml_string_t *data);

/**
 * Callback for start tags.
 * Callback functions of this form are used to process start tags.
 * 
 * I.e. <FOO>data_to_process</FOO>  
 * The tag passed into the callback will be "FOO" with a length of 3.
 *
 * @param cbdata Callback data, as previously set by ekhtml_parser_cbdata_set
 * @param tag    A pointer to tag name.  This is a traditional NUL terminated
 *               string.
 * @param attrs  Attributes of the tag.  
 *              
 * @see ekhtml_parser_cbdata_set()
 * @see ekhtml_parser_startcb_add()
 */

typedef void (*ekhtml_starttag_cb_t)(void *cbdata, ekhtml_string_t *tag,
				     ekhtml_attr_t *attrs);

/**
 * Callback for end tags.
 * Callback functions of this form are used to process end tags.
 * 
 * I.e. <FOO>data_to_process</FOO>  
 * The tag passed into the callback will be "FOO" with a length of 3.
 *
 * @param cbdata Callback data, as previously set by ekhtml_parser_cbdata_set
 * @param tag    A pointer to tag name.  This is a traditional NUL terminated
 *               string.
 *
 * @see ekhtml_parser_cbdata_set()
 * @see ekhtml_parser_endcb_add()
 */

typedef void (*ekhtml_endtag_cb_t)(void *cbdata, ekhtml_string_t *tag);

/**
 * Create a new parser object.
 * This routine creates a new parser object, with no set callback
 * functions or state.
 *
 * @param cbdata  Callback data to use when invoking callbacks
 *
 * @returns A new ekhtml_parser_t object
 *
 * @see ekhtml_parser_cbdata_set()
 */

extern ekhtml_parser_t *ekhtml_parser_new(void *cbdata);

/**
 * Set the callback data for the parser.
 * This routine sets the callback data which is passed to set callbacks.
 *
 * @param parser  Parser to set the callback data for
 * @param cbdata  Callback data the parser should use to pass to callbacks
 */

extern void ekhtml_parser_cbdata_set(ekhtml_parser_t *parser, void *cbdata);

/**
 * Set the parser's data callback.
 * This routine sets the callback which should be invoked for
 * non-tagged data.
 *
 * @param parser  Parser to set the callback for
 * @param cb      Callback to invoke when processing non-tagged data
 */

extern void ekhtml_parser_datacb_set(ekhtml_parser_t *parser, 
                                     ekhtml_data_cb_t cb);

/**
 * Set the parser's comment callback.
 * This routine sets the callback which should be invoked when 
 * the parser processes a comment.
 *
 * @param parser  Parser to set the callback for
 * @param cb      Callback to invoke when processing a comment
 */

extern void ekhtml_parser_commentcb_set(ekhtml_parser_t *parser, 
                                        ekhtml_data_cb_t cb);

/**
 * Feed data for the parser to process.
 * Feed data into the HTML parser.  This routine will fill up the 
 * internal buffer until it can go no more, then flush the data 
 * and refill.  If there is more data that is required than the 
 * internal buffer can hold, it will be resized
 *
 * @param parser  Parser to feed data to
 * @param data    Data to feed to the parser
 */

extern void ekhtml_parser_feed(ekhtml_parser_t *parser, 
                               ekhtml_string_t *data);

/**
 * Flush the parser innards.
 * When this function is invoked, the parser will flush all data that is
 * currently held, and any remaining state is saved.  All data which is
 * processed is removed from the parser, and the internal buffer is
 * reshuffled.
 *
 * @param parser   Parser to flush
 * @param flushall If true, will flush all data, even if tags are not
 *                 complete (i.e. "<FO")
 * @returns 1 if action was taken (i.e. bytes were processed and the
 *          internal buffer was reshuffled) else 0
 */

extern int ekhtml_parser_flush(ekhtml_parser_t *parser, int flushall);

/**
 * Add a callback for a start tag.
 * This routine sets the callback which should be invoked when 
 * the parser processes a start tag.  Both specific tags, and
 * unknown tags can be used with this method.
 *
 * @param parser  Parser to set the callback for
 * @param tag     Name of the tag to call `cb` for.  If `tag` is NULL, then
 *                any tags which are unknown to the parser will be sent
 *                to the callback specified by `cb`.
 * @param cb      Callback to invoke
 */

extern void ekhtml_parser_startcb_add(ekhtml_parser_t *parser, const char *tag,
				      ekhtml_starttag_cb_t cb);

/**
 * Add a callback for an end tag.
 * This routine sets the callback which should be invoked when 
 * the parser processes an end tag.  Both specific tags, and
 * unknown tags can be used with this method.
 *
 * @param parser  Parser to set the callback for
 * @param tag     Name of the tag to call `cb` for.  If `tag` is NULL, then
 *                any tags which are unknown to the parser will be sent
 *                to the callback specified by `cb`.
 * @param cb      Callback to invoke
 */

extern void ekhtml_parser_endcb_add(ekhtml_parser_t *parser, const char *tag,
				    ekhtml_endtag_cb_t cb);

// MMCC -- not sure why this isn't in there...
extern void ekhtml_parser_destroy(ekhtml_parser_t *ekparser);

/** EKHTML_BLOCKSIZE = # of blocks to allocate per chunk */
#define EKHTML_BLOCKSIZE (1024 * 4)

#endif
