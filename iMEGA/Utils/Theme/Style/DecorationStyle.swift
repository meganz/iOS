import UIKit

struct DecorationStyle: Codable {
    var shadow: ShadowStyle? = nil
    var border: BorderStyle? = nil
    var corner: CornerStyle? = nil
}

// MARK: - Constants

extension DecorationStyle {

    static var roundCornerButtonDecorationStyle: DecorationStyle {
        DecorationStyle(corner: CornerStyle.roundCornerStyle)
    }
}

// MARK: - UI Applier

extension DecorationStyle {
    
    @discardableResult
    func applied(on view: UIView) -> UIView {
        apply(style: self)(view)
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
