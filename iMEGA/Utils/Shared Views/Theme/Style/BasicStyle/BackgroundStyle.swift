import UIKit

struct BackgroundStyle: Codable {
    let backgroundColor: ThemeColor
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
        view.backgroundColor = style.backgroundColor.uiColor
        return view
    }
}
