import UIKit

struct Styler<View: UIView> {
    var style: (View) -> View
}

enum ButtonStyle {
    case primaryButton
    case secondaryButton

    var style: (UIButton) -> Void {
        switch self {
        case .primaryButton:
            return primaryButtonStyler
        case .secondaryButton:
            return secondaryButtonStyler
        }
    }
}

fileprivate let primaryButtonStyler: (UIButton) -> Void = { button in
    DecorationStyle.buttonDecorationStyle.applied(on:
        ButtonStatedStyle.greenBackgroundStyle.applied(on:
            ButtonStatedStyle.whiteTextStyle.applied(on: button)))
}

fileprivate let secondaryButtonStyler: (UIButton) -> Void = { (button: UIButton) in
    DecorationStyle.buttonDecorationStyle.applied(on:
        ButtonStatedStyle.whiteBackgroundStyle.applied(on:
            ButtonStatedStyle.greenTextStyle.applied(on: button)))
}
