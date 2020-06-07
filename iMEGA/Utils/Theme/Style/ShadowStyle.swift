import UIKit

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
