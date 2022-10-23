import UIKit
import CoreGraphics

public extension UIImage {
    static func drawImage(
        forInitials initials:String,
        size imageSize:CGSize,
        backgroundColor:UIColor,
        backgroundGradientColor:UIColor?,
        textColor:UIColor,
        font:UIFont,
        isRightToLeftLanguage: Bool
    ) -> UIImage? {
        
        let width: CGFloat = imageSize.width
        let height: CGFloat = imageSize.height
        let radius: CGFloat = imageSize.width / 2
        
        UIGraphicsBeginImageContextWithOptions(imageSize, false, UIScreen.main.scale)
        
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        context.setStrokeColor(backgroundColor.cgColor)
        context.setFillColor(backgroundColor.cgColor)
        
        let path = UIBezierPath(ovalIn: CGRectMake(0, 0, width, height))
        path.addClip()
        path.lineWidth = 1.0
        path.stroke()
        
        if let backgroundGradientColor {
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            
            var colorComponents:[CGFloat] = []
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            var alpha: CGFloat = 0

            backgroundColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            colorComponents.append(contentsOf: [red, green, blue, alpha])
            
            backgroundGradientColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            colorComponents.append(contentsOf: [red, green, blue, alpha])

            guard let gradient = CGGradient(colorSpace: colorSpace, colorComponents: colorComponents, locations: nil, count: 2) else { return nil}
            context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: height), end: CGPoint(x: width, y: 0), options: [])
        } else {
            context.setFillColor(backgroundColor.cgColor)
            context.fill(CGRectMake(0, 0, width, height))
        }
        
        let dict: [NSAttributedString.Key : Any] = [
            NSAttributedString.Key.font: font,
            NSAttributedString.Key.foregroundColor: textColor
        ]
        
        let textSize = initials.size(withAttributes: dict)
        
        let xFactor: CGFloat = isRightToLeftLanguage ? -1 : 1
        initials.draw(in: CGRectMake(xFactor * (radius - textSize.width / 2), radius - font.lineHeight / 2, textSize.width, textSize.height), withAttributes:dict)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return image
    }
    
}
