import UIKit

typealias ButtonStyler = (UIButton) -> Void

enum ButtonStyle {
    case active
    case inactive

    var style: ButtonStyler {
        switch self {
        case .active: return primaryButtonStyler
        case .inactive: return secondaryButtonStyler
        }
    }
}

fileprivate let primaryButtonStyler: (UIButton) -> Void = { button in
    CornerStyle.roundCornerStyle.applied(on:
        ButtonStatedStyle.greenBackgroundStyle.applied(on:
            ButtonStatedStyle.whiteTextStyle.applied(on: button)))
}

fileprivate let secondaryButtonStyler: (UIButton) -> Void = { (button: UIButton) in
    CornerStyle.roundCornerStyle.applied(on:
        BorderStyle.inactiveBorderStyle.applied(on:
            ButtonStatedStyle.whiteBackgroundStyle.applied(on:
                ButtonStatedStyle.greenTextStyle.applied(on: button))))
}
