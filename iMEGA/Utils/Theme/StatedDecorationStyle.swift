import UIKit

struct BackgroundStyle: Codable {
    let backgroundColor: Color
}

extension BackgroundStyle {

    @discardableResult
    func applied(on view: UIView) -> UIView {
        apply(style: self)(view)
    }
}

@discardableResult
fileprivate func apply(style: BackgroundStyle) -> (UIView) -> UIView {
    return { view in
        view.backgroundColor = style.backgroundColor.uiColor
        return view
    }
}

struct DecorationStyle: Codable {
    var shadow: ShadowStyle? = nil
    var border: BorderStyle? = nil
    var corner: CornerStyle? = nil
}

extension DecorationStyle {
    
    @discardableResult
    func applied(on view: UIView) -> UIView {
        apply(style: self)(view)
    }
}

struct ShadowStyle: Codable {
    typealias Offset = CGSize
    
    let shadowOffset: Offset
    let shadowColor: Color

    let cornerRadius: Radiux = 8
    typealias Radiux = CGFloat
}

extension ShadowStyle {
    
    // MARK: - UIView
     
    @discardableResult
    func applied(on view: UIView) -> UIView {
        apply(style: self)(view)
    }
}

@discardableResult
fileprivate func apply(style: ShadowStyle) -> (UIView) -> UIView {
    return { view in
        view.layer.shadowColor = style.shadowColor.uiColor.cgColor
        view.layer.shadowOffset = .zero
        view.layer.shadowOpacity = 1.0
        view.layer.shadowRadius = 10
        view.layer.masksToBounds = false

        return view
    }
}

struct BorderStyle: Codable {
    typealias BorderWidth = CGFloat
    
    let width: BorderWidth
    let color: Color
}

extension BorderStyle {
    
    // MARK: - UIView
     
    @discardableResult
    func applied(on view: UIView) -> UIView {
        apply(style: self)(view)
    }
}

@discardableResult
fileprivate func apply(style: BorderStyle) -> (UIView) -> UIView {
    return { view in
        view.layer.borderColor = style.color.uiColor.cgColor
        view.layer.borderWidth = style.width
        return view
    }
}

struct CornerStyle: Codable {
    typealias Radiux = CGFloat
    let radius: Radiux
}

extension CornerStyle {
    
    // MARK: - UIView
     
    @discardableResult
    func applied(on view: UIView) -> UIView {
        apply(style: self)(view)
    }
}

@discardableResult
fileprivate func apply(style: CornerStyle) -> (UIView) -> UIView {
    return { view in
        view.layer.cornerRadius = style.radius
        view.clipsToBounds = true
        return view
    }
}

struct StatefulColorStyle: Codable {
    let normal: Color
    let highlighted: Color
    let disabled: Color
}

extension StatefulColorStyle {
    
    // MARK: - UILabel
     
    @discardableResult
    func applied(on label: UILabel) -> UILabel {
        apply(style: self)(label)
    }
    
    // MARK: - UIButton
     
    @discardableResult
    func applied(on button: UIButton) -> UIButton {
        apply(style: self)(button)
    }
}

@discardableResult
fileprivate func apply(style: StatefulColorStyle) -> (UIButton) -> UIButton {
    return { button in
        button.setBackgroundColor(style.normal.uiColor, for: .normal)
        button.setBackgroundColor(style.highlighted.uiColor, for: .highlighted)
        button.setBackgroundColor(style.disabled.uiColor, for: .disabled)
        
        return button
    }
}

@discardableResult
fileprivate func apply(style: StatefulColorStyle) -> (UILabel) -> UILabel {
    return { label in
        label.backgroundColor = style.normal.uiColor
        return label
    }
}

extension StatefulColorStyle {
    static var greenButtonColor: StatefulColorStyle { StatefulColorStyle(normal: .backgroundEnabledPrimary,
                                                               highlighted: .backgroundHighlightedPrimary,
                                                               disabled: .backgroundDisabledPrimary) }
}

@discardableResult
fileprivate func apply(style: DecorationStyle) -> (UIView) -> UIView {
    
    return { view in
        style.border?.applied(on: view)
        style.corner?.applied(on: view)
        style.shadow?.applied(on: view)
        return view
    }
}

extension UIColor {
    
    func image(withSize size: CGSize) -> UIImage {
        return UIGraphicsImageRenderer.init(size: size).image { context in
            setFill()
            context.fill(CGRect(origin: CGPoint(x: 0, y: 0), size: size))
        }
    }
}

extension UIButton {

    func setBackgroundColor(_ color: UIColor, for state: UIControl.State) {
        self.setBackgroundImage(color.image(withSize: CGSize(width: 1, height: 1)), for: state)
    }
}

final class RoundCornerShadowButton: UIButton {

    override func layoutSubviews() {
        super.layoutSubviews()
        if nil != layer.shadowPath {
            layer.shadowPath = UIBezierPath(roundedRect: bounds,
                                            cornerRadius: layer.cornerRadius).cgPath
        }
    }
}
