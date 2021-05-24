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
 * @author    Virtual Jasper
 * @copyright Copyright © 2018 Teclib
 * @package   plist
 * @license   MIT
 * @link      https://github.com/TECLIB/CFPropertyList/
 * ------------------------------------------------------------------------------
 */

/**
 * Examples for how to use CFPropertyList with xmlStream
 * Read from a PropertyList with array
 *
 * @package plist
 * @subpackage plist.examples
 */
namespace CFPropertyList;

use \XMLReader;

// just in case...
error_reporting(E_ALL);
ini_set('display_errors', 'on');

/**
 * Require CFPropertyList
 */
require_once(__DIR__.'/../vendor/autoload.php');


/*
 * create a new CFPropertyList instance which loads the sample.plist on construct.
 * We don't know that it is a binary plist, so we simply call ->parse()
 */

$reader=new XMLReader();
$reader->open(__DIR__.'/sample.xml.array.plist');

while ($reader->read()) {
    if ($reader->depth==3 && $reader->nodeType==XMLReader::TEXT && $reader->value=='large_array') {
        // array found!
        break;
    }
}

while ($reader->read()) {
    if ($reader->depth==3 && $reader->nodeType==XMLReader::ELEMENT && $reader->name=='dict') {
        $stream = fopen('php://memory', 'r+');
        // wrap it to mimic to be a plist xml doc
        $foo='<?xml version="1.0" encoding="UTF-8"?>'.PHP_EOL.'<plist version="1.0">'.PHP_EOL.$reader->readOuterXml().PHP_EOL.'</plist>';
        fwrite($stream, $foo);
        rewind($stream);
        $plist=new CFPropertyList();
        $plist->loadXMLStream($stream);
        fclose($stream);
        echo '<pre>';
        var_dump($plist->toArray());
        echo '</pre>';
        // first dict found! exit!
        break;
    }
}


//read remaining <dict> node until the end
while ($reader->next('dict')) {
    if ($reader->depth==3 && $reader->nodeType==XMLReader::ELEMENT && $reader->name=='dict') {
        $stream = fopen('php://memory', 'r+');
        // wrap it to mimic to be a plist xml doc
        $foo='<?xml version="1.0" encoding="UTF-8"?>'.PHP_EOL.'<plist version="1.0">'.PHP_EOL.$reader->readOuterXml().PHP_EOL.'</plist>';
        fwrite($stream, $foo);
        rewind($stream);
        $plist=new CFPropertyList();
        $plist->loadXMLStream($stream);
        fclose($stream);
        echo '<pre>';
        var_dump($plist->toArray());
        echo '</pre>';
    }
}
