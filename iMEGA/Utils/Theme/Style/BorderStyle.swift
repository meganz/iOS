import UIKit

struct BorderStyle: Codable {
    typealias BorderWidth = CGFloat
    
    let width: BorderWidth
    let color: Color
}

extension BorderStyle {

    static var inactiveBorderStyle: BorderStyle { BorderStyle(width: 1, color: Color.borderInactiveGrey) }

    static var warningBorderStyle: BorderStyle { BorderStyle(width: 1, color: Color.borderWarningYellow) }
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
