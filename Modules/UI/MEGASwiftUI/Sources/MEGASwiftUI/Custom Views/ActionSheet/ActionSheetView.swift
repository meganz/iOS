import MEGADesignToken
import SwiftUI

public struct ActionSheetContentView<HeaderView: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    var actionButtons: [ActionSheetButton]
    var headerView: HeaderView
    
    private var headerBackgroundColor: Color {
        guard isDesignTokenEnabled else {
            return colorScheme == .dark ? Color(red: 0.286, green: 0.290, blue: 0.302) : Color(red: 0.953, green: 0.957, blue: 0.957)
        }
        
        return TokenColors.Background.surface2.swiftUI
    }
    
    private var bodyBackgroundColor: Color {
        guard isDesignTokenEnabled else {
            return colorScheme == .dark ? Color(red: 0.188, green: 0.196, blue: 0.2) : Color(red: 0.980, green: 0.980, blue: 0.980)
        }
        
        return TokenColors.Background.surface1.swiftUI
    }

    public init(headerView: HeaderView, actionButtons: [ActionSheetButton]) {
        self.headerView = headerView
        self.actionButtons = actionButtons
    }

    public var body: some View {
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
                .background(headerBackgroundColor)
                
                ForEach(actionButtons, id: \.self) { button in
                    button
                }
            }
            .padding([.bottom], 30)
        }
        .background(bodyBackgroundColor)
    }
}

public struct ActionSheetButton: View, Hashable {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.presentationMode) var presentationMode
    var icon: String
    var title: String
    var subtitle: String?
    var action: () -> Void
    
    private var buttonBackgroundColor: Color {
        guard isDesignTokenEnabled else {
            return colorScheme == .dark ? Color(red: 0.188, green: 0.196, blue: 0.2) : Color(red: 0.980, green: 0.980, blue: 0.980)
        }
        
        return TokenColors.Background.surface1.swiftUI
    }
    
    public init(icon: String, title: String, subtitle: String? = nil, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.action = action
    }
    
    public static func == (lhs: ActionSheetButton, rhs: ActionSheetButton) -> Bool {
        lhs.icon == rhs.icon && lhs.title == rhs.title && lhs.subtitle == rhs.subtitle
    }
    
    public func hash(into hasher: inout Hasher) {
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
                    .foregroundStyle(isDesignTokenEnabled ? TokenColors.Text.primary.swiftUI : .primary)
                
                Spacer()
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.callout)
                        .foregroundStyle(isDesignTokenEnabled ? TokenColors.Text.secondary.swiftUI : .secondary)
                    
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
        .background(buttonBackgroundColor)
    }
}
