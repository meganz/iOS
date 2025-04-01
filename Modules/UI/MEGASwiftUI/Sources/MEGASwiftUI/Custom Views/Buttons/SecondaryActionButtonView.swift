import MEGAAppPresentation
import MEGADesignToken
import SwiftUI

public struct SecondaryActionButtonView: View {
    private let title: String
    private let action: (() -> Void)
    
    public init(
        title: String,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            SecondaryActionButtonViewText(title: title)
            .font(.title3)
        }
    }
}

public struct SecondaryActionButtonViewText: View {
    public init(title: String) {
        self.title = title
    }
    
    var title: String
    
    public var body: some View {
        Text(title)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .foregroundStyle(TokenColors.Text.accent.swiftUI)
            .background(TokenColors.Button.secondary.swiftUI)
            .cornerRadius(10)
            .contentShape(Rectangle())
    }
}
