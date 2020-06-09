import UIKit

typealias ViewStyler = (UIView) -> Void

enum ViewStyle {
    case warning

    var style: ViewStyler {
        switch self {
        case .warning: return warningStyler
        }
    }
}

fileprivate let warningStyler: (UIView) -> Void = { view in
    BackgroundStyle.warningBackgroundStyle.applied(on:
        CornerStyle.roundCornerStyle.applied(on:
            BorderStyle.warningBorderStyle.applied(on: view)))
}
