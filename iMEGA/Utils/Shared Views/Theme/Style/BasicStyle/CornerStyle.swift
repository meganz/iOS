import UIKit

struct CornerStyle: Codable {
    typealias Radiux = CGFloat
    let radius: Radiux
}

// MARK: - Constant

extension CornerStyle {

    static var roundCornerStyle: CornerStyle { CornerStyle(radius: 8) }
}

// MARK: - UI Applier

extension CornerStyle {

    @discardableResult
    func applied<T: UIView>(on view: T) -> T {
        apply(style: self)(view)
    }
}

@discardableResult
private func apply<T: UIView>(style: CornerStyle) -> (T) -> T {
    return { view in
        view.layer.cornerRadius = style.radius
        view.clipsToBounds = true
        return view
    }
}
