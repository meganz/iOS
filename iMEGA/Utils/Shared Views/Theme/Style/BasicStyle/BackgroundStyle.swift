import UIKit

struct BackgroundStyle {
    let backgroundColor: UIColor
}

extension BackgroundStyle {

    @discardableResult
    func applied(on view: UIView) -> UIView {
        apply(style: self)(view)
    }
}

@discardableResult
private func apply(style: BackgroundStyle) -> (UIView) -> UIView {
    return { view in
        view.backgroundColor = style.backgroundColor
        return view
    }
}
