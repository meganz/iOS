import MEGADesignToken
import SwiftUI

struct SnackBar: Equatable {
    
    enum Layout {
        case crisscross
        case horizontal
    }
    struct Action: Equatable {
        var title: String
        var handler: () -> Void
        
        static func == (lhs: Action, rhs: Action) -> Bool {
            lhs.title == rhs.title
        }
        
    }
    
    struct Colors {
        typealias ColorProvider = (_ designTokenEnabled: Bool, _ scheme: ColorScheme) -> Color
        var titleForeground: ColorProvider
        var background: ColorProvider
        var buttonForeground: ColorProvider
        var shadow: ColorProvider
        
        static var `default`: Colors {
            Colors(
                titleForeground: { designTokenEnabled, colorScheme in
                    if designTokenEnabled {
                        TokenColors.Text.inverse.swiftUI
                    } else {
                        colorScheme == .light ? UIColor.whiteFFFFFF.swiftUI : UIColor.black000000.swiftUI
                    }
                },
                background: { designTokenEnabled, colorScheme in
                    if designTokenEnabled {
                        TokenColors.Components.toastBackground.swiftUI
                    } else {
                        colorScheme == .light ? UIColor.gray3A3A3C.swiftUI : UIColor.whiteFFFFFF.swiftUI
                    }
                },
                buttonForeground: { designTokenEnabled, _ in
                    designTokenEnabled ? TokenColors.Link.inverse.swiftUI : MEGAAppColor.Green._00A886.color
                },
                shadow: { designTokenEnabled, _ in
                    designTokenEnabled ? .clear : MEGAAppColor.Black._000000.color.opacity(0.1)
                }
            )
        }
        
        static var raiseHand: Colors {
            let base = Colors.default
            return .init(
                titleForeground: base.titleForeground,
                background: { _, _ in
                    return .white
                },
                buttonForeground: base.buttonForeground,
                shadow: base.shadow
            )
        }
    }
    
    var message: String
    var layout: Layout = .crisscross
    var action: Action?
    var colors: Colors = .default
    
    var isActionable: Bool {
        action != nil
    }
    
    static func == (lhs: SnackBar, rhs: SnackBar) -> Bool {
        lhs.message == rhs.message && lhs.action == rhs.action
    }
    
    // modifier that simply appends an action to be executed after the initial one
    // use case: be able to simply and in single call sit add some action without
    // knowing what was the original one
    // Used to trigger hiding of snack bar independently of the factory code that produced initial
    // snack bar actions
    func withSupplementalAction(_ afterAction: @escaping () -> Void) -> Self {
        
        // if SnackBar has `action`, we execute `afterAction` after `action` was triggered
        // if SnackBar has no `action` we do not modify the snack bar
        func action() -> SnackBar.Action? {
            guard let action = self.action else {
                return nil
            }
            return .init(
                title: action.title,
                handler: {
                    action.handler()
                    afterAction()
                }
            )
        }
        
        return SnackBar(
            message: message,
            layout: layout,
            action: action(),
            colors: colors
        )
    }
}
