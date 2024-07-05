import MEGADesignToken
import SwiftUI

// SnackBar.Layout options:
// .crisscross:
// ┌───────────────────────────────────────────────────────────┐
// │                                           ▲               │
// │ ┌────────────────────────┐                │               │
// │ │      Title             │       Spacer   │               │
// │ └────────────────────────┘                ▼               │
// │            ▲                  ┌────────────────────────┐  │
// │            │                  │        Button          │  │
// │  Spacer    │                  │                        │  │
// │            │                  └────────────────────────┘  │
// │            ▼                                              │
// └───────────────────────────────────────────────────────────┘
//  .horizontal
// ┌───────────────────────────────────────────────────────────┐
// │                                                           │
// │ ┌────────────────────────┐   ┌──────────────────────────┐ │
// │ │                        │   │                          │ │
// │ │       Title            │   │       Button             │ │
// │ └────────────────────────┘   └──────────────────────────┘ │
// │                                                           │
// └───────────────────────────────────────────────────────────┘

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
}

struct SnackBarView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject var viewModel: SnackBarViewModel
    
    private enum Constants {
        static let padding: CGFloat = 16
        static let spacing: CGFloat = 8
        static let cornerRadius: CGFloat = 8
    }
    
    var body: some View {
        content
            .background(viewModel.snackBar.colors.background(isDesignTokenEnabled, colorScheme))
            .cornerRadius(Constants.cornerRadius)
            .shadow(color: viewModel.snackBar.colors.shadow(isDesignTokenEnabled, colorScheme), radius: 4, x: 0, y: 1) // This line should be removed when design token is permanently applied. SnackBar won't have a shadow on design token UI.
            .padding(Constants.padding)
    }
    
    @ViewBuilder
    private var content: some View {
        switch viewModel.snackBar.layout {
        case .crisscross:
            crisscross
        case .horizontal:
            horizontal
        }
    }
    
    private var crisscross: some View {
        VStack(alignment: .trailing, spacing: Constants.spacing) {
            HStack {
                Text(viewModel.snackBar.message)
                    .font(.footnote)
                    .foregroundColor(viewModel.snackBar.colors.titleForeground(isDesignTokenEnabled, colorScheme))
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
                    .padding(viewModel.snackBar.isActionable ? [.leading, .top] : [.leading, .top, .trailing, .bottom], Constants.padding)
                Spacer()
            }
            if let action = viewModel.snackBar.action {
                HStack {
                    Spacer()
                    actionButton(action)
                    .padding([.trailing, .bottom], Constants.padding)
                }
            }
        }
    }
    
    private var horizontal: some View {
        HStack(spacing: Constants.spacing) {
            Text(viewModel.snackBar.message)
                .font(.footnote)
                .foregroundColor(viewModel.snackBar.colors.titleForeground(isDesignTokenEnabled, colorScheme))
                .multilineTextAlignment(.leading)
                .lineLimit(nil)
            Spacer()
            
            if let action = viewModel.snackBar.action {
                actionButton(action)
            }
        }
        .padding(Constants.padding)
    }
    
    private func actionButton(_ action: SnackBar.Action) -> some View {
        Button(
            action: action.handler,
            label: {
                Text(action.title)
                    .font(.footnote).bold()
                    .foregroundColor(viewModel.snackBar.colors.buttonForeground(isDesignTokenEnabled, colorScheme))
            })
    }
}

// MARK: - Preview

#Preview {
    VStack {
        SnackBarView(
            viewModel: SnackBarViewModel(
                snackBar: SnackBar(
                    message: "Your hand is raised",
                    layout: .crisscross,
                    action: .init(
                        title: "Lower hand",
                        handler: {}
                    ),
                    colors: .default
                )
            )
        )
        SnackBarView(
            viewModel: SnackBarViewModel(
                snackBar: SnackBar(
                    message: "Your hand is raised",
                    layout: .horizontal,
                    action: .init(
                        title: "Lower hand",
                        handler: {}
                    ),
                    colors: .raiseHand
                )
            )
        )
        SnackBarView(
            viewModel: SnackBarViewModel(
                snackBar: SnackBar(
                    message: "Message",
                    layout: .crisscross,
                    action: nil,
                    colors: .default
                )
            )
        )
        SnackBarView(
            viewModel: SnackBarViewModel(
                snackBar: SnackBar(
                    message: "Message",
                    layout: .horizontal,
                    action: nil,
                    colors: .default
                )
            )
        )
    }
}
