import UIKit

public extension UILabel {
    @objc static func customNavBarLabel(title: String,
                                        titleFont: UIFont = UIFont.preferredFont(forTextStyle: .headline),
                                        subtitle: String?,
                                        subtitleFont: UIFont = UIFont.preferredFont(style: .caption1, weight: .semibold),
                                        titleColor: UIColor,
                                        subtitleColor: UIColor?) -> UILabel {
        let label = UILabel()
        label.numberOfLines = (subtitle != nil) ? 2 : 1
        label.lineBreakMode = .byTruncatingTail
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.8
        
        let attributedTitleString = NSMutableAttributedString(string: title, attributes: [
            NSAttributedString.Key.font: titleFont,
            .foregroundColor: titleColor
        ])
        
        guard let subtitle = subtitle, subtitle.count != 0 else {
            label.attributedText = attributedTitleString
            return label
        }
        
        let subtitleString = String(format: "\n%@", subtitle)
        var subtitleAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: subtitleFont]
        
        if let subtitleColor {
            subtitleAttributes[.foregroundColor] = subtitleColor
        }
        
        let attributedSubtitleString = NSMutableAttributedString(string: subtitleString, attributes: subtitleAttributes)
        
        attributedTitleString.append(attributedSubtitleString)
        label.attributedText = attributedTitleString
        return label
    }
}
