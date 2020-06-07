import UIKit

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

    static var buttonDecorationStyle: DecorationStyle {
        DecorationStyle(corner: CornerStyle.roundCornerStyle)
    }
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
