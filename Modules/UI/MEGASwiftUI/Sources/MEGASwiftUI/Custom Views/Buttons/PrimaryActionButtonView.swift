import MEGAAppPresentation
import MEGADesignToken
import SwiftUI

public struct PrimaryActionButtonView: View {
    private let title: String
    private let font: Font
    private let action: @MainActor () -> Void
    
    public init(title: String, font: Font = .title3, action: @escaping @MainActor () -> Void) {
        self.title = title
        self.action = action
        self.font = font
    }
    
    public var body: some View {
        Button(action: action) {
            PrimaryActionButtonViewText(title: title)
            .font(font)
        }
    }
}

public struct PrimaryActionButtonViewText: View {
    public init(title: String) {
        self.title = title
    }
    
    var title: String
    
    public var body: some View {
        Text(title)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .foregroundColor(TokenColors.Text.inverseAccent.swiftUI)
            .background(TokenColors.Button.primary.swiftUI)
            .cornerRadius(10)
            .contentShape(Rectangle())
    }
}
