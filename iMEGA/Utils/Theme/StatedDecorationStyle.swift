import UIKit

struct DecorationStyle: Codable {
    var background: StatefulColorStyle? = nil
    var shadow: ShadowStyle? = nil
    var border: BorderStyle? = nil
    var corner: CornerStyle? = nil
}

extension DecorationStyle {
    
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

struct ShadowStyle: Codable {
    typealias Offset = CGSize
    
    let offset: Offset
    let color: Color
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
        view.layer.shadowColor = style.color.uiColor.cgColor
        view.layer.shadowOffset = style.offset
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
fileprivate func apply(style: DecorationStyle) -> (UILabel) -> UILabel {
    return { label in
        style.background?.applied(on: label)
        style.border?.applied(on: label)
        style.shadow?.applied(on: label)
        style.corner?.applied(on: label)
        return label
    }
}

@discardableResult
fileprivate func apply(style: DecorationStyle) -> (UIButton) -> UIButton {
    
    return { button in
        style.background?.applied(on: button)
        style.border?.applied(on: button)
        style.shadow?.applied(on: button)
        style.corner?.applied(on: button)
        return button
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
