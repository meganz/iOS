import UIKit

struct BorderStyle {
    typealias BorderWidth = CGFloat
    
    let width: BorderWidth
    let color: UIColor
}

extension BorderStyle {
    
    // MARK: - UIView
     
    @discardableResult
    @MainActor
    func applied(on view: UIView) -> UIView {
        apply(style: self)(view)
    }
}

@discardableResult
@MainActor
private func apply(style: BorderStyle) -> (UIView) -> UIView {
    return { view in
        view.layer.borderColor = style.color.cgColor
        view.layer.borderWidth = style.width
        return view
    }
}
