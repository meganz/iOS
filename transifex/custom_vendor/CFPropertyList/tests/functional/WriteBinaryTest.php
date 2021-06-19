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
 * @author    Jocelyn Badgley <github@twipped.com>
 * @copyright Copyright © 2018 Teclib
 * @package   plist
 * @license   MIT
 * @link      https://github.com/TECLIB/CFPropertyList/
 * @link      http://developer.apple.com/documentation/Darwin/Reference/ManPages/man5/plist.5.html Property Lists
 * ------------------------------------------------------------------------------
 */

namespace CFPropertyList;

class WriteBinaryTest extends \PHPUnit\Framework\TestCase
{
    public function testWriteFile()
    {
        $plist = new CFPropertyList();
        $dict = new CFDictionary();

        $names = new CFDictionary();
        $names->add('given-name', new CFString('John'));
        $names->add('surname', new CFString('Dow'));

        $dict->add('names', $names);

        $pets = new CFArray();
        $pets->add(new CFString('Jonny'));
        $pets->add(new CFString('Bello'));
        $dict->add('pets', $pets);

        $dict->add('age', new CFNumber(28));
        $dict->add('birth-date', new CFDate(412035803));

        $plist->add($dict);
        $plist->saveBinary(WRITE_BINARY_DATA_FILE);

        $this->assertTrue(is_file(WRITE_BINARY_DATA_FILE));
        $this->assertTrue(filesize(WRITE_BINARY_DATA_FILE) > 32);

        $plist->load(WRITE_BINARY_DATA_FILE);

        unlink(WRITE_BINARY_DATA_FILE);
    }

    public function testWriteString()
    {
        $plist = new CFPropertyList();
        $dict = new CFDictionary();

        $names = new CFDictionary();
        $names->add('given-name', new CFString('John'));
        $names->add('surname', new CFString('Dow'));

        $dict->add('names', $names);

        $pets = new CFArray();
        $pets->add(new CFString('Jonny'));
        $pets->add(new CFString('Bello'));
        $dict->add('pets', $pets);

        $dict->add('age', new CFNumber(28));
        $dict->add('birth-date', new CFDate(412035803));

        $plist->add($dict);
        $content = $plist->toBinary();

        $this->assertTrue(strlen($content) > 32);

        $plist->parse($content);
    }

    public function testWriteUid()
    {
        $plist = new CFPropertyList();
        $dict = new CFDictionary();
        $dict->add('test', new CFUid(1));
        $plist->add($dict);

        $plist1 = new CFPropertyList(TEST_UID_BPLIST);
        $this->assertEquals($plist1->toBinary(), $plist->toBinary());
    }
}


# eof
