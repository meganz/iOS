import UIKit

struct BorderStyle {
    typealias BorderWidth = CGFloat
    
    let width: BorderWidth
    let color: UIColor
}

extension BorderStyle {
    
    // MARK: - UIView
     
    @discardableResult
    func applied(on view: UIView) -> UIView {
        apply(style: self)(view)
    }
}

@discardableResult
private func apply(style: BorderStyle) -> (UIView) -> UIView {
    return { view in
        view.layer.borderColor = style.color.cgColor
        view.layer.borderWidth = style.width
        return view
    }
}
