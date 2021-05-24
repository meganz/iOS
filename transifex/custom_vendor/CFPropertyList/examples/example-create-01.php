<?php
/**
 * LICENSE
 *
 * This file is part of CFPropertyList.
 *
 * The PHP implementation of Apple's PropertyList can handle XML PropertyLists
 * as well as binary PropertyLists. It offers functionality to easily convert
 * data between worlds, e.g. recalculating timestamps from unix epoch to apple
 * epoch and vice versa. A feature to automagically create (guess) the plist
 * structure from a normal PHP data structure will help you dump your data to
 * plist in no time.
 *
 * Copyright (c) 2018 Teclib'
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 *
 * ------------------------------------------------------------------------------
 * @author    Christian Kruse <cjk@wwwtech.de>
 * @copyright Copyright © 2018 Teclib
 * @package   plist
 * @license   MIT
 * @link      https://github.com/TECLIB/CFPropertyList/
 * ------------------------------------------------------------------------------
 */
/**
 * Examples for how to use CFPropertyList
 * Create the PropertyList sample.xml.plist by using the CFPropertyList API.
 * @package plist
 * @subpackage plist.examples
 */
namespace CFPropertyList;

// just in case...
error_reporting( E_ALL );
ini_set( 'display_errors', 'on' );

/**
 * Require CFPropertyList
 */
require_once(__DIR__.'/../vendor/autoload.php');


/*
 * create a new CFPropertyList instance without loading any content
 */
$plist = new CFPropertyList();

/*
 * Manuall Create the sample.xml.plist
 */
// the Root element of the PList is a Dictionary
$plist->add( $dict = new CFDictionary() );

// <key>Year Of Birth</key><integer>1965</integer>
$dict->add( 'Year Of Birth', new CFNumber( 1965 ) );

// <key>Date Of Graduation</key><date>2004-06-22T19:23:43Z</date>
$dict->add( 'Date Of Graduation', new CFDate( gmmktime( 19, 23, 43, 06, 22, 2004 ) ) );

// <key>Pets Names</key><array/>
$dict->add( 'Pets Names', new CFArray() );

// <key>Picture</key><data>PEKBpYGlmYFCPA==</data>
// to keep it simple we insert an already base64-encoded string
$dict->add( 'Picture', new CFData( 'PEKBpYGlmYFCPA==', true ) );

// <key>City Of Birth</key><string>Springfield</string>
$dict->add( 'City Of Birth', new CFString( 'Springfield' ) );

// <key>Name</key><string>John Doe</string>
$dict->add( 'Name', new CFString( 'John Doe' ) );

// <key>Kids Names</key><array><string>John</string><string>Kyra</string></array>
$dict->add( 'Kids Names', $array = new CFArray() );
$array->add( new CFString( 'John' ) );
$array->add( new CFString( 'Kyra' ) );


/*
 * Save PList as XML
 */
$plist->saveXML( __DIR__.'/example-create-01.xml.plist' );


/*
 * Save PList as Binary
 */
$plist->saveBinary( __DIR__.'/example-create-01.binary.plist' );

?>