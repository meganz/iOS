import UIKit

struct CornerStyle: Codable {
    typealias Radiux = CGFloat
    let radius: Radiux
}

extension CornerStyle {
     
    @discardableResult
    func applied(on view: UIView) -> UIView {
        apply(style: self)(view)
    }

    static var roundCornerStyle: CornerStyle { CornerStyle(radius: 8) }
}

@discardableResult
fileprivate func apply(style: CornerStyle) -> (UIView) -> UIView {
    return { view in
        view.layer.cornerRadius = style.radius
        view.clipsToBounds = true
        return view
    }
}
