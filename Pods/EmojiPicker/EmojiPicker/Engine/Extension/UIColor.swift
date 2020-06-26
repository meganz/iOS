//
//  UIColor.swift
//  EmojiPicker
//
//  Created by levantAJ on 13/11/18.
//  Copyright © 2018 levantAJ. All rights reserved.
//

import UIKit

extension UIColor {
    public convenience init?(hexString: String, alpha: Float = 1.0) {
        var hex = hexString
        
        if hex.hasPrefix("#") {
            let subHex = Substring(hex)
            hex = String(subHex.suffix(from: subHex.index(hex.startIndex, offsetBy: 1)))
        }
        
        if hex.range(of: "(^[0-9A-Fa-f]{6}$)|(^[0-9A-Fa-f]{3}$)", options: .regularExpression) != nil {
            var subHex = Substring(hex)
            if hex.count == 3 {
                let redHex = subHex.prefix(upTo: subHex.index(hex.startIndex, offsetBy: 1))
                let greenHex = String(subHex[subHex.index(hex.startIndex, offsetBy: 1)..<subHex.index(hex.startIndex, offsetBy: 2)])
                let blueHex = subHex.suffix(from: subHex.index(hex.startIndex, offsetBy: 2))
                hex = redHex + redHex + greenHex + greenHex + blueHex + blueHex
            }
            subHex = Substring(hex)
            let redHex = String(subHex.prefix(upTo: subHex.index(hex.startIndex, offsetBy: 2)))
            let greenHex = String(subHex[subHex.index(hex.startIndex, offsetBy: 2)..<subHex.index(hex.startIndex, offsetBy: 4)])
            let blueHex = String(subHex[subHex.index(hex.startIndex, offsetBy: 4)..<subHex.index(hex.startIndex, offsetBy: 6)])
            
            var redInt: CUnsignedInt = 0
            var greenInt: CUnsignedInt = 0
            var blueInt: CUnsignedInt = 0
            
            Scanner(string: redHex).scanHexInt32(&redInt)
            Scanner(string: greenHex).scanHexInt32(&greenInt)
            Scanner(string: blueHex).scanHexInt32(&blueInt)
            
            self.init(red: CGFloat(redInt) / 255.0, green: CGFloat(greenInt) / 255.0, blue: CGFloat(blueInt) / 255.0, alpha: CGFloat(alpha))
        } else {
            self.init()
            return nil
        }
    }
}
