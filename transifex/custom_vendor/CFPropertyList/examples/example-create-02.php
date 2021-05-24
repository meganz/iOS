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
 * Create the PropertyList sample.xml.plist by using {@link CFTypeDetector}.
 * @package plist
 * @subpackage plist.examples
 */
namespace CFPropertyList;
use \DateTime, \DateTimeZone;

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
 * import the array structure to create the sample.xml.plist
 * We make use of CFTypeDetector, which truly is not almighty!
 */

$structure = array(
  'Year Of Birth' => 1965,
  // Note: dates cannot be guessed, so this will become a CFNumber and be treated as an integer
  // See example-04.php for a possible workaround
  'Date Of Graduation' => gmmktime( 19, 23, 43, 06, 22, 2004 ),
  'Date Of Birth' => new DateTime( '1984-09-07 08:15:23', new DateTimeZone( 'Europe/Berlin' ) ),
  'Pets Names' => array(),
  // Note: data cannot be guessed, so this will become a CFString
  // See example-03.php for a possible workaround
  'Picture' => 'PEKBpYGlmYFCPA==',
  'City Of Birth' => 'Springfield',
  'Name' => 'John Doe',
  'Kids Names' => array( 'John', 'Kyra' ),
);

$td = new CFTypeDetector();
$guessedStructure = $td->toCFType( $structure );
$plist->add( $guessedStructure );


/*
 * Save PList as XML
 */
$plist->saveXML( __DIR__.'/example-create-02.xml.plist' );

/*
 * Save PList as Binary
 */
$plist->saveBinary( __DIR__.'/example-create-02.binary.plist' );

?>