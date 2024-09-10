import MEGADesignToken
import SwiftUI

public struct RadioButton: View {
    let id: Int
    private let text: String
    private let textFont: Font
    private let isSelected: Bool
    private let action: (() -> Void)
    
    public init(
        id: Int,
        text: String,
        textFont: Font = .subheadline,
        isSelected: Bool,
        action: @escaping () -> Void
    ) {
        self.id = id
        self.text = text
        self.textFont = textFont
        self.isSelected = isSelected
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                RadioButtonIcon(isSelected: isSelected)
                
                Text(text)
                    .font(textFont)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(TokenColors.Text.primary.swiftUI)
                
                Spacer()
            }
            .transaction { transaction in
                transaction.animation = nil
            }
        }
        .frame(maxWidth: .infinity)
        .background(.clear)
        .contentShape(Rectangle())
        .buttonStyle(PlainButtonStyle())
    }
}

private struct RadioButtonIcon: View {
    let isSelected: Bool
    let size: CGFloat = 20

    var body: some View {
        ZStack {
            Circle()
                .stroke()
                .foregroundStyle(TokenColors.Icon.primary.swiftUI)
                .frame(width: size, height: size)
            
            if isSelected {
                Circle()
                    .fill(TokenColors.Icon.primary.swiftUI)
                    .frame(width: size * 0.5, height: size * 0.5)
            }
        }
    }
}

#Preview {
    Group {
        RadioButton(id: 1, text: "Test Item 1", isSelected: true, action: {})
        RadioButton(id: 2, text: "Test Item 2", isSelected: false, action: {})
    }
}
