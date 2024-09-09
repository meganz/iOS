import MEGADesignToken
import SwiftUI

public struct SnackBar: Equatable {
    
    public enum Layout {
        case crisscross
        case horizontal
    }
    
    public struct Action: Equatable {
        public let title: String
        public let handler: () -> Void
        
        public init(title: String, handler: @escaping () -> Void) {
            self.title = title
            self.handler = handler
        }
        
        public static func == (lhs: Action, rhs: Action) -> Bool {
            lhs.title == rhs.title
        }
    }
    
    public struct Colors {
        typealias ColorProvider = (_ designTokenEnabled: Bool, _ scheme: ColorScheme) -> Color
        var titleForeground: ColorProvider
        var background: ColorProvider
        var buttonForeground: ColorProvider
        var shadow: ColorProvider
        
        public static var `default`: Colors {
            Colors(
                titleForeground: { _, _ in TokenColors.Text.inverse.swiftUI },
                background: { _, _ in TokenColors.Components.toastBackground.swiftUI },
                buttonForeground: { _, _ in TokenColors.Link.inverse.swiftUI },
                shadow: { _, _ in .clear }
            )
        }
        
        public static var raiseHand: Colors {
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
    
    public let message: String
    public let layout: Layout
    public let action: Action?
    public let colors: Colors
    
    public init(message: String, layout: Layout = .crisscross, action: Action? = nil, colors: Colors = .default) {
        self.message = message
        self.layout = layout
        self.action = action
        self.colors = colors
    }
    
    var isActionable: Bool {
        action != nil
    }
    
    public static func == (lhs: SnackBar, rhs: SnackBar) -> Bool {
        lhs.message == rhs.message && lhs.action == rhs.action
    }
    
    // modifier that simply appends an action to be executed after the initial one
    // use case: be able to simply and in single call sit add some action without
    // knowing what was the original one
    // Used to trigger hiding of snack bar independently of the factory code that produced initial
    // snack bar actions
    public func withSupplementalAction(_ afterAction: @escaping () -> Void) -> Self {
        
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
