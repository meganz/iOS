import UIKit

struct BorderStyle: Codable {
    typealias BorderWidth = CGFloat
    
    let width: BorderWidth
    let color: ThemeColor
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
        view.layer.borderColor = style.color.uiColor.cgColor
        view.layer.borderWidth = style.width
        return view
    }
}
