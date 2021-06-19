<?php
/**
 * LICENSE
 *
 * This file is part of CFPropertyList.
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
 * @package   CFPropertyList
 * @license   MIT
 * @link      https://github.com/TECLIB/CFPropertyList/
 * @link      http://developer.apple.com/documentation/Darwin/Reference/ManPages/man5/plist.5.html Property Lists
 * ------------------------------------------------------------------------------
 */

namespace CFPropertyList;

class CFTypeDetectorTest extends \PHPUnit\Framework\TestCase
{
    public function providerToCFType()
    {
        $stdClass = new \stdClass();
        $stdClass->key1 = 'value1';

        return [
            [
                'input'     => new CFString('a string'),
                'options'   => [],
                'expected'  => [
                    'type' => CFString::class,
                ],
            ],
            [
                'input'     => $stdClass,
                'options'   => [],
                'expected'  => [
                    'type' => CFDictionary::class,
                ]
                ],
            [
                'input'     => new \DateTime(),
                'options'   => [],
                'expected'  => [
                    'type' => CFDate::class,
                ]
            ],
            [
                'input'     => true,
                'options'   => [],
                'expected'  => [
                    'type' => CFBoolean::class,
                ]
            ],
            [
                'input'     => null,
                'options'   => [],
                'expected'  => [
                    'type'  => CFString::class,
                ]
            ],
            [
                'input'     => 42,
                'options'   => [],
                'expected'  => [
                    'type'  => CFNumber::class,
                ]
            ],
            [
                'input'     => 3.1415,
                'options'   => [],
                'expected'  => [
                    'type'  => CFNumber::class,
                ]
            ],
            [
                'input'     => '3.1415',
                'options'   => [],
                'expected'  => [
                    'type'  => CFNumber::class,
                ]
            ],
            [
                'input'     => '3.1415',
                'options'   => ['castNumericStrings' => false],
                'expected'  => [
                    'type'  => CFString::class,
                ]
            ],
            [
                'input'     => "data \x00 here",
                'options'   => ['castNumericStrings' => false],
                'expected'  => [
                    'type'  => CFData::class,
                ]
            ],
        ];
    }

   /**
    * @dataProvider providerToCFType
    */
    public function testToCFType($input, array $options, array $expected)
    {
        $instance = new \CFPropertyList\CFTypeDetector($options);
        $output = $instance->toCFType($input);
        $this->assertTrue($output instanceof $expected['type']);
    }
}
