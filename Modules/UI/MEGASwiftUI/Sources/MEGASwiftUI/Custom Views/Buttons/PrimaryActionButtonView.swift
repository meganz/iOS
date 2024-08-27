import MEGADesignToken
import MEGAPresentation
import SwiftUI

public struct PrimaryActionButtonView: View {
    private let title: String
    private let action: (() -> Void)
    
    @Environment(\.colorScheme) var colorScheme
    private var backgroundColor: Color {
        colorScheme == .dark ? Color(red: 0, green: 0.76, blue: 0.60) : Color(red: 0, green: 0.65, blue: 0.52)
    }
    public init(title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            Text(title)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .foregroundColor(
                    isDesignTokenEnabled ? TokenColors.Text.inverseAccent.swiftUI : .white
                )
                .font(.title3)
                .background(
                    isDesignTokenEnabled ? TokenColors.Button.primary.swiftUI : backgroundColor
                )
                .cornerRadius(10)
                .contentShape(Rectangle())
        }
    }
}
