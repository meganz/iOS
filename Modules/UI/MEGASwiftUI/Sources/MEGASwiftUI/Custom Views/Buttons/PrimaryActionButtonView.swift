import MEGADesignToken
import MEGAPresentation
import SwiftUI

public struct PrimaryActionButtonView: View {
    private let title: String
    private let action: (() -> Void)
    
    public init(title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            PrimaryActionButtonViewText(title: title)
            .font(.title3)
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
