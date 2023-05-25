import UIKit

struct ShadowStyle: Codable {
    typealias Offset = CGSize
    typealias Opacity = Float
    typealias Radius = CGFloat
    
    let shadowColor: ThemeColor
    var shadowOffset: Offset = .zero
    var shadowOpacity: Opacity = 1.0
    var shadowRadius: Radius = 10
}

extension ShadowStyle {
    
    // MARK: - UIView
     
    @discardableResult
    func applied(on view: UIView) -> UIView {
        apply(style: self)(view)
    }
}

@discardableResult
private func apply(style: ShadowStyle) -> (UIView) -> UIView {
    return { view in
        view.layer.shadowColor = style.shadowColor.uiColor.cgColor
        view.layer.shadowOffset = style.shadowOffset
        view.layer.shadowOpacity = style.shadowOpacity
        view.layer.shadowRadius = style.shadowRadius
        view.layer.masksToBounds = false

        return view
    }
}
