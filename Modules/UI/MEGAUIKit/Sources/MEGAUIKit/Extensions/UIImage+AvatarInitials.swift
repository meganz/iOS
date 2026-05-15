import UIKit

public extension UIImage {

    @objc(imageForName:size:backgroundColor:backgroundGradientColor:textColor:font:)
    static func avatarImage(
        forName name: String,
        size: CGSize,
        backgroundColor: UIColor,
        backgroundGradientColor: UIColor?,
        textColor: UIColor,
        font: UIFont
    ) -> UIImage {
        let key = AvatarImageKey(
            initials: name.avatarInitials,
            size: size,
            backgroundColor: backgroundColor.cacheableRGBA,
            backgroundGradientColor: backgroundGradientColor?.cacheableRGBA,
            textColor: textColor.cacheableRGBA,
            fontName: font.fontName,
            pointSize: font.pointSize
        )

        if let cached = avatarImageCache[key] {
            return cached
        }

        let image = drawAvatarImage(
            initials: key.initials,
            size: size,
            backgroundColor: backgroundColor,
            backgroundGradientColor: backgroundGradientColor,
            textColor: textColor,
            font: font
        )
        avatarImageCache[key] = image
        return image
    }

    @objc(imageForName:size:backgroundColor:textColor:font:)
    static func avatarImage(
        forName name: String,
        size: CGSize,
        backgroundColor: UIColor,
        textColor: UIColor,
        font: UIFont
    ) -> UIImage {
        avatarImage(
            forName: name,
            size: size,
            backgroundColor: backgroundColor,
            backgroundGradientColor: nil,
            textColor: textColor,
            font: font
        )
    }

    private static func drawAvatarImage(
        initials: String,
        size: CGSize,
        backgroundColor: UIColor,
        backgroundGradientColor: UIColor?,
        textColor: UIColor,
        font: UIFont
    ) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            let cgContext = context.cgContext

            cgContext.addEllipse(in: rect)
            cgContext.clip()

            if let gradientColor = backgroundGradientColor,
               let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [backgroundColor.cgColor, gradientColor.cgColor] as CFArray,
                locations: nil
               ) {
                cgContext.drawLinearGradient(
                    gradient,
                    start: CGPoint(x: 0, y: size.height),
                    end: CGPoint(x: size.width, y: 0),
                    options: []
                )
            } else {
                backgroundColor.setFill()
                cgContext.fill(rect)
            }

            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: textColor,
                .paragraphStyle: paragraphStyle
            ]

            let textHeight = font.lineHeight
            let textRect = CGRect(
                x: 0,
                y: (size.height - textHeight) / 2,
                width: size.width,
                height: textHeight
            )
            (initials as NSString).draw(in: textRect, withAttributes: attributes)
        }
    }
}

private struct AvatarImageKey: Hashable {
    let initials: String
    let size: CGSize
    let backgroundColor: RGBA
    let backgroundGradientColor: RGBA?
    let textColor: RGBA
    let fontName: String
    let pointSize: CGFloat

    var nsKey: NSString {
        [
            initials,
            "\(size.width)x\(size.height)",
            backgroundColor.serialized,
            backgroundGradientColor?.serialized ?? "none",
            textColor.serialized,
            fontName,
            "\(pointSize)"
        ].joined(separator: "|") as NSString
    }
}

private struct RGBA: Hashable {
    let red: CGFloat
    let green: CGFloat
    let blue: CGFloat
    let alpha: CGFloat

    var serialized: String { "\(red),\(green),\(blue),\(alpha)" }
}

private extension UIColor {
    var cacheableRGBA: RGBA {
        let resolved = resolvedColor(with: UITraitCollection.current)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        resolved.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return RGBA(red: red, green: green, blue: blue, alpha: alpha)
    }
}

private final class AvatarImageCache: @unchecked Sendable {
    private let storage = NSCache<NSString, UIImage>()

    init() {
        storage.countLimit = 256
    }

    subscript(key: AvatarImageKey) -> UIImage? {
        get { storage.object(forKey: key.nsKey) }
        set {
            if let newValue {
                storage.setObject(newValue, forKey: key.nsKey)
            } else {
                storage.removeObject(forKey: key.nsKey)
            }
        }
    }
}

private let avatarImageCache = AvatarImageCache()

private extension String {
    var avatarInitials: String {
        String(split(whereSeparator: \.isWhitespace).prefix(2).compactMap(\.first))
    }
}
