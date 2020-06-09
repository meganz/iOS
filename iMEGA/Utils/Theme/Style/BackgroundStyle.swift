import UIKit

struct BackgroundStyle: Codable {
    let backgroundColor: Color
}

// MARK: - Constant

extension BackgroundStyle {

    static var warningBackgroundStyle: BackgroundStyle { BackgroundStyle(backgroundColor: .backgroundWarningYellow) }
}


extension BackgroundStyle {

    @discardableResult
    func applied(on view: UIView) -> UIView {
        apply(style: self)(view)
    }
}

@discardableResult
fileprivate func apply(style: BackgroundStyle) -> (UIView) -> UIView {
    return { view in
        view.backgroundColor = style.backgroundColor.uiColor
        return view
    }
}
