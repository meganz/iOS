

/*
File: MeterTable.h
Abstract: Class for handling conversion from linear scale to dB
 Version: 1.4.3
 
Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
Inc. ("Apple") in consideration of your agreement to the following
terms, and your use, installation, modification or redistribution of
this Apple software constitutes acceptance of these terms.  If you do
not agree with these terms, please do not use, install, modify or
redistribute this Apple software.
 
In consideration of your agreement to abide by the following terms, and
subject to these terms, Apple grants you a personal, non-exclusive
license, under Apple's copyrights in this original Apple software (the
"Apple Software"), to use, reproduce, modify and redistribute the Apple
Software, with or without modifications, in source and/or binary forms;
provided that if you redistribute the Apple Software in its entirety and
without modifications, you must retain this notice and the following
text and disclaimers in all such redistributions of the Apple Software.
Neither the name, trademarks, service marks or logos of Apple Inc. may
be used to endorse or promote products derived from the Apple Software
without specific prior written permission from Apple.  Except as
expressly stated in this notice, no other rights or licenses, express or
implied, are granted by Apple herein, including but not limited to any
patent rights that may be infringed by your derivative works or by other
works in which the Apple Software may be incorporated.
 
The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.
 
Copyright (C) 2014 Apple Inc. All Rights Reserved.
*/

import Foundation

class MeterTable {
    private var minDecibels: Float
    private var decibelResolution: Float
    private var scaleFactor: Float
    private var table: [Float] = []
    
    init(minDecibels: Float = -160.0, tableSize: Int = 400, root: Double = 2.0) {
        guard minDecibels < 0.0 else {
            fatalError("MeterTable inMinDecibels must be negative")
        }
        
        self.minDecibels = minDecibels
        
        decibelResolution = minDecibels / Float(tableSize - 1)
        scaleFactor = 1.0 / decibelResolution
        
        let minAmp = dbToAmp(Double(minDecibels))
        let ampRange = 1.0 - minAmp
        let invAmpRange = 1.0 / ampRange

        let rroot: Double = 1.0 / root
        table = (0..<tableSize).map { index in
            let decibels = Double(index) * Double(decibelResolution)
            let amp = dbToAmp(decibels)
            let adjAmp = (amp - minAmp) * Double(invAmpRange)
            return Float(pow(adjAmp, rroot))
        }
    }

    subscript(index: Float) -> Float {
        if index < minDecibels  {
            return 0.0
        } else if index >= 0.0 {
            return 1.0
        } else {
            let index = Int(index * scaleFactor)
            return table[index]
        }
    }
    
    private func dbToAmp(_ db: Double) -> Double {
        return pow(10.0, 0.05 * db)
    }
}
