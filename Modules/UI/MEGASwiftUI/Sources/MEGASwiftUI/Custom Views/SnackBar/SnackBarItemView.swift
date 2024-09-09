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

struct SnackBarItemView: View {
    @Environment(\.colorScheme) private var colorScheme
    let snackBar: SnackBar

    private enum Constants {
        static let padding: CGFloat = 16
        static let spacing: CGFloat = 8
        static let cornerRadius: CGFloat = 8
    }
    
    var body: some View {
        content
            .background(snackBar.colors.background(isDesignTokenEnabled, colorScheme))
            .cornerRadius(Constants.cornerRadius)
            .shadow(color: snackBar.colors.shadow(isDesignTokenEnabled, colorScheme), radius: 4, x: 0, y: 1) // This line should be removed when design token is permanently applied. SnackBar won't have a shadow on design token UI.
            .padding(Constants.padding)
    }
        
    @ViewBuilder
    private var content: some View {
        switch snackBar.layout {
        case .crisscross:
            crisscross
        case .horizontal:
            horizontal
        }
    }
    
    private var crisscross: some View {
        VStack(alignment: .trailing, spacing: Constants.spacing) {
            HStack {
                Text(snackBar.message)
                    .font(.footnote)
                    .foregroundColor(snackBar.colors.titleForeground(isDesignTokenEnabled, colorScheme))
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
                    .padding(snackBar.isActionable ? [.leading, .top] : [.leading, .top, .trailing, .bottom], Constants.padding)
                Spacer()
            }
            if let action = snackBar.action {
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
            Text(snackBar.message)
                .font(.footnote)
                .foregroundColor(snackBar.colors.titleForeground(isDesignTokenEnabled, colorScheme))
                .multilineTextAlignment(.leading)
                .lineLimit(nil)
            Spacer()
            
            if let action = snackBar.action {
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
                    .foregroundColor(snackBar.colors.buttonForeground(isDesignTokenEnabled, colorScheme))
            })
    }
}

// MARK: - Preview

#Preview {
    VStack {
        SnackBarItemView(
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
        SnackBarItemView(
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
        SnackBarItemView(
            snackBar: SnackBar(
                message: "Message",
                layout: .crisscross,
                action: nil,
                colors: .default
            )
        )
        SnackBarItemView(
            snackBar: SnackBar(
                message: "Message",
                layout: .horizontal,
                action: nil,
                colors: .default
            )
        )
    }
}
