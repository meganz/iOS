import MEGADesignToken
import MEGAPresentation
import SwiftUI

public struct SecondaryActionButtonView: View {
    private let title: String
    private let action: (() -> Void)
    private let isDesignTokenEnabled: Bool
    public init(
        isDesignTokenEnabled: Bool = designTokenEnabled(),
        title: String,
        action: @escaping () -> Void
    ) {
        self.isDesignTokenEnabled = isDesignTokenEnabled
        self.title = title
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            SecondaryActionButtonViewText(
                title: title,
                isDesignTokenEnabled: isDesignTokenEnabled
            )
            .font(.title3)
        }
        .shadow(color: isDesignTokenEnabled ? .clear : Color.black.opacity(0.15), radius: 4, y: 1) // Shadow should be removed when design token is permanently applied as it won't be needed.
    }
}

public struct SecondaryActionButtonViewText: View {
    public init(
        title: String,
        isDesignTokenEnabled: Bool
    ) {
        self.title = title
        self.isDesignTokenEnabled = isDesignTokenEnabled
    }
    
    var title: String
    var isDesignTokenEnabled: Bool
    
    @Environment(\.colorScheme) var colorScheme
    private var textColor: Color {
        colorScheme == .dark ? Color(red: 0, green: 0.76, blue: 0.60) : Color(red: 0, green: 0.65, blue: 0.52)
    }
    
    private var background: Color {
        colorScheme == .dark ? Color(red: 0.21, green: 0.21, blue: 0.22) : Color.white
    }
    
    public var body: some View {
        Text(title)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .foregroundStyle(isDesignTokenEnabled ? TokenColors.Text.accent.swiftUI : textColor)
            .background(isDesignTokenEnabled ? TokenColors.Button.secondary.swiftUI : background)
            .cornerRadius(10)
            .contentShape(Rectangle())
    }
}
