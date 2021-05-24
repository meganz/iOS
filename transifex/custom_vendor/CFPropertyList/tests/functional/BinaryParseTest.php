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
 * @link      http://developer.apple.com/documentation/Darwin/Reference/ManPages/man5/plist.5.html Property Lists
 * ------------------------------------------------------------------------------
 */

namespace CFPropertyList;

class BinaryParseTest extends \PHPUnit\Framework\TestCase
{
    public function testParseBinary()
    {
        $plist = new CFPropertyList(TEST_BINARY_DATA_FILE);

        $vals = $plist->toArray();
        $this->assertEquals(count($vals), 4);

        $this->assertEquals($vals['names']['given-name'], 'John');
        $this->assertEquals($vals['names']['surname'], 'Dow');

        $this->assertEquals($vals['pets'][0], 'Jonny');
        $this->assertEquals($vals['pets'][1], 'Bello');

        $this->assertEquals($vals['age'], 28);
        $this->assertEquals($vals['birth-date'], 412035803);
    }

    public function testParseBinaryString()
    {
        $content = file_get_contents(TEST_BINARY_DATA_FILE);

        $plist = new CFPropertyList();
        $plist->parse($content);

        $vals = $plist->toArray();
        $this->assertEquals(count($vals), 4);

        $this->assertEquals($vals['names']['given-name'], 'John');
        $this->assertEquals($vals['names']['surname'], 'Dow');

        $this->assertEquals($vals['pets'][0], 'Jonny');
        $this->assertEquals($vals['pets'][1], 'Bello');

        $this->assertEquals($vals['age'], 28);
        $this->assertEquals($vals['birth-date'], 412035803);
    }

    public function testParseStream()
    {
        $plist = new CFPropertyList();
        if (($fd = fopen(TEST_BINARY_DATA_FILE, "rb")) == null) {
            throw new IOException("Error opening test data file for reading!");
        }

        $plist->readBinaryStream($fd);

        $vals = $plist->toArray();
        $this->assertEquals(count($vals), 4);

        $this->assertEquals($vals['names']['given-name'], 'John');
        $this->assertEquals($vals['names']['surname'], 'Dow');

        $this->assertEquals($vals['pets'][0], 'Jonny');
        $this->assertEquals($vals['pets'][1], 'Bello');

        $this->assertEquals($vals['age'], 28);
        $this->assertEquals($vals['birth-date'], 412035803);
    }

  /**
   * @expectedException CFPropertyList\PListException
   */
    public function testEmptyString()
    {
        $plist = new CFPropertyList();
        $plist->parseBinary('');
    }

    public function testInvalidString()
    {
        $catched = false;

        try {
            $plist = new CFPropertyList();
            $plist->parseBinary('lalala');
        } catch (PListException $e) {
            $catched = true;
        }

        $this->assertTrue($catched, 'No exception thrown for invalid string!');

        $catched = false;
        try {
            $plist = new CFPropertyList();
            $plist->parseBinary('bplist00dfwefwefwef');
        } catch (PListException $e) {
            $catched = true;
        }

        $this->assertTrue($catched, 'No exception thrown for invalid string!');
    }

    public function testUidPlist()
    {
        $plist = new CFPropertyList(TEST_UID_BPLIST);
        $val = $plist->toArray();
        $this->assertEquals(array('test' => 1), $val);

        $v = $plist->getValue()->getValue();
        $this->assertTrue($v['test'] instanceof CFUid);
    }
}

# eof
