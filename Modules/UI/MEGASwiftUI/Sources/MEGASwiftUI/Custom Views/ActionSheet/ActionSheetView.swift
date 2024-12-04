import MEGADesignToken
import SwiftUI

public struct ActionSheetContentView<HeaderView: View>: View {
    var style: Style = .default
    var actionButtons: [ActionSheetButton]
    var headerView: HeaderView
    
    public enum Style {
        case `default`
        case plainIgnoreHeaderIgnoreScrolling
    }
    
    private var bodyBackgroundColor: Color {
        TokenColors.Background.surface1.swiftUI
    }

    public init(
        style: ActionSheetContentView.Style = .default,
        headerView: HeaderView,
        actionButtons: [ActionSheetButton]
    ) {
        self.style = style
        self.headerView = headerView
        self.actionButtons = actionButtons
    }

    public var body: some View {
        switch style {
        case .default:
            defaultContent
        case .plainIgnoreHeaderIgnoreScrolling:
            plainIgnoreHeaderIgnoreScrolling
        }
    }
    
    private var defaultContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    Capsule()
                        .fill(Color.secondary)
                        .opacity(0.5)
                        .frame(width: 36, height: 5)
                        .padding(5)
                    
                    headerView
                        .padding(.bottom, 2)
                    
                    Divider()
                }
                .background(TokenColors.Background.surface2.swiftUI)
                
                ForEach(actionButtons, id: \.self) { button in
                    button
                }
            }
            .padding([.bottom], 30)
        }
        .background(bodyBackgroundColor)
    }
    
    private var plainIgnoreHeaderIgnoreScrolling: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 16)
            ForEach(actionButtons, id: \.self) { button in
                button
            }
            Spacer()
        }
        .padding([.bottom, .top], 30)
        .background(bodyBackgroundColor)
    }
}

public struct ActionSheetButton: View, Hashable {
    @Environment(\.presentationMode) var presentationMode
    var icon: String
    var title: String
    var subtitle: String?
    var action: () -> Void
    
    public init(icon: String, title: String, subtitle: String? = nil, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.action = action
    }
    
    nonisolated public static func == (lhs: ActionSheetButton, rhs: ActionSheetButton) -> Bool {
        lhs.icon == rhs.icon && lhs.title == rhs.title && lhs.subtitle == rhs.subtitle
    }
    
    nonisolated public func hash(into hasher: inout Hasher) {
        hasher.combine(icon)
        hasher.combine(title)
        hasher.combine(subtitle)
    }

    public var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(icon)
                    .frame(width: 28, height: 28)
                    .padding(16)
                
                Text(title)
                    .font(.body)
                    .foregroundStyle(TokenColors.Text.primary.swiftUI)
                
                Spacer()
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.callout)
                        .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                    
                    Image("standardDisclosureIndicator")
                        .padding([.trailing], 16)
                        .padding([.leading], 5)
                }
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .onTapGesture {
                action()
                presentationMode.wrappedValue.dismiss()
            }
            Divider()
                .padding([.leading], 60)
        }
        .background(TokenColors.Background.surface1.swiftUI)
    }
}
